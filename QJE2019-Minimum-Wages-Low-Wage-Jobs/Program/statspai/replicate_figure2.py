"""StatsPAI replication of Figure 2 (employment change by $1 wage bin relative to the
new MW, -4 ... 17+), mirroring Figure2_for_QJE.do.

Figure2_for_QJE.do runs three reghdfe regressions (true bins -4..4, placebo bins
5..13, placebo bins 14..17+), each time absorbing the other blocks as linear
controls. By Frisch-Waugh-Lovell this is numerically identical to ONE regression
with all blocks as regressors (same residual-maker, same absorbed dof), so we run
one sp.hdfe_ols and read the three coefficient blocks from it.

Run: /usr/local/bin/python3.13 Program/statspai/replicate_figure2.py
Outputs: Results/statspai/figure2_bins.csv, figure2_bins.png
"""
from __future__ import annotations

import json

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from bunching import (OUT, Panel, T_AFTER, TREAT_AFTER, TREAT_BEFORE, WINDOW, add_placebo_bins,
                      bin_profile, constants, fit, log, notmiss, qcew_multiplier, read_main,
                      s_gt, s_ne, tname, wmean, add_rsums)

KMAX = 16   # placebo2wmax; open bin = 17


def main():
    df = read_main()
    df = df.merge(qcew_multiplier(), on=["statenum", "quarterdate"], how="left", validate="m:1")
    assert df["multiplier"].notna().all()
    df["count"] = df["count"] * df["multiplier"]
    df["overallcountpc"] = df["overallcountpc"] * df["multiplier"]
    df["overallcountpcall"] = df["overallcountpcall"] * df["multiplier"]
    df = df.sort_values(["statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    P = Panel(df)
    add_placebo_bins(df, P, kmax=KMAX)
    add_rsums(df, "overall", "count", "population", "overallcountpc")
    K = constants(df, P, "overall", "wtoverall1979", "overallcountpcall")
    w = df["wtoverall1979"].to_numpy()
    numbins = wmean(df["sum_inf"], w, s_gt(df["overallcountgroup"], 0) & notmiss(df["overallcountgroup"])
                    & s_ne(df["fedincrease"], 1))
    K["numbins_open"] = numbins
    log("constants: " + json.dumps(K))

    pbins = [f"p{k}" for k in range(5, KMAX + 2)]
    x_after = TREAT_AFTER + [tname(t, b) for t in T_AFTER for b in pbins]
    lin = TREAT_BEFORE + WINDOW + [tname(t, b, True) for t in (12, 8) for b in pbins] \
        + [f"window_p{k}" for k in range(5, KMAX + 2)]
    d = df[(df["year"] >= 1979) & (df["cleansample"] == 1)]
    params, V, N = fit(d, "overallcountpc", x_after, lin, "wtoverall1979", spec=1, tag="figure2_joint")
    prof = bin_profile(params, V, K, kmax=KMAX, numbins=numbins)
    prof.to_csv(OUT / "figure2_bins.csv", index=False)

    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.bar(prof["bin"], prof["est"], color="#9ecae1", width=0.8)
    ax.errorbar(prof["bin"], prof["est"], yerr=1.96 * prof["se"], fmt="none", ecolor="#3182bd", lw=2)
    ax.plot(prof["bin"], prof["running_sum"], color="#e6550d", lw=2.5, alpha=.6)
    ax.axhline(0, color="grey", lw=.5)
    ax.set_xticks([-4, -2, 0, 2, 4, 6, 8, 10, 12, 14, 17])
    ax.set_xticklabels(["-4", "-2", "0", "2", "4", "6", "8", "10", "12", "14", "17+"])
    ax.set_xlabel("Wage bins in $ relative to new MW")
    ax.set_ylabel("Difference between actual and counterfactual\nemployment count / pre-treatment employment")
    below = prof.loc[prof.bin < 0, "est"].sum()
    above = prof.loc[(prof.bin >= 0) & (prof.bin <= 4), "est"].sum()
    ax.set_title(f"StatsPAI replication of Figure 2  (Δb={below:.3f}, Δa={above:.3f})", fontsize=10)
    fig.tight_layout()
    fig.savefig(OUT / "figure2_bins.png", dpi=160)
    log("done")


if __name__ == "__main__":
    main()
