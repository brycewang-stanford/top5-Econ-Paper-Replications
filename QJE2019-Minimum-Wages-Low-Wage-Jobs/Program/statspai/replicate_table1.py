"""StatsPAI replication of Table 1 cols (1)-(6), Figure 3 (event-time path) and
Table 4 row "Overall" (wage effect with / without spillovers).

Cengiz, Dube, Lindner & Zipperer (QJE 2019). Mirrors Table1_for_QJE.do and
wage_estimate_base.do.

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_table1.py [--specs 1,4,10,5,6,11] [--reuse]
  --reuse : skip regressions whose coefficient files already exist in Results/statspai/estimates/

Outputs (Results/statspai/):
  table1_cols1_6.csv, figure3_eventtime.csv, table4_overall.csv, constants_overall.json
"""
from __future__ import annotations

import argparse
import json

import numpy as np
import pandas as pd

from bunching import (EST, OUT, Panel, TREAT_AFTER, TREAT_BEFORE, WINDOW, add_rsums,
                      bunching_stats, constants, eventtime_path, fit, load_fit, log,
                      qcew_overall, read_main)

SPEC_LABEL = {1: "TWFE", 4: "ST", 10: "STQ", 5: "DP", 6: "ST_DP", 11: "STQ_DP"}
PUBLISHED_COL = {1: 1, 4: 2, 10: 3, 5: 4, 6: 5, 11: 6}


def prepare() -> tuple[pd.DataFrame, Panel, dict]:
    df = read_main()
    q = qcew_overall()
    df = df.merge(q, on=["statenum", "quarterdate"], how="left", validate="m:1")
    assert df["emp"].notna().all(), "QCEW merge should be assert(3)"
    m = df["emp"].to_numpy() != 0
    cnt = df["count"].to_numpy(dtype=float).copy()
    cnt[m] = cnt[m] * df["emp"].to_numpy()[m] / df["countall"].to_numpy()[m]
    df["count"] = cnt
    df["overallcountpc"] = df["count"] / df["population"]
    pcall = df["overallcountpcall"].to_numpy(dtype=float).copy()
    pcall[m] = df["emp"].to_numpy()[m] / df["population"].to_numpy()[m]
    df["overallcountpcall"] = pcall
    df = df.sort_values(["statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    add_rsums(df, "overall", "count", "population", "overallcountpc")
    P = Panel(df)
    K = constants(df, P, "overall", "wtoverall1979", "overallcountpcall")
    log("constants: " + json.dumps(K))
    (OUT / "constants_overall.json").write_text(json.dumps(K, indent=2))
    return df, P, K


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--specs", default="1,4,10,5,6,11")
    ap.add_argument("--reuse", action="store_true")
    a = ap.parse_args()
    specs = [int(s) for s in a.specs.split(",")]

    df, P, K = prepare()
    d = df[(df["year"] >= 1979) & (df["cleansample"] == 1)]
    rows = []
    csv = OUT / "table1_cols1_6.csv"
    for s in specs:
        tag = f"table1_spec{s}"
        if a.reuse and (EST / f"{tag}_b.csv").exists():
            params, V, N = load_fit(tag)
            log(f"reused {tag}")
        else:
            params, V, N = fit(d, "overallcountpc", TREAT_AFTER, TREAT_BEFORE + WINDOW,
                               "wtoverall1979", spec=s, tag=tag)
        st = bunching_stats(params, V, K, with_alt=(s == 1))
        row = dict(col=PUBLISHED_COL[s], spec=s, label=SPEC_LABEL[s], N=N,
                   b_minus1=K["B"], mwpc=K["mwpc"], n_events=K["n_events"], **st)
        rows.append(row)
        log(f"spec {s}: " + ", ".join(f"{k}={row[k]:.4f}" for k in
                                       ["below", "above", "wage", "emp", "elas_mw", "elas_wage"]))
        out = pd.DataFrame(rows).sort_values("col")
        out.to_csv(csv, index=False)
        if s == 1:
            eventtime_path(params, V, K).to_csv(OUT / "figure3_eventtime.csv", index=False)
            pd.DataFrame([dict(group="overall", wage=st["wage"], wage_se=st["wage_se"],
                               wage_nospill=st["wage_nospill"], wage_nospill_se=st["wage_nospill_se"],
                               spill_share=st["spill_share"], spill_share_se=st["spill_share_se"])]) \
                .to_csv(OUT / "table4_overall.csv", index=False)
    log("done")


if __name__ == "__main__":
    main()
