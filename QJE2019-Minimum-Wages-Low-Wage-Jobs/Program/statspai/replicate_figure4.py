"""StatsPAI replication of Figure 4 (first-year bunching estimates for new entrants vs
incumbents, matched CPS) and the Incumbent / New entrant rows of Table 4.

Mirrors Figure4_for_QJE.do and wage_estimate_incum_new_sr.do:
* data: state_panels_with3quant1979_matched.dta (long in emp_prev = employed a year
  earlier: 1 incumbent, 0 new entrant); panel unit = wagebinstateprev (also used as
  the bin-state FE), QCEW multiplier = emp / mt_countall;
* outcome m_overallcountpc on the emp_prev==1 (incumbent) or ==0 (new entrant)
  subsample, weights wtoverall1979, same absorbed controls + placebo bins as Figure 2;
* first-year quantities: only tau=0 (L0) coefficients, denominator 1;
* E from mt_overallcountpcall; B, EWB from m_overall running sums within
  (emp_prev, state, quarter); sum_inf halved because the data are long.

Run: /usr/local/bin/python3.13 Program/statspai/replicate_figure4.py
Outputs: Results/statspai/figure4_*.csv, table4_incumbent_newentrant.csv
"""
from __future__ import annotations

import json

import numpy as np
import pandas as pd
import pyreadstat

from bunching import (BINS, CAT_CONTROLS, DATA, OUT, Panel, T_AFTER, TREAT_AFTER, TREAT_BEFORE, WINDOW,
                      add_placebo_bins, delta, fit, log, notmiss, qcew_overall, s_gt, s_ne, tname, wmean)

GROUPS = {1: "incumbent", 0: "newentrant"}


