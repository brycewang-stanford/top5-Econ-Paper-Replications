"""Modern-methods EXTENSIONS (not replication) for Bai, Jia & Yang (2023, QJE), using StatsPAI.

E1  Conley spatial + serial HAC (sp.conley) vs. the authors' reg2hdfespatial (Appendix Table B.1.III)
E2  Wild cluster bootstrap with few clusters (sp.hdfe_ols(wild=True)): Hunan-only regressions have 14-15 prefectures
E3  Event-study diagnostics on Figure 4A: pretrends_test / pretrends_power / honest_did / breakdown_m
    + exact Rambachan-Roth benchmark with the full event-study covariance through R HonestDiD
E4  Continuous-treatment DID: sp.cgs_continuous_did (Callaway, Goodman-Bacon & Sant'Anna 2024) and dose bins
E5  Functional form with many zeros (Chen & Roth 2024; I4R comment): FE-Poisson (sp.fepois) + extensive margin LPM
E6  Joint pre-trend test for the national DDD event study (Figure 6C)
E7  Weak-IV robust inference for the Table 4 IV (tF, Anderson-Rubin)

Run:  /usr/local/bin/python3.13 Program/statspai/extensions.py
"""
from __future__ import annotations

import json
import subprocess
import time

import numpy as np
import pandas as pd
import statspai as sp
from scipy import stats
from statspai.core.results import CausalResult

from common import HUNAN_CTRL, NAT_CTRL, NAT_CTRL_FIG6, OUT, coef_vcov, hunan, national, ols

T0 = time.time()
LOG: dict = {}


def tick(msg):
    print(f"[{time.time() - T0:7.1f}s] {msg}", flush=True)


def demean(df, cols, fes, tol=1e-12, maxit=10000):
    """Alternating projections (what reg2hdfe/hdfe do before the spatial HAC step)."""
    X = df[cols].to_numpy(float).copy()
    groups = [pd.factorize(df[f])[0] for f in fes]
    for _ in range(maxit):
        old = X.copy()
        for g in groups:
            cnt = np.bincount(g)
            for j in range(X.shape[1]):
                X[:, j] -= (np.bincount(g, X[:, j]) / cnt)[g]
        if np.max(np.abs(X - old)) < tol:
            break
    return pd.DataFrame(X, columns=cols, index=df.index)


# ============================================================================ E1 Conley
def e1_conley():
    h = hunan()
    specs = [("(1) weighted, no controls", "Zeng_all0_invdist_Post", []),
             ("(4) weighted, all controls", "Zeng_all0_invdist_Post", HUNAN_CTRL),
             ("(7) unweighted, no controls", "Zeng_all0_Post", [])]
    stata = {50: {"(1) weighted, no controls": 0.055, "(4) weighted, all controls": 0.057, "(7) unweighted, no controls": 0.040},
             100: {}, 200: {}}
    from common import parse_outreg2, STATA_TABLES
    for k in (50, 100, 200):
        t = parse_outreg2(STATA_TABLES / f"Appendix_Table_B1_III_{k}KM.txt")
        stata[k] = {"(1) weighted, no controls": t[1]["vars"]["Zeng_all0_invdist_Post"][1],
                    "(4) weighted, all controls": t[4]["vars"]["Zeng_all0_invdist_Post"][1],
                    "(7) unweighted, no controls": t[7]["vars"]["Zeng_all0_Post"][1]}
    rows = []
    for name, x, c in specs:
        cols = ["lnmartyr1", x] + c
        dm = demean(h, cols, ["cntyid", "year"])
        dm[["y_coord", "x_coord", "year", "cntyid"]] = h[["y_coord", "x_coord", "year", "cntyid"]]
        base = sp.regress(f"lnmartyr1 ~ {' + '.join([x] + c)}", data=dm)
        for k in (50, 100, 200):
            for kern in ("bartlett", "uniform"):
                r = sp.conley(base, dm, lat="y_coord", lon="x_coord", dist_cutoff=k, kernel=kern, time="year",
                              lag_cutoff=20, unit="cntyid")
                rows.append(dict(spec=name, cutoff_km=k, spatial_kernel=kern, coef=float(r.params[x]),
                                 conley_se=float(r.std_errors[x]),
                                 stata_reg2hdfespatial_se=stata[k][name] if kern == "bartlett" else np.nan))
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "ext_E1_conley.csv", index=False)
    LOG["E1"] = df
    tick("E1 Conley done")


