"""Shared helpers for the StatsPAI replication of Autor, Dorn & Hanson (2013).

Conventions that reproduce the author's Stata output exactly
-----------------------------------------------------------
* ``ivregress 2sls y (x=z) controls [aw=timepwt48], cluster(statefip)`` without
  ``small`` applies **no** finite-sample factor to the cluster sandwich.  In
  StatsPAI this is ``sp.feols("y ~ controls | x ~ z", weights=..., vcov={"CRV1":
  "statefip"}, ssc=pf.ssc(adj=False, cluster_adj=False))``.
* ``regress y x controls [aw=...], cluster(statefip)`` uses
  G/(G-1)*(N-1)/(N-K) -> StatsPAI/pyfixest default ``ssc``.
* ``sp.iv`` / ``sp.ivreg`` (StatsPAI's native k-class IV) has no analytic-weight
  argument (a ``weights=`` keyword is accepted and silently ignored, see the
  StatsPAI note), so the native path is run on sqrt(w)-transformed data as a
  cross-check.
"""
from __future__ import annotations

import re
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import pyfixest as pf
import statspai as sp

ROOT = Path(__file__).resolve().parents[2]
DTA = ROOT / "Data" / "dta"
EXT = ROOT / "Data" / "external"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)

W = "timepwt48"
CL = "statefip"
REG = ["reg_midatl", "reg_encen", "reg_wncen", "reg_satl", "reg_escen",
       "reg_wscen", "reg_mount", "reg_pacif"]
DEMO = ["l_sh_popedu_c", "l_sh_popfborn", "l_sh_empl_f"]
TASK = ["l_sh_routine33", "l_task_outsource"]
MFG = ["l_shind_manuf_cbp"]
FULL = MFG + DEMO + TASK + REG + ["t2"]          # column 6 of Table 3

SSC_IVREGRESS = pf.ssc(adj=False, cluster_adj=False)   # ivregress, vce(cluster)
SSC_REGRESS = pf.ssc(adj=True, cluster_adj=True)       # regress, vce(cluster)

warnings.filterwarnings("ignore", message=".*predict\\(\\) method is currently not supported for IV.*")
warnings.filterwarnings("ignore", message=".*fitted values are not attached.*")


def load(name: str) -> pd.DataFrame:
    d = pd.read_stata(DTA / name, convert_categoricals=False)
    for c in ("statefip", "yr"):
        if c in d.columns:
            d[c] = d[c].astype(int)
    return d


def _wr2(y, yhat, w):
    w = np.asarray(w, float)
    ybar = np.sum(w * y) / np.sum(w)
    return 1.0 - np.sum(w * (y - yhat) ** 2) / np.sum(w * (y - ybar) ** 2)


def _design(d: pd.DataFrame, names) -> np.ndarray:
    cols = [np.ones(len(d)) if n in ("Intercept", "_cons") else d[n].to_numpy(float) for n in names]
    return np.column_stack(cols)


def fit_iv(y: str, x: str | list, z, ctrl, data: pd.DataFrame, cond=None):
    """Weighted 2SLS with state clusters via StatsPAI (sp.feols IV syntax)."""
    xs = [x] if isinstance(x, str) else list(x)
    zs = [z] if isinstance(z, str) else list(z)
    d = data if cond is None else data.loc[cond]
    d = d.dropna(subset=[y, *xs, *zs, *ctrl, W]).copy()
    rhs = " + ".join(ctrl) if ctrl else "1"
    fml = f"{y} ~ {rhs} | {' + '.join(xs)} ~ {' + '.join(zs)}"
    r = sp.feols(fml, data=d, weights=W, vcov={"CRV1": CL}, ssc=SSC_IVREGRESS)
    names = list(r.params.index)
    yhat = _design(d, names) @ r.params.to_numpy(float)
    r2 = _wr2(d[y].to_numpy(float), yhat, d[W])
    return r, d, r2


def fit_ols(y: str, xs, data: pd.DataFrame, cond=None, ssc=SSC_REGRESS):
    xs = [xs] if isinstance(xs, str) else list(xs)
    d = data if cond is None else data.loc[cond]
    d = d.dropna(subset=[y, *xs, W]).copy()
    r = sp.feols(f"{y} ~ {' + '.join(xs)}", data=d, weights=W, vcov={"CRV1": CL}, ssc=ssc)
    names = list(r.params.index)
    yhat = _design(d, names) @ r.params.to_numpy(float)
    return r, d, _wr2(d[y].to_numpy(float), yhat, d[W])


def fit_first_stage(x: str, rhs, data: pd.DataFrame, cond=None, vcov="HC1"):
    """First-stage OLS. ``vcov='HC1'`` reproduces the published first-stage SEs;
    ``{'CRV1': 'statefip'}`` gives the state-clustered SE without small-sample factor."""
    d = data if cond is None else data.loc[cond]
    d = d.dropna(subset=[x, *rhs, W]).copy()
    ssc = SSC_REGRESS if vcov == "HC1" else SSC_IVREGRESS
    r = sp.feols(f"{x} ~ {' + '.join(rhs)}", data=d, weights=W, vcov=vcov, ssc=ssc)
    yhat = _design(d, list(r.params.index)) @ r.params.to_numpy(float)
    return r, d, _wr2(d[x].to_numpy(float), yhat, d[W])


