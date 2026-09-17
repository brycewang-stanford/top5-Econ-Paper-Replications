"""Tables IV and V: does the lagged stock of public-security AI blunt the effect of
unrest-conducive weather on unrest?  (Analysis.do section 10)

Starts from the prefecture-quarter panels saved *before* the conducive-weather first stage
(Data/Intermediate/statspai/s10_raw_b{1,2,3}.dta, see make_export_do.py) and rebuilds every
variable in Python:
  1. first stage  event ~ event_elsewhere + LASSO-selected weather terms | qofd + place  -> event_hat (xb)
  2. demean / standardize exactly as the do-file (Stata `su` uses the full, non-missing sample)
  3. second stage event ~ pol + blank_hat + blank_pol + controls x quarter | qofd + place,
     if circle_1000k==1, cluster(place)  [ivreghdfe small-sample factor]
"""
from common import *

KEEP = ["blank_hat", "pol", "blank_pol"]


def z(s):
    return (s - s.mean()) / s.std()


def first_stage(d, terms):
    """terms: list of (name, expression over d). Returns xb from HDFE OLS of event on terms."""
    names = []
    for name, f in terms:
        d[name] = f(d)
        names.append(name)
    sc = d[names].std().replace(0, 1.0).fillna(1.0)
    names = [v for v in names if d[v].std() > 0]  # all-zero terms are dropped as collinear (as in Stata)
    sc = sc.reindex(names)
    tmp = d.copy()
    for v in names:
        tmp[v] = d[v] / sc[v]  # rescale for the demeaning algorithm; xb unchanged
    b, _, info, _ = hdfe("event ~ " + " + ".join(names), tmp, ["qofd", "place"], singletons=True)
    coef = (b / sc.reindex(b.index)).reindex(names).fillna(0.0)
    xb = (d[names] * coef.values).sum(axis=1)
    xb[d[names].isna().any(axis=1)] = np.nan
    return xb, coef, info


E = lambda v: (lambda d: d[v])
P = lambda a, b: (lambda d: d[a] * d[b])
I3_T4 = [("event_elsewhere", E("event_elsewhere")), ("fog_visib", P("fog", "visib")),
         ("frshtt_visib", P("frshtt", "visib")), ("rainXEE_", E("rainXEE")), ("stpXEE_", E("stpXEE")),
         ("rain_stp", P("rainXEE", "stpXEE")), ("snowXEE_", E("snowXEE")), ("snow_stp", P("snowXEE", "stpXEE")),
         ("stp_stp", P("stpXEE", "stpXEE")), ("stp_visib", P("stpXEE", "visibXEE")),
         ("fog_min", P("fogXEE", "minXEE")), ("frshtt_stp", P("frshttXEE", "stpXEE"))]
# Table V Panel B uses a different LASSO-selected list (do-file block "Table 5B")
I3_T5B = [("event_elsewhere", E("event_elsewhere")), ("fog_visib", P("fog", "visib")),
          ("frshtt_visib", P("frshtt", "visib")), ("dew_fog", P("dewXEE", "fogXEE")),
          ("min2_temp5", P("min2XEE", "temp5XEE")), ("min3XEE_", E("min3XEE")), ("stpXEE_", E("stpXEE")),
          ("min3_stp", P("min3XEE", "stpXEE")), ("rainXEE_", E("rainXEE")), ("rain_stp", P("rainXEE", "stpXEE")),
          ("snowXEE_", E("snowXEE")), ("snow_stp", P("snowXEE", "stpXEE")), ("stp_stp", P("stpXEE", "stpXEE")),
          ("stp_visib", P("stpXEE", "visibXEE")), ("frshtt_stp", P("frshttXEE", "stpXEE")),
          ("max1_min4", P("max1XEE", "min4XEE")), ("max2_stp", P("max2XEE", "stpXEE"))]


def build(block, i3, impute=True, cam=False):
    d = read_dta(XDATA / f"s10_raw_b{block}.dta")
    xb, coef, info = first_stage(d, i3)
    d["event_hat"] = xb - xb.mean()
    if cam:
        d["lead_camera_time_city_pc"] = z(d["lead_camera_time_city_pc"])
    d["event"] = z(d["event"])
    d["blank_hat"] = z(d["event_hat"])
    if impute:
        g = d.groupby("prov_eng")
        d["prefecture_gdp"] = d["prefecture_gdp"].fillna(g["prefecture_gdp"].transform("mean"))
        d["prefecture_city_population"] = np.log(d["prefecture_city_population"])
        d["prefecture_city_population"] = d["prefecture_city_population"].fillna(
            d.groupby("prov_eng")["prefecture_city_population"].transform("mean"))
        d["epop"] = np.exp(d["prefecture_city_population"])
        d["prefecture_fiscal_revenue"] = d["prefecture_fiscal_revenue"].fillna(
            g["prefecture_fiscal_revenue"].transform("mean"))
    return d, coef, info