def wcr_fe(df, y, x, controls, fes, cl, B=9999, weights="webb", seed=20230501):
    """Correct wild-cluster restricted (WCR-C) bootstrap with absorbed FEs: every bootstrap outcome is
    re-projected on the FE space before the CR1 t-statistic is formed (needed whenever an FE, here `year`,
    is not nested in the cluster). Written because sp.hdfe_ols(wild=True) skips that step (StatsPAI bug #3)."""
    import scipy.sparse as sps
    d = df[[y, x] + controls + fes + [cl]].dropna()
    D = sps.hstack([sps.csr_matrix(pd.get_dummies(d[f].astype("int64"), dtype=float).to_numpy()) for f in fes]).tocsr()
    P = np.linalg.pinv((D.T @ D).toarray())

    def M(v):
        return v - D @ (P @ (D.T @ v))

    Y = M(d[y].to_numpy(float))
    Xf = np.column_stack([M(d[c].to_numpy(float)) for c in [x] + controls])
    Xr = Xf[:, 1:]
    g = pd.factorize(d[cl])[0]
    G = g.max() + 1
    XtXi = np.linalg.inv(Xf.T @ Xf)

    def tstat(yv):
        b = XtXi @ (Xf.T @ yv)
        e = yv - Xf @ b
        S = np.zeros((G, Xf.shape[1]))
        for k in range(Xf.shape[1]):
            S[:, k] = np.bincount(g, Xf[:, k] * e, minlength=G)
        V = XtXi @ (S.T @ S) @ XtXi
        return b[0] / np.sqrt(V[0, 0]), b[0]

    t0, b0 = tstat(Y)
    if Xr.shape[1]:
        br = np.linalg.lstsq(Xr, Y, rcond=None)[0]
        fit_r, e_r = Xr @ br, Y - Xr @ br
    else:
        fit_r, e_r = np.zeros_like(Y), Y
    rng = np.random.default_rng(seed)
    vals = (np.array([-np.sqrt(1.5), -1, -np.sqrt(0.5), np.sqrt(0.5), 1, np.sqrt(1.5)]) if weights == "webb"
            else np.array([-1.0, 1.0]))
    W = rng.choice(vals, size=(B, G))
    ts = np.array([tstat(M(fit_r + e_r * W[b][g]))[0] for b in range(B)])
    return dict(coef=float(b0), t=float(t0), wcr_p=float(np.mean(np.abs(ts) >= abs(t0))), reps=B)