def wmean_sd(x, w):
    """Stata ``summarize [aw=w]`` mean and sd (aweights normalised to N)."""
    x = np.asarray(x, float); w = np.asarray(w, float)
    m = ~np.isnan(x); x, w = x[m], w[m]
    n = len(x); wn = w * n / w.sum()
    mean = np.sum(wn * x) / n
    var = np.sum(wn * (x - mean) ** 2) / (n - 1)
    return mean, np.sqrt(var)


def stata_wpctile(x, w, p):
    """Stata ``summarize, detail`` percentile with aweights (p in 0..100)."""
    x = np.asarray(x, float); w = np.asarray(w, float)
    o = np.argsort(x, kind="mergesort"); x, w = x[o], w[o]
    cw = np.cumsum(w); P = p / 100.0 * cw[-1]
    i = int(np.searchsorted(cw, P, side="left"))
    if np.isclose(cw[i], P) and i + 1 < len(x):
        return 0.5 * (x[i] + x[i + 1])
    return x[i]


def stata_pctile(x, p):
    """Stata ``_pctile`` default definition (unweighted)."""
    x = np.sort(np.asarray(x, float)); n = len(x); np_ = n * p / 100.0
    if float(np_).is_integer():
        k = int(np_)
        return 0.5 * (x[k - 1] + x[k])
    return x[int(np.ceil(np_)) - 1]


# --------------------------------------------------------------------------
# Parser for Stata logs: full-precision coefficients for every estimation
# --------------------------------------------------------------------------
_NUM = r"-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?"
_ROW = re.compile(rf"^\s*(\S+)\s+\|\s+({_NUM})\s+({_NUM})\s+({_NUM})\s+({_NUM})")


def parse_stata_log(path: Path) -> list[dict]:
    """Return one dict per estimation command with its coefficient blocks."""
    lines = Path(path).read_text(errors="replace").splitlines()
    out, cur, i = [], None, 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith(". "):
            cmd = ln[2:]
            j = i + 1
            while j < len(lines) and lines[j].startswith("> "):
                cmd += lines[j][2:]
                j += 1
            c = cmd.strip()
            c2 = re.sub(r"^eststo:\s*", "", c)
            if re.match(r"^(ivregress|reg |regress )", c2):
                cur = {"cmd": c2, "blocks": [], "N": None}
                out.append(cur)
            elif not c2.startswith("*") and c2:
                cur = None if not c2.startswith("est") else cur
            i = j
            continue
        if cur is not None:
            m = re.search(r"Number of obs\s+=\s+([\d,]+)", ln)
            if m:
                cur["N"] = int(m.group(1).replace(",", ""))
            if "Coefficient" in ln and "|" in ln:
                cur["blocks"].append({})
            else:
                r = _ROW.match(ln)
                if r and cur["blocks"]:
                    cur["blocks"][-1][r.group(1)] = (float(r.group(2)), float(r.group(3)))
        i += 1
    return out


def canon_cmd(cmd: str) -> tuple:
    """Canonical key (depvar, endog, instruments, controls, if) of a Stata command."""
    c = cmd.split(",")[0]
    cond = ""
    m = re.search(r"\bif\s+(.*)$", c)
    if m:
        cond = re.sub(r"\s+", "", m.group(1)); c = c[: m.start()]
    c = re.sub(r"\[aw=[^\]]*\]", "", c)
    endog, inst = "", ""
    m = re.search(r"\(([^=]+)=([^)]+)\)", c)
    if m:
        endog = m.group(1).strip(); inst = " ".join(sorted(m.group(2).split()))
        c = c[: m.start()] + " " + c[m.end():]
    toks = c.split()
    toks = toks[2:] if toks[0] == "ivregress" else toks[1:]
    dep = toks[0]
    rest = toks[1:]
    if not endog:                       # OLS: first regressor is the variable of interest
        endog, rest = rest[0], rest[1:]
    return (dep, endog, inst, " ".join(sorted(rest)), cond)


def py_key(y, x, z, ctrl, cond_str=""):
    ctrl = list(ctrl)
    if all(r in ctrl for r in REG):
        ctrl = [c for c in ctrl if c not in REG] + ["reg*"]
    zs = [z] if isinstance(z, str) else list(z or [])
    return (y, x, " ".join(sorted(zs)), " ".join(sorted(ctrl)), re.sub(r"\s+", "", cond_str))


def abbrev_match(abbr: str, full: str) -> bool:
    if abbr == full:
        return True
    if "~" in abbr:
        a, b = abbr.split("~", 1)
        return full.startswith(a) and full.endswith(b) and len(full) > len(abbr)
    if abbr.endswith(".."):
        return full.startswith(abbr[:-2])
    return False


def lookup(block: dict, full: str):
    for k, v in block.items():
        if abbrev_match(k, full):
            return v
    return (np.nan, np.nan)