def controls(col, epop=True):
    gdp = "prefecture_gdp + i(qofd, prefecture_gdp)"
    pop = "prefecture_city_population + i(qofd, prefecture_city_population)"
    rev = "prefecture_fiscal_revenue + i(qofd, prefecture_fiscal_revenue)"
    e = " + epop" if epop else ""
    return {1: gdp,
            2: "prefecture_gdp" + e + " + " + pop,
            3: "prefecture_gdp + " + rev,
            4: "prefecture_gdp" + e + " + " + gdp + " + " + pop + " + " + rev}[col]


def run_panel(d, table, panel, polvar, epop=True):
    rows = []
    s = d[d.circle_1000k == 1].copy()
    # NOTE (StatsPAI/pyfixest friction): the GDP / population / revenue x quarter controls are on
    # scales up to 1e7, and sp.feols then returns NaN or wrong CRV1 SEs (ill-conditioned X'X, no
    # internal column scaling).  Rescaling these nuisance controls leaves the coefficients and SEs of
    # the reported terms unchanged (linear reparametrisation of the control space), so we divide by
    # their standard deviation.
    for v in ["prefecture_gdp", "prefecture_city_population", "prefecture_fiscal_revenue", "epop"]:
        if v in s:
            s[v] = s[v] / s[v].std()
    for col in (1, 2, 3, 4):
        fml = f"event ~ {polvar} + blank_hat + blank_{polvar} + " + controls(col, epop)
        b, se, info, _ = hdfe(fml, s, ["qofd", "place"], cluster="place",
                              keep=["blank_hat", polvar, "blank_" + polvar])
        for term, lab in zip(["blank_hat", polvar, "blank_" + polvar], ["Conducive weather", "Stock_{t-1}", "Conducive weather x stock_{t-1}"]):
            rows.append(dict(table=table, panel=panel, column=col, term=lab, coef=b[term], se=se[term],
                             N=info["N"], clusters=info["G"], estimator="sp.feols (HDFE, CRV1 x ivreghdfe small)"))
    return rows


def main():
    rows = []
    # ---- block 1: Table IV Panel A (public-security AI stock) and Table V Panel A (non-public AI stock)
    d, coef, info = build(1, I3_T4)
    fs_rows = [dict(block=1, term=k, coef=v) for k, v in coef.items()]
    d["pol"] = z(d["police_pc"]); d["blank_pol"] = d["blank_hat"] * d["pol"]
    rows += run_panel(d, "IV", "A", "pol")
    d["pol2"] = z(d["lead_nonpolice_pc"]); d["blank_pol2"] = d["blank_hat"] * d["pol2"]
    rows += run_panel(d, "V", "A", "pol2")
    # check against the Stata snapshot
    snap = read_dta(XDATA / "s10_Table4_PanelA_ai.dta", cols=["place", "qofd", "blank_hat", "blank_pol"])
    m = d[["place", "qofd", "blank_hat"]].merge(snap, on=["place", "qofd"], suffixes=("", "_stata"))
    print("max |blank_hat python - stata| =", np.nanmax(np.abs(m.blank_hat - m.blank_hat_stata)))
    # ---- block 2: Table IV Panel B (cameras x AI stock)
    d, coef, _ = build(2, I3_T4, cam=True)
    d["pol"] = z(d["police_pc"] * d["lead_camera_time_city_pc"]); d["blank_pol"] = d["blank_hat"] * d["pol"]
    rows += run_panel(d, "IV", "B", "pol")
    # ---- block 3: Table V Panel B (past unrest); no imputation, population in levels, no epop
    d, coef, _ = build(3, I3_T5B, impute=False)
    d["pol"] = z(d["protest_t1"] + d["demand_t1"] + d["threat_t1"]); d["blank_pol"] = d["blank_hat"] * d["pol"]
    rows += run_panel(d, "V", "B", "pol", epop=False)
    out = save_rows(rows, "table4_table5")
    save_rows(fs_rows, "table4_first_stage_coefs")
    print(out.pivot_table(index=["table", "panel", "term"], columns="column", values="coef").round(4))
    return out


if __name__ == "__main__":
    main()