# ============================================================================ E2 wild cluster bootstrap
def e2_wild():
    h = hunan()
    n = national()
    rows = []
    jobs = [
        ("Table 2 (1), cluster=prefecture", "lnmartyr1", ["Zeng_all0_invdist_Post"], ["year", "cntyid"], h, "prefid"),
        ("Table 2 (4), cluster=prefecture", "lnmartyr1", ["Zeng_all0_invdist_Post"] + HUNAN_CTRL, ["year", "cntyid"], h, "prefid"),
        ("Table 5 (1) Hunan DD, cluster=prefecture", "alloff", ["Zeng_all0_invdistXperiod"], ["year", "samcntyid"],
         n[n.hunan == 1], "prefid"),
        ("Table 5 (2) Hunan DD+controls, cluster=prefecture", "alloff", NAT_CTRL + ["Zeng_all0_invdistXperiod"],
         ["year", "samcntyid"], n[n.hunan == 1], "prefid"),
    ]
    stata_boottest = {("Table 2 (1), cluster=prefecture", "rademacher"): 0.3028, ("Table 2 (1), cluster=prefecture", "webb"): 0.3054,
                      ("Table 2 (4), cluster=prefecture", "webb"): 0.0464, ("Table 5 (1) Hunan DD, cluster=prefecture", "webb"): 0.2182}
    for name, y, xs, fe, d, cl in jobs:
        x = xs[-1] if "Table 2" not in name else xs[0]
        controls = [c for c in xs if c != x]
        cols = list(dict.fromkeys([y] + xs + fe + [cl]))
        dd = d[cols].dropna()
        for wt in ("rademacher", "webb"):
            r = sp.hdfe_ols(f"{y} ~ {' + '.join(xs)} | {' + '.join(fe)}", data=dd, cluster=cl, wild=True,
                            wild_n_boot=4999, wild_weight_type=wt, wild_seed=20230501)
            G = dd[cl].nunique()
            ci = r.cluster_info["wild_ci"][x]
            ok = wcr_fe(dd, y, x, controls, fe, cl, B=9999, weights=wt)
            rows.append(dict(regression=name, var=x, n_clusters=G, coef=float(r.coef[x]), cluster_se=float(r.se[x]),
                             cluster_p_tG1=float(2 * stats.t.sf(abs(r.coef[x] / r.se[x]), G - 1)),
                             wild_weights=wt, sp_hdfe_ols_wild_p=float(r.cluster_info["wild_p"][x]),
                             sp_hdfe_ols_wild_ci_low=float(ci[0]), sp_hdfe_ols_wild_ci_high=float(ci[1]),
                             corrected_wcr_p=ok["wcr_p"], stata_boottest_p=stata_boottest.get((name, wt), np.nan)))
            tick(f"  E2 {name} {wt}")
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "ext_E2_wild_bootstrap.csv", index=False)
    LOG["E2"] = df
    tick("E2 wild bootstrap done")


