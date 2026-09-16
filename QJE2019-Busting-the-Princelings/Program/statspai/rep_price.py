"""Tables III, V, X and Figure V (price.dta, 1.21M land transactions).

Stata original (reghdfe 6, keepsingletons):
    reghdfe lnprice princeling [pscm|retired|pp*] quality lnarea [if near1500/near500],
            ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
StatsPAI:
    sp.feols("lnprice ~ ... | cityyearusage + ind + month + salemethod + state + size",
             vcov={"CRV1": "provid + firmid"})      # pyfixest backend, singletons kept (fixef_rm="none")
Figure V:
    reghdfe lnprice pt3-pt13, same FEs / clustering, pt_k = princeling x 1[year = 2003+k]
    (2004-2005 princeling transactions are the omitted base).
"""
from __future__ import annotations

import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statspai as sp

from common import OUT, extract, fe_count, load, save_rows, tic

FE = ["cityyearusage", "ind", "month", "salemethod", "state", "size"]
FML_FE = " + ".join(FE)
VC = {"CRV1": "provid + firmid"}
REPORT = ["princeling", "pscm", "retired", "pp1", "pp2", "pp3", "pp4"]


def fit(d, xs, sample, table, col):
    s = d if sample is None else d[d[sample] == 1]
    s = s.dropna(subset=["lnprice"] + xs + ["quality", "lnarea"] + FE + ["provid", "firmid"])
    t0 = tic()
    fml = f"lnprice ~ {' + '.join(xs + ['quality', 'lnarea'])} | {FML_FE}"
    r = sp.feols(fml, data=s, vcov=VC)
    n = len(s)
    rows = extract(r, REPORT, table, col, n=n, k=len(xs) + 2, df_fe=fe_count(s, FE),
                   spec=f"{fml}; CRV1 provid+firmid; sample={sample or 'all'}")
    print(f"  {table} col{col}: N={n}  b={rows[0]['coef']:.4f} se={rows[0]['se']:.4f}  {tic() - t0:.0f}s", flush=True)
    return rows


def table_iii(d):
    rows = []
    for lab, s in [("All", d), ("<=1500m", d[d.near1500 == 1]), ("<=500m", d[d.near500 == 1])]:
        for v in ["lnprice", "princeling", "quality", "lnarea"]:
            rows.append(dict(sample=lab, var=v, N=int(s[v].notna().sum()), mean=float(s[v].mean())))
        for k, name in zip([1, 2, 3, 4], ["Bilateral agreement", "English auction", "Invited bidding", "Listing auction"]):
            rows.append(dict(sample=lab, var=f"salemethod={k} ({name})", N=int((s.salemethod == k).sum()),
                             mean=float((s.salemethod == k).mean())))
    out = pd.DataFrame(rows)
    out.to_csv(OUT / "table_III_summary.csv", index=False)
    print(out.to_string())


def table_v(d):
    rows = []
    col = 0
    for extra in [[], ["pscm"], ["retired"]]:
        for sample in [None, "near1500", "near500"]:
            col += 1
            rows += fit(d, ["princeling"] + extra, sample, "V", col)
    return rows


def table_x(d):
    rows = []
    col = 0
    for extra in [["pp1"], ["pp2"], ["pp3"], ["pp1", "pp2", "pp3"], ["pp4"]]:
        for sample in [None, "near500"]:
            col += 1
            rows += fit(d, ["princeling"] + extra, sample, "X", col)
    return rows


def figure_v(d, outcome="lnprice", fe=FE, vc=VC, fname="figure_V_event_study", ylabel=None):
    s = d.dropna(subset=[outcome] + fe + ["year"]).copy()
    years = sorted(s["year"].dropna().unique().astype(int))  # 2004..2016
    xs = []
    for y in years[2:]:
        s[f"pt_{y}"] = (s["princeling"] * (s["year"] == y)).astype(float)
        xs.append(f"pt_{y}")
    t0 = tic()
    r = sp.feols(f"{outcome} ~ {' + '.join(xs)} | {' + '.join(fe)}", data=s, vcov=vc)
    es = pd.DataFrame({"year": [int(x[3:]) for x in xs],
                       "coef": [float(r.params[x]) for x in xs],
                       "se": [float(r.std_errors[x]) for x in xs]})
    es["ci_lo"] = es.coef - 1.96 * es.se
    es["ci_hi"] = es.coef + 1.96 * es.se
    es["N"] = len(s)
    es.to_csv(OUT / f"{fname}.csv", index=False)
    fig, ax = plt.subplots(figsize=(7, 4.2))
    ax.errorbar(es.year, es.coef, yerr=1.96 * es.se, fmt="o-", color="black", capsize=3, lw=1)
    ax.axhline(0, color="black", lw=0.8)
    ax.axvline(2012.5, color="grey", ls="--", lw=0.8)
    ax.set_xticks(es.year)
    ax.set_ylabel(ylabel or "Price difference, princeling vs non-princeling")
    ax.set_title(f"StatsPAI re-estimate ({fname}); base = 2004-2005", fontsize=9)
    fig.tight_layout()
    fig.savefig(OUT / f"{fname}.png", dpi=160)
    plt.close(fig)
    print(f"  {fname}: N={len(s)} {tic() - t0:.0f}s")
    print(es.round(3).to_string())
    return es


def main(which=("III", "V", "X", "FigV")):
    cols = ["lnprice", "princeling", "pscm", "retired", "pp1", "pp2", "pp3", "pp4", "quality", "lnarea",
            "near500", "near1500", "salemethod", "year"] + [f for f in FE if f != "salemethod"] + ["provid", "firmid"]
    d = load("price", columns=list(dict.fromkeys(cols)))
    rows = []
    if "III" in which:
        table_iii(d)
    if "V" in which:
        print("Table V")
        rows += table_v(d)
        save_rows(rows, "table_V")
    if "X" in which:
        print("Table X")
        rx = table_x(d)
        save_rows(rx, "table_X")
        rows += rx
    if "FigV" in which:
        print("Figure V")
        figure_v(d)
    return rows


if __name__ == "__main__":
    main(tuple(sys.argv[1:]) or ("III", "V", "X", "FigV"))
