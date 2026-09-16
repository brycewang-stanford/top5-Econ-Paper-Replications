"""Shared helpers for the StatsPAI replication of Haushofer & Shapiro (QJE 2016).

Everything starts from the author's final analysis file Data/UCT_FINAL_CLEAN.dta
(no data construction happens in the package's analysis do-files beyond sample
flags, which are re-created here line by line).
"""
from __future__ import annotations

import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import pyreadstat
import statspai as sp
from scipy import stats

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "Data"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------- outcome lists (MASTER.do)
INDICES = ["asset_total_ppp", "cons_nondurable_ppp", "ent_total_rev_ppp", "fs_hhfoodindexnew",
           "med_hh_healthindex", "ed_index", "psy_index_z", "ih_overall_index_z"]
PSYVARS = ["psy_lncort_mean", "psy_lncort_mean_clean", "psy_cesdscore", "psy_worries_z",
           "psy_stressscore_z", "psy_hap_z", "psy_sat_z", "psy_trust_z", "psy_locus_z",
           "psy_scheierscore_z", "psy_rosenbergscore_z", "psy_index_z"]
CONS_FINAL = ["cons_allfood_ppp_m", "cons_cereals_ppp_m", "cons_meatfish_ppp_m", "cons_alcohol_ppp_m",
              "cons_tobacco_ppp_m", "cons_social_ppp_m", "cons_med_total_ppp_m", "cons_ed_ppp_m",
              "cons_nondurable_ppp"]
ASSETS_SHORT = ["asset_total_ppp", "asset_livestock_ppp", "asset_durable_ppp", "asset_savings_ppp",
                "asset_land_owned_total", "asset_niceroof"]
ENT_SHORT = ["ent_wagelabor", "ent_ownfarm", "ent_nonagbusiness", "ent_total_rev_ppp",
             "ent_total_cost_ppp", "ent_total_profit_ppp"]
BASELINECONTROLS = ["b_age", "b_married", "b_edu", "b_children", "b_hhsize", "asset_total_ppp0",
                    "cons_total_ppp0", "ent_wagelabor0", "ent_ownfarm0", "ent_business0",
                    "ent_nonagbusiness0"]
SPILLOVERCONTROLS = ["b_age", "b_married", "b_children", "b_hhsize", "b_edu"]

# the four comparisons of Tables I, II, IV, V, VI: (column, tested regressor, full regressor list)
ARMS = [
    ("treat", "treat", ["treat"]),
    ("female", "treatXfemalerecXmarried", ["treatXfemalerecXmarried", "treatXsinglerec", "spillover"]),
    ("monthly", "treatXmonthlyXsmall", ["treatXmonthlyXsmall", "treatXlarge", "spillover"]),
    ("large", "treatXlarge", ["treatXlarge", "spillover"]),
]
ARM_LABEL = {"treat": "Treatment effect", "female": "Female recipient",
             "monthly": "Monthly transfer", "large": "Large transfer"}


def load(name: str = "UCT_FINAL_CLEAN.dta"):
    df, meta = pyreadstat.read_dta(str(DATA / name))
    # pyreadstat returns mixed int/NaN columns (e.g. psy_cesdscore1) as object: coerce to float
    for c in df.columns[df.dtypes == object]:
        conv = pd.to_numeric(df[c], errors="coerce")
        if conv.notna().sum() == df[c].notna().sum():
            df[c] = conv
    return df, meta.column_names_to_labels


def clean_label(s: str) -> str:
    return (s or "").replace("\\hspace{0.2cm}", "").replace("\\&", "&").strip()


# ---------------------------------------------------------------- estimation wrappers
def areg(d: pd.DataFrame, y: str, xs: list[str], controls: list[str] = (),
         fe: str | None = "village", cluster: str = "surveyid", weights: str | None = None):
    """Stata `areg y xs controls, absorb(fe) cluster(cluster)` via sp.feols.

    sp.feols/pyfixest CRV1 uses the same small-sample factor as areg
    ((N-1)/(N-K) * G/(G-1)) and t(G-1) p-values, so SEs and stars match.
    Controls that are constant zero (all-zero *_miss0 dummies) are dropped
    exactly as Stata omits them.
    """
    controls = [c for c in controls if d[c].abs().sum() > 0 or d[c].isna().any()]
    need = [y, *xs, *controls] + ([fe] if fe else []) + [cluster]
    dd = d.dropna(subset=need)
    rhs = " + ".join([*xs, *controls])
    fml = f"{y} ~ {rhs}" + (f" | {fe}" if fe else "")
    kw = {"weights": weights} if weights else {}
    return sp.feols(fml, dd, vcov={"CRV1": cluster}, **kw), dd


