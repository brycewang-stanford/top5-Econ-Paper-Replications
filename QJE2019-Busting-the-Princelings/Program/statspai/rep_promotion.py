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
REPORT = ["princeling", "discount", "lnarea", "ties", "gdpgrowth", "revgrowth",
          "pp1", "pp2", "pd1", "pd2", "alp1", "alp2"]


def oprobit(df, y, xs, unit, table, col):
    need = [y] + xs + ["year", unit]
    s = df.dropna(subset=need).copy()
    D = dummies(s, ["year", unit])
    X = s[xs].astype(float).join(D)
    keep = drop_collinear(X, keep_first=xs)
    t0 = tic()
    r = sp.oprobit(data=s[[y]].join(X[keep]), y=y, x=keep)
    rows = extract(r, REPORT, table, col, n=len(s), spec=f"oprobit {y} ~ {' '.join(xs)} + i.year i.{unit}")
    print(f"  {table} col{col}: oprobit N={len(s)} k={len(keep)}  {tic() - t0:.1f}s")
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


def promotion_table(data_name, unit, table):
    d = load(data_name)
    d = d[d["year"] >= 2004]
    rows = []
    for ps, off in [(1, 0), (0, 5)]:
        s = d[d["ps"] == ps]
        rows += oprobit(s, "promote", ["princeling"], unit, table, off + 1)
        rows += oprobit(s, "promote", ["princeling"] + CTRL, unit, table, off + 2)
        rows += lpm(s, "promote1", ["princeling"] + CTRL, unit, table, off + 3)
        rows += oprobit(s, "promote", ["discount"] + CTRL, unit, table, off + 4)
        rows += oprobit(s, "promote", ["lnarea"] + CTRL, unit, table, off + 5)
    return rows


def table_xii():
    prov = load("province_panel"); prov = prov[(prov.year >= 2004) & (prov.ps == 1)]
    pref = load("prefecture_panel"); pref = pref[(pref.year >= 2004) & (pref.ps == 1)]
    rows = []
    col = 0
    for main, i1, i2 in [("princeling", "pp1", "pp2"), ("discount", "pd1", "pd2"), ("lnarea", "alp1", "alp2")]:
        for df, unit in [(prov, "provid"), (pref, "prefid")]:
            for inter, post in [(i1, "post2012"), (i2, "inspection")]:
                col += 1
                ctrl = CTRL
                # do-file quirk reproduced: column 11 (prefecture, lnarea x post2012) omits ties
                if col == 11:
                    ctrl = CTRL_NOTIES
                rows += oprobit(df, "promote", [main, post, inter] + ctrl, unit, "XII", col)
    # esttab column order in the do-file: prov pp1, prov pp2, pref pp1, pref pp2, ...
    # our loop order is prov post, prov insp, pref post, pref insp -> same
    return rows


def main(which=("VIII", "IX", "XII")):
    rows = []
    if "VIII" in which:
        print("Table VIII (province_panel)")
        rows += promotion_table("province_panel", "provid", "VIII")
    if "IX" in which:
        print("Table IX (prefecture_panel)")
        rows += promotion_table("prefecture_panel", "prefid", "IX")
    if "XII" in which:
        print("Table XII")
        rows += table_xii()
    return save_rows(rows, "tables_promotion")


if __name__ == "__main__":
    main(tuple(sys.argv[1:]) or ("VIII", "IX", "XII"))
