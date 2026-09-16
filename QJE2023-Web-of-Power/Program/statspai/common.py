"""Shared helpers for the StatsPAI replication of Bai, Jia & Yang (2023, QJE).

Data preparation mirrors the author do-files line by line (variable names kept).
"""
from __future__ import annotations

import re
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import pyfixest as pf
import statspai as sp

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "Data"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)
STATA_TABLES = ROOT / "Results" / "Tables"
AUTHOR = ROOT / "Results" / "author_outputs"


def read(name: str) -> pd.DataFrame:
    df = pd.read_stata(DATA / f"{name}.dta", convert_categoricals=False)
    for c in df.columns:  # avoid int8/int16 overflow when building group ids
        if pd.api.types.is_integer_dtype(df[c]):
            df[c] = df[c].astype("int64")
    return df


# ----------------------------------------------------------------------------- data
HUNAN_POST_VARS = (
    "Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist Zeng_all0 Zeng_all0_invdist "
    "Zeng_exam0_invdist Zeng_BMF_invdist Zeng_Juren_invdist invdist0_L1 invdist0_F1 lnarea capital "
    "lnurbanpop lnpop lnhh dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice "
    "dist_xiangxiang LangSimilarity"
).split()
# Table 2 col (4) / Tables 3-4 control set, in do-file order
HUNAN_CTRL = (
    "capital_Post lnurbanpop_Post lnjinshi_Post lnquotas_Post route1_Post dist_nanjing_Post mainriv_Post "
    "dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post"
).split()
HUNAN_CTRL_GEO = "lnurbanpop_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post".split()
HUNAN_CTRL_POL = (
    "capital_Post lnurbanpop_Post lnjinshi_Post lnquotas_Post mainriv_Post dist2canal_Post lnwheat_Post "
    "lnrice_Post lnpop_Post lnarea_Post"
).split()

# `lnurbanpopXperiod-Taiping_route1Xperiod` in the national do-files = these 12, in order
NAT_CTRL_BASE = (
    "lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea mainriv dist2canal lnrice lnwheat "
    "dist_nanjing Taiping_route1"
).split()
NAT_CTRL = [f"{x}Xperiod" for x in NAT_CTRL_BASE]
# In Figure_6.do / Appendix_Figure_C1.do the loop creates xXperiod1, xXperiod2, xXperiod interleaved, so the SAME
# varlist range `lnurbanpopXperiod-Taiping_route1Xperiod` there expands to 34 variables (a do-file quirk kept here).
NAT_CTRL_FIG6 = ["lnurbanpopXperiod"] + [f"{x}Xperiod{k}" for x in NAT_CTRL_BASE[1:] for k in ("1", "2", "")]


def hunan() -> pd.DataFrame:
    h = read("HunanCntyYr")
    h["Post"] = np.where(h.year < 1854, 0.0, np.where(h.year <= 1864, 1.0, np.nan))
    for v in HUNAN_POST_VARS:
        h[f"{v}_Post"] = h[v] * h["Post"]
    h["prefidXyear"] = h.groupby(["prefid", "year"]).ngroup()
    return h


def national(keep1820: bool = True) -> pd.DataFrame:
    n = read("NationalCntyYr")
    n = n[n.year.notna()].copy()
    n["nhXZenghu_all_invdist"] = n.nonhunan * n.Zenghu_all_invdist
    n["hXZenghu_all_invdist"] = n.hunan * n.Zenghu_all_invdist
    n["nhXZeng_all0_invdist"] = n.nonhunan * n.Zeng_all0_invdist
    n["hXZeng_all0_invdist"] = n.hunan * n.Zeng_all0_invdist
    n["hXZeng_exam0_invdist"] = n.hunan * n.Zeng_exam0_invdist
    n["hXZeng_Extraexam_invdist"] = n.hunan * n.Zeng_Extraexam_invdist
    for x in (
        "hunan Zenghu_all_invdist Zeng_all0_invdist Zeng_exam0_invdist Zeng_Extraexam_invdist "
        "nhXZeng_all0_invdist hXZeng_all0_invdist hXZeng_exam0_invdist hXZeng_Extraexam_invdist martyrs_tot_post"
    ).split():
        n[f"{x}Xperiod"] = n[x] * n.period
    for x in NAT_CTRL_BASE:
        n[f"{x}Xperiod"] = n[x] * n.period
        n[f"{x}Xperiod1"] = n[x] * n.period1
        n[f"{x}Xperiod2"] = n[x] * n.period2
    n["year"] = n.year.astype("int64")
    if keep1820:
        n = n[n.year >= 1820].copy()
    return n