def coef(res, x):
    return float(res.params[x]), float(res.std_errors[x]), float(res.pvalues[x])


def stars(p: float) -> str:
    if p is None or np.isnan(p):
        return ""
    return "***" if p < 0.01 else "**" if p < 0.05 else "*" if p < 0.1 else ""


def fmt(b, p=None, prec=2):
    s = f"{b:.{prec}f}"
    if s in ("-0.00", "-0.0"):
        s = s  # Stata prints -0.00 too; keep
    return s + (stars(p) if p is not None else "")


# ---------------------------------------------------------------- SUR / suest joint tests
def _fe_matrix(d: pd.DataFrame, fe: str | None):
    if fe is None:
        return np.empty((len(d), 0))
    dums = pd.get_dummies(d[fe].astype(int), prefix="fe", drop_first=True, dtype=float)
    return dums.to_numpy()


def _partial_out(W: np.ndarray, v: np.ndarray):
    """Residual of v (n x m) on W (n x k) with rank-revealing lstsq."""
    coefs, *_ = np.linalg.lstsq(W, v, rcond=None)
    return v - W @ coefs


def influence_for(d: pd.DataFrame, y: str, x: str, others: list[str], fe: str | None,
                  weights: np.ndarray | None = None):
    """OLS influence function of the coefficient on `x` (FWL), indexed like d.

    IF_i = w_i * xtilde_i * e_i / sum(w * xtilde^2).  Used to reproduce
    `suest ..., cluster()` followed by `test` (sandwich with G/(G-1)).
    Returns (beta, IF Series on d.index restricted to estimation sample).
    """
    cols = [y, x, *others]
    dd = d.dropna(subset=cols)
    n = len(dd)
    W = np.column_stack([np.ones(n), dd[others].to_numpy(float) if others else np.empty((n, 0)),
                         _fe_matrix(dd, fe)])
    w = np.ones(n) if weights is None else weights[d.index.get_indexer(dd.index)]
    sw = np.sqrt(w)
    Yt = _partial_out(W * sw[:, None], (dd[[y, x]].to_numpy(float) * sw[:, None]))
    yt, xt = Yt[:, 0], Yt[:, 1]
    beta = (xt @ yt) / (xt @ xt)
    e = yt - beta * xt
    IF = (sw * xt * e) / (xt @ xt)
    return beta, pd.Series(IF, index=dd.index)


def suest_wald(d: pd.DataFrame, pieces: list[tuple[float, pd.Series]], cluster: str,
               R: np.ndarray | None = None):
    """Wald chi2 test of R b = 0 across equations using cluster-robust suest VCV.

    pieces: list of (beta_j, IF_j) from influence_for, all on d's index.
    Default R = identity (all coefficients jointly zero).
    """
    k = len(pieces)
    b = np.array([p[0] for p in pieces])
    IFm = np.column_stack([p[1].reindex(d.index).fillna(0.0).to_numpy() for p in pieces])
    g = d[cluster].to_numpy()
    S = pd.DataFrame(IFm).groupby(g).sum().to_numpy()
    G = S.shape[0]
    V = (G / (G - 1)) * S.T @ S
    if R is None:
        R = np.eye(k)
    Rb = R @ b
    RVR = R @ V @ R.T
    rank = np.linalg.matrix_rank(RVR)
    chi2 = float(Rb @ np.linalg.pinv(RVR) @ Rb)
    return chi2, int(rank), float(stats.chi2.sf(chi2, rank)), V


