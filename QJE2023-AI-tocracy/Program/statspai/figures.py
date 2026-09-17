"""Key figures re-estimated with StatsPAI and compared with the Stata coefficient files.

Figure II (and A.12/A.13): ivreghdfe y blank_0..blank_5 c.gdp0#qofd c.logpop#qofd c.rev0#qofd gdp0 logpop rev0,
    absorb(place qofd) cl(place); blank_k = standardized unrest shifted by k-2 quarters and orthogonalised
    on blank_2 (done in the do-file, saved in s2_<outcome>.dta).  Stata coefficient file: Data/Intermediate/Fig2.dta.
Figure V: event-time profile of Table VI (inter + base, author's variance sum) from t6_t7_firm_eventstudy.py,
    plotted against Data/Intermediate/Fig5_event_ALL.dta (section 5 of Analysis.do).
"""
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from common import *

INTER = DATA / "Intermediate"


def figure2():
    rows = []
    for outcome, stata_file, fig in (("lead_police_pc", "Fig2.dta", "Figure II"),
                                     ("lead_camera_time_city_pc", "FigA12.dta", "Figure A.12"),
                                     ("aiXcam", "FigA13.dta", "Figure A.13")):
        p = XDATA / f"s2_{outcome}.dta"
        if not p.exists():
            continue
        d = read_dta(p)
        for v in ("prefecture_gdp0", "logpop", "prefecture_fiscal_revenue0"):
            d[v] = d[v] / d[v].std()
        blanks = [f"blank_{k}" for k in range(6)]
        fml = (f"{outcome} ~ " + " + ".join(blanks) +
               " + prefecture_gdp0 + logpop + prefecture_fiscal_revenue0 + i(qofd, prefecture_gdp0) + i(qofd, logpop)"
               " + i(qofd, prefecture_fiscal_revenue0)")
        b, se, info, _ = hdfe(fml, d, ["place", "qofd"], cluster="place", keep=blanks)
        st = pd.read_stata(INTER / stata_file) if (INTER / stata_file).exists() else None
        for k, bl in enumerate(blanks):
            # regToCoefDataset: id = k - 3 + 1 ... the graph flips the sign of id; quarter label = 2 - k relative to unrest
            row = dict(figure=fig, term=bl, rel_quarter_label=["3 Q after", "2 Q after", "1 Q after", "Q of unrest",
                                                               "1 Q before", "2 Q before"][k],
                       coef=b[bl], se=se[bl], N=info["N"], clusters=info["G"])
            if st is not None and k < len(st):
                row["stata_coef"] = float(st.beta1.iloc[k]); row["stata_se"] = float(st.se1.iloc[k])
            rows.append(row)
    return rows


def figure5():
    prof = pd.read_csv(OUT / "figure5_eventstudy_profile.csv")
    fig, axes = plt.subplots(1, 3, figsize=(14, 4))
    for ax, (t, lab) in zip(axes, (("ALL", "Panel A: total"), ("GOVERNMENT", "Panel B: government"), ("BUSINESS", "Panel C: commercial"))):
        for col, color, name in ((1, "grey", "OLS (unrest)"), (2, "tab:blue", "OLS + firm index"), (4, "black", "IV (predicted unrest)")):
            g = prof[(prof.outcome == t) & (prof.column == col)].sort_values("event_time")
            g = pd.concat([g, pd.DataFrame([dict(event_time=-1, coef=0.0, se=0.0)])]).sort_values("event_time")
            off = {1: -0.2, 2: 0.0, 4: 0.2}[col]
            ax.errorbar(g.event_time + off, g.coef, yerr=1.645 * g.se, fmt="o", ms=3, color=color, capsize=2, label=name)
        stf = INTER / f"Fig5_event_{t}.dta"
        if stf.exists():
            s = pd.read_stata(stf)
            s = s[(s.id >= -8) & (s.id <= 8)]
            ax.plot(s.id, s.beta1, "x", color="red", ms=5, label="Stata Fig5 file (section 5)")
        ax.axhline(0, color="k", lw=0.5); ax.axvline(-1, color="grey", ls=":")
        ax.set_title(lab); ax.set_xlabel("Quarters to the first contract")
    axes[0].set_ylabel("# of software (author's cumulative outcome)"); axes[0].legend(fontsize=7)
    fig.tight_layout(); fig.savefig(OUT / "figure5_statspai.png", dpi=150)