# ============================================================================ E3 event-study sensitivity
def e3_event_study():
    h = hunan()
    yrs = [y for y in range(1850, 1865) if y != 1853]
    names = [f"Z_yr{y}" for y in yrs]
    for y, nm in zip(yrs, names):
        h[nm] = h.Zeng_all0_invdist * (h.year == y)
    rows, r = ols("lnmartyr1", names + HUNAN_CTRL, ["year", "cntyid", "prefidXyear"], h, "cntyid", keep=names)
    cf, VV, nobs = coef_vcov(r)
    V = VV.loc[names, names]
    b = cf[names].to_numpy()
    se = np.sqrt(np.diag(V.values))
    rel = np.array(yrs) - 1854  # 1853 (last pre-war year, omitted) -> -1 ; 1854 -> 0
    es = pd.DataFrame(dict(relative_time=rel, att=b, se=se))
    es["ci_lower"], es["ci_upper"] = b - 1.96 * se, b + 1.96 * se
    es["pvalue"] = 2 * stats.norm.sf(np.abs(b / se))
    pre = [nm for nm, t in zip(names, rel) if t < 0]
    post_avg = float(b[rel >= 0].mean())
    cr = CausalResult(method="TWFE event study (continuous exposure x year)", estimand="ATT", estimate=post_avg,
                      se=float(np.sqrt(np.ones(11) @ V.values[3:, 3:] @ np.ones(11)) / 11), pvalue=np.nan, ci=(np.nan, np.nan),
                      alpha=0.05, n_obs=nobs, detail=es,
                      model_info={"event_study": es, "vcv_pre": V.loc[pre, pre].values, "df_resid": 73,
                                  "vcv": V.values})
    out = {}
    out["pretrends_test"] = sp.pretrends_test(cr)
    try:
        out["pretrends_power"] = {k: v for k, v in sp.pretrends_power(cr).items() if np.isscalar(v) or isinstance(v, str)}
    except Exception as ex:  # noqa: BLE001
        out["pretrends_power"] = f"ERROR {ex!r}"
    # exact joint Wald using the full pre-period covariance (for comparison with StatsPAI's pretrends_test)
    bp = V.loc[pre, pre]
    w = float(b[:3] @ np.linalg.solve(bp.values, b[:3]))
    out["joint_wald_full_vcov"] = dict(stat=w, df=3, p=float(stats.chi2.sf(w, 3)),
                                       F=w / 3, p_F_73=float(stats.f.sf(w / 3, 3, 73)))
    hd = []
    for e in (0, 4):
        for meth in ("smoothness", "relative_magnitude"):
            for backend in ("native", "r"):
                try:
                    t = sp.honest_did(cr, e=e, method=meth, backend=backend,
                                      m_grid=[0, 0.25, 0.5, 1.0, 1.5, 2.0] if meth == "relative_magnitude" else None)
                    t = t.assign(e=e, method=meth, backend=f"statspai-{backend}")
                    hd.append(t)
                except Exception as ex:  # noqa: BLE001
                    hd.append(pd.DataFrame([dict(e=e, method=meth, backend=f"statspai-{backend}", error=repr(ex)[:200])]))
        try:
            out[f"breakdown_m_e{e}"] = float(sp.breakdown_m(cr, e=e))
        except Exception as ex:  # noqa: BLE001
            out[f"breakdown_m_e{e}"] = repr(ex)[:200]
    # exact R HonestDiD with the FULL covariance (StatsPAI cannot take user-supplied beta/sigma)
    np.savetxt(OUT / "_es_beta.csv", b, delimiter=",")
    np.savetxt(OUT / "_es_sigma.csv", V.values, delimiter=",")
    rcode = f"""
suppressMessages(library(HonestDiD))
b <- as.numeric(read.csv('{OUT / "_es_beta.csv"}', header=FALSE)[,1])
S <- as.matrix(read.csv('{OUT / "_es_sigma.csv"}', header=FALSE))
res <- list()
for (e in c(0,4)) {{
  l <- basisVector(e+1, 11)
  rm <- createSensitivityResults_relativeMagnitudes(betahat=b, sigma=S, numPrePeriods=3, numPostPeriods=11,
          Mbarvec=c(0,0.25,0.5,1,1.5,2), l_vec=l)
  sd <- createSensitivityResults(betahat=b, sigma=S, numPrePeriods=3, numPostPeriods=11,
          Mvec=c(0, 0.025, 0.05, 0.1, 0.15, 0.2), l_vec=l, method='FLCI')
  rm$e <- e; rm$family <- 'relative_magnitude'; names(rm)[names(rm)=='Mbar'] <- 'M'
  sd$e <- e; sd$family <- 'smoothness'
  res[[length(res)+1]] <- as.data.frame(rm)[,c('lb','ub','method','M','e','family')]
  res[[length(res)+1]] <- as.data.frame(sd)[,c('lb','ub','method','M','e','family')]
}}
write.csv(do.call(rbind,res), '{OUT / "ext_E3_honestdid_R_fullvcov.csv"}', row.names=FALSE)
"""
    try:
        subprocess.run(["/usr/local/bin/Rscript", "-e", rcode], check=True, capture_output=True, text=True, timeout=1800)
        out["R_full_vcov"] = "ok"
    except Exception as ex:  # noqa: BLE001
        out["R_full_vcov"] = repr(ex)[:500]
    for f in ("_es_beta.csv", "_es_sigma.csv"):
        (OUT / f).unlink(missing_ok=True)
    pd.concat(hd, ignore_index=True).to_csv(OUT / "ext_E3_honestdid_statspai.csv", index=False)
    es.to_csv(OUT / "ext_E3_event_study_fig4A.csv", index=False)
    with open(OUT / "ext_E3_pretrends.json", "w") as f:
        json.dump(out, f, indent=2, default=str)
    LOG["E3"] = out
    tick("E3 event-study sensitivity done")


