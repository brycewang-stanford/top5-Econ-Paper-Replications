"""Modern-methods extensions (NOT replication).  Results -> Results/statspai/ext_*.csv/png

E1  Mechanical accumulation check for Table VI.  In the author's firm panel the outcome
    n_software_cum is a running cumulative sum *only* for contracted-firm copies from event time -1
    on; pre-period rows and the never-contracted "control" copies keep the quarterly *flow*.  We
    re-run the author's exact Table VI column-1 regression with the flow n_software for every row and
    add up the event-time effects 0..8 (vcov-consistent SE) - the flow analogue of "8 quarters after".
E2  Staggered-adoption robust event studies on the firm x quarter *flow* panel of police-contract
    copies (cohort = quarter of first politically motivated public-security contract; not-yet-treated
    controls): sp.callaway_santanna, sp.did_imputation (BJS), sp.sun_abraham (last-cohort control),
    vs. a TWFE event study; cumulative 0..8 effects.
E3  sp.honest_did (smoothness + relative magnitudes) and sp.pretrends_power on the BJS/CS event study.
E4  Few clusters: Table VI column 1 is clustered on only 38 prefectures -> wild cluster bootstrap
    (sp.wild_cluster_bootstrap on the FWL-residualised regression, Webb/Rademacher weights).
E5  Weak-IV robust inference for the parsimonious weather IV of Figure III (rain, gust, thunder and
    their interactions with unrest-elsewhere): first-stage F, 2SLS, and a cluster-robust
    Anderson-Rubin confidence set computed by test inversion (sp.feols Wald test per grid point).
"""
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from common import *

EVT, QTF = "semi_to_f_x_ca_x_with_c", "quarter_to_first"


def e1_flow_vs_cum():
    rows = []
    d = read_dta(XDATA / "s11_ALL_event_0.dta")
    rhs = (f"i({EVT}, ref=23) + i({QTF}, ref=23) + C(with_contract_dummy) + C(qofd) + ca_x_with_c + "
           f"semi_to_f_x_with_c + semi_to_f_x_ca + police_data")
    for yv in ("n_software_cum", "n_software"):
        dd = drop_singletons(d.dropna(subset=[yv]), ["sub_fe"])
        fit = pf.feols(f"{yv} ~ {rhs} | sub_fe", data=dd, vcov={"CRV1": "place"})
        b, V = fit.coef(), fit._vcov
        names = list(b.index)
        N, G, k = fit._N, dd.place.nunique(), int(np.linalg.matrix_rank(fit._X)) if hasattr(fit, "_X") else len(names)
        # pyfixest default ssc (adj, cluster_adj) ~ reghdfe here (sub_fe nested in place)
        def w_for(ks):
            w = np.zeros(len(names))
            for kk in ks:
                for var in (EVT, QTF):
                    for cand in (f"{var}::{kk}", f"{var}::{float(kk)}"):
                        if cand in names:
                            w[names.index(cand)] += 1
            return w
        w8 = w_for([32])
        est8 = float(w8 @ b.values); se8 = float(np.sqrt(w8 @ V @ w8))
        se8_author = float(np.sqrt(sum(fit.se()[n] ** 2 for n in np.array(names)[w8 > 0])))
        rows.append(dict(ext="E1", outcome=yv, quantity="event time 8 (author's inter+base)", estimate=est8,
                         se_full_vcov=se8, se_author_no_cov=se8_author, N=N, clusters=G))
        if yv == "n_software":
            wsum = w_for(range(24, 33))
            rows.append(dict(ext="E1", outcome=yv, quantity="sum of flow effects, event time 0..8", estimate=float(wsum @ b.values),
                             se_full_vcov=float(np.sqrt(wsum @ V @ wsum)), se_author_no_cov=np.nan, N=N, clusters=G))
            wsum = w_for(range(23, 33))
            rows.append(dict(ext="E1", outcome=yv, quantity="sum of flow effects, event time -1..8 (window of the author's cumsum)",
                             estimate=float(wsum @ b.values), se_full_vcov=float(np.sqrt(wsum @ V @ wsum)),
                             se_author_no_cov=np.nan, N=N, clusters=G))
    return rows


