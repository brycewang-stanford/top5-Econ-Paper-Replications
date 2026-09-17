"""NOT StatsPAI — fallback / cross-check for the prefecture-level ordered probits (Tables IX, XII).

sp.oprobit uses BFGS with finite-difference gradients; with ~300 prefecture dummies one model
takes 20-50 min single-threaded (hours on a loaded machine).  This module fits the same model
with an analytic score and analytic (observed-information) Hessian via Newton-Raphson, i.e. what
Stata's -oprobit- does, in about a second.  Used only to (i) produce Tables IX / XII when the
StatsPAI run cannot finish, and (ii) document the size of the StatsPAI performance gap.

    python3.13 oprobit_fast.py            -> Results/statspai/table_IX_fallback.csv, table_XII_fallback.csv
"""
from __future__ import annotations

import time

import numpy as np
import pandas as pd
from scipy.stats import norm

from common import OUT, drop_collinear, dummies, load, save_rows

CTRL = ["ties", "gdpgrowth", "lngdppc", "lnpop", "revgrowth", "age", "age2", "eduyear"]
CTRL_NOTIES = [c for c in CTRL if c != "ties"]
REPORT = ["princeling", "discount", "lnarea", "ties", "gdpgrowth", "revgrowth",
          "pp1", "pp2", "pd1", "pd2", "alp1", "alp2"]


def fit_oprobit(y, X, maxit=100, tol=1e-10):
    """Ordered probit MLE.  y: integer codes 0..J-1, X: (n,k) without constant.
    Returns beta, cutpoints, vcov (inverse observed information), loglik."""
    cats = np.unique(y)
    yi = np.searchsorted(cats, y)
    J = len(cats)
    n, k = X.shape
    # start: OLS slope on y, cutpoints from marginal frequencies
    beta = np.zeros(k)
    cum = np.cumsum(np.bincount(yi, minlength=J))[:-1] / n
    kap = norm.ppf(np.clip(cum, 1e-4, 1 - 1e-4))
    theta = np.r_[beta, kap]

    def pieces(theta):
        b, kp = theta[:k], theta[k:]
        xb = X @ b
        up = np.where(yi < J - 1, kp[np.minimum(yi, J - 2)] - xb, np.inf)
        lo = np.where(yi > 0, kp[np.maximum(yi - 1, 0)] - xb, -np.inf)
        return b, kp, up, lo

    def loglik(theta):
        _, _, up, lo = pieces(theta)
        p = norm.cdf(up) - norm.cdf(lo)
        return np.sum(np.log(np.clip(p, 1e-300, None)))

    ll_old = -np.inf
    for it in range(maxit):
        b, kp, up, lo = pieces(theta)
        fu, fl = norm.pdf(up), norm.pdf(lo)
        fu[~np.isfinite(up)] = 0.0
        fl[~np.isfinite(lo)] = 0.0
        p = np.clip(norm.cdf(up) - norm.cdf(lo), 1e-300, None)
        # d log p / d(up) = fu/p, d log p / d(lo) = -fl/p ; up,lo depend on -xb and on cutpoints
        gu, gl = fu / p, -fl / p
        # second derivatives of log p wrt (up, lo)
        upz = np.where(np.isfinite(up), up, 0.0)
        loz = np.where(np.isfinite(lo), lo, 0.0)
        huu = -upz * fu / p - gu ** 2
        hll = loz * fl / p - gl ** 2        # d/dlo(-fl/p) = lo*fl/p - (fl/p)^2
        hul = -gu * gl                       # cross term
        # Jacobians: up = K_up - xb, lo = K_lo - xb
        Dup = np.zeros((n, J - 1)); Dlo = np.zeros((n, J - 1))
        m_up = yi < J - 1; m_lo = yi > 0
        Dup[np.where(m_up)[0], yi[m_up]] = 1.0
        Dlo[np.where(m_lo)[0], yi[m_lo] - 1] = 1.0
        A_up = np.hstack([-X, Dup])            # d up / d theta
        A_lo = np.hstack([-X, Dlo])
        g = A_up.T @ gu + A_lo.T @ gl
        H = (A_up.T * huu) @ A_up + (A_lo.T * hll) @ A_lo + (A_up.T * hul) @ A_lo + (A_lo.T * hul) @ A_up
        step = np.linalg.solve(H, g)
        # Newton with step halving
        t = 1.0
        ll_cur = loglik(theta)
        while t > 1e-8:
            cand = theta - t * step
            if np.all(np.diff(cand[k:]) > 0) and loglik(cand) >= ll_cur - 1e-12:
                break
            t /= 2
        theta = theta - t * step
        ll = loglik(theta)
        if abs(ll - ll_old) < tol and np.max(np.abs(g)) < 1e-6:
            break
        ll_old = ll
    V = np.linalg.inv(-H)
    return theta[:k], theta[k:], V, loglik(theta), it + 1


def run(df, y, xs, unit, table, col):
    s = df.dropna(subset=[y] + xs + ["year", unit]).copy()
    X = s[xs].astype(float).join(dummies(s, ["year", unit]))
    keep = drop_collinear(X, keep_first=xs)
    t0 = time.time()
    b, kap, V, ll, iters = fit_oprobit(s[y].to_numpy(), X[keep].to_numpy(float))
    se = np.sqrt(np.diag(V))[: len(keep)]
    rows = [dict(table=table, col=col, var=v, coef=float(b[keep.index(v)]), se=float(se[keep.index(v)]),
                 N=len(s), adj_r2=None, loglik=ll, iters=iters, seconds=round(time.time() - t0, 2),
                 spec="analytic-Newton ordered probit (NOT StatsPAI)")
            for v in REPORT if v in keep]
    print(f"  {table} col{col}: N={len(s)} k={len(keep)} ll={ll:.4f} iters={iters} {time.time() - t0:.2f}s", flush=True)
    return rows


def main():
    import statspai as sp
    from rep_promotion import lpm
    out = {}
    for tab, dn, unit in [("VIII", "province_panel", "provid"), ("IX", "prefecture_panel", "prefid")]:
        d = load(dn); d = d[d.year >= 2004]
        rows = []
        for ps, off in [(1, 0), (0, 5)]:
            s = d[d.ps == ps]
            rows += run(s, "promote", ["princeling"], unit, tab, off + 1)
            rows += run(s, "promote", ["princeling"] + CTRL, unit, tab, off + 2)
            rows += lpm(s, "promote1", ["princeling"] + CTRL, unit, tab, off + 3)
            rows += run(s, "promote", ["discount"] + CTRL, unit, tab, off + 4)
            rows += run(s, "promote", ["lnarea"] + CTRL, unit, tab, off + 5)
        out[tab] = save_rows(rows, f"table_{tab}_fallback")
    prov = load("province_panel"); prov = prov[(prov.year >= 2004) & (prov.ps == 1)]
    pref = load("prefecture_panel"); pref = pref[(pref.year >= 2004) & (pref.ps == 1)]
    rows, col = [], 0
    for main_, i1, i2 in [("princeling", "pp1", "pp2"), ("discount", "pd1", "pd2"), ("lnarea", "alp1", "alp2")]:
        for df, unit in [(prov, "provid"), (pref, "prefid")]:
            for inter, post in [(i1, "post2012"), (i2, "inspection")]:
                col += 1
                main_eff = "post2012" if col in (10, 12) else post   # do-file quirk (cols 10, 12)
                rows += run(df, "promote", [main_, main_eff, inter] + (CTRL_NOTIES if col == 11 else CTRL), unit, "XII", col)
    out["XII"] = save_rows(rows, "table_XII_fallback")
    return out


if __name__ == "__main__":
    main()