# ============================================================================ E4 continuous-treatment DID
def e4_continuous():
    h = hunan()
    h["cohort"] = np.where(h.Zeng_all0_invdist > 0, 1854, 0)
    rows = []
    for deg in (1, 2, 3):
        c = sp.cgs_continuous_did(h, "lnmartyr1", dose="Zeng_all0_invdist", time="year", unit="cntyid",
                                  cohort="cohort", degree=deg)
        rows.append(dict(estimator=f"sp.cgs_continuous_did degree={deg}", overall_att=float(c.overall_att),
                         overall_acrt=float(c.overall_acrt), overall_acrt_se=float(c.overall_acrt_se),
                         n_units=int(c.n_units)))
        if deg == 3:
            c.to_frame().to_csv(OUT / "ext_E4_cgs_dose_response_deg3.csv", index=False)
    # benchmarks: TWFE slope (Table 2 col 1) and binary DID (any connection)
    tw, _ = ols("lnmartyr1", ["Zeng_all0_invdist_Post"], ["year", "cntyid"], h, "cntyid")
    rows.append(dict(estimator="TWFE continuous slope (Table 2 col 1)", overall_acrt=tw[0]["coef"], overall_acrt_se=tw[0]["se"]))
    h["any_Post"] = (h.Zeng_all0_invdist > 0) * h.Post
    bi, _ = ols("lnmartyr1", ["any_Post"], ["year", "cntyid"], h, "cntyid")
    rows.append(dict(estimator="TWFE binary: any connection x Post", overall_att=bi[0]["coef"], overall_acrt_se=bi[0]["se"]))
    # dose terciles among connected
    pos = h.loc[h.Zeng_all0_invdist > 0].groupby("cntyid").Zeng_all0_invdist.first()
    q = pd.qcut(pos, 3, labels=["T1", "T2", "T3"])
    h["tercile"] = h.cntyid.map(q).astype(object)
    xs = []
    for t in ["T1", "T2", "T3"]:
        h[f"{t}_Post"] = (h.tercile == t) * h.Post
        xs.append(f"{t}_Post")
    tb, _ = ols("lnmartyr1", xs, ["year", "cntyid"], h, "cntyid")
    for rr, t in zip(tb, ["T1", "T2", "T3"]):
        lo, hi = pos[q == t].min(), pos[q == t].max()
        rows.append(dict(estimator=f"TWFE dose bin {t} [{lo:.2f},{hi:.2f}] x Post vs unconnected", overall_att=rr["coef"],
                         overall_acrt_se=rr["se"]))
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "ext_E4_continuous_did.csv", index=False)
    LOG["E4"] = df
    tick("E4 continuous DID done")


# ============================================================================ E5 functional form
def e5_functional_form():
    h = hunan()
    h["any_death"] = (h.martyr > 0).astype(float)
    rows = []
    for name, xs in [("no controls", ["Zeng_all0_invdist_Post"]), ("all controls", ["Zeng_all0_invdist_Post"] + HUNAN_CTRL)]:
        f = f"martyr ~ {' + '.join(xs)} | cntyid + year"
        p = sp.fepois(f, data=h, vcov={"CRV1": "cntyid"})
        b, s = float(p.params["Zeng_all0_invdist_Post"]), float(p.std_errors["Zeng_all0_invdist_Post"])
        rows.append(dict(outcome="soldier deaths (count)", model=f"FE Poisson, {name}", coef=b, se=s,
                         pct_effect=100 * (np.exp(b) - 1), p=float(2 * stats.norm.sf(abs(b / s)))))
        l, _ = ols("any_death", xs, ["cntyid", "year"], h, "cntyid", keep=["Zeng_all0_invdist_Post"])
        rows.append(dict(outcome="1[soldier deaths>0]", model=f"LPM, {name}", coef=l[0]["coef"], se=l[0]["se"],
                         p=float(2 * stats.t.sf(abs(l[0]["coef"] / l[0]["se"]), 74))))
        o, _ = ols("lnmartyr1", xs, ["cntyid", "year"], h, "cntyid", keep=["Zeng_all0_invdist_Post"])
        rows.append(dict(outcome="ln(1+deaths) (paper)", model=f"OLS, {name}", coef=o[0]["coef"], se=o[0]["se"],
                         p=float(2 * stats.t.sf(abs(o[0]["coef"] / o[0]["se"]), 74))))
    n = national()
    xs = NAT_CTRL + ["hXZeng_all0_invdistXperiod", "Zeng_all0_invdistXperiod", "hunanXperiod"]
    p = sp.fepois(f"alloff ~ {' + '.join(xs)} | samcntyid + year", data=n, vcov={"CRV1": "prefid"})
    b, s = float(p.params["hXZeng_all0_invdistXperiod"]), float(p.std_errors["hXZeng_all0_invdistXperiod"])
    rows.append(dict(outcome="national offices (count)", model="FE Poisson DDD (Table 5 col 6 spec)", coef=b, se=s,
                     pct_effect=100 * (np.exp(b) - 1), p=float(2 * stats.norm.sf(abs(b / s)))))
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "ext_E5_functional_form.csv", index=False)
    LOG["E5"] = df
    tick("E5 functional form done")