def main():
    meta = pyreadstat.read_dta(str(DATA / "state_panels_with3quant1979_matched.dta"), metadataonly=True)[1]
    have = set(meta.column_names)
    want = ["statenum", "quarterdate", "year", "wagebins", "wagebinstateprev", "wagequarterdate", "emp_prev",
            "population", "cleansample", "wtoverall1979", "fedincrease", "overallcountgroup", "DMW_real",
            "MW_real", "MW", "MW_realM25", "wageM25", "F1MW_realM25", "F2MW_realM25", "F3MW_realM25",
            "F4MW_realM25", "m_count", "m_overallcountpc", "m_overallcountpcall", "m_countall",
            "mt_count", "mt_overallcountpc", "mt_overallcountpcall", "mt_countall",
            "treat_p5", "treat_p6", "treat_p7"] + TREAT_AFTER + TREAT_BEFORE + WINDOW + CAT_CONTROLS
    cols = [c for c in dict.fromkeys(want) if c in have]
    log(f"missing columns: {[c for c in want if c not in have]}")
    df, _ = pyreadstat.read_dta(str(DATA / "state_panels_with3quant1979_matched.dta"), usecols=cols)
    log(f"read {df.shape}")
    df["wagebinstate"] = df["wagebinstateprev"]
    q = qcew_overall()
    df = df.merge(q, on=["statenum", "quarterdate"], how="left")
    mult = df["emp"] / df["mt_countall"]
    mult = mult.where(~(mult == 0), 1.0)          # replace multiplier = 1 if multiplier==0 (missing stays missing)
    for Y in ("m_", "mt_"):
        for c in (f"{Y}count", f"{Y}overallcountpc", f"{Y}overallcountpcall", f"{Y}countall"):
            df[c] = df[c] * mult
    df = df.sort_values(["emp_prev", "statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    g = [df["emp_prev"].to_numpy(), df["statenum"].to_numpy(), df["quarterdate"].to_numpy()]
    df["m_overallcountpcrsum"] = df.groupby(g)["m_overallcountpc"].cumsum()
    df["m_overallWBpcFH"] = df["wagebins"] * df["m_count"] / (100 * df["population"])
    df["m_overallWBpcrsumFH"] = df.groupby(g)["m_overallWBpcFH"].cumsum()

    P = Panel(df, unit="wagebinstateprev")
    add_placebo_bins(df, P, kmax=16)
    df["sum_inf"] = df["sum_inf"] / 2

    w = df["wtoverall1979"].to_numpy(dtype=float)
    yr = df["year"].to_numpy() >= 1979
    cs = df["cleansample"].to_numpy() == 1
    fed = df["fedincrease"].to_numpy(dtype=float)
    grp = df["overallcountgroup"].to_numpy(dtype=float)
    Ff = {k: P.shift(fed, k) for k in (1, 2, 3, 4)}
    Fg = {k: P.shift(grp, k) for k in (1, 2, 3, 4)}
    mwc = wmean(df["DMW_real"], w, s_ne(fed, 1) & s_gt(grp, 0) & yr & cs)
    mw = wmean(df["MW_real"], w, s_ne(Ff[1], 1) & s_gt(Fg[1], 0) & yr & cs)
    mwpc = mwc / mw

    def fev(k):
        return s_ne(Ff[k], 1) & notmiss(Ff[k]) & s_gt(Fg[k], 0) & notmiss(Fg[k])

    E = wmean(df["mt_overallcountpcall"], w, (fev(1) | fev(2) | fev(3) | fev(4)) & yr & cs)
    wb = df["wagebins"].to_numpy(dtype=float)
    up = (wb + 25) / 100
    tp0 = (df["treat_p0"].to_numpy() == 1) & yr & cs
    wagemult = wmean(wb, w, tp0) / 100
    numbins = wmean(df["sum_inf"], w, s_gt(grp, 0) & notmiss(grp) & s_ne(fed, 1))

    pbins = [f"p{k}" for k in range(5, 18)]
    x_after = TREAT_AFTER + [tname(t, b) for t in T_AFTER for b in pbins]
    lin = TREAT_BEFORE + WINDOW + [tname(t, b, True) for t in (12, 8) for b in pbins] \
        + [f"window_p{k}" for k in range(5, 18)]
    rows, profiles = [], []
    for ep, name in GROUPS.items():
        sub = df["emp_prev"].to_numpy() == ep
        cond = ((fev(1) & (up == df["F1MW_realM25"].to_numpy(dtype=float))) |
                (fev(2) & (up == df["F2MW_realM25"].to_numpy(dtype=float))) |
                (fev(3) & (up == df["F3MW_realM25"].to_numpy(dtype=float))) |
                (fev(4) & (up == df["F4MW_realM25"].to_numpy(dtype=float)) & yr & cs & sub))
        B = wmean(df["m_overallcountpcrsum"], w, cond) / E
        EWB = wmean(df["m_overallWBpcrsumFH"], w, cond)
        K = dict(E=E, B=B, EWB=EWB, mwpc=mwpc, wagemult=wagemult, numbins=numbins)
        log(f"{name} constants {json.dumps(K)}")
        d = df[yr & cs & sub]
        params, V, N = fit(d, "m_overallcountpc", x_after, lin, "wtoverall1979", spec=1, tag=f"figure4_{name}")
        # first-year (tau = 0) quantities, denominator = 1
        names = [tname(0, b) for b in BINS]
        bvec = params.loc[names].to_numpy()
        Vm = V.loc[names, names].to_numpy()
        bi = [names.index(tname(0, f"m{j}")) for j in (1, 2, 3, 4)]
        ai = [names.index(tname(0, f"p{j}")) for j in (0, 1, 2, 3, 4)]
        wbb = np.array([wagemult - j for j in (1, 2, 3, 4)])
        wba = np.array([wagemult + j for j in (0, 1, 2, 3, 4)])
        jb = np.array([1, 2, 3, 4], dtype=float)
        below = lambda x: x[bi].sum() * 4 / E
        above = lambda x: x[ai].sum() * 4 / E
        bunch = lambda x: (x[bi].sum() + x[ai].sum()) * 4 / E / B
        wbE = lambda x: ((x[bi] @ wbb + x[ai] @ wba) * 4 / EWB - bunch(x)) / (1 + bunch(x))
        nosp = lambda x: -(x[bi] @ jb) / EWB * 4
        spill = lambda x: 1 - nosp(x) / wbE(x)
        row = dict(group=name, N=N, b_minus1=B)
        for k, f in (("below", below), ("above", above), ("emp", bunch), ("wage", wbE),
                     ("wage_nospill", nosp), ("spill_share", spill)):
            est, se = delta(f, bvec, Vm)
            row[k] = est; row[k + "_se"] = se
        rows.append(row)
        log(json.dumps(row))
        # Figure 4 bin profile (first year): (L0 coefficient) * 4 / E ; open bin uses numbins
        prof = []
        for k in list(range(-4, 0)) + list(range(0, 18)):
            b = f"m{-k}" if k < 0 else f"p{k}"
            nm = tname(0, b)
            m = numbins if k == 17 else 4.0
            prof.append(dict(group=name, bin=k, est=params[nm] * m / E, se=np.sqrt(V.loc[nm, nm]) * m / E))
        profiles += prof
        pd.DataFrame(rows).to_csv(OUT / "table4_incumbent_newentrant.csv", index=False)
        pd.DataFrame(profiles).to_csv(OUT / "figure4_bins.csv", index=False)
    log("done")


if __name__ == "__main__":
    main()
