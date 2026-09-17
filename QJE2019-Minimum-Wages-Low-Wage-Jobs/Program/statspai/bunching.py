"""Generic bunching-estimator machinery (Cengiz, Dube, Lindner & Zipperer, QJE 2019),
re-implemented on top of StatsPAI (`sp.hdfe_ols`, reghdfe-style HDFE OLS).

Mirrors create_programs.do (treatmentcontrolwindows, abovebelowbunch/full,
abovebelowWBbunch/full, abovebelowWBbunch_alt, placebowindows*, placebosamplecorr*)
and the constant blocks shared by Table1/Table2/Table3/Figure2 do-files.

Numerical fidelity notes
------------------------
* Stata stores most generated variables as float (32-bit). Comparisons such as
  `(wagebins+25)/100 == F1MW_realM25` or `wageM25 >= MW_realM25 + k` are done in
  double precision on the float-stored values.  pyreadstat returns float32
  columns as float64 holding the *same* binary value, so we compare exactly
  (no isclose), and we store variables we re-create ourselves as float32 first.
* Stata missing values compare as +infinity: `x != 1` and `x > 0` are TRUE when
  x is missing.  Helpers s_ne / s_gt reproduce this.
* `A | B | C | D & year>=b & cleansample==1`: `&` binds tighter than `|`, so the
  sample restriction in the below-share / wage-bill means applies only to the
  fourth lead.  We replicate this literally.
"""
from __future__ import annotations

import json
import time
from pathlib import Path

import numpy as np
import pandas as pd
import pyreadstat
import statspai as sp

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "Data" / "data"
OUT = ROOT / "Results" / "statspai"
EST = OUT / "estimates"
OUT.mkdir(parents=True, exist_ok=True)
EST.mkdir(parents=True, exist_ok=True)

T_AFTER = [0, 4, 8, 12, 16]
T_BEFORE = [12, 8]
BINS = ["m4", "m3", "m2", "m1", "p0", "p1", "p2", "p3", "p4"]
CAT_CONTROLS = [f"{p}cont{f}_{s}" for f in ("", "f") for s in ("m", "p")
                for p in ("post", "pre", "early")]


def log(msg: str) -> None:
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def tname(t: int, b: str, before: bool = False) -> str:
    if before:
        return f"F{t}treat_{b}"
    return f"treat_{b}" if t == 0 else f"L{t}treat_{b}"


def names_after(bins):
    return [tname(t, b) for t in T_AFTER for b in bins]


def names_before(bins):
    return [tname(t, b, True) for t in T_BEFORE for b in bins]


TREAT_AFTER = names_after(BINS)
TREAT_BEFORE = names_before(BINS)
WINDOW = [f"window_{b}" for b in BINS]

# ---------------------------------------------------------------------------
# Stata semantics helpers
# ---------------------------------------------------------------------------

def f32(x) -> np.ndarray:
    return np.asarray(x, dtype=np.float32).astype(np.float64)


def s_ne(x, v):
    x = np.asarray(x, dtype=float)
    return np.isnan(x) | (x != v)


def s_gt(x, v):
    x = np.asarray(x, dtype=float)
    return np.isnan(x) | (x > v)


def notmiss(x):
    return ~np.isnan(np.asarray(x, dtype=float))


def wmean(x, w, mask):
    x = np.asarray(x, dtype=float)
    w = np.asarray(w, dtype=float)
    m = np.asarray(mask, dtype=bool) & notmiss(x) & notmiss(w)
    return float(np.sum(x[m] * w[m]) / np.sum(w[m]))