# ============================================================================ E6 national DDD pre-trends
def e6_national_pretrend():
    est = pd.read_csv(OUT / "figure6_estimates.csv") if (OUT / "figure6_estimates.csv").exists() else None
    n = national(keep1820=False)
    years = list(range(1821, 1911))
    for y in years:
        dy = (n.year == y).astype(float)
        n[f"h_{y}"] = n.hXZeng_all0_invdist * dy
        n[f"z_{y}"] = n.Zeng_all0_invdist * dy
        n[f"hun_{y}"] = n.hunan * dy
    H = [f"h_{y}" for y in years]
    xs = H + [f"z_{y}" for y in years] + [f"hun_{y}" for y in years] + NAT_CTRL_FIG6
    _, r = ols("alloff", xs, ["year", "samcntyid"], n, "prefid", keep=H)
    cf, V, _ = coef_vcov(r)
    G = n.prefid.nunique()
    out = {}
    for label, yy in [("1821-1853 (all pre-war)", range(1821, 1854)), ("1821-1849", range(1821, 1850)),
                      ("1850-1853", range(1850, 1854))]:
        nm = [f"h_{y}" for y in yy]
        bb = cf[nm].to_numpy()
        vv = V.loc[nm, nm].to_numpy()
        w = float(bb @ np.linalg.pinv(vv) @ bb)
        k = len(nm)
        out[label] = dict(k=k, wald=w, p_chi2=float(stats.chi2.sf(w, k)), p_F=float(stats.f.sf(w / k, k, G - 1)),
                          mean_coef=float(bb.mean()))
    # flatness within the DDD pre-period (Table 5 uses 1820-1853 as "pre"): H0 all 1821-1853 coefs equal the 1820 base
    # is the test above; H0' they are equal to each other (level shift vs 1800-1820 allowed) and H0'' no linear trend
    yy = list(range(1821, 1854))
    nm = [f"h_{y}" for y in yy]
    bb = cf[nm].to_numpy()
    vv = V.loc[nm, nm].to_numpy()
    k = len(nm)
    Dm = np.eye(k)[1:] - np.eye(k)[:-1]  # successive differences
    wd = float((Dm @ bb) @ np.linalg.pinv(Dm @ vv @ Dm.T) @ (Dm @ bb))
    out["1821-1853 equal to each other (no dynamics in pre-period)"] = dict(k=k - 1, wald=wd, p_chi2=float(stats.chi2.sf(wd, k - 1)),
                                                                          p_F=float(stats.f.sf(wd / (k - 1), k - 1, G - 1)))
    tt = np.array(yy, float) - np.mean(yy)
    a = tt / (tt @ tt)
    slope = float(a @ bb)
    slope_se = float(np.sqrt(a @ vv @ a))
    out["1821-1853 linear trend in DDD coefs"] = dict(slope_per_year=slope, se=slope_se, t=slope / slope_se,
                                                       implied_change_1821_1853=slope * 32)
    post = [f"h_{y}" for y in range(1854, 1911)]
    out["mean post 1854-1910 minus mean pre 1821-1853"] = float(cf[post].mean() - cf[[f"h_{y}" for y in range(1821, 1854)]].mean())
    with open(OUT / "ext_E6_national_ddd_pretrends.json", "w") as f:
        json.dump(out, f, indent=2)
    LOG["E6"] = out
    tick("E6 national DDD pre-trends done")


