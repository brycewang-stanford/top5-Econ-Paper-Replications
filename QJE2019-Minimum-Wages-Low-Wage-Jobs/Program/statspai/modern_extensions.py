"""EXTENSIONS (not replication): modern staggered-DID estimators on a state-by-quarter
aggregate of the bunching outcomes, using the authors' stacked event file
Data/data/stackedevents_regready_pre12.dta (138 primary events x 51 states x
event time -12..19; built by create_stacked_events.do).

Outcomes (per capita, relative to each event's new MW):
  below_epop  = jobs in [MW-4, MW)   (missing jobs)
  above_epop  = jobs in [MW, MW+5)   (excess jobs)
  affected    = below + above        (bunching employment change)
Sample follows stacked_events_event_specific_regressions_DC_fulltable_clean_controls_QJE.do:
cleansample==1, and "clean controls": control states with any other primary event
inside the event window are dropped.

Estimators
  1. sp.hdfe_ols stacked event study  (event-by-state FE + event-by-time FE +
     event-by-{federal, other} control FEs, [aw=avg state pop], cluster state)
  2. sp.stacked_did    (StatsPAI's built-in CDLZ stacked estimator)
  3. sp.callaway_santanna, 4. sp.sun_abraham, 5. sp.did_imputation (BJS)
     -- unit = event x state, time = calendar quarter, cohort = treatment quarter
        for the treated state of each event, never-treated = clean controls
  6. sp.honest_did (Rambachan-Roth smoothness bounds) on the Sun-Abraham result.
All effects are rescaled by 1/EPOP_{-1} as in the paper and annualised
(averaged over quarters of event year) for comparability with Figure 3.

Run: /usr/local/bin/python3.13 Program/statspai/modern_extensions.py
Outputs: Results/statspai/ext_*.csv, ext_eventstudy_compare.png
"""
from __future__ import annotations

import json
import time
import traceback
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyreadstat
import statspai as sp

from bunching import DATA, OUT, log

warnings.filterwarnings("ignore")


def load() -> tuple[pd.DataFrame, float]:
    df, _ = pyreadstat.read_dta(str(DATA / "stackedevents_regready_pre12.dta"))
    df = df[df["cleansample"] == 1].copy()
    df = df.sort_values(["eventstate", "time"])
    # yearbeforeevent: F1..F4.origevent==1 within eventstate (tsset eventstate time)
    key = df.set_index(["eventstate", "time"])["origevent"]
    ybe = np.zeros(len(df), dtype=bool)
    for k in (1, 2, 3, 4):
        s = key.reindex(pd.MultiIndex.from_arrays([df["eventstate"], df["time"] + k])).to_numpy()
        ybe |= (s == 1)
    df["yearbeforeevent"] = ybe
    df["below_epop"] = df["overallmissingepop"]
    df["above_epop"] = df["overallexcessepop"]
    df["all_epop"] = df["overalltotalepop"]
    df["affected"] = df["below_epop"] + df["above_epop"]
    todrop = df.groupby(["statenum", "event"])["control_origeventpost"].transform("max")
    df = df[~((todrop != 0) & (df["treatedstatenum"] != df["statenum"]))].copy()
    tr = (df["origevent_treated"] == 1) & df["yearbeforeevent"]
    epop = float(np.average(df.loc[tr, "all_epop"], weights=df.loc[tr, "aveoverallpop"]))
    df["treated_unit"] = (df["statenum"] == df["treatedstatenum"]).astype(int)
    df["g"] = np.where(df["treated_unit"] == 1, df["treatdate"], 0).astype(int)
    df["unit"] = df["eventstate"].astype(int)
    df["eventtime"] = df.groupby(["event", "time"]).ngroup()
    df["ev_fed"] = df.groupby(["event", "control_fedeventpost"]).ngroup()
    df["ev_oth"] = df.groupby(["event", "control_othereventpost"]).ngroup()
    log(f"stacked clean-control sample: {df.shape}, events={df.event.nunique()}, units={df.unit.nunique()}, EPOP_-1={epop:.4f}")
    return df, epop


def annual(es: pd.DataFrame, tcol: str, bcol: str, secol: str, epop: float) -> pd.DataFrame:
    """Collapse quarterly relative-time coefficients (e = -12..19) to event years
    (tau = floor(e/4), -3..4) by averaging; SE conservatively by averaging variances
    assuming perfect correlation is not available -> use sqrt(mean(se^2)/n) as a
    lower bound and mean(se) as an upper bound; we report mean(se)."""
    e = es[[tcol, bcol, secol]].copy()
    e["tau"] = np.floor(e[tcol] / 4).astype(int)
    g = e.groupby("tau").agg(est=(bcol, "mean"), se=(secol, "mean")).reset_index()
    g["est"] /= epop
    g["se"] /= epop
    return g[(g.tau >= -3) & (g.tau <= 4)]


