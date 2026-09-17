"""Tables VI and VII (+ Figures V/VI event-time profiles): politically motivated public-security
contracts and firms' cumulative software production.  (Analysis.do sections 11 and 12)

Input: firm x quarter panels saved by the export hooks right before each -reghdfe- call
(Data/Intermediate/statspai/s11_<type>_<pre>_<i>.dta, s12_...).  They already contain the
author's collapse (lastnm place under -set sortseed-) and cumulative counts.

Table VI  : reghdfe n_software_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first
            i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca police_data
            [index_firm] [aw=weight], absorb(sub_fe) cl(place)
            then program addQuarterInter: b_k(inter) + b_k(quarter), Var = V_inter + V_quarter (no covariance!)
Table VII : same RHS without i.qofd, absorb(sub_fe qofd); col 2 adds scale* capital_usd_m*; col 3 aw=1000 controls.

The event-time dummies are collinear with the absorbed FE (event time = calendar time - cohort), so the
*normalisation* of individual coefficients depends on which terms are omitted.  We build the design
explicitly in Stata's variable order and drop collinear columns sequentially (common.stata_keep_order),
reproducing reghdfe's omission pattern.
"""
from common import *

TYPES = {"ALL": "A", "GOVERNMENT": "B", "BUSINESS": "C"}
PRES = [("event", 0), ("event_hat_lasso", 3)]
EVT = "semi_to_f_x_ca_x_with_c"
QTF = "quarter_to_first"


def design(d, qofd_dummies, extra):
    cols = []
    for var, pre in ((EVT, "e"), (QTF, "q")):
        for lev in sorted(d[var].dropna().unique()):
            if int(lev) == 23:
                continue
            c = f"{pre}_{int(lev)}"
            d[c] = (d[var] == lev).astype(float)
            cols.append(c)
    d["wc_1"] = (d.with_contract_dummy == 1).astype(float); cols.append("wc_1")
    if qofd_dummies:
        levs = sorted(d.qofd.dropna().unique())
        for lev in levs[1:]:
            c = f"t_{int(lev)}"
            d[c] = (d.qofd == lev).astype(float)
            cols.append(c)
    cols += ["ca_x_with_c", "semi_to_f_x_with_c", "semi_to_f_x_ca", "police_data"] + extra
    return cols


def fit(d, fes, extra=(), weights=None, qofd_dummies=False):
    d = d.copy()
    cols = design(d, qofd_dummies, list(extra))
    dd = drop_singletons(d.dropna(subset=["n_software_cum", "place"] + cols), fes)
    keep = stata_keep_order(dd, cols, fes)
    b, se, info, _ = hdfe("n_software_cum ~ " + " + ".join(keep), dd, fes, cluster="place", weights=weights,
                          singletons=False, stata="reghdfe")
    return b, se, info, [c for c in cols if c not in keep]


def table6():
    rows, prof = [], []
    for t, panel in TYPES.items():
        for pre, off in PRES:
            for j in range(3):
                i = off + j
                d = read_dta(XDATA / f"s11_{t}_{pre}_{i}.dta")
                w, extra = None, []
                if j == 1:
                    extra = ["index_firm"]
                if j == 2:
                    d["weight"] = np.where(d.with_contract_dummy == 0, 10.0, 1.0)
                    w = "weight"
                b, se, info, omitted = fit(d, ["sub_fe"], extra, w, qofd_dummies=True)
                for k in range(16, 33):
                    ke, kq = f"e_{k}", f"q_{k}"
                    if ke not in b.index or kq not in b.index:
                        continue
                    coef = b[ke] + b[kq]
                    s = float(np.sqrt(se[ke] ** 2 + se[kq] ** 2))   # addQuarterInter: no covariance term
                    prof.append(dict(table="VI", panel=panel, outcome=t, unrest=pre, column=i + 1, event_time=k - 24,
                                     coef=coef, se=s, N=info["N"], clusters=info["G"]))
                    if k == 32:
                        rows.append(dict(table="VI", panel=panel, outcome=t, unrest=pre, column=i + 1,
                                         term="8 quarters after contract", coef=coef, se=s, N=info["N"], clusters=info["G"],
                                         omitted=";".join(o for o in omitted if not o.startswith("t_")),
                                         estimator="sp.feols (HDFE firm FE, CRV1 place, reghdfe small) + addQuarterInter"))
    return rows, prof


def table7():
    rows, prof = [], []
    for t, panel in TYPES.items():
        for pre, off in PRES:
            for j in range(3):
                i = off + j
                d = read_dta(XDATA / f"s12_{t}_{pre}_{i}.dta")
                w, extra = None, []
                if j == 1:
                    # `scale* capital_usd_m*` expands (in dataset order) to scale, scale_2013..2019, capital_usd_m, capital_usd_m_2013..
                    # scale_yyyy were built with `if qofd == yyyy` (never true) and are all zero -> omitted
                    extra = [c for c in d.columns if c.startswith("scale")] + [c for c in d.columns if c.startswith("capital_usd_m")]
                if j == 2:
                    d["weight"] = np.where(d.with_contract_dummy == 0, 1000.0, 1.0)
                    w = "weight"
                b, se, info, omitted = fit(d, ["sub_fe", "qofd"], extra, w, qofd_dummies=False)
                for k in range(16, 33):
                    for pre_, lab in (("q", "base"), ("e", "public security")):
                        kk = f"{pre_}_{k}"
                        if kk not in b.index:
                            continue
                        prof.append(dict(table="VII", panel=panel, outcome=t, unrest=pre, column=i + 1, event_time=k - 24,
                                         term=lab, coef=b[kk], se=se[kk]))
                        if k in (16, 32):
                            when = "8 quarters before contract" if k == 16 else "8 quarters after contract"
                            rows.append(dict(table="VII", panel=panel, outcome=t, unrest=pre, column=i + 1,
                                             term=when + ("" if pre_ == "q" else " x public security"),
                                             coef=b[kk], se=se[kk], N=info["N"], clusters=info["G"],
                                             omitted=";".join(o for o in omitted if not o.startswith(("scale_", "capital_usd_m_"))),
                                             estimator="sp.feols (HDFE firm + quarter FE, CRV1 place, reghdfe small)"))
    return rows, prof


def main():
    r6, p6 = table6()
    r7, p7 = table7()
    out = save_rows(r6 + r7, "table6_table7")
    save_rows(p6, "figure5_eventstudy_profile")
    save_rows(p7, "figure6_eventstudy_profile")
    pd.set_option("display.width", 250)
    print(out.pivot_table(index=["table", "panel", "term"], columns="column", values="coef", aggfunc="first").round(3).to_string())
    print(out.groupby(["table", "column"]).omitted.first().to_string())
    return out


if __name__ == "__main__":
    main()