class Panel:
    """Fast Stata-style time-series operators on the (unit, quarterdate) panel.

    Rows are located on a dense (unit x time) grid, so L./F. of any column are
    O(n) array lookups (missing where the target row does not exist)."""

    def __init__(self, df: pd.DataFrame, unit: str = "wagebinstate", time_col: str = "quarterdate"):
        u = df[unit].to_numpy()
        t = df[time_col].to_numpy().astype(np.int64)
        self.uc, self.ui = np.unique(u, return_inverse=True)
        self.tmin = int(t.min())
        self.T = int(t.max()) - self.tmin + 1
        self.ti = t - self.tmin
        self.pos = np.full(len(self.uc) * self.T, -1, dtype=np.int64)
        self.pos[self.ui * self.T + self.ti] = np.arange(len(df))
        self.n = len(df)

    def shift(self, arr, k: int) -> np.ndarray:
        """F<k>.arr for k>0, L<-k>.arr for k<0."""
        arr = np.asarray(arr, dtype=float)
        tt = self.ti + k
        ok = (tt >= 0) & (tt < self.T)
        out = np.full(self.n, np.nan)
        idx = np.where(ok, self.pos[self.ui * self.T + np.clip(tt, 0, self.T - 1)], -1)
        good = idx >= 0
        out[good] = arr[idx[good]]
        return out


# ---------------------------------------------------------------------------
# Delta method
# ---------------------------------------------------------------------------

def delta(fun, b: np.ndarray, V: np.ndarray, eps: float = 1e-6):
    f0 = fun(b)
    g = np.zeros_like(b)
    for i in range(len(b)):
        h = eps * max(1e-3, abs(b[i]))
        bp = b.copy(); bp[i] += h
        bm = b.copy(); bm[i] -= h
        g[i] = (fun(bp) - fun(bm)) / (2 * h)
    return float(f0), float(np.sqrt(max(g @ V @ g, 0.0)))


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------
BASE_COLS = ["statenum", "quarterdate", "year", "wagebins", "wagebinstate", "wagequarterdate",
             "division", "count", "countall", "population", "overallcountpc",
             "overallcountpcall", "cleansample", "wtoverall1979", "fedincrease",
             "overallcountgroup", "DMW_real", "MW_real", "MW", "MW_realM25", "wageM25",
             "F1MW_realM25", "F2MW_realM25", "F3MW_realM25", "F4MW_realM25", "quarterdatesq"]


def read_main(extra=(), path="state_panels_with3quant1979.dta") -> pd.DataFrame:
    meta = pyreadstat.read_dta(str(DATA / path), metadataonly=True)[1]
    have = set(meta.column_names)
    want = BASE_COLS + TREAT_AFTER + TREAT_BEFORE + [tname(4, b, True) for b in BINS] + WINDOW \
        + CAT_CONTROLS + ["treat_p5", "treat_p6", "treat_p7"] + list(extra)
    cols = [c for c in dict.fromkeys(want) if c in have]
    missing = [c for c in dict.fromkeys(want) if c not in have]
    if missing:
        log(f"note: columns not in {path}: {missing}")
    log(f"reading {path} ({len(cols)} columns)")
    df, _ = pyreadstat.read_dta(str(DATA / path), usecols=cols)
    log(f"read {df.shape}")
    return df


def qcew_overall() -> pd.DataFrame:
    q, _ = pyreadstat.read_dta(str(DATA / "qcew_state_overall_counts_2016.dta"))
    q = q.rename(columns={"statefips": "statenum"})
    q["quarterdate"] = ((q["year"] - 1960) * 4 + q["quarter"] - 1).astype(int)
    return q[["statenum", "quarterdate", "emp"]]


def qcew_multiplier() -> pd.DataFrame:
    q, _ = pyreadstat.read_dta(str(DATA / "qcew_multiplier.dta"),
                               usecols=["statenum", "quarterdate", "multiplier"])
    return q


# ---------------------------------------------------------------------------
# Constants (E, B, EWB, %dMW, wagemult)
# ---------------------------------------------------------------------------

def add_rsums(df: pd.DataFrame, Y: str, count: str, pop: str, pc: str) -> None:
    """Running sums from wagebins==100 upward within state-quarter (sorted by wagebins)."""
    assert (df[["statenum", "quarterdate", "wagebins"]].diff().fillna(1)
            .pipe(lambda d: ((d.statenum != 0) | (d.quarterdate != 0) | (d.wagebins > 0)).all())), \
        "df must be sorted by statenum quarterdate wagebins"
    g = [df["statenum"].to_numpy(), df["quarterdate"].to_numpy()]
    df[f"{Y}countpcrsum"] = df.groupby(g)[pc].cumsum()
    df[f"{Y}WBpcFH"] = df["wagebins"] * df[count] / (100 * df[pop])
    df[f"{Y}WBpcrsumFH"] = df.groupby(g)[f"{Y}WBpcFH"].cumsum()


