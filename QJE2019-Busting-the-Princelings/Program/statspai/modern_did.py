"""EXTENSIONS (not replication): modern DID diagnostics for Chen & Kung (2019).

The paper's Table X interacts the transaction-level princeling dummy with three
province-level "campaign" indicators whose timing differs across provinces:
  * xiappointed : province party secretary replaced by a Xi appointee (absorbing; first year
                  2013/2014/2015/2016; several provinces never treated by 2016)  -> staggered
  * inspection  : province under a CCDI central inspection that year (rounds in 2013, 2014,
                  second round 2016; NOT absorbing)  -> first-inspection cohort 2013 vs 2014
A TWFE triple interaction with staggered timing is exposed to the forbidden-comparison
problem (Goodman-Bacon 2021; de Chaisemartin & D'Haultfoeuille 2020).  We therefore

  A. collapse the transaction data to a province x year panel of the *princeling price gap*
     (coefficient on princeling x province-year from the paper's own Table V specification,
     i.e. lnprice ~ i(provyear, princeling) + quality + lnarea | cityyearusage + ind + month +
     salemethod + state + size), and treat Xi-appointed timing as a staggered adoption;
  B. estimate TWFE, Goodman-Bacon decomposition, Callaway-Sant'Anna (never- and not-yet-
     treated), Sun-Abraham and Borusyak-Jaravel-Spiess on that panel (outcome: gap, so a
     positive ATT = smaller princeling discount after a Xi appointee arrives);
  C. repeat the CS estimator with first central-inspection year as the cohort (not-yet-treated);
  D. Rambachan-Roth HonestDiD and Roth (2022) pre-trend power for the paper's Figure V event
     study (princeling discount by year, 2013+ = campaign).
"""
from __future__ import annotations

import json
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statspai as sp

from common import OUT, load, tic

warnings.filterwarnings("ignore")
FE = "cityyearusage + ind + month + salemethod + state + size"
LOG = {}


def _num(x):
    try:
        return float(x)
    except Exception:
        return None


def build_gap_panel(min_princeling=3):
    cols = ["lnprice", "princeling", "quality", "lnarea", "cityyearusage", "ind", "month", "salemethod",
            "state", "size", "provid", "firmid", "year", "xiappointed", "inspection"]
    d = load("price", columns=cols).dropna(subset=["lnprice", "quality", "lnarea", "provid", "year",
                                                   "cityyearusage", "ind", "month"])
    d["provid"] = d["provid"].astype(int)
    d["year"] = d["year"].astype(int)
    d["py"] = d["provid"] * 10000 + d["year"]
    cnt = d[d.princeling == 1].groupby("py").size()
    # Cell gap = pooled Table V (col 1) princeling coefficient + mean residual of the cell's
    # princeling parcels.  Equivalent to a princeling x province-year interaction model up to
    # FE re-weighting, but needs one regression instead of ~400 dense dummy columns.
    t0 = tic()
    r = sp.feols(f"lnprice ~ princeling + quality + lnarea | {FE}", data=d, vcov={"CRV1": "provid + firmid"})
    b = float(r.params["princeling"])
    e = np.asarray(r.residuals if not callable(r.residuals) else r.residuals())
    assert len(e) == len(d), (len(e), len(d))
    d["e"] = e
    print(f"pooled regression b={b:.4f} ({tic() - t0:.0f}s)", flush=True)
    pr = d[d.princeling == 1].groupby("py").e.agg(["mean", "std", "size"])
    pr = pr[pr["size"] >= min_princeling]
    gap = pd.DataFrame({"py": pr.index.astype(int), "gap": b + pr["mean"].values,
                        "gap_se": (pr["std"] / np.sqrt(pr["size"])).values})
    gap["provid"] = gap.py // 10000
    gap["year"] = gap.py % 10000
    gap["n_princeling"] = gap.py.map(cnt)
    # province-level timing
    pt = d.groupby(["provid", "year"]).agg(xi=("xiappointed", "mean"), insp=("inspection", "mean")).reset_index()
    first_xi = pt[pt.xi >= 0.5].groupby("provid").year.min()
    first_insp = pt[(pt.insp >= 0.05) & (pt.year >= 2013)].groupby("provid").year.min()
    gap["g_xi"] = gap.provid.map(first_xi).fillna(0).astype(int)
    gap["g_insp"] = gap.provid.map(first_insp).fillna(0).astype(int)
    gap["treat_xi"] = ((gap.g_xi > 0) & (gap.year >= gap.g_xi)).astype(float)
    gap.to_csv(OUT / "modern_gap_panel.csv", index=False)
    return gap