# ----------------------------------------------------------------------------- estimation
def drop_singletons(df: pd.DataFrame, fes: list[str]) -> pd.DataFrame:
    """Iteratively drop singleton groups (reghdfe/ivreghdfe default)."""
    d = df
    while True:
        mask = np.ones(len(d), bool)
        for fe in fes:
            mask &= d.groupby(fe)[fe].transform("size").to_numpy() > 1
        if mask.all():
            return d
        d = d[mask]


def _nested(d: pd.DataFrame, fe: str, cl: str) -> bool:
    return bool((d.groupby(fe)[cl].nunique() <= 1).all())


def absorbed_dof(d: pd.DataFrame, fes: list[str], clusters: list[str]) -> int:
    """reghdfe-style absorbed dof: rank of the FE dummies not nested in a cluster var, minus 1."""
    keep = [f for f in fes if not any(_nested(d, f, c) for c in clusters)]
    if not keep:
        return 0
    mats = [pd.get_dummies(d[f].astype("int64"), prefix=f, dtype=float).to_numpy() for f in keep]
    D = np.hstack(mats)
    return int(np.linalg.matrix_rank(D)) - 1


def ols(y: str, x: list[str], fe: list[str], data: pd.DataFrame, cluster, keep: list[str] | None = None,
        engine: str = "auto"):
    """reghdfe replica.

    * one-way cluster (default engine): sp.feols (pyfixest backend) on the singleton-free sample, unadjusted CRV1,
      then reghdfe's factor G/(G-1)*(N-1)/(N-K-df_a) with df_a = rank of FE dummies not nested in the cluster.
    * multi-way cluster, or engine="hdfe_ols": sp.hdfe_ols (native reghdfe-style solver).
      NB: sp.hdfe_ols 1.28.0 can stop early at a wrong solution with >=3 FEs where one FE nests another
      (e.g. year within prefecture x year) and over-counts df_a in that case -- see analysis note (StatsPAI bug #1).
    """
    x = list(dict.fromkeys(x))
    clusters = [cluster] if isinstance(cluster, str) else list(cluster)
    cols = [y] + x + fe + clusters
    d = data[list(dict.fromkeys(cols))].dropna()
    if engine == "hdfe_ols" or len(clusters) > 1 or not fe:
        fml = f"{y} ~ {' + '.join(x)}" + (f" | {' + '.join(fe)}" if fe else "")
        r = sp.hdfe_ols(fml, data=d, cluster=cluster)
        keep = keep or x
        rows = [dict(var=v, coef=float(r.coef[v]), se=float(r.se[v]), N=int(r.n_obs)) for v in keep if v in r.coef.index]
        return rows, r
    d = drop_singletons(d, fe)
    fml = f"{y} ~ {' + '.join(x)} | {' + '.join(fe)}"
    r = sp.feols(fml, data=d, vcov={"CRV1": cluster}, ssc=pf.ssc(adj=False, cluster_adj=False))
    b, se0 = r.params, r.std_errors
    N, K, G = len(d), len(b), d[cluster].nunique()
    dfa = absorbed_dof(d, fe, clusters)
    fac = np.sqrt(G / (G - 1) * (N - 1) / (N - K - dfa - 1))  # reghdfe counts _cons in K
    keep = keep or x
    rows = [dict(var=v, coef=float(b[v]), se=float(se0[v] * fac), N=N) for v in keep if v in b.index]
    r.reghdfe_se = se0 * fac
    r.reghdfe_vcov_factor = fac ** 2
    return rows, r


def iv(y: str, exog: list[str], endog: str, inst: list[str], fe: list[str], data: pd.DataFrame,
       cluster: str, keep: list[str] | None = None, extra_dof: int = 0):
    """ivreghdfe replica: 2SLS via sp.feols (pyfixest IV backend), singletons dropped, then the
    ivreghdfe cluster small-sample factor G/(G-1)*(N-1)/(N-K-df_a) applied by hand
    (pyfixest's own ssc does not reproduce it -- see analysis note, StatsPAI gap #2)."""
    cols = list(dict.fromkeys([y, endog] + exog + inst + fe + [cluster]))
    d = drop_singletons(data[cols].dropna(), fe)
    fml = f"{y} ~ {' + '.join(exog) if exog else '1'} | {' + '.join(fe)} | {endog} ~ {' + '.join(inst)}"
    r = sp.feols(fml, data=d, vcov={"CRV1": cluster}, ssc=pf.ssc(adj=False, cluster_adj=False))
    b, se0 = r.params, r.std_errors
    N, K, G = len(d), len(b), d[cluster].nunique()
    dfa = absorbed_dof(d, fe, [cluster]) + extra_dof
    fac = np.sqrt(G / (G - 1) * (N - 1) / (N - K - dfa))
    keep = keep or [endog] + exog
    rows = [dict(var=v, coef=float(b[v]), se=float(se0[v] * fac), N=N) for v in keep if v in b.index]
    return rows, r