# ---------------------------------------------------------------- author's stepdown (FWER) port
def stepdown_perm(d: pd.DataFrame, ys: list[str], treat: str, others: list[str],
                  controls_by_y: dict[str, list[str]] | None, cluster: str, fe: str | None,
                  iters: int = 10000, seed: int = 1073741823, chunk: int = 500):
    """Python port of Program/Ado/stepdown.ado (Haushofer-Shapiro, 2013).

    * actual p-values: 2*ttail(e(N), |t|) from `reg y treat others fev* controls, cluster()`
    * each iteration: placebo treatment = 1{U <= mean(treat in memory)} drawn for
      every row (cutoff uses the variable literally called `treat`, as in the ado),
      the tested regressor is replaced by the placebo, all regressions re-run
    * stepdown: sort outcomes by actual p, successive minima from the bottom,
      count sims with min-p <= actual p; enforce monotonicity; reorder.
    Stata's uniform() stream cannot be reproduced, so p-values differ by
    Monte-Carlo error only (sd <= 0.005 at 10,000 iterations).
    """
    rng = np.random.default_rng(seed)
    cutoff = float(d["treat"].mean())
    nall = len(d)
    act_p, prep = [], []
    for y in ys:
        ctr = list(controls_by_y.get(y, [])) if controls_by_y else []
        cols = [y, treat, *others, *ctr]
        mask = d[cols].notna().all(axis=1).to_numpy()
        dd = d.loc[mask]
        n = len(dd)
        W = np.column_stack([np.ones(n), dd[others + ctr].to_numpy(float) if (others or ctr) else np.empty((n, 0)),
                             _fe_matrix(dd, fe)])
        Q, Rm = np.linalg.qr(W)
        keep = np.abs(np.diag(Rm)) > 1e-9 * np.abs(np.diag(Rm)).max()
        Q = Q[:, keep]
        K = Q.shape[1] + 1
        yv = dd[y].to_numpy(float)
        yt = yv - Q @ (Q.T @ yv)
        codes, uniq = pd.factorize(dd[cluster])
        G = len(uniq)
        adj = (n - 1) / (n - K) * G / (G - 1)

        def tstat(T, Q=Q, yt=yt, codes=codes, G=G, adj=adj):  # T: n x B (defaults bind loop vars)
            Tt = T - Q @ (Q.T @ T)
            ss = (Tt * Tt).sum(0)
            b = (yt @ Tt) / ss
            e = yt[:, None] - Tt * b
            sc = np.zeros((G, T.shape[1]))
            np.add.at(sc, codes, Tt * e)
            se = np.sqrt(adj * (sc * sc).sum(0) / ss ** 2)
            return np.abs(b / se)

        t0 = tstat(dd[[treat]].to_numpy(float))[0]
        act_p.append(2 * stats.t.sf(t0, n))
        prep.append((mask, tstat, n))
    act_p = np.array(act_p)
    order = np.argsort(act_p, kind="stable")
    counts = np.zeros(len(ys))
    done = 0
    while done < iters:
        B = min(chunk, iters - done)
        U = rng.random((nall, B))
        Tsim = (U <= cutoff).astype(float)
        psim = np.empty((len(ys), B))
        for j, (mask, tstat, n) in enumerate(prep):
            psim[j] = 2 * stats.t.sf(tstat(Tsim[mask]), n)
        ps = psim[order]
        for k in range(len(ys) - 1, -1, -1):
            if k < len(ys) - 1:
                ps[k] = np.minimum(ps[k], ps[k + 1])
            counts[k] += (ps[k] <= act_p[order][k]).sum()
        done += B
    padj_sorted = np.zeros(len(ys))
    for k in range(len(ys)):
        val = round(counts[k] / iters, 5)
        padj_sorted[k] = max(val, padj_sorted[k - 1]) if k > 0 else val
    padj = np.empty(len(ys))
    padj[order] = padj_sorted
    return pd.Series(padj, index=ys), pd.Series(act_p, index=ys)


def write_md(df: pd.DataFrame, path: Path, title: str, notes: str = ""):
    with open(path, "w") as f:
        f.write(f"# {title}\n\n")
        f.write(df.to_markdown(index=False))
        f.write("\n")
        if notes:
            f.write(f"\n{notes}\n")
