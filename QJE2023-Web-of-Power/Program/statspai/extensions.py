"""Modern-methods EXTENSIONS (not replication) for Bai, Jia & Yang (2023, QJE), using StatsPAI.

E1  Conley spatial + serial HAC (sp.conley) vs. the authors' reg2hdfespatial (Appendix Table B.1.III)
E2  Wild cluster bootstrap with few clusters (sp.hdfe_ols(wild=True)): Hunan-only regressions have 14-15 prefectures
E3  Event-study diagnostics on Figure 4A: pretrends_test / pretrends_power / honest_did / breakdown_m
    + exact Rambachan-Roth benchmark with the full event-study covariance through R HonestDiD
E4  Continuous-treatment DID: sp.cgs_continuous_did (Callaway, Goodman-Bacon & Sant'Anna 2024) and dose bins
E5  Functional form with many zeros (Chen & Roth 2024; I4R comment): FE-Poisson (sp.fepois) + extensive margin LPM
E6  Joint pre-trend test for the national DDD event study (Figure 6C)

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

from common import HUNAN_CTRL, NAT_CTRL, OUT, coef_vcov, hunan, national, ols

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
    for name, y, xs, fe, d, cl in jobs:
        x = xs[-1] if "Table 2" not in name else xs[0]
        cols = list(dict.fromkeys([y] + xs + fe + [cl]))
        dd = d[cols].dropna()
        for wt in ("rademacher", "webb"):
            r = sp.hdfe_ols(f"{y} ~ {' + '.join(xs)} | {' + '.join(fe)}", data=dd, cluster=cl, wild=True,
                            wild_n_boot=9999, wild_weight_type=wt, wild_seed=20230501)
            G = dd[cl].nunique()
            ci = r.cluster_info["wild_ci"][x]
            rows.append(dict(regression=name, var=x, n_clusters=G, coef=float(r.coef[x]), cluster_se=float(r.se[x]),
                             cluster_p_tG1=float(2 * stats.t.sf(abs(r.coef[x] / r.se[x]), G - 1)),
                             wild_weights=wt, wild_p=float(r.cluster_info["wild_p"][x]), wild_ci_low=float(ci[0]),
                             wild_ci_high=float(ci[1])))
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
    xs = H + [f"z_{y}" for y in years] + [f"hun_{y}" for y in years] + NAT_CTRL
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
    post = [f"h_{y}" for y in range(1854, 1911)]
    out["mean post 1854-1910 minus mean pre 1821-1853"] = float(cf[post].mean() - cf[[f"h_{y}" for y in range(1821, 1854)]].mean())
    with open(OUT / "ext_E6_national_ddd_pretrends.json", "w") as f:
        json.dump(out, f, indent=2)
    LOG["E6"] = out
    tick("E6 national DDD pre-trends done")


if __name__ == "__main__":
    import sys
    todo = sys.argv[1:] or ["e1", "e2", "e3", "e4", "e5", "e6"]
    fns = dict(e1=e1_conley, e2=e2_wild, e3=e3_event_study, e4=e4_continuous, e5=e5_functional_form, e6=e6_national_pretrend)
    for k in todo:
        try:
            fns[k]()
        except Exception as ex:  # noqa: BLE001
            import traceback
            traceback.print_exc()
            tick(f"{k} FAILED: {ex!r}")
    tick("all done")