def stacked_hdfe(df, y, epop):
    x = ["F12treat", "F8treat", "L0treat", "L4treat", "L8treat", "L12treat", "L16treat"]
    r = sp.hdfe_ols(f"{y} ~ {' + '.join(x)} | eventstate + eventtime + ev_fed + ev_oth",
                    data=df, weights="aveoverallpop", cluster="statenum")
    b = pd.Series(r.params); se = pd.Series(r.se)
    tau = {"F12treat": -3, "F8treat": -2, "L0treat": 0, "L4treat": 1, "L8treat": 2, "L12treat": 3, "L16treat": 4}
    out = pd.DataFrame([dict(tau=tau[k], est=b[k] / epop, se=se[k] / epop) for k in x])
    out = pd.concat([out, pd.DataFrame([dict(tau=-1, est=0.0, se=0.0)])]).sort_values("tau")
    post = ["L0treat", "L4treat", "L8treat", "L12treat", "L16treat"]
    V = pd.DataFrame(np.asarray(r.vcov), index=b.index, columns=b.index)
    avg = b[post].mean() / epop
    avg_se = np.sqrt(V.loc[post, post].to_numpy().sum()) / 5 / epop
    return out, avg, avg_se, r


def run_estimator(name, fn):
    t0 = time.time()
    try:
        res = fn()
        log(f"{name}: ok in {time.time() - t0:.0f}s")
        return res, None
    except Exception as ex:   # record API friction precisely
        log(f"{name}: FAILED {type(ex).__name__}: {ex}")
        return None, f"{type(ex).__name__}: {ex}\n{traceback.format_exc(limit=3)}"


def es_table(res):
    mi = getattr(res, "model_info", {}) or {}
    for k in ("event_study", "dynamic", "es"):
        if k in mi and mi[k] is not None:
            return pd.DataFrame(mi[k])
    if hasattr(res, "event_study"):
        return pd.DataFrame(res.event_study)
    det = getattr(res, "detail", None)          # sp.aggte(type="dynamic") stores the event study here
    if isinstance(det, pd.DataFrame) and "relative_time" in det:
        return det
    raise KeyError(f"no event-study table in model_info keys={list(mi)}")