def firm_flow_panel():
    d = read_dta(XDATA / "s11_ALL_event_0.dta")
    t = d[(d.with_contract_dummy == 1) & (d.police_data == 1)].copy()
    g = t[t[QTF] == 24].groupby("sub_fe").qofd.min().rename("g")
    f = t.groupby(["sub_fe", "qofd"]).agg(y=("n_software", "sum"), place=("place", "first")).reset_index()
    f = f.merge(g, left_on="sub_fe", right_index=True, how="inner")
    # balance within the observed window of each firm is not required by CS (allow_unbalanced) / BJS
    f["rel"] = f.qofd - f.g
    f["sub_fe"] = f.sub_fe.astype(int); f["qofd"] = f.qofd.astype(int); f["g"] = f.g.astype(int)
    return f


def es_table(res, label):
    """Normalise event-study output of CausalResult objects to rel/est/se."""
    out = None
    for key in ("event_study",):
        mi = getattr(res, "model_info", {}) or {}
        if key in mi and isinstance(mi[key], pd.DataFrame):
            out = mi[key].copy()
    if out is None and isinstance(getattr(res, "detail", None), pd.DataFrame):
        out = res.detail.copy()
    if out is None:
        return pd.DataFrame()
    cols = {c.lower(): c for c in out.columns}
    rel = next((cols[c] for c in ("relative_time", "rel_time", "event_time", "e", "horizon", "h", "k") if c in cols), out.columns[0])
    est = next((cols[c] for c in ("att", "estimate", "coef", "beta", "effect") if c in cols), None)
    se = next((cols[c] for c in ("se", "std_error", "std. error", "stderr") if c in cols), None)
    o = pd.DataFrame({"rel": pd.to_numeric(out[rel], errors="coerce"), "est": out[est], "se": out[se] if se else np.nan})
    o["estimator"] = label
    # StatsPAI CS reports cells without any valid comparison group as att=0, se=0 -> treat as missing
    o = o[~((o.est == 0) & (o.se.fillna(0) == 0))]
    return o