def figure3():
    """Figure III bars that StatsPAI can estimate: OLS, parsimonious weather IV, LIML with the LASSO candidate set.
    Author's bar values are stored in the first 6 rows of Data/Intermediate_shipped/Fig3.dta (b, s)."""
    from itertools import combinations_with_replacement
    rows = []
    auth = pd.read_stata(DATA / "Intermediate_shipped" / "Fig3.dta", columns=["b", "s"], chunksize=6)
    auth = next(auth).iloc[:6]
    lab = ["LASSO IV", "Parsimonious IV", "LIML", "JIVE", "LASSO IV, 7-day window", "OLS"]
    A = dict(zip(lab, zip(auth.b, auth.s)))
    # OLS = Table II A col 1
    t2 = pd.read_csv(OUT / "table2_table3_ols.csv")
    r = t2[(t2.table == "II") & (t2.column == 1)].iloc[0]
    rows.append(dict(bar="OLS", author_b=A["OLS"][0], author_se=A["OLS"][1], statspai_b=r.coef, statspai_se=r.se,
                     how="sp.feols HDFE (Table II A col 1)"))
    # parsimonious IV: rain, gust, thunder and x unrest-elsewhere; ivreghdfe ... c.gdp##qofd, absorb(place qofd) cl(place)
    d = read_dta(XDATA / "s8_ols_lead_police_pc.dta")
    d["gdp_s"] = d.prefecture_gdp / d.prefecture_gdp.std()
    z = ["rain", "gust", "thunder", "rainI", "gustI", "thunderI"]
    iv = sp.feols("lead_police_pc ~ gdp_s + i(qofd, gdp_s) | place + qofd | blank ~ " + " + ".join(z),
                  data=d, vcov={"CRV1": "place"})
    rows.append(dict(bar="Parsimonious IV", author_b=A["Parsimonious IV"][0], author_se=A["Parsimonious IV"][1],
                     statspai_b=float(iv.params["blank"]), statspai_se=float(iv.std_errors["blank"]),
                     how="sp.feols IV (pyfixest default ssc)"))
    # LIML with the full LASSO candidate set, FE + GDP block partialled out (LIML is invariant to FWL partialling)
    d = read_dta(XDATA / "s8_lasso_lead_police_pc.dta")
    w = [f"w{i}" for i in range(1, 19)]; wi = [f"wI{i}" for i in range(1, 19)]
    Z = pd.DataFrame(index=d.index)
    for g in (w, wi):
        for v in g:
            Z[v] = d[v]
        for a, b in combinations_with_replacement(g, 2):
            Z[f"{a}x{b}"] = d[a] * d[b]
    Z = Z.loc[:, Z.std() > 0]
    gdpq = [c for c in d.columns if c.startswith("gdp_")]
    base = drop_singletons(d[["place", "qofd", "lead_police_pc", "blank", "prefecture_gdp"] + gdpq].join(Z).dropna(), ["place", "qofd"])
    cols = ["lead_police_pc", "blank"] + list(Z.columns)
    M = base[cols + ["prefecture_gdp"] + gdpq].to_numpy(float); sc = M.std(0); sc[sc == 0] = 1
    Mw, _ = sp.demean(M / sc, base[["place", "qofd"]].reset_index(drop=True), drop_singletons=False); Mw *= sc
    k = len(cols); C = Mw[:, k:]; C = C[:, C.std(0) > 1e-9]
    Rm = Mw[:, :k] - C @ np.linalg.lstsq(C, Mw[:, :k], rcond=None)[0]
    R = pd.DataFrame(Rm, columns=cols); R["place"] = base.place.values
    zc = [c for c in Z.columns if R[c].std() > 1e-8]
    R[zc] = R[zc] / R[zc].std()
    lm = sp.liml(data=R, y="lead_police_pc", x_endog=["blank"], z=zc, cluster="place")
    rows.append(dict(bar="LIML", author_b=A["LIML"][0], author_se=A["LIML"][1], statspai_b=float(lm.params["blank"]),
                     statspai_se=float(lm.std_errors["blank"]), n_instruments=len(zc),
                     how="FWL + sp.liml(cluster=place) on standardized instruments; Stata re-run with standardized "
                         "instruments gives 0.2678 (raw-scale products: 0.2936) -> author's bar is numerically unstable"))
    for bar in ("LASSO IV", "LASSO IV, 7-day window", "JIVE"):
        rows.append(dict(bar=bar, author_b=A[bar][0], author_se=A[bar][1], statspai_b=np.nan, statspai_se=np.nan,
                         how="not available in StatsPAI (cross-fit PO-LASSO-IV / UJIVE1 with 700 dummies)"))
    return rows


def main():
    rows = figure2()
    if rows:
        out = save_rows(rows, "figure2_leads_lags")
        print(out.round(4).to_string())
    figure5()
    f3 = save_rows(figure3(), "figure3_estimators")
    print(f3.round(4).drop(columns=["how"]).to_string())


if __name__ == "__main__":
    main()