def constants(df: pd.DataFrame, P: Panel, Y: str, weight: str, pcall: str, b: int = 1979,
              mw_denominator_needs_nonmissing: bool = False) -> dict:
    w = df[weight].to_numpy(dtype=float)
    yr = df["year"].to_numpy() >= b
    cs = df["cleansample"].to_numpy() == 1
    yr79 = df["year"].to_numpy() >= 1979
    fed = df["fedincrease"].to_numpy(dtype=float)
    grp = df["overallcountgroup"].to_numpy(dtype=float)
    Ff = {k: P.shift(fed, k) for k in (1, 2, 3, 4)}
    Fg = {k: P.shift(grp, k) for k in (1, 2, 3, 4)}

    ev = s_ne(fed, 1) & s_gt(grp, 0) & yr & cs
    mwc = wmean(df["DMW_real"], w, ev)
    if mw_denominator_needs_nonmissing:   # CK_groups_regressions_longfigure_QJE.do variant
        ev1 = s_ne(Ff[1], 1) & notmiss(Ff[1]) & s_gt(Fg[1], 0) & notmiss(Fg[1]) & yr & cs
    else:
        ev1 = s_ne(Ff[1], 1) & s_gt(Fg[1], 0) & yr & cs
    mw = wmean(df["MW_real"], w, ev1)
    mwpc = mwc / mw

    def fev(k):
        return s_ne(Ff[k], 1) & notmiss(Ff[k]) & s_gt(Fg[k], 0) & notmiss(Fg[k])

    E = wmean(df[pcall], w, (fev(1) | fev(2) | fev(3) | fev(4)) & yr & cs)
    wb = df["wagebins"].to_numpy(dtype=float)
    up = (wb + 25) / 100
    cond = ((fev(1) & (up == df["F1MW_realM25"].to_numpy(dtype=float))) |
            (fev(2) & (up == df["F2MW_realM25"].to_numpy(dtype=float))) |
            (fev(3) & (up == df["F3MW_realM25"].to_numpy(dtype=float))) |
            (fev(4) & (up == df["F4MW_realM25"].to_numpy(dtype=float)) & yr & cs))
    B = wmean(df[f"{Y}countpcrsum"], w, cond) / E
    EWB = wmean(df[f"{Y}WBpcrsumFH"], w, cond)
    tp0 = (df["treat_p0"].to_numpy() == 1) & yr & cs
    wagemult = wmean(wb, w, tp0) / 100
    n_events = int((s_ne(fed, 1) & s_gt(grp, 0) & (wb == 300)).sum())
    return dict(E=E, B=B, EWB=EWB, mwpc=mwpc, C=1 / (E * mwpc), wagemult=wagemult,
                n_events=n_events)


# ---------------------------------------------------------------------------
# Placebo bins (Figure 2 / CK groups): treat_p8 ... treat_p17, window vars
# ---------------------------------------------------------------------------

def add_placebo_bins(df: pd.DataFrame, P: Panel, kmax: int = 16) -> None:
    """placebosamplecorr1 (p8..p13) + placebosamplecorr2 (p14..p16, open bin p17)."""
    MW_real = df["MW_real"].to_numpy(dtype=float)
    MW = df["MW"].to_numpy(dtype=float)
    dmwr = MW_real - P.shift(MW_real, -1)
    dmw = MW - P.shift(MW, -1)
    ifc = (dmwr > 0.25) & notmiss(dmwr) & (dmw > 0) & notmiss(dmw)   # D.MW_real>0.25 & D.MW_real<. & D.MW>0
    ok = ifc & s_gt(df["overallcountgroup"], 0) & s_ne(df["fedincrease"], 1)
    wage = df["wageM25"].to_numpy(dtype=float)
    mwb = df["MW_realM25"].to_numpy(dtype=float)
    state_q = df.groupby(["statenum", "quarterdate"]).ngroup().to_numpy()
    for k in range(8, kmax + 2):
        if k <= kmax:
            _t = ok & (wage >= mwb + k) & (wage < mwb + 1 + k)
        else:   # open-ended top bin
            _t = ok & (wage >= mwb + k)
        _t = _t.astype(float)
        treat = _t + P.shift(_t, -1) + P.shift(_t, -2) + P.shift(_t, -3)
        df[f"treat_p{k}"] = treat
        if k == kmax + 1:
            df["sum_inf"] = pd.Series(_t).groupby(state_q).transform("sum").to_numpy()
    for k in range(5, kmax + 2):
        tr = df[f"treat_p{k}"].to_numpy(dtype=float)
        for j in (4, 8, 12, 16):
            f = P.shift(tr, j); f[np.isnan(f)] = 0
            l = P.shift(tr, -j); l[np.isnan(l)] = 0
            df[f"F{j}treat_p{k}"] = f
            df[f"L{j}treat_p{k}"] = l
        if True:   # window_p5..p7 exist in the .dta but are rebuilt here (identical definition)
            df[f"window_p{k}"] = sum(df[c] for c in
                                     [f"F12treat_p{k}", f"F8treat_p{k}", f"F4treat_p{k}", f"treat_p{k}",
                                      f"L4treat_p{k}", f"L8treat_p{k}", f"L12treat_p{k}", f"L16treat_p{k}"])