def safe(name, fn):
    t0 = tic()
    try:
        out = fn()
        print(f"[ok] {name} ({tic() - t0:.0f}s)", flush=True)
        return out
    except Exception as e:  # record StatsPAI failures instead of aborting
        msg = f"{type(e).__name__}: {str(e)[:400]}"
        print(f"[FAIL] {name}: {msg}", flush=True)
        LOG[f"error_{name}"] = msg
        return None


def causal_summary(res):
    if res is None:
        return None
    return {"estimate": _num(getattr(res, "estimate", None)), "se": _num(getattr(res, "se", None)),
            "pvalue": _num(getattr(res, "pvalue", None)), "ci": [_num(c) for c in (getattr(res, "ci", None) or [None, None])],
            "n_obs": _num(getattr(res, "n_obs", None))}


def es_table(res):
    info = getattr(res, "model_info", {}) or {}
    es = info.get("event_study")
    if es is None and isinstance(getattr(res, "detail", None), pd.DataFrame):
        es = res.detail
    return es


def staggered(gap):
    out = {}
    # balanced panel for Bacon: longest window start..2016 keeping >= 12 provinces with a gap every year
    g = gap.copy()
    best = None
    for start in range(2004, 2013):
        yrs = list(range(start, 2017))
        gg = g[g.year.isin(yrs)]
        full = gg.groupby("provid").year.nunique()
        provs = full[full == len(yrs)].index
        if len(provs) >= 12 and (best is None or len(yrs) * len(provs) > best[0]):
            best = (len(yrs) * len(provs), start, provs)
    bal = g[(g.year >= best[1]) & g.provid.isin(best[2])].copy() if best else g.iloc[0:0]
    out["panel"] = {"cells": int(len(gap)), "provinces": int(gap.provid.nunique()),
                    "balanced_window_start": (int(best[1]) if best else None), "balanced_provinces": int(bal.provid.nunique()),
                    "cohorts_xi": {int(k): int(v) for k, v in gap.groupby("g_xi").provid.nunique().items()},
                    "cohorts_insp": {int(k): int(v) for k, v in gap.groupby("g_insp").provid.nunique().items()}}
    print(out["panel"], flush=True)

    tw = safe("twfe", lambda: sp.feols("gap ~ treat_xi | provid + year", data=g, vcov={"CRV1": "provid"}))
    if tw is not None:
        out["twfe"] = {"coef": float(tw.params["treat_xi"]), "se": float(tw.std_errors["treat_xi"]), "N": int(len(g))}
    tw_b = safe("twfe_balanced", lambda: sp.feols("gap ~ treat_xi | provid + year", data=bal, vcov={"CRV1": "provid"}))
    if tw_b is not None:
        out["twfe_balanced"] = {"coef": float(tw_b.params["treat_xi"]), "se": float(tw_b.std_errors["treat_xi"]), "N": int(len(bal))}

    bac = safe("bacon", lambda: sp.bacon_decomposition(bal, y="gap", treat="treat_xi", time="year", id="provid"))
    if bac is not None:
        dec = bac["decomposition"]
        dec.to_csv(OUT / "modern_bacon_decomposition.csv", index=False)
        out["bacon"] = {"beta_twfe": _num(bac.get("beta_twfe")), "weighted_sum": _num(bac.get("weighted_sum")),
                        "n_comparisons": bac.get("n_comparisons"),
                        "by_type": dec.groupby("type").apply(lambda x: {"weight": float(x.weight.sum()),
                                   "avg_est": float(np.average(x.estimate, weights=x.weight)) if x.weight.sum() > 0 else None}).to_dict()}

    cs_nt = safe("cs_never", lambda: sp.callaway_santanna(g, y="gap", g="g_xi", t="year", i="provid",
                                                          estimator="reg", control_group="nevertreated",
                                                          allow_unbalanced_panel=True))
    cs_ny = safe("cs_notyet", lambda: sp.callaway_santanna(g, y="gap", g="g_xi", t="year", i="provid",
                                                           estimator="reg", control_group="notyettreated",
                                                           allow_unbalanced_panel=True))
    for nm, rr in [("never", cs_nt), ("notyet", cs_ny)]:
        if rr is not None and isinstance(getattr(rr, "detail", None), pd.DataFrame):
            rr.detail.to_csv(OUT / f"modern_cs_attgt_{nm}.csv", index=False)
    out["cs_never"] = causal_summary(cs_nt)
    out["cs_notyet"] = causal_summary(cs_ny)
    dyn = None
    if cs_ny is not None:
        dyn = safe("cs_dynamic", lambda: sp.aggte(cs_ny, type="dynamic", random_state=1))
        if dyn is not None:
            es = es_table(dyn)
            if es is not None:
                es.to_csv(OUT / "modern_cs_event_study.csv", index=False)
            out["cs_dynamic_overall"] = causal_summary(dyn)
    sa = safe("sun_abraham", lambda: sp.sun_abraham(g, y="gap", g="g_xi", t="year", i="provid", cluster="provid"))
    out["sun_abraham"] = causal_summary(sa)
    if sa is not None and es_table(sa) is not None:
        es_table(sa).to_csv(OUT / "modern_sa_event_study.csv", index=False)
    g2 = g.copy()
    g2["g_bjs"] = g2.g_xi.replace(0, np.inf)
    bjs = safe("bjs", lambda: sp.did_imputation(g2, y="gap", group="provid", time="year", first_treat="g_bjs",
                                                cluster="provid", horizon=[0, 1, 2, 3], pretrends=3))
    out["bjs"] = causal_summary(bjs)
    if bjs is not None and es_table(bjs) is not None:
        es_table(bjs).to_csv(OUT / "modern_bjs_event_study.csv", index=False)

    # honest DiD on CS dynamic event study
    if dyn is not None:
        hd = safe("honest_did_cs", lambda: sp.honest_did(dyn, e=0, method="relative_magnitude",
                                                         m_grid=[0, 0.5, 1, 1.5, 2]))
        if hd is not None:
            hd.to_csv(OUT / "modern_honest_did_cs_xi.csv", index=False)
            out["honest_did_cs"] = hd.to_dict("records")

    # C. first central inspection as cohort (only not-yet-treated comparisons exist)
    cs_insp = safe("cs_inspection", lambda: sp.callaway_santanna(g[g.g_insp > 0], y="gap", g="g_insp", t="year",
                                                                  i="provid", estimator="reg",
                                                                  control_group="notyettreated",
                                                                  allow_unbalanced_panel=True))
    out["cs_inspection_notyet"] = causal_summary(cs_insp)
    return out


