"""StatsPAI replication of the data figures (Figures 3-8; package/NBER numbering) of
Bai, Jia & Yang (2023, QJE).  Published QJE numbering is one higher (Figure 3 here = QJE Figure IV, ...).

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_figures.py
Output: Results/statspai/figure*.png, figure*_estimates.csv, figures_check.csv
"""
from __future__ import annotations

import time

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from common import AUTHOR, HUNAN_CTRL, NAT_CTRL, NAT_CTRL_FIG6, OUT, hunan, national, ols, read  # noqa: E402

T0 = time.time()
CHECK = []


def check(fig, what, ours, ref):
    ours, ref = np.asarray(ours, float), np.asarray(ref, float)
    CHECK.append(dict(figure=fig, quantity=what, n=len(ours), max_abs_diff=float(np.nanmax(np.abs(ours - ref)))))


# ============================================================================ Figure 3
def figure3():
    h = hunan()
    h["connect"] = (h.Zeng_all0_invdist > 0).astype(int)
    m = h.pivot_table(index="year", columns="connect", values="martyr", aggfunc="mean")
    ref = pd.read_csv(AUTHOR / "Figure_3.txt", sep="\t", skiprows=3, header=None, nrows=15)
    check("Figure 3", "mean soldier deaths by year x connected (30 cells)", m[[0, 1]].to_numpy().ravel(),
          ref[[1, 2]].to_numpy().ravel())
    m.to_csv(OUT / "figure3_means.csv")
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.plot(m.index, m[1], "o-", color="0.35", label="Connected")
    ax.plot(m.index, m[0], "o--", mfc="white", color="0.35", label="Unconnected")
    ax.axvline(1853, color="blue")
    ax.set_title("Number of soldier deaths: connected & unconnected counties in Hunan")
    ax.legend()
    fig.savefig(OUT / "figure3.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


# ============================================================================ Figure 4
def figure4():
    h = hunan()
    yrs = [y for y in range(1850, 1865) if y != 1853]
    panels = [("Zeng_all0_invdist", "A. Weighted connections", "Placebo_Yearly_ctrl_all0_invdist"),
              ("Zeng_all0", "B. Unweighted connections", "Placebo_Yearly_ctrl_all0"),
              ("Zeng_all0_invdist_pc", "C. Weighted connections per capita", "Placebo_Yearly_ctrl_all0_invdist_pc"),
              ("Zeng_all0_pc", "D. Unweighted connections per capita", "Placebo_Yearly_ctrl_all0_pc")]
    fig, axes = plt.subplots(2, 2, figsize=(10, 11))
    est = []
    for (v, title, ref), ax in zip(panels, axes.ravel()):
        names = [f"{v}_yr{y}" for y in yrs]
        for y, nm in zip(yrs, names):
            h[nm] = h[v] * (h.year == y)
        rows, r = ols("lnmartyr1", names + HUNAN_CTRL, ["year", "cntyid", "prefidXyear"], h, "cntyid", keep=names)
        e = pd.DataFrame(rows)
        e["year"] = yrs
        e["panel"] = title
        # parmest min95/max95 use t(df = G-1)
        from scipy import stats
        tcrit = stats.t.ppf(0.975, h.cntyid.nunique() - 1)
        e["min95"], e["max95"] = e.coef - tcrit * e.se, e.coef + tcrit * e.se
        a = pd.read_stata(AUTHOR / f"{ref}.dta").iloc[:14]
        check("Figure 4", f"{title}: 14 coefs", e.coef, a.estimate)
        check("Figure 4", f"{title}: 14 SEs", e.se, a.stderr)
        est.append(e)
        p = pd.concat([e, pd.DataFrame(dict(year=[1853], coef=[0.0], min95=[0.0], max95=[0.0]))]).sort_values("year")
        ax.vlines(p.year, p.min95, p.max95, color="0.5")
        ax.plot(p.year, p.coef, "o-", color="black")
        ax.axhline(0, color="red")
        ax.axvline(1853, color="blue")
        ax.set_title(title)
    fig.savefig(OUT / "figure4.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    pd.concat(est).to_csv(OUT / "figure4_estimates.csv", index=False)
    return est[0]


# ============================================================================ Figure 5
def figure5():
    n = national(keep1820=True)
    n["connect"] = (n.Zenghu_all_invdist > 0).astype(int)
    n["grp"] = np.select([(n.hunan == 1) & (n.connect == 1), (n.hunan == 0) & (n.connect == 1),
                          (n.hunan == 1) & (n.connect == 0)], [4, 3, 2], 1)
    m = n.pivot_table(index="year", columns="grp", values="alloff", aggfunc="mean")
    ref = pd.read_csv(AUTHOR / "Official_HunanXconn_1800_1910.txt", sep="\t", skiprows=3, header=None, nrows=91)
    check("Figure 5", "mean national offices by year x 4 groups (364 cells)", m[[1, 2, 3, 4]].to_numpy().ravel(),
          ref[[1, 2, 3, 4]].to_numpy().ravel())
    m.to_csv(OUT / "figure5_means.csv")
    fig, ax = plt.subplots(figsize=(8, 6))
    lab = {4: "Connected, Hunan", 3: "Connected, non-Hunan", 2: "Unconnected, Hunan", 1: "Unconnected, non-Hunan"}
    sty = {4: "o-", 3: "o--", 2: "-", 1: "--"}
    for g in [4, 3, 2, 1]:
        ax.plot(m.index, m[g], sty[g], ms=3, color="0.35", label=lab[g])
    for x, ls in [(1850, "--"), (1853, "-"), (1864, "--")]:
        ax.axvline(x, color="blue", ls=ls)
    ax.set_ylabel("Number of national offices")
    ax.legend()
    fig.savefig(OUT / "figure5.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


# ============================================================================ Figure 6
def figure6():
    n = national(keep1820=False)  # Figure_6.do does NOT restrict to 1820+: all 1800-1910, base years 1800-1820
    years = list(range(1821, 1911))
    for y in years:
        dy = (n.year == y).astype(float)
        n[f"h_{y}"] = n.hXZeng_all0_invdist * dy
        n[f"nh_{y}"] = n.nhXZeng_all0_invdist * dy
        n[f"z_{y}"] = n.Zeng_all0_invdist * dy
        n[f"hun_{y}"] = n.hunan * dy
    H, NH, Z, HU = ([f"{p}_{y}" for y in years] for p in ["h", "nh", "z", "hun"])
    fe = ["year", "samcntyid"]
    from scipy import stats
    tcrit = stats.t.ppf(0.975, n.prefid.nunique() - 1)
    out = {}
    for spec, xs, ref in [("01", H + NH + HU, "ConnectionOnSenior_all0_yearly_01"),
                          ("02", H + Z + HU, "ConnectionOnSenior_all0_yearly_02")]:
        rows, r = ols("alloff", xs + NAT_CTRL_FIG6, fe, n, "prefid", keep=xs[:180])
        e = pd.DataFrame(rows)
        a = pd.read_stata(AUTHOR / f"{ref}.dta").iloc[:180]
        check("Figure 6", f"spec {spec}: 180 yearly coefs", e.coef, a.estimate)
        check("Figure 6", f"spec {spec}: 180 yearly SEs", e.se, a.stderr)
        e["year"] = years * 2
        e["min95"], e["max95"] = e.coef - tcrit * e.se, e.coef + tcrit * e.se
        out[spec] = e
    est = pd.concat([out["01"].iloc[:90].assign(panel="A. Hunan"), out["01"].iloc[90:180].assign(panel="B. Non-Hunan"),
                     out["02"].iloc[:90].assign(panel="C. Difference Hunan - non-Hunan")])
    est.to_csv(OUT / "figure6_estimates.csv", index=False)
    fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)
    for (p, g), ax in zip(est.groupby("panel", sort=False), axes):
        g = pd.concat([pd.DataFrame(dict(year=[1820], coef=[0.0], min95=[0.0], max95=[0.0])), g])
        ax.fill_between(g.year, g.min95, g.max95, color="0.85")
        ax.plot(g.year, g.coef, "o-", ms=2, color="0.45")
        ax.axhline(0, ls="--", color="black")
        for x, ls in [(1850, "--"), (1853, "-"), (1864, "--")]:
            ax.axvline(x, color="blue", ls=ls)
        ax.set_ylim(-0.2, 0.45)
        ax.set_title(p)
    fig.savefig(OUT / "figure6.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    return est


# ============================================================================ Figure 7 (EG index)
def eg_index():
    e = read("EG_Index")
    e["hunan"] = (e.provcd == 11).astype(int)
    e["alloff_NoConn"] = np.where(e.hunan == 1, e.alloff - e.estimate * e.Zeng_all0_invdist, e.alloff)
    p = e.groupby(["provcd", "year"], as_index=False)[["alloff", "alloff_NoConn", "labor"]].sum()
    p["x"] = p.labor / p.groupby("year").labor.transform("sum")
    p["sigmax2"] = (p.x ** 2).groupby(p.year).transform("sum")
    for y in ["alloff", "alloff_NoConn"]:
        t = p.groupby("year")[y].transform("sum")
        s = p[y] / t
        H = 1 / t
        G = ((s - p.x) ** 2).groupby(p.year).transform("sum")
        p[f"gama{y}"] = (G - (1 - p.sigmax2) * H) / ((1 - p.sigmax2) * (1 - H))
    g = p[p.provcd == 10][["year", "gamaalloff", "gamaalloff_NoConn"]].reset_index(drop=True)
    g["hXconnRole"] = g.gamaalloff - g.gamaalloff_NoConn
    return g


def figure7():
    g = eg_index()
    g.to_csv(OUT / "figure7_eg_index.csv", index=False)
    dec = g.assign(dec=(g.year // 10).astype(int)).groupby("dec")[["gamaalloff", "gamaalloff_NoConn"]].mean()
    dec.to_csv(OUT / "tableC7_eg_by_decade.csv")
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    axes[0].scatter(g.year, g.gamaalloff, color="0.3", label="Real")
    axes[0].scatter(g.year, g.gamaalloff_NoConn, facecolors="none", edgecolors="blue",
                    label="Counterfactual: net the effect of Hunan*connections")
    axes[0].set_title("A. EG index")
    axes[0].legend()
    axes[1].scatter(g.year, g.hXconnRole, facecolors="none", edgecolors="black")
    axes[1].set_title("B. The role of Hunan*connections")
    fig.savefig(OUT / "figure7.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    return dec


# ============================================================================ Figure 8
def figure8():
    p = read("ProvGovernors")
    for a in ["2053", "5464", "6599"]:
        p[f"RatioWar{a}"] = p[f"mobbased{a}"] / p[f"num{a}"]
    p.to_csv(OUT / "figure8_ratios.csv", index=False)
    q = p[p.provinceid != 6]
    fig, axes = plt.subplots(1, 3, figsize=(18, 6))
    for ax, (x, y, t) in zip(axes[:2], [("RatioWar2053", "RatioWar5464", "A. 1820-53 vs 1854-64"),
                                         ("RatioWar5464", "RatioWar6599", "B. 1854-64 vs 1865-99")]):
        ax.scatter(q[x], q[y], facecolors="none", edgecolors="blue")
        for _, r in q.iterrows():
            ax.annotate(r.prov_en, (r[x], r[y]), fontsize=8)
        ax.set_xlim(-0.01, 0.31), ax.set_ylim(-0.01, 0.31), ax.set_title(t)
    b = np.polyfit(q.RatioWar5464, q.Yangtze, 1)
    axes[2].scatter(p.RatioWar5464, p.Yangtze, facecolors="none", edgecolors="blue")
    xs = np.linspace(q.RatioWar5464.min(), q.RatioWar5464.max(), 50)
    axes[2].plot(xs, np.polyval(b, xs), color="black")
    axes[2].set_title(f"C. Prob. of disobeying the state (slope {b[0]:.2f})")
    fig.savefig(OUT / "figure8.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    figure3(); print("F3", round(time.time() - T0, 1))
    figure4(); print("F4", round(time.time() - T0, 1))
    figure5(); print("F5", round(time.time() - T0, 1))
    figure6(); print("F6", round(time.time() - T0, 1))
    print(figure7()); print("F7", round(time.time() - T0, 1))
    figure8(); print("F8", round(time.time() - T0, 1))
    c = pd.DataFrame(CHECK)
    c.to_csv(OUT / "figures_check.csv", index=False)
    print(c.to_string())