# ---------------------------------------------------------------------------
# Regression
# ---------------------------------------------------------------------------

def absorb_part(spec: int) -> str:
    fe = ["wagebinstate", "wagequarterdate" if spec in (1, 4, 10) else "wqdiv"]
    if spec in (4, 6, 10, 11):
        fe.append("i.wagebinstate#c.quarterdate")
    if spec in (10, 11):
        fe.append("i.wagebinstate#c.quarterdatesq")
    return " + ".join(fe + CAT_CONTROLS)


def fit(d: pd.DataFrame, y: str, xvars, linear_abs, weight: str, spec: int = 1, tag: str = ""):
    d = d.copy()
    if spec in (5, 6, 11):
        d["wqdiv"] = d.groupby(["wagequarterdate", "division"]).ngroup()
    keep = [c for c in dict.fromkeys(list(xvars) + list(linear_abs))]
    fml = f"{y} ~ {' + '.join(keep)} | {absorb_part(spec)}"
    t0 = time.time()
    log(f"[{tag}] hdfe_ols N={len(d):,} k={len(keep)} spec={spec}")
    r = sp.hdfe_ols(fml, data=d, weights=weight, cluster="statenum")
    params = pd.Series(r.params)
    V = pd.DataFrame(np.asarray(r.vcov), index=params.index, columns=params.index)
    log(f"[{tag}] done in {time.time() - t0:.0f}s, N={r.n_obs}, df_resid={r.df_resid}")
    if tag:
        params.to_csv(EST / f"{tag}_b.csv")
        V.to_csv(EST / f"{tag}_V.csv")
        (EST / f"{tag}_meta.json").write_text(json.dumps(dict(N=int(r.n_obs), df_resid=int(r.df_resid),
                                                              formula=fml, weight=weight)))
    return params, V, int(r.n_obs)


def load_fit(tag: str):
    params = pd.read_csv(EST / f"{tag}_b.csv", index_col=0).iloc[:, 0]
    V = pd.read_csv(EST / f"{tag}_V.csv", index_col=0)
    meta = json.loads((EST / f"{tag}_meta.json").read_text())
    return params, V, meta["N"]


# ---------------------------------------------------------------------------
# Post-estimation quantities (Table 1 rows, Table 4 columns, figures)
# ---------------------------------------------------------------------------