def figure_v_sensitivity():
    """HonestDiD + Roth (2022) power for the paper's Figure V design, re-based to 2012.

    Paper's Figure V omits 2004-05, so its coefficients are *levels* of the princeling discount.
    For a campaign event study the omitted period must be the last pre-campaign year:
        lnprice ~ princeling + sum_{y != 2012} princeling x 1[year=y] + quality-free spec | FEs
    (same FEs / two-way clustering as the paper; no controls, as in the do-file).  Coefficients are
    then changes in the discount relative to 2012; rel. time 0 = 2013 (Xi's campaign)."""
    cols = ["lnprice", "princeling", "year", "cityyearusage", "ind", "month", "salemethod", "state", "size",
            "provid", "firmid"]
    d = load("price", columns=cols).dropna()
    d["year"] = d["year"].astype(int)
    xs = []
    for y in range(2004, 2017):
        if y == 2012:
            continue
        nm = f"pt_{y}"
        d[nm] = (d["princeling"] * (d["year"] == y)).astype(float)
        xs.append(nm)
    t0 = tic()
    r = sp.feols(f"lnprice ~ princeling + {' + '.join(xs)} | {FE}", data=d, vcov={"CRV1": "provid + firmid"})
    dropped = [x for x in xs if x not in r.params.index]  # e.g. no priced princeling parcel in 2004
    xs = [x for x in xs if x in r.params.index]
    LOG["figV_rebased_dropped"] = dropped
    tab = pd.DataFrame({"relative_time": [int(x[3:]) - 2013 for x in xs],
                        "att": [float(r.params[x]) for x in xs],
                        "se": [float(r.std_errors[x]) for x in xs]})
    tab = pd.concat([tab, pd.DataFrame({"relative_time": [-1], "att": [0.0], "se": [0.0]})]).sort_values("relative_time")
    tab.to_csv(OUT / "modern_figureV_rebased_2012.csv", index=False)
    print(f"re-based Figure V ({tic() - t0:.0f}s)\n" + tab.round(3).to_string(), flush=True)
    es = tab[tab.relative_time != -1]
    post = es[es.relative_time >= 0]
    res = sp.CausalResult(method="Event study (Figure V spec, base 2012)", estimand="ATT",
                          estimate=float(post.att.mean()), se=float(np.sqrt((post.se ** 2).sum()) / len(post)),
                          pvalue=np.nan, ci=(np.nan, np.nan), alpha=0.05, n_obs=len(d),
                          detail=es, model_info={"event_study": es})
    out = {"event_study": tab.to_dict("records")}
    for e in [0, 1, 2, 3]:
        hd = safe(f"honest_did_figV_rm_e{e}", lambda e=e: sp.honest_did(res, e=e, method="relative_magnitude",
                                                                         m_grid=[0, 0.25, 0.5, 1.0, 1.5, 2.0]))
        if hd is not None:
            out[f"rm_e{e}"] = hd.to_dict("records")
        hs = safe(f"honest_did_figV_sd_e{e}", lambda e=e: sp.honest_did(res, e=e, method="smoothness"))
        if hs is not None:
            out[f"sd_e{e}"] = hs.to_dict("records")
    pw = safe("pretrends_power_figV", lambda: sp.pretrends_power(res))
    if pw is not None:
        out["pretrends_power"] = {k: (_num(v) if np.isscalar(v) else str(v)[:300]) for k, v in pw.items()}
    rows = []
    for k, v in out.items():
        if k.startswith(("rm_", "sd_")):
            for rr in v:
                rows.append({"spec": k, **rr})
    if rows:
        pd.DataFrame(rows).to_csv(OUT / "modern_honest_did_figureV.csv", index=False)
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.errorbar(tab.relative_time + 2013, tab.att, yerr=1.96 * tab.se, fmt="o-", color="black", capsize=3, lw=1)
    ax.axhline(0, color="black", lw=0.8); ax.axvline(2012.5, color="grey", ls="--", lw=0.8)
    ax.set_ylabel("Change in princeling price gap vs 2012"); ax.set_title("Figure V re-based to 2012 (StatsPAI)", fontsize=9)
    fig.tight_layout(); fig.savefig(OUT / "modern_figureV_rebased_2012.png", dpi=160); plt.close(fig)
    return out


