"""Tables VI, XI and Figure VI (firm_panel.dta, firm_prov_panel.dta).

Stata original:
  Table VI : reghdfe lnarea princeling [pscm|retired], ab(year state size) cluster(firmid) keepsin
  Table XI : reghdfe lnarea princeling pp1 / inspection pp2 / xi pp3 / all,
             ab(provid year state size) cluster(provid firmid) keepsin
  Figure VI: reghdfe lnarea pt3-pt13, ab(year state size) cluster(firmid) keepsin
NB (Manso 2026): in these panels `lnarea` is area (m2)/1,000,000, not a logarithm.
"""
from __future__ import annotations

import gc
import sys

import pandas as pd
import statspai as sp

from common import extract, fe_count, load, save_rows, tic
from rep_price import figure_v

REPORT = ["princeling", "pscm", "retired", "pp1", "inspection", "pp2", "xi", "pp3"]


def table_vi():
    d = load("firm_panel", columns=["lnarea", "princeling", "pscm", "retired", "year", "state", "size", "firmid"])
    print("firm_panel", d.shape, flush=True)
    rows = []
    fe = ["year", "state", "size"]
    for col, xs in enumerate([["princeling"], ["princeling", "pscm"], ["princeling", "retired"]], start=1):
        s = d.dropna(subset=["lnarea"] + xs + fe + ["firmid"])
        t0 = tic()
        r = sp.feols(f"lnarea ~ {' + '.join(xs)} | {' + '.join(fe)}", data=s, vcov={"CRV1": "firmid"})
        rows += extract(r, REPORT, "VI", col, n=len(s), k=len(xs), df_fe=fe_count(s, fe),
                        spec=f"lnarea ~ {' + '.join(xs)} | year+state+size; CRV1 firmid")
        print(f"  VI col{col}: N={len(s)} {tic() - t0:.0f}s", flush=True)
    save_rows(rows, "table_VI")
    print("Figure VI", flush=True)
    figure_v(d, outcome="lnarea", fe=fe, vc={"CRV1": "firmid"}, fname="figure_VI_event_study",
             ylabel="Quantity difference, princeling vs non-princeling (area/1e6)")
    del d
    gc.collect()
    return rows


def table_xi():
    """11.5M rows: sp.feols (pyfixest) peaks at ~12 GB already for the 5.7M-row firm panel, so
    Table XI uses StatsPAI's native reghdfe port sp.hdfe_ols (validated to reproduce reghdfe's
    two-way-cluster SEs and nested-FE dof exactly on Table V col 3)."""
    import numpy as np
    # the do-file writes `xi`, which Stata's variable-name abbreviation expands to `xi_assign`
    cols = ["lnarea", "princeling", "pp1", "inspection", "pp2", "xi_assign", "pp3", "provid", "year", "state", "size", "firmid"]
    d = load("firm_prov_panel", columns=cols).rename(columns={"xi_assign": "xi"})
    print("firm_prov_panel", d.shape, flush=True)
    fe = ["provid", "year", "state", "size"]
    rows = []
    specs = [["princeling", "pp1"], ["princeling", "inspection", "pp2"], ["princeling", "xi", "pp3"],
             ["princeling", "pp1", "inspection", "pp2", "xi", "pp3"]]
    y = d["lnarea"].to_numpy(dtype="float64")
    tss = float(((y - np.nanmean(y)) ** 2)[~np.isnan(y)].sum())
    for col, xs in enumerate(specs, start=1):
        t0 = tic()
        r = sp.hdfe_ols(f"lnarea ~ {' + '.join(xs)} | {' + '.join(fe)}", data=d,
                        cluster=["provid", "firmid"], drop_singletons=False)
        e = np.asarray(r.residuals, dtype="float64")
        n = int(r.n_obs)
        r2 = 1 - float(e @ e) / tss
        adj = 1 - (1 - r2) * (n - 1) / float(r.df_resid)
        for v in xs:
            rows.append(dict(table="XI", col=col, var=v, coef=float(r.params[v]), se=float(r.std_errors[v]),
                             N=n, adj_r2=adj, spec=f"sp.hdfe_ols lnarea ~ {' + '.join(xs)} | provid+year+state+size; cluster provid firmid"))
        print(f"  XI col{col}: N={n} b={rows[-len(xs)]['coef']:.4f} ({rows[-len(xs)]['se']:.4f}) adjR2={adj:.3f} {tic() - t0:.0f}s", flush=True)
        save_rows(rows, "table_XI")
        del r, e
        gc.collect()
    return rows


if __name__ == "__main__":
    which = tuple(sys.argv[1:]) or ("VI", "XI")
    if "VI" in which:
        table_vi()
    if "XI" in which:
        table_xi()
