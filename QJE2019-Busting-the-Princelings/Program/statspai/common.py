"""Shared helpers for the StatsPAI replication of Chen & Kung (2019, QJE).

Paths are resolved relative to this file:  <project>/Program/statspai/common.py
"""
from __future__ import annotations

import json
import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
DATA = ROOT / "Data"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)


def load(name: str, columns=None) -> pd.DataFrame:
    """Read an original .dta file (numeric codes, no value labels)."""
    return pd.read_stata(DATA / f"{name}.dta", convert_categoricals=False, columns=columns)


def tic():
    return time.time()


def fe_count(df: pd.DataFrame, fes: list[str]) -> int:
    """Degrees of freedom absorbed by a set of FEs (sum of levels minus redundancies,
    counted the simple way: first FE all levels, others levels-1).  Only used for the
    adjusted R2 of reghdfe-style models; small differences in df are immaterial at N~1e6."""
    k = 0
    for j, f in enumerate(fes):
        k += df[f].nunique() - (0 if j == 0 else 1)
    return k


def extract(res, names, table, col, *, n=None, r2=None, k=None, df_fe=None, spec=""):
    """Turn a StatsPAI EconometricResults into tidy rows."""
    rows = []
    params, ses = res.params, res.std_errors
    params.index = [str(i) for i in params.index]
    ses.index = [str(i) for i in ses.index]
    if n is None:
        n = (getattr(res, "data_info", {}) or {}).get("nobs")
    adj = None
    if r2 is None:
        r2 = (getattr(res, "diagnostics", {}) or {}).get("R-squared")
    if r2 is not None and n is not None and k is not None and df_fe is not None:
        adj = 1 - (1 - float(r2)) * (n - 1) / (n - k - df_fe)
    for v in names:
        if v in params.index:
            rows.append(dict(table=table, col=col, var=v, coef=float(params[v]), se=float(ses[v]),
                             N=int(n) if n is not None else None,
                             adj_r2=adj, spec=spec))
    return rows


def drop_collinear(X: pd.DataFrame, keep_first: list[str], tol: float = 1e-9,
                   add_const: bool = True) -> list[str]:
    """Greedy (Stata-like, in column order) removal of linearly dependent columns.

    A constant is implicitly part of the span when add_const=True (ordered probit
    cut points / regression intercept), so one level of each dummy set is dropped
    automatically, as Stata's -xi- + -oprobit- does."""
    cols = list(X.columns)
    order = keep_first + [c for c in cols if c not in keep_first]
    M = X[order].to_numpy(dtype=float)
    n = M.shape[0]
    basis = []
    if add_const:
        basis.append(np.ones(n) / np.sqrt(n))
    kept = []
    for j, c in enumerate(order):
        v = M[:, j].copy()
        for b in basis:
            v -= b * (b @ v)
        # second pass for numerical stability
        for b in basis:
            v -= b * (b @ v)
        nv = np.linalg.norm(v)
        scale = np.linalg.norm(M[:, j]) + 1e-300
        if nv / scale > tol ** 0.5:
            basis.append(v / nv)
            kept.append(c)
    return kept


def dummies(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    parts = []
    for c in cols:
        parts.append(pd.get_dummies(df[c].astype("int64").astype(str), prefix=c, dtype=float))
    return pd.concat(parts, axis=1)


def save_rows(rows, name):
    df = pd.DataFrame(rows)
    df.to_csv(OUT / f"{name}.csv", index=False)
    return df


def write_json(obj, name):
    (OUT / f"{name}.json").write_text(json.dumps(obj, indent=2, default=float))
