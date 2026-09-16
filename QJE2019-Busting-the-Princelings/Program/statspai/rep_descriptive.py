"""Descriptive exhibits produced by the package: Table VII (do-file "Table 3B"), Figure IV, Figure VII.
(Table III is in rep_price.py.)  Pure pandas/matplotlib — no estimator involved."""
from __future__ import annotations

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from common import OUT, load

# Paper Table VII: (N, mean, sd) for ps==1 / ps==0; turnover categories as (count, share)
P7 = {
    ("province_panel", 1): dict(turnover=[(3, 35), (2, 328), (1, 35), (0, 5)], N=403,
        princeling=(399, .596, .491), discount=(403, .685, .686), lnarea=(401, .904, 1.286), ties=(395, .686, .465),
        gdpgrowth=(403, .137, .064), lngdppc=(403, 7.936, .664), lnpop=(403, 8.085, .857), revgrowth=(390, .172, .102),
        age=(403, 59.859, 4.258), age2=(403, 3601.129, 495.371), eduyear=(403, 17.938, 1.918)),
    ("province_panel", 0): dict(turnover=[(3, 42), (2, 324), (1, 33), (0, 4)], N=403,
        princeling=(399, .654, .476), discount=(403, .617, .576), lnarea=(401, .895, 1.285), ties=(403, .591, .492),
        gdpgrowth=(403, .137, .064), lngdppc=(403, 7.936, .664), lnpop=(403, 8.085, .857), revgrowth=(390, .175, .103),
        age=(403, 58.134, 3.864), age2=(403, 3394.457, 439.508), eduyear=(403, 18.007, 1.818)),
    ("prefecture_panel", 1): dict(turnover=[(3, 209), (2, 2836), (1, 177), (0, 15)], N=3237,
        princeling=(3663, .497, .500), discount=(3597, 3.232, 5.322), lnarea=(3657, 1.704, 1.468), ties=(3663, .616, .486),
        gdpgrowth=(3511, .151, .076), lngdppc=(3556, 9.968, .840), lnpop=(3656, 5.641, .850), revgrowth=(3090, .150, .105),
        age=(3564, 53.049, 3.621), age2=(3564, 2827.256, 381.029), eduyear=(3582, 17.555, 2.156)),
    ("prefecture_panel", 0): dict(turnover=[(3, 204), (2, 2655), (1, 166), (0, 23)], N=3048,
        princeling=(3663, .480, .500), discount=(3605, 3.224, 5.318), lnarea=(3661, 1.579, 1.287), ties=(3663, .616, .486),
        gdpgrowth=(3511, .151, .076), lngdppc=(3556, 9.968, .840), lnpop=(3656, 5.641, .850), revgrowth=(3090, .150, .105),
        age=(3577, 51.098, 3.939), age2=(3577, 2626.469, 400.419), eduyear=(3603, 17.279, 2.107)),
}
GROUP = {("province_panel", 1): "Provincial party secretaries", ("province_panel", 0): "Provincial governors",
         ("prefecture_panel", 1): "Municipal party secretaries", ("prefecture_panel", 0): "Municipal mayors"}


def table_vii():
    rows = []
    for (dn, ps), pv in P7.items():
        d = load(dn)
        s = d[d.ps == ps]
        for code, cnt in pv["turnover"]:
            ours = int((s.promote == code).sum())
            rows.append(dict(group=GROUP[(dn, ps)], stat=f"promote=={code} count", paper=cnt, ours=ours,
                             match=ours == cnt))
        for v, (n, m, sd) in ((k, x) for k, x in pv.items() if k not in ("turnover", "N")):
            x = s[v].dropna()
            ok = int(len(x)) == n and abs(x.mean() - m) < 0.0005 + 1e-6 and abs(x.std() - sd) < 0.0005 + 1e-6
            rows.append(dict(group=GROUP[(dn, ps)], stat=v, paper=f"{n} / {m:.3f} / {sd:.3f}",
                             ours=f"{len(x)} / {x.mean():.3f} / {x.std():.3f}", match=ok))
    out = pd.DataFrame(rows)
    out.to_csv(OUT / "table_VII_summary.csv", index=False)
    print(out.to_string())
    print("Table VII cells matching:", int(out.match.sum()), "/", len(out))
    return out


def figure_iv():
    d = load("figure4")
    fig, ax = plt.subplots(figsize=(5.5, 5))
    ax.scatter(d.lnprice, d.lnpricenear500, s=2, color="grey", label="Princeling land price")
    lo, hi = np.nanmin(d.lnprice), np.nanmax(d.lnprice)
    ax.plot([lo, hi], [lo, hi], "k--", lw=0.8, label="45 degree line")
    ax.set_xlabel("Log land price, princeling parcel")
    ax.set_ylabel("Average land price within 500-meter radius")
    ax.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(OUT / "figure_IV.png", dpi=160); plt.close(fig)
    x = d.dropna(subset=["lnprice", "lnpricenear500"]); share_above = float((x.lnpricenear500 > x.lnprice).mean())
    print(f"Figure IV: N={len(d)} (non-missing pairs {len(x)}), share of princeling parcels below neighbours' average = {share_above:.3f}")


def figure_vii():
    d = load("figure7")
    fig, axes = plt.subplots(2, 1, figsize=(8, 8))
    ax = axes[0]
    ax.fill_between(d.no, d.gap.fillna(0), color="grey", label="Price gap")
    ax.plot(d.no, d.princeling_price, color="grey", label="Princelings")
    ax.plot(d.no, d.near_price, color="black", label="Non-princelings (matched, 500m)")
    ax.axvline(62, color="black"); ax.set_title("Panel A: Average land prices / gap"); ax.legend(fontsize=7)
    ax = axes[1]
    ax.fill_between(d.no, d.near_area.fillna(0), color="grey", label="Non-princelings (matched, 500m)")
    ax.fill_between(d.no, d.princeling_area.fillna(0), color="black", label="Princelings")
    ax.axvline(62, color="black"); ax.set_title("Panel B: Quantity of land purchased"); ax.legend(fontsize=7)
    ticks = list(range(1, 124, 10))
    for ax in axes:
        ax.set_xticks(ticks); ax.set_xticklabels([str(int(d.date[d.no == t].iloc[0])) for t in ticks], rotation=45, fontsize=7)
    fig.tight_layout(); fig.savefig(OUT / "figure_VII.png", dpi=160); plt.close(fig)
    pre, post = d[d.no < 62], d[d.no >= 62]
    print(f"Figure VII: mean gap before day 62 = {pre.gap.mean():.1f}, after = {post.gap.mean():.1f}")


if __name__ == "__main__":
    table_vii()
    figure_iv()
    figure_vii()