def wild_cluster_bootstrap():
    """Only 31-32 province clusters: WCR wild cluster bootstrap (Rademacher, 999 reps, province
    clusters) for the key 500 m matched-sample columns (Table V col 3; Table X cols 2, 4, 6)."""
    cols = ["lnprice", "princeling", "quality", "lnarea", "pp1", "pp2", "pp3", "cityyearusage", "ind", "month",
            "salemethod", "state", "size", "provid", "firmid", "near500"]
    d = load("price", columns=cols)
    s = d[d.near500 == 1].dropna().copy()
    rows = []
    for label, xs, target in [("Table V col 3", [], "princeling"), ("Table X col 2", ["pp1"], "pp1"),
                              ("Table X col 4", ["pp2"], "pp2"), ("Table X col 6", ["pp3"], "pp3")]:
        fml = f"lnprice ~ {' + '.join(['princeling'] + xs + ['quality', 'lnarea'])} | {FE}"
        r = safe(f"wcb {label}", lambda fml=fml: sp.feols(fml, data=s, vcov="wild", cluster="provid",
                                                          wild_reps=999, seed=42))
        if r is None:
            continue
        for v in dict.fromkeys(["princeling", target]):
            rows.append(dict(exhibit=label, var=v, coef=float(r.params[v]), wcb_se=float(r.std_errors[v]),
                             p_wcb=float(r.pvalues[v]), ci_lo=float(r.conf_int_lower[v]),
                             ci_hi=float(r.conf_int_upper[v]), N=len(s)))
    out = pd.DataFrame(rows)
    out.to_csv(OUT / "modern_wild_cluster_bootstrap.csv", index=False)
    print(out.round(4).to_string())
    return out


def plot_es(files, fname):
    fig, ax = plt.subplots(figsize=(7, 4))
    for f, lab, off in files:
        p = OUT / f
        if not p.exists():
            continue
        es = pd.read_csv(p)
        tcol = "relative_time" if "relative_time" in es.columns else es.columns[0]
        bcol = "att" if "att" in es.columns else ("estimate" if "estimate" in es.columns else es.columns[1])
        scol = "se" if "se" in es.columns else None
        x = es[tcol] + off
        ax.errorbar(x, es[bcol], yerr=1.96 * es[scol] if scol else None, fmt="o-", capsize=2, lw=1, label=lab)
    ax.axhline(0, color="black", lw=0.8)
    ax.axvline(-0.5, color="grey", ls="--", lw=0.8)
    ax.set_xlabel("Years relative to Xi-appointed party secretary")
    ax.set_ylabel("Princeling price gap (log points)")
    ax.legend(fontsize=8)
    fig.tight_layout()
    fig.savefig(OUT / fname, dpi=160)
    plt.close(fig)


def main():
    gap = build_gap_panel()
    res = {"staggered_xi": staggered(gap), "figure_V_sensitivity": figure_v_sensitivity(), "errors": LOG}
    (OUT / "modern_did_results.json").write_text(json.dumps(res, indent=2, default=str))
    plot_es([("modern_cs_event_study.csv", "Callaway-Sant'Anna (not-yet-treated)", -0.1),
             ("modern_sa_event_study.csv", "Sun-Abraham", 0.0),
             ("modern_bjs_event_study.csv", "BJS imputation", 0.1)], "modern_event_studies_xi.png")
    print(json.dumps(res, indent=1, default=str)[:6000])


if __name__ == "__main__":
    import sys
    if "wcb" in sys.argv[1:]:
        wild_cluster_bootstrap()
    else:
        main()
