"""Shared helpers for the StatsPAI replication of Beraja, Kao, Yang & Yuchtman (2023, QJE) "AI-tocracy".

Estimation is done with ``sp.feols`` (StatsPAI's fixest-style HDFE OLS, pyfixest backend).
Stata's -reghdfe- / -ivreghdfe ..., small- apply a finite-sample factor that pyfixest does not
reproduce exactly when (i) singletons are dropped, (ii) an absorbed FE is nested in the cluster
variable, or (iii) aweights are used with robust SEs.  To match Stata to the last digit we ask
sp.feols for the *unadjusted* sandwich (ssc adj=False, cluster_adj=False) and apply the
Stata factor ourselves:

  cluster : V * (N-1)/(N-K) * G/(G-1)      K = rank(X) + df_a (absorbed FE dof not nested in cluster)
  robust  : V * N/(N-K)
where N excludes singleton groups (reghdfe/ivreghdfe drop them by default).
"""
from __future__ import annotations

import json
import re
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import pyfixest as pf
import statspai as sp

warnings.filterwarnings("ignore")

PROJ = Path(__file__).resolve().parents[2]
DATA = PROJ / "Data"
XDATA = DATA / "Intermediate" / "statspai"
OUT = PROJ / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)

SSC0 = pf.ssc(adj=False, cluster_adj=False)


def read_dta(path, cols=None):
    return pd.read_stata(path, convert_categoricals=False, columns=cols)


def drop_singletons(df: pd.DataFrame, fes: list[str]) -> pd.DataFrame:
    """Iteratively drop singleton FE groups (as reghdfe does)."""
    d = df
    while True:
        keep = np.ones(len(d), dtype=bool)
        for fe in fes:
            keep &= d.groupby(fe)[fe].transform("size").to_numpy() > 1
        if keep.all():
            return d
        d = d[keep]


def _df_a(d: pd.DataFrame, fes: list[str], cluster: str | None) -> int:
    """Degrees of freedom absorbed by the FEs, reghdfe convention:
    sum of levels - (number of FEs - 1) [pairwise redundancy] - levels of FEs nested in the cluster.
    Calibrated against e(df_a) of reghdfe/ivreghdfe for the specs used in this paper."""
    if not fes:
        return 0
    tot = sum(d[fe].nunique() for fe in fes) - (len(fes) - 1)
    if cluster is not None:
        for fe in fes:
            if (d.groupby(fe)[cluster].nunique() <= 1).all():
                tot -= d[fe].nunique()
    return max(tot, 0)


def hdfe(fml: str, data: pd.DataFrame, fes: list[str], cluster: str | None = None,
         weights: str | None = None, robust: bool = False, keep: list[str] | None = None,
         singletons: bool = True, stata: str = "ivreghdfe", **kw):
    """Run sp.feols and return (coef, se, info, result) with Stata (ivreghdfe/reghdfe, small) SE factors.

    fml: 'y ~ x1 + x2 + i(qofd, z)' (no FE part); fes appended as '| fe1 + fe2'.
    stata='reghdfe' counts the reported _cons in K (reghdfe keeps a constant; ivreghdfe partials it out)."""
    full = fml + (" | " + " + ".join(fes) if fes else "")
    toks = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", full))
    vars_ = [c for c in data.columns if c in toks] + ([cluster] if cluster else []) + ([weights] if weights else [])
    d = data.dropna(subset=list(dict.fromkeys(vars_)))
    if weights:
        d = d[d[weights] > 0]
    if fes and singletons:
        d = drop_singletons(d, fes)
    vc = {"CRV1": cluster} if cluster else ("hetero" if robust else "iid")
    res = sp.feols(full, data=d, vcov=vc, ssc=SSC0, weights=weights,
                   fixef_maxiter=kw.pop("fixef_maxiter", 100000), **kw)
    b, se = res.params, res.std_errors
    N = len(d)
    k = int(b.notna().sum())
    dfa = _df_a(d, fes, cluster)
    k_tot = k + dfa if fes else k
    if fes and stata == "reghdfe":
        k_tot += 1
    if cluster:
        G = d[cluster].nunique()
        fac = (N - 1) / (N - k_tot) * G / (G - 1)
    else:
        fac = N / (N - k_tot)
    se = se * np.sqrt(fac)
    info = dict(N=N, k=k, df_a=dfa, factor=fac, formula=full, cluster=cluster, weights=weights,
                G=(d[cluster].nunique() if cluster else None))
    if keep:
        b, se = b.reindex(keep), se.reindex(keep)
    return b, se, info, res


def stata_keep_order(d: pd.DataFrame, cols: list[str], fes: list[str], tol: float = 1e-8) -> list[str]:
    """Mimic Stata's -_rmcoll- on the FE-demeaned design: walk the regressors in the order they
    appear on the command line and omit any column that is (numerically) a linear combination of
    the columns already kept.  pyfixest instead keeps/drops by pivoted QR, which can pick a
    different (equally valid) normalisation when event-time dummies are collinear with FE."""
    X = d[cols].to_numpy(float)
    if fes:
        sc = X.std(axis=0); sc[sc == 0] = 1.0
        Xw, _ = sp.demean(X / sc, d[fes].reset_index(drop=True), drop_singletons=False)
    else:
        Xw = X - X.mean(axis=0)
        sc = np.ones(X.shape[1])
    keep, Q = [], np.zeros((X.shape[0], 0))
    for j, c in enumerate(cols):
        x = Xw[:, j]
        nx = float(x @ x)
        if nx <= 1e-12:
            continue
        r = x - Q @ (Q.T @ x) if Q.shape[1] else x
        r = r - Q @ (Q.T @ r) if Q.shape[1] else r  # re-orthogonalise
        if float(r @ r) <= tol * nx:
            continue
        keep.append(c)
        Q = np.column_stack([Q, r / np.sqrt(r @ r)])
    return keep


def save_rows(rows: list[dict], name: str):
    df = pd.DataFrame(rows)
    df.to_csv(OUT / f"{name}.csv", index=False)
    return df


def star(b, se):
    if se is None or not np.isfinite(se) or se == 0:
        return ""
    z = abs(b / se)
    return "***" if z > 2.576 else "**" if z > 1.960 else "*" if z > 1.645 else ""