def e2_e3_staggered(f):
    rows, tabs, sens = [], [], []
    win = f[(f.rel >= -12) & (f.rel <= 12)].copy()
    # TWFE event study (dynamic, ref -1), firm + quarter FE, cluster place
    win["relc"] = win.rel.clip(-12, 12)
    # all units are eventually treated -> a dynamic TWFE needs two normalisations (Borusyak et al.):
    # omit -1 and the binned far-lead endpoint (<= -12)
    dcols = []
    for lev in sorted(win.relc.unique()):
        if lev in (-1, -12):
            continue
        c = f"r_{'m' if lev < 0 else 'p'}{abs(int(lev))}"
        win[c] = (win.relc == lev).astype(float); dcols.append(c)
    tw = sp.feols("y ~ " + " + ".join(dcols) + " | sub_fe + qofd", data=win, vcov={"CRV1": "place"})
    ct = tw.params; st = tw.std_errors
    relv = [(-1 if n[2] == "m" else 1) * float(n[3:]) for n in ct.index]
    twfe = pd.DataFrame({"rel": relv, "est": ct.values, "se": st.values, "estimator": "TWFE event study (sp.feols)"})
    tabs.append(twfe)
    results = {}
    try:
        # NOTE: estimator="reg" with allow_unbalanced_panel=True silently returns ATT=0, SE=inf for every
        # (g,t) cell on this panel (StatsPAI bug, see the analysis note) -> use the doubly-robust estimator.
        cs = sp.callaway_santanna(f, y="y", g="g", t="qofd", i="sub_fe", control_group="notyettreated",
                                  notyet_cutoff="cohort", allow_unbalanced_panel=True, clustervars="place",
                                  estimator="dr", bstrap=True, biters=999, random_state=1)
        results["CS"] = cs
        tabs.append(es_table(cs, "Callaway-Sant'Anna (not-yet-treated, DR)"))
    except Exception as e:
        rows.append(dict(ext="E2", estimator="callaway_santanna", error=repr(e)[:300]))
    try:
        # BJS needs >=1 untreated period per treated unit to estimate its FE: drop firms contracted in
        # their first observed quarter (window starts at event time -24, so these are early 2013 cohorts)
        first_obs = f.groupby("sub_fe").qofd.transform("min")
        fb = f[(f.groupby("sub_fe").g.transform("first") > first_obs)]
        # ... and quarters in which every remaining firm is already treated (no untreated obs to impute from)
        last_untreated = fb.loc[fb.qofd < fb.g, "qofd"].max()
        fb = fb[fb.qofd <= last_untreated]
        rows.append(dict(ext="E2", estimator="did_imputation", quantity="firms dropped (no untreated history)",
                         estimate=f.sub_fe.nunique() - fb.sub_fe.nunique()))
        bjs = sp.did_imputation(fb, y="y", group="sub_fe", time="qofd", first_treat="g", horizon=list(range(0, 9)),
                                cluster="place", pretrends=8)
        results["BJS"] = bjs
        tabs.append(es_table(bjs, "Borusyak-Jaravel-Spiess imputation"))
    except Exception as e:
        rows.append(dict(ext="E2", estimator="did_imputation", error=repr(e)[:300]))
    try:
        sa = sp.sun_abraham(f, y="y", g="g", t="qofd", i="sub_fe", event_window=(-8, 8),
                            control_group="lastcohort", cluster="place")
        results["SA"] = sa
        tabs.append(es_table(sa, "Sun-Abraham IW (last cohort as control)"))
    except Exception as e:
        rows.append(dict(ext="E2", estimator="sun_abraham", error=repr(e)[:300]))
    es = pd.concat([t for t in tabs if len(t)], ignore_index=True)
    es.to_csv(OUT / "ext_E2_eventstudy_flow.csv", index=False)
    for lab, g in es.groupby("estimator"):
        post = g[(g.rel >= 0) & (g.rel <= 8)]
        rows.append(dict(ext="E2", estimator=lab, quantity="sum of flow effects 0..8 (point)", estimate=post.est.sum(),
                         n_post=len(post), pre_mean=g[(g.rel < -1) & (g.rel >= -8)].est.mean()))
        pre = g[(g.rel <= -2) & (g.rel >= -8)]
        if len(pre):
            rows.append(dict(ext="E2", estimator=lab, quantity="sum over 0..8 of (effect - mean pre-period effect -8..-2)",
                             estimate=float((post.est - pre.est.mean()).sum())))
    for name, r in results.items():
        rows.append(dict(ext="E2", estimator=name, quantity="overall ATT (package aggregate)",
                         estimate=float(getattr(r, "estimate", np.nan)), se=float(getattr(r, "se", np.nan))))
    # E3 sensitivity
    for name in ("CS", "SA", "BJS"):
        r = results.get(name)
        if r is None:
            continue
        for method, grid in (("smoothness", [0, 0.1, 0.25, 0.5]), ("relative_magnitude", [0, 0.5, 1, 2])):
            try:
                h = sp.honest_did(r, e=0, m_grid=grid, method=method)
                h["estimator"], h["method"] = name, method
                sens.append(h)
            except Exception as e:
                sens.append(pd.DataFrame([dict(estimator=name, method=method, error=repr(e)[:300])]))
        try:
            p = sp.pretrends_power(r)
            rows.append(dict(ext="E3", estimator=name, quantity="pretrends_power (Roth 2022, individual)",
                             estimate=p.get("power"), note=str(p.get("warning"))[:200]))
        except Exception as e:
            rows.append(dict(ext="E3", estimator=name, quantity="pretrends_power", error=repr(e)[:300]))
    if sens:
        pd.concat(sens, ignore_index=True).to_csv(OUT / "ext_E3_honest_did.csv", index=False)
    # figure
    fig, ax = plt.subplots(figsize=(8, 4.5))
    for i, (lab, g) in enumerate(es.groupby("estimator")):
        g = g[(g.rel >= -8) & (g.rel <= 8)].sort_values("rel")
        ax.errorbar(g.rel + (i - 1.5) * 0.12, g.est, yerr=1.96 * g.se, fmt="o", ms=3, capsize=2, label=lab)
    ax.axhline(0, color="k", lw=0.6); ax.axvline(-0.5, color="grey", ls=":")
    ax.set_xlabel("Quarters relative to first politically motivated public-security contract")
    ax.set_ylabel("Software releases per quarter (flow)")
    ax.legend(fontsize=7); fig.tight_layout(); fig.savefig(OUT / "ext_E2_eventstudy_flow.png", dpi=150)
    return rows


