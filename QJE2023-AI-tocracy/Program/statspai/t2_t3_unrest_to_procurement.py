"""Tables II and III: unrest in quarter t-1 -> public-security AI / camera procurement.
(Analysis.do sections 8 and 9)

Panel A (OLS)  : ivreghdfe y blank c.X##qofd [AI_stock_t2], absorb(place qofd) cl(place)   -> exact via sp.feols
                 (Table III column 4 in the do-file already includes all three X x quarter blocks + AI stock)
Panel B (LASSO): xpoivregress y [AI_stock_t2] (blank = weather x weather, weather x unrest-elsewhere),
                 control((i.qofd i.place) X X_q*), vce(cl place) rseed(1)  -- Stata's cross-fit
                 partialing-out LASSO IV (10 folds, plugin lambda).
                 StatsPAI has no cross-fit PO-LASSO-IV with clustered inference.  Closest available:
                   1. partial the fixed effects and the control block out of y, d and every candidate
                      instrument (Frisch-Waugh-Lovell, sp.demean / sp.feols residuals);
                   2. sp.rlasso_iv(select_Z=True, select_X=False): BCH (2012) rigorous-LASSO optimal
                      instrument (no cross-fitting, heteroskedastic plug-in penalty);
                   3. re-estimate the just-identified IV with the LASSO-fitted instrument and cluster by
                      prefecture (sp.ivreg).
                 Reported as an approximation, not an exact replication.
"""
from itertools import combinations_with_replacement

from common import *

CTRL = {
    1: ["gdp"], 2: ["pop"], 3: ["rev"], 4: ["stock"], 5: ["gdp", "pop", "rev", "stock"],
}
VAR = {"gdp": "prefecture_gdp", "pop": "prefecture_city_population", "rev": "prefecture_fiscal_revenue"}


def ols_formula(y, col, col4_all=False):
    parts = ["blank"]
    for c in (CTRL[5] if (col == 4 and col4_all) else CTRL[col]):
        if c == "stock":
            parts.append("AI_stock_t2")
        else:
            parts.append(f"{VAR[c]} + i(qofd, {VAR[c]})")
    return f"{y} ~ " + " + ".join(parts)


def run_ols(fname, y, table, panel, col4_all=False):
    d = read_dta(XDATA / fname)
    for v in VAR.values():
        d[v] = d[v] / d[v].std()  # conditioning of the X x quarter block (does not affect `blank`)
    rows = []
    for col in range(1, 6):
        b, se, info, _ = hdfe(ols_formula(y, col, col4_all), d, ["place", "qofd"], cluster="place", keep=["blank"])
        rows.append(dict(table=table, panel=panel, column=col, term="Unrest events_{t-1}", coef=b["blank"], se=se["blank"],
                         N=info["N"], clusters=info["G"], estimator="sp.feols HDFE OLS, CRV1(place) x ivreghdfe small"))
    return rows


