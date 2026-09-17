"""Tables VIII, IX, XII (do-file Tables 7, 8, 11): promotion of provincial / municipal leaders.

Stata original:
    xi: oprobit promote X controls i.year i.provid if year>=2004 & ps==1      (default OIM SEs)
    xi: reg promote1 X controls i.year i.provid if year>=2004 & ps==1          (classical SEs)
StatsPAI:
    sp.oprobit(data, y, x=[X, controls, year & unit dummies])  -- dummies built by hand and
        collinear columns dropped greedily (Stata -xi- omits them silently; sp.oprobit's
        formula interface does not accept C() terms)
    sp.feols("promote1 ~ X + controls | year + unit", vcov="iid")  -- identical to -reg- with dummies
"""
from __future__ import annotations

import sys

import statspai as sp

from common import dummies, drop_collinear, extract, load, save_rows, tic

CTRL = ["ties", "gdpgrowth", "lngdppc", "lnpop", "revgrowth", "age", "age2", "eduyear"]
CTRL_NOTIES = ["gdpgrowth", "lngdppc", "lnpop", "revgrowth", "age", "age2", "eduyear"]
MAXITER = 1000
REPORT = ["princeling", "discount", "lnarea", "ties", "gdpgrowth", "revgrowth",
          "pp1", "pp2", "pd1", "pd2", "alp1", "alp2"]


def oprobit(df, y, xs, unit, table, col):
    need = [y] + xs + ["year", unit]
    s = df.dropna(subset=need).copy()
    D = dummies(s, ["year", unit])
    X = s[xs].astype(float).join(D)
    keep = drop_collinear(X, keep_first=xs)
    # sp.oprobit = BFGS on finite-difference gradients, default maxiter=100; with unscaled
    # regressors (age2 ~ 3,500, lngdppc ~ 8) it stops early (3rd-decimal drift vs Stata).
    # Standardise the substantive regressors, then back-transform b and se (exact).
    XX = X[keep].copy()
    sd = {c: float(XX[c].std()) for c in xs if c in keep and XX[c].std() > 0}
    for c, v in sd.items():
        XX[c] = XX[c] / v
    t0 = tic()
    r = sp.oprobit(data=s[[y]].join(XX), y=y, x=keep, maxiter=MAXITER)
    for c, v in sd.items():
        r.params[c] = r.params[c] / v
        r.std_errors[c] = r.std_errors[c] / v
    rows = extract(r, REPORT, table, col, n=len(s), spec=f"oprobit {y} ~ {' '.join(xs)} + i.year i.{unit} (scaled, maxiter={MAXITER})")
    for rw in rows:
        rw["loglik"] = r.model_info.get("log_likelihood")
        rw["sp_converged_flag"] = r.model_info.get("converged")
        rw["seconds"] = round(tic() - t0, 1)
    print(f"  {table} col{col}: oprobit N={len(s)} k={len(keep)}  {tic() - t0:.1f}s", flush=True)
    return rows


def lpm(df, y, xs, unit, table, col):
    need = [y] + xs + ["year", unit]
    s = df.dropna(subset=need).copy()
    r = sp.feols(f"{y} ~ {' + '.join(xs)} | year + {unit}", data=s, vcov="iid")
    k = len(xs)
    df_fe = s["year"].nunique() + s[unit].nunique() - 1
    rows = extract(r, REPORT, table, col, n=len(s), k=k, df_fe=df_fe,
                   spec=f"feols {y} ~ {' + '.join(xs)} | year + {unit}, iid")
    print(f"  {table} col{col}: LPM N={len(s)}")
    return rows


def _data(data_name, ps):
    d = load(data_name)
    return d[(d["year"] >= 2004) & (d["ps"] == ps)]


def _run(job):
    kind, data_name, ps, y, xs, unit, table, col = job
    import json
    from common import OUT
    s = _data(data_name, ps)
    rows = (oprobit if kind == "oprobit" else lpm)(s, y, xs, unit, table, col)
    # incremental checkpoint: one JSON line per finished model (survives interruption)
    with open(OUT / f"table_{table}_partial.jsonl", "a") as f:
        for r in rows:
            f.write(json.dumps(r, default=str) + "\n")
    return rows


def promotion_jobs(data_name, unit, table):
    jobs = []
    for ps, off in [(1, 0), (0, 5)]:
        jobs += [("oprobit", data_name, ps, "promote", ["princeling"], unit, table, off + 1),
                 ("oprobit", data_name, ps, "promote", ["princeling"] + CTRL, unit, table, off + 2),
                 ("lpm", data_name, ps, "promote1", ["princeling"] + CTRL, unit, table, off + 3),
                 ("oprobit", data_name, ps, "promote", ["discount"] + CTRL, unit, table, off + 4),
                 ("oprobit", data_name, ps, "promote", ["lnarea"] + CTRL, unit, table, off + 5)]
    return jobs


def xii_jobs():
    jobs = []
    col = 0
    for main, i1, i2 in [("princeling", "pp1", "pp2"), ("discount", "pd1", "pd2"), ("lnarea", "alp1", "alp2")]:
        for data_name, unit in [("province_panel", "provid"), ("prefecture_panel", "prefid")]:
            for inter, post in [(i1, "post2012"), (i2, "inspection")]:
                col += 1
                # do-file quirks reproduced: column 11 (prefecture, lnarea x post2012) omits ties;
                # columns 10 and 12 (alp2 = area x inspection) enter post2012, not inspection, as main effect
                ctrl = CTRL_NOTIES if col == 11 else CTRL
                main_eff = "post2012" if col in (10, 12) else post
                jobs.append(("oprobit", data_name, 1, "promote", [main, main_eff, inter] + ctrl, unit, "XII", col))
    return jobs


def main(which=("VIII", "IX", "XII"), workers=3):
    """sp.oprobit is single-threaded and slow with ~300 prefecture dummies (20-50 min per model),
    so models run in a process pool."""
    import pandas as pd
    from multiprocessing import Pool
    from common import OUT
    for tab in which:
        print(f"Table {tab}", flush=True)
        jobs = {"VIII": lambda: promotion_jobs("province_panel", "provid", "VIII"),
                "IX": lambda: promotion_jobs("prefecture_panel", "prefid", "IX"),
                "XII": xii_jobs}[tab]()
        # longest (prefecture) jobs first
        jobs.sort(key=lambda j: j[1] != "prefecture_panel")
        with Pool(workers) as pool:
            rows = [r for part in pool.imap_unordered(_run, jobs) for r in part]
        save_rows(sorted(rows, key=lambda r: (r["col"], r["var"])), f"table_{tab}")
    parts = [pd.read_csv(OUT / f"table_{t}.csv") for t in ("VIII", "IX", "XII") if (OUT / f"table_{t}.csv").exists()]
    return save_rows(pd.concat(parts).to_dict("records"), "tables_promotion")


if __name__ == "__main__":
    main(tuple(sys.argv[1:]) or ("VIII", "IX", "XII"))