def e4_wild(nboot=9999):
    """Wild cluster bootstrap for Table VI col.1 '8 quarters after' (interaction coefficient) after FWL."""
    d = read_dta(XDATA / "s11_ALL_event_0.dta")
    d = drop_singletons(d, ["sub_fe"])
    dums = pd.get_dummies(d[EVT].astype(int), prefix="e").drop(columns="e_23").astype(float)
    dq = pd.get_dummies(d[QTF].astype(int), prefix="q").drop(columns="q_23").astype(float)
    dt = pd.get_dummies(d["qofd"].astype(int), prefix="t", drop_first=True).astype(float)
    X = pd.concat([dums, dq, dt, d[["with_contract_dummy", "ca_x_with_c", "semi_to_f_x_with_c", "semi_to_f_x_ca", "police_data"]]], axis=1)
    X = X.loc[:, X.std() > 0]
    # absorb firm FE by within transformation (FWL), then OLS on the demeaned design
    M = pd.concat([d[["n_software_cum"]], X], axis=1).to_numpy(float)
    Mw, keep = sp.demean(M, d[["sub_fe"]].reset_index(drop=True), drop_singletons=False)
    W = pd.DataFrame(Mw, columns=["y"] + list(X.columns))
    # drop collinear columns (QR) to mimic Stata omitted terms
    q, r = np.linalg.qr(W.iloc[:, 1:].to_numpy())
    good = np.abs(np.diag(r)) > 1e-8 * np.abs(np.diag(r)).max()
    cols = list(np.array(X.columns)[good])
    W = W[["y"] + cols]
    W["place"] = d["place"].to_numpy()
    rows = []
    for tv in ("e_32",):
        try:
            res = sp.wild_cluster_bootstrap(W, y="y", x=cols, cluster="place", test_var=tv, n_boot=nboot,
                                            weight_type="webb", seed=20230101)
            rows.append(dict(ext="E4", quantity=f"Table VI col1 interaction {tv} (8q after x public security)",
                             estimate=res.get("beta_hat"), se=res.get("se_cluster"), p_boot=res.get("p_boot"),
                             ci_boot=str(res.get("ci_boot")), clusters=res.get("n_clusters"), n_boot=res.get("n_boot"),
                             note="interaction only; the author's total effect adds the base-quarter coefficient"))
        except Exception as e:
            rows.append(dict(ext="E4", quantity=tv, error=repr(e)[:300]))
    return rows