def bunching_stats(params: pd.Series, V: pd.DataFrame, K: dict, with_alt: bool = False) -> dict:
    names = TREAT_AFTER
    b = params.loc[names].to_numpy()
    Vm = V.loc[names, names].to_numpy()
    idx = {n: i for i, n in enumerate(names)}
    E, B, EWB, C, wm = K["E"], K["B"], K["EWB"], K["C"], K["wagemult"]
    den = 1 / (1 + 16 / 4)
    bi = [idx[tname(t, f"m{j}")] for t in T_AFTER for j in (1, 2, 3, 4)]
    ai = [idx[tname(t, f"p{j}")] for t in T_AFTER for j in (0, 1, 2, 3, 4)]
    wbb = np.array([wm - j for t in T_AFTER for j in (1, 2, 3, 4)])
    wba = np.array([wm + j for t in T_AFTER for j in (0, 1, 2, 3, 4)])
    jb = np.array([j for t in T_AFTER for j in (1, 2, 3, 4)], dtype=float)

    def below(x): return x[bi].sum() * 4 * den / E
    def above(x): return x[ai].sum() * 4 * den / E
    def bunch(x): return (x[bi].sum() + x[ai].sum()) * 4 * den / E / B
    def elas(x): return (x[bi].sum() + x[ai].sum()) * 4 * den * C
    def wbE(x):
        wbch = (x[bi] @ wbb + x[ai] @ wba) * 4 * den / EWB
        return (wbch - bunch(x)) / (1 + bunch(x))
    def labdem(x): return bunch(x) / wbE(x)
    # Table2_for_QJE.do (cols 1-5) uses the linear variant %dwb - %de (no division by 1+%de)
    def wbE_lin(x): return (x[bi] @ wbb + x[ai] @ wba) * 4 * den / EWB - bunch(x)
    def labdem_lin(x): return bunch(x) / wbE_lin(x)
    # Table 4, "no spillover" wage effect (abovebelowWBbunch_alt, secondmethod(Y)):
    # sum_t sum_nn (nn * b[L_t treat_m nn]) * (-1), scaled by 4*0.2/EWB
    def wb_nospill(x): return -(x[bi] @ jb) / EWB * 4 * 0.2
    def spill(x): return 1 - wb_nospill(x) / wbE(x)

    fns = [("below", below), ("above", above), ("wage", wbE), ("emp", bunch),
           ("elas_mw", elas), ("elas_wage", labdem), ("wage_lin", wbE_lin), ("elas_wage_lin", labdem_lin)]
    if with_alt:
        fns += [("wage_nospill", wb_nospill), ("spill_share", spill)]
    out = {}
    for k, f in fns:
        est, se = delta(f, b, Vm)
        out[k] = est
        out[k + "_se"] = se
    return out


def eventtime_path(params: pd.Series, V: pd.DataFrame, K: dict) -> pd.DataFrame:
    """Figure 3: excess (p0..p4) and missing (m1..m4) jobs by annualized event time."""
    rows = []
    for tau, before, t in [(-3, True, 12), (-2, True, 8), (0, False, 0), (1, False, 4),
                           (2, False, 8), (3, False, 12), (4, False, 16)]:
        for side, bins in (("excess", ["p0", "p1", "p2", "p3", "p4"]), ("missing", ["m1", "m2", "m3", "m4"])):
            nm = [tname(t, bb, before) for bb in bins]
            est = params.loc[nm].sum() * 4 / K["E"]
            se = np.sqrt(V.loc[nm, nm].to_numpy().sum()) * 4 / K["E"]
            rows.append(dict(tau=tau, side=side, est=est, se=se, lo=est - 1.96 * se, hi=est + 1.96 * se))
    for side in ("excess", "missing"):
        rows.append(dict(tau=-1, side=side, est=0.0, se=0.0, lo=0.0, hi=0.0))
    return pd.DataFrame(rows).sort_values(["side", "tau"]).reset_index(drop=True)


def bin_profile(params: pd.Series, V: pd.DataFrame, K: dict, kmax: int = 16, numbins: float = 4.0) -> pd.DataFrame:
    """Figure 2: 5-year-averaged employment change by $1 bin k=-4..17 (17 = open bin)."""
    den = 0.2
    rows = []
    for k in list(range(-4, 0)) + list(range(0, kmax + 2)):
        b = f"m{-k}" if k < 0 else f"p{k}"
        nm = [tname(t, b) for t in T_AFTER]
        mult = numbins if k == kmax + 1 else 4.0
        est = params.loc[nm].sum() * mult * den / K["E"]
        se = np.sqrt(V.loc[nm, nm].to_numpy().sum()) * mult * den / K["E"]
        rows.append(dict(bin=k, est=est, se=se, lo=est - 1.96 * se, hi=est + 1.96 * se))
    out = pd.DataFrame(rows)
    out["running_sum"] = out["est"].cumsum()
    return out