# ============================================================================ E7 weak-IV robust inference, Table 4 IV
def e7_weak_iv():
    """Table 4 cols 4-6 instrument actual connections with national-exam (jinshi-cohort) connections; Stata reports a
    Kleibergen-Paap F of 11.7 for col 4. Report tF-adjusted critical values and a cluster-robust AR confidence set."""
    from common import drop_singletons
    h = hunan()
    s = h[h.cntyid != 25]
    fe = ["year", "cntyid", "prefidXyear"]
    rows = []
    kp_f = {4: 11.684}
    for col, pl in [(4, ["invdist0_L1_Post"]), (5, ["invdist0_F1_Post"]), (6, ["invdist0_L1_Post", "invdist0_F1_Post"])]:
        cols = ["lnmartyr1", "Zeng_all0_invdist_Post", "Zeng_exam0_invdist_Post"] + pl + HUNAN_CTRL + fe
        d = drop_singletons(s[cols].dropna(), fe)
        rec = dict(col=col)
        try:
            ar = sp.anderson_rubin_test(d, y="lnmartyr1", endog="Zeng_all0_invdist_Post", instruments=["Zeng_exam0_invdist_Post"],
                                        exog=pl + HUNAN_CTRL, absorb=fe, cluster="cntyid")
            rec.update({f"sp_{k}": (v if np.isscalar(v) or isinstance(v, str) else str(v)) for k, v in ar.items()
                        if k in ("ar_stat", "ar_pvalue", "ar_ci", "first_stage_F", "effective_F", "tF_critical_value")})
        except Exception as ex:  # noqa: BLE001
            rec["sp_anderson_rubin_test_error"] = repr(ex)[:300]
        # manual AR inversion: reduced form of (y - b0*d) on z with the same FE / cluster conventions as Table 4
        grid = np.round(np.arange(-0.5, 2.0001, 0.01), 3)
        acc = []
        for b0 in grid:
            d["_ytil"] = d.lnmartyr1 - b0 * d.Zeng_all0_invdist_Post
            rr, _ = ols("_ytil", ["Zeng_exam0_invdist_Post"] + pl + HUNAN_CTRL, fe, d, "cntyid", keep=["Zeng_exam0_invdist_Post"])
            t = rr[0]["coef"] / rr[0]["se"]
            if abs(t) < stats.t.ppf(0.975, d.cntyid.nunique() - 1):
                acc.append(b0)
        d["_ytil"] = d.lnmartyr1
        rr0, _ = ols("_ytil", ["Zeng_exam0_invdist_Post"] + pl + HUNAN_CTRL, fe, d, "cntyid", keep=["Zeng_exam0_invdist_Post"])
        rec["manual_AR_t_at_0 (= Table 4 reduced form)"] = rr0[0]["coef"] / rr0[0]["se"]
        rec["manual_AR_p_at_0"] = float(2 * stats.t.sf(abs(rec["manual_AR_t_at_0 (= Table 4 reduced form)"]), d.cntyid.nunique() - 1))
        rec["manual_AR95_set"] = f"[{min(acc):.2f}, {max(acc):.2f}]" if acc else "empty"
        rec["manual_AR95_bounded_in_grid"] = bool(acc) and min(acc) > grid[0] and max(acc) < grid[-1]
        if col in kp_f:
            rec["KP_F_stata"] = kp_f[col]
            rec["tF_critical_value"] = float(sp.tF_adjustment(kp_f[col]))
            rec["t_stat_2sls"] = 0.3289626 / 0.1374197
        rows.append(rec)
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "ext_E7_weak_iv_table4.csv", index=False)
    LOG["E7"] = df
    tick("E7 weak-IV robust inference done")


if __name__ == "__main__":
    import sys
    todo = sys.argv[1:] or ["e1", "e2", "e3", "e4", "e5", "e6", "e7"]
    fns = dict(e1=e1_conley, e2=e2_wild, e3=e3_event_study, e4=e4_continuous, e5=e5_functional_form, e6=e6_national_pretrend, e7=e7_weak_iv)
    for k in todo:
        try:
            fns[k]()
        except Exception as ex:  # noqa: BLE001
            import traceback
            traceback.print_exc()
            tick(f"{k} FAILED: {ex!r}")
    tick("all done")