def main():
    df, epop = load()
    summary, errors, paths = [], {}, {}
    for y in ("affected", "below_epop", "above_epop"):
        out, avg, avg_se, _ = stacked_hdfe(df, y, epop)
        out["estimator"] = "stacked hdfe_ols (event FE)"; out["outcome"] = y
        paths[("stacked_hdfe", y)] = out
        summary.append(dict(outcome=y, estimator="stacked hdfe_ols (event-by-state, event-by-time FE)",
                            post_avg=avg, se=avg_se))
        log(f"stacked hdfe {y}: 5-yr avg {avg:.4f} ({avg_se:.4f})")

    y = "affected"
    base = df[["unit", "quarterdate", "g", y, "aveoverallpop", "statenum", "time", "event"]].copy()

    # 2. StatsPAI built-in stacked DID
    res, err = run_estimator("stacked_did", lambda: sp.stacked_did(
        data=base, y=y, group="unit", time="quarterdate", first_treat="g", window=(-12, 19),
        cluster="statenum", never_treated_only=True))
    if res is not None:
        es = es_table(res)
        a = annual(es, "relative_time", "att", "se", epop); a["estimator"] = "sp.stacked_did"
        paths[("stacked_did", y)] = a
        summary.append(dict(outcome=y, estimator="sp.stacked_did", post_avg=float(res.estimate) / epop,
                            se=float(res.se) / epop))
    else:
        errors["stacked_did"] = err

    # 3. Callaway-Sant'Anna
    res, err = run_estimator("callaway_santanna", lambda: sp.callaway_santanna(
        data=base, y=y, g="g", t="quarterdate", i="unit", control_group="nevertreated",
        estimator="reg", allow_unbalanced_panel=True, clustervars="statenum", base_period="universal",
        bstrap=True, biters=199, random_state=42))
    if res is not None:
        try:
            agg = sp.aggte(res, type="dynamic", min_e=-12, max_e=19, n_boot=199, random_state=42) if hasattr(sp, "aggte") else None
            es = es_table(agg if agg is not None else res)
            ecol = "relative_time" if "relative_time" in es else es.columns[0]
            bcol = "att" if "att" in es else es.columns[1]
            secol = "se" if "se" in es else es.columns[2]
            a = annual(es, ecol, bcol, secol, epop); a["estimator"] = "sp.callaway_santanna"
            paths[("cs", y)] = a
            post = es[(es[ecol] >= 0) & (es[ecol] <= 19)]
            summary.append(dict(outcome=y, estimator="sp.callaway_santanna (dynamic, e=0..19 mean)",
                                post_avg=post[bcol].mean() / epop, se=post[secol].mean() / epop))
        except Exception as ex:
            errors["callaway_santanna_aggte"] = f"{type(ex).__name__}: {ex}\n{traceback.format_exc(limit=3)}"
            summary.append(dict(outcome=y, estimator="sp.callaway_santanna (overall ATT)",
                                post_avg=float(res.estimate) / epop, se=float(res.se) / epop))
    else:
        errors["callaway_santanna"] = err

    # 4. Sun-Abraham
    sa, err = run_estimator("sun_abraham", lambda: sp.sun_abraham(
        data=base, y=y, g="g", t="quarterdate", i="unit", event_window=(-12, 19),
        control_group="nevertreated", weights="aveoverallpop", cluster="statenum"))
    if sa is not None:
        try:
            es = es_table(sa)
            ecol = "relative_time" if "relative_time" in es else es.columns[0]
            bcol = "att" if "att" in es else ("estimate" if "estimate" in es else es.columns[1])
            secol = "se" if "se" in es else es.columns[2]
            a = annual(es, ecol, bcol, secol, epop); a["estimator"] = "sp.sun_abraham"
            paths[("sa", y)] = a
            post = es[(es[ecol] >= 0) & (es[ecol] <= 19)]
            summary.append(dict(outcome=y, estimator="sp.sun_abraham (IW, e=0..19 mean)",
                                post_avg=post[bcol].mean() / epop, se=post[secol].mean() / epop))
        except Exception as ex:
            errors["sun_abraham_table"] = f"{type(ex).__name__}: {ex}"
    else:
        errors["sun_abraham"] = err

    # 5. BJS imputation
    res, err = run_estimator("did_imputation", lambda: sp.did_imputation(
        data=base, y=y, group="unit", time="quarterdate", first_treat="g",
        horizon=list(range(0, 20)), pretrends=11, cluster="statenum"))
    if res is not None:
        try:
            es = es_table(res)
            ecol = "relative_time" if "relative_time" in es else es.columns[0]
            bcol = "att" if "att" in es else ("estimate" if "estimate" in es else es.columns[1])
            secol = "se" if "se" in es else es.columns[2]
            a = annual(es, ecol, bcol, secol, epop); a["estimator"] = "sp.did_imputation (BJS)"
            paths[("bjs", y)] = a
        except Exception as ex:
            errors["did_imputation_table"] = f"{type(ex).__name__}: {ex}"
        summary.append(dict(outcome=y, estimator="sp.did_imputation (BJS overall ATT, unweighted)",
                            post_avg=float(res.estimate) / epop, se=float(res.se) / epop))
    else:
        errors["did_imputation"] = err

    # 6. HonestDiD on Sun-Abraham
    if sa is not None:
        hd, err = run_estimator("honest_did", lambda: sp.honest_did(sa, e=0, m_grid=[0, 0.0005, 0.001, 0.002, 0.005],
                                                                    method="smoothness"))
        if hd is not None:
            hd = pd.DataFrame(hd)
            for c in hd.columns:
                if c not in ("M", "m", "method") and np.issubdtype(hd[c].dtype, np.number):
                    hd[c + "_scaled"] = hd[c] / epop
            hd.to_csv(OUT / "ext_honest_did_sunabraham_e0.csv", index=False)
        else:
            errors["honest_did"] = err

    pd.DataFrame(summary).to_csv(OUT / "ext_summary.csv", index=False)
    allp = pd.concat([v.assign(key=f"{k[0]}:{k[1]}") for k, v in paths.items()], ignore_index=True)
    allp.to_csv(OUT / "ext_eventstudy_paths.csv", index=False)
    (OUT / "ext_errors.json").write_text(json.dumps(errors, indent=2))

    fig, ax = plt.subplots(figsize=(7.5, 4.5))
    off = -0.24
    for k, v in paths.items():
        if k[1] != "affected":
            continue
        ax.errorbar(v["tau"] + off, v["est"], yerr=1.96 * v["se"], marker="o", capsize=2, label=k[0])
        off += 0.12
    ax.axhline(0, color="grey", lw=.6); ax.axvline(-0.5, color="k", ls="--", lw=.6)
    ax.set_xlabel("Years relative to minimum wage increase")
    ax.set_ylabel("Δ(missing + excess jobs) / EPOP$_{-1}$")
    ax.set_title("Bunching employment change: stacked TWFE vs modern DID estimators (extension)", fontsize=9)
    ax.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(OUT / "ext_eventstudy_compare.png", dpi=160)
    log("done")


if __name__ == "__main__":
    main()
