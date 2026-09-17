"""Plot Figure 3 (event-time missing/excess jobs) from Results/statspai/figure3_eventtime.csv and
overlay the author's shipped-estimate values (Results/statspai/author_ster_figures.csv, produced
from Materials/author_outputs/estimates/*.ster with lincom) for Figures 2 and 3.

Run: /usr/local/bin/python3.13 Program/statspai/make_figures.py
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

from bunching import OUT

f3 = pd.read_csv(OUT / "figure3_eventtime.csv")
fig, ax = plt.subplots(figsize=(7, 4.5))
for side, col in (("excess", "#3182bd"), ("missing", "#de2d26")):
    d = f3[f3.side == side].sort_values("tau")
    ax.plot(d.tau, d.est, color=col, lw=2.5, label=f"{side} jobs (StatsPAI)")
    ax.errorbar(d.tau, d.est, yerr=1.96 * d.se, fmt="none", ecolor=col, capsize=3, lw=2)
auth = OUT / "author_ster_figures.csv"
if auth.exists():
    a = pd.read_csv(auth)
    a = a[a.figure == 3].copy()
    a[["side", "tau"]] = a.key.str.split("_", expand=True)
    a["tau"] = a.tau.astype(int)
    for side, mk in (("excess", "x"), ("missing", "+")):
        d = a[a.side == side]
        ax.scatter(d.tau, d.est, marker=mk, color="k", zorder=5, label=f"{side} (author .ster)")
ax.axhline(0, color="grey", lw=.5)
ax.axvline(0, color="k", ls="--", lw=.8)
ax.set_xlabel("Years relative to the minimum wage change")
ax.set_ylabel("Excess and missing jobs relative to\npre-treatment total employment")
ax.set_ylim(-0.04, 0.04)
ax.legend(fontsize=8)
ax.set_title("StatsPAI replication of Figure 3", fontsize=10)
fig.tight_layout()
fig.savefig(OUT / "figure3_eventtime.png", dpi=160)
print("saved figure3_eventtime.png")

# Figure 4: first-year bin profile, new entrants vs incumbents
f4p = OUT / "figure4_bins.csv"
if f4p.exists():
    f4 = pd.read_csv(f4p)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2), sharey=True)
    for ax, (g, col, lab) in zip(axes, [("newentrant", "#9ecae1", "(a) New entrants"), ("incumbent", "#a1d99b", "(b) Incumbents")]):
        d = f4[f4.group == g].sort_values("bin")
        ax.bar(d.bin, d.est, color=col)
        ax.errorbar(d.bin, d.est, yerr=1.96 * d.se, fmt="none", ecolor="#3182bd", lw=1.5)
        ax.plot(d.bin, d.est.cumsum(), color="#636363", lw=2)
        ax.axhline(0, color="grey", lw=.5)
        da, db = d[(d.bin >= 0) & (d.bin <= 4)].est.sum(), d[d.bin < 0].est.sum()
        ax.set_title(f"{lab}: Δa={da:.3f}, Δb={db:.3f}", fontsize=9)
        ax.set_xticks([-4, -2, 0, 2, 4, 6, 8, 10, 12, 14, 16, 17])
        ax.set_xticklabels(["-4", "-2", "0", "2", "4", "6", "8", "10", "12", "14", "16", "17+"])
        ax.set_xlabel("Wage bins in $ relative to new MW")
    axes[0].set_ylabel("Change in employment (first year)\n/ pre-treatment total employment")
    fig.tight_layout()
    fig.savefig(OUT / "figure4_bins.png", dpi=160)
    print("saved figure4_bins.png")