def e5_weakiv():
    d = read_dta(XDATA / "s8_ols_lead_police_pc.dta")
    d["gdp_s"] = d.prefecture_gdp / d.prefecture_gdp.std()
    z = ["rain", "gust", "thunder", "rainI", "gustI", "thunderI"]
    d = d.dropna(subset=["lead_police_pc", "blank", "gdp_s"] + z)
    d = drop_singletons(d, ["place", "qofd"])
    ctrl = "gdp_s + i(qofd, gdp_s)"
    rows = []
    fs = pf.feols(f"blank ~ {' + '.join(z)} + {ctrl} | place + qofd", data=d, vcov={"CRV1": "place"})
    wf = fs.wald_test(R=None) if False else None
    # cluster-robust first-stage F on the excluded instruments
    b = fs.coef()[z].values; V = fs._vcov
    idx = [list(fs.coef().index).index(v) for v in z]
    Vz = V[np.ix_(idx, idx)]
    F = float(b @ np.linalg.solve(Vz, b) / len(z))
    iv = sp.feols(f"lead_police_pc ~ {ctrl} | place + qofd | blank ~ {' + '.join(z)}", data=d, vcov={"CRV1": "place"})
    rows.append(dict(ext="E5", quantity="parsimonious weather IV (rain,gust,thunder x unrest elsewhere): 2SLS", estimate=float(iv.params["blank"]),
                     se=float(iv.std_errors["blank"]), first_stage_F_cluster=F, N=len(d), clusters=d.place.nunique()))
    # AR confidence set by test inversion: regress (y - b*d) on Z with FE+controls, cluster-robust Wald
    grid = np.round(np.arange(-1.0, 2.01, 0.02), 3)
    acc = []
    for b0 in grid:
        d["ytil"] = d.lead_police_pc - b0 * d.blank
        r = pf.feols(f"ytil ~ {' + '.join(z)} + {ctrl} | place + qofd", data=d, vcov={"CRV1": "place"})
        bb = r.coef()[z].values; VV = r._vcov[np.ix_(idx, idx)]
        W = float(bb @ np.linalg.solve(VV, bb))
        from scipy.stats import chi2
        acc.append((b0, W, chi2.sf(W, len(z))))
    A = pd.DataFrame(acc, columns=["beta0", "wald", "p"])
    A.to_csv(OUT / "ext_E5_ar_grid.csv", index=False)
    inside = A[A.p > 0.05].beta0
    rows.append(dict(ext="E5", quantity="cluster-robust Anderson-Rubin 95% set (grid -1..2 step .02)",
                     estimate=np.nan, ci_low=inside.min() if len(inside) else np.nan,
                     ci_high=inside.max() if len(inside) else np.nan,
                     note=("unbounded/at grid edge" if len(inside) and (inside.min() <= grid[0] or inside.max() >= grid[-1]) else "")))
    # StatsPAI's built-in AR CI (iid only) on FWL-residualised data, for comparison
    try:
        M = d[["lead_police_pc", "blank"] + z].to_numpy(float)
        Mw, _ = sp.demean(M, d[["place", "qofd"]].reset_index(drop=True), drop_singletons=False)
        ar = sp.anderson_rubin_ci(y=Mw[:, 0], endog=Mw[:, 1], instruments=Mw[:, 2:], add_const=False)
        rows.append(dict(ext="E5", quantity="sp.anderson_rubin_ci (iid, FE partialled; no cluster option)", note=str(ar)[:300]))
    except Exception as e:
        rows.append(dict(ext="E5", quantity="sp.anderson_rubin_ci", error=repr(e)[:300]))
    return rows


def cached(name, fn):
    """E4/E5 are slow (9,999 bootstrap draws; 151-point AR grid): reuse saved rows unless --force."""
    import sys
    p = OUT / f"ext_{name}.csv"
    if p.exists() and "--force" not in sys.argv:
        return lambda: pd.read_csv(p).to_dict("records")
    def run():
        r = fn(); pd.DataFrame(r).to_csv(p, index=False); return r
    return run


def main():
    rows = []
    for fn in (e1_flow_vs_cum, lambda: e2_e3_staggered(firm_flow_panel()), cached("E4_wild", e4_wild), cached("E5_weakiv", e5_weakiv)):
        try:
            r = fn()
            rows += r
            print(pd.DataFrame(r).to_string()[:3000], flush=True)
        except Exception as e:
            import traceback; traceback.print_exc()
            rows.append(dict(ext=str(fn), error=repr(e)[:300]))
    save_rows(rows, "extensions_summary")


if __name__ == "__main__":
    main()