def lasso_iv(fname, y, table, panel, interactions=True):
    """Approximate Stata's xpoivregress with FWL partialling + sp.rlasso_iv + clustered IV."""
    d = read_dta(XDATA / fname)
    w = [f"w{i}" for i in range(1, 19)]
    wi = [f"wI{i}" for i in range(1, 19)]
    Z = pd.DataFrame(index=d.index)
    for g in (w, wi):
        for v in g:
            Z[v] = d[v]
        if interactions:
            for a, b in combinations_with_replacement(g, 2):
                Z[f"{a}x{b}"] = d[a] * d[b]
    Z = Z.loc[:, Z.std() > 0]
    rows = []
    for col in range(1, 6):
        ctrl = []
        for c in CTRL[col] if col != 4 else ["gdp", "stock"]:  # col 4 of the do-file keeps the GDP block
            if c == "stock":
                ctrl.append("AI_stock_t2")
            else:
                q = {"gdp": "gdp_", "pop": "pcp_", "rev": "pfr_"}[c]
                ctrl += [VAR[c]] + [x for x in d.columns if x.startswith(q)]
        base = d[["place", "qofd", y, "blank"] + ctrl].join(Z)
        base = base.dropna()
        cols = [y, "blank"] + list(Z.columns)
        # FWL: sweep place + quarter FE out of everything (sp.demean), then the control block (OLS)
        M = base[cols + ctrl].to_numpy(float)
        sc = M.std(axis=0); sc[sc == 0] = 1.0
        Mw, keep = sp.demean(M / sc, base[["place", "qofd"]].reset_index(drop=True), drop_singletons=False)
        Mw = Mw * sc
        k = len(cols)
        C = Mw[:, k:]
        if C.shape[1]:
            beta, *_ = np.linalg.lstsq(C, Mw[:, :k], rcond=None)
            Mw = Mw[:, :k] - C @ beta
        R = pd.DataFrame(Mw[:, :k], columns=cols, index=base.index)
        zc = [c for c in Z.columns if R[c].std() > 1e-8]
        zs = R[zc].std().to_numpy()
        fit = sp.rlasso_iv(y=R[y].values, d=R["blank"].values, z=R[zc].values / zs, select_Z=True, select_X=False)
        selm = np.asarray(fit.selection.get("selection_matrix_Z")).ravel().astype(bool)
        sel = np.flatnonzero(selm)
        # sp.rlasso_iv's plug-in penalty selects no instrument here (and then still returns a numeric
        # coefficient with SE ~1e14 instead of failing) -> use sp.lasso_iv with a CV penalty, clustered.
        Rz = R.copy()
        Rz[zc] = Rz[zc] / zs
        Rz["place"] = base["place"].values
        r2 = sp.lasso_iv(Rz, y=y, x_endog=["blank"], z=zc, cluster="place", penalty="cv")
        coef = float(r2.params["blank"])
        se_ = float(r2.std_errors["blank"])
        nsel = None
        for key in ("N instruments", "n_selected", "n_instruments_selected", "selected_instruments", "selected"):
            v = (r2.diagnostics or {}).get(key) if isinstance(r2.diagnostics, dict) else None
            if v is not None:
                nsel = len(v) if hasattr(v, "__len__") and not isinstance(v, str) else v
                break
        rows.append(dict(table=table, panel=panel, column=col, term="Unrest events_{t-1}", coef=coef, se=se_,
                         N=len(base), clusters=base.place.nunique(), n_candidate_z=len(zc),
                         n_selected_z_lasso_cv=nsel, n_selected_z_rlasso_plugin=int(sel.size),
                         rlasso_iv_coef=float(np.ravel(fit.coef)[0]),
                         rlasso_iv_se=float(np.ravel(fit.se)[0]),
                         estimator="APPROX: FWL partial-out (FE+controls) + sp.lasso_iv(penalty='cv', cluster=place)"))
        print(table, panel, col, round(coef, 3), round(se_, 3), "selected:", nsel, "diag keys:",
              list(r2.diagnostics.keys())[:12] if isinstance(r2.diagnostics, dict) else None, flush=True)
    return rows


def main(lasso=True):
    rows = []
    rows += run_ols("s8_ols_lead_police_pc.dta", "lead_police_pc", "II", "A (OLS)")
    rows += run_ols("s9_ols_lead_camera_time_city_pc.dta", "lead_camera_time_city_pc", "III", "A (OLS, cameras)", col4_all=True)
    rows += run_ols("s9_ols_aiXcam.dta", "aiXcam", "III", "C (OLS, AI x cameras)", col4_all=True)
    save_rows(rows, "table2_table3_ols")
    print(pd.DataFrame(rows).pivot_table(index=["table", "panel"], columns="column", values=["coef", "se"], aggfunc="first").round(3))
    if lasso:
        lr = []
        lr += lasso_iv("s8_lasso_lead_police_pc.dta", "lead_police_pc", "II", "B (LASSO IV)", interactions=True)
        lr += lasso_iv("s9_lasso_lead_camera_time_city_pc.dta", "lead_camera_time_city_pc", "III", "B (LASSO IV, cameras)", interactions=False)
        lr += lasso_iv("s9_lasso_aiXcam.dta", "aiXcam", "III", "D (LASSO IV, AI x cameras)", interactions=False)
        save_rows(lr, "table2_table3_lassoiv_approx")


if __name__ == "__main__":
    import sys
    main(lasso="--no-lasso" not in sys.argv)