# ----------------------------------------------------------------------------- outreg2 text parser
def parse_outreg2(path: Path) -> dict:
    """Return {col_index: {'vars': {var: (coef, se)}, 'N': int}} from an outreg2 .txt file."""
    lines = [l.rstrip("\r\n") for l in open(path, encoding="latin-1")]
    rows = [l.split("\t") for l in lines]
    ncol = len(rows[0]) - 1
    res = {j: {"vars": {}, "N": None} for j in range(1, ncol + 1)}
    i = 2
    while i < len(rows):
        r = rows[i]
        name = r[0].strip()
        if name in ("", "VARIABLES") and i + 1 < len(rows):
            i += 1
            continue
        if name == "Observations":
            for j in range(1, ncol + 1):
                v = r[j].replace(",", "").strip() if j < len(r) else ""
                res[j]["N"] = int(v) if v else None
            i += 1
            continue
        if name in ("R-squared",) or name.startswith("Robust") or name.startswith("***"):
            i += 1
            continue
        nxt = rows[i + 1] if i + 1 < len(rows) else []
        for j in range(1, ncol + 1):
            c = r[j].strip() if j < len(r) else ""
            s = nxt[j].strip() if j < len(nxt) else ""
            if c:
                cnum = float(re.sub(r"\*", "", c))
                snum = float(s.strip("()")) if s.startswith("(") else np.nan
                res[j]["vars"][name] = (cnum, snum)
        i += 2
    return res


def attach_reference(rows: pd.DataFrame, table_file: str, paper_override: dict | None = None) -> pd.DataFrame:
    """Add original-Stata (our rerun) and paper (author output = NBER w28667 rev. Aug-2022) columns."""
    stata = parse_outreg2(STATA_TABLES / table_file)
    paper = parse_outreg2(AUTHOR / table_file)
    out = []
    for _, r in rows.iterrows():
        col = int(r["col"])
        s = stata.get(col, {"vars": {}, "N": None})
        p = paper.get(col, {"vars": {}, "N": None})
        sc, ss = s["vars"].get(r["var"], (np.nan, np.nan))
        pc, ps = p["vars"].get(r["var"], (np.nan, np.nan))
        pN = p["N"]
        if paper_override and (col, r["var"]) in paper_override:
            pc, ps, pN = paper_override[(col, r["var"])]
        out.append({**r.to_dict(), "paper_coef": pc, "paper_se": ps, "paper_N": pN,
                    "stata_coef": sc, "stata_se": ss, "stata_N": s["N"]})
    df = pd.DataFrame(out)
    df["abs_diff_coef_vs_stata"] = (df.coef.round(3) - df.stata_coef).abs()
    df["abs_diff_se_vs_stata"] = (df.se.round(3) - df.stata_se).abs()
    return df


def status(r) -> str:
    ok_c = abs(round(r.coef, 3) - r.paper_coef) < 1e-9
    ok_s = abs(round(r.se, 3) - r.paper_se) < 1e-9
    ok_n = (r.paper_N is None) or pd.isna(r.paper_N) or int(r.paper_N) == int(r.N)
    if ok_c and ok_s and ok_n:
        return "✅"
    if abs(r.coef - r.paper_coef) <= 0.0015 and abs(r.se - r.paper_se) <= 0.0015:
        return "⚠️"
    return "❌"


def coef_vcov(r):
    """(coef Series, reghdfe-scaled vcov DataFrame, N) for a result returned by `ols`."""
    if hasattr(r, "_pyfixest_fit"):
        f = r._pyfixest_fit
        names = list(f._coefnames)
        V = pd.DataFrame(np.asarray(f._vcov) * getattr(r, "reghdfe_vcov_factor", 1.0), index=names, columns=names)
        return pd.Series(np.asarray(f._beta_hat), index=names), V, int(f._N)
    V = pd.DataFrame(np.asarray(r.vcov), index=r.coef.index, columns=r.coef.index)
    return r.coef, V, int(r.n_obs)
