"""Modern-methods EXTENSIONS (not replication) for ADH (2013), headline spec =
Table 3 columns 1 and 6 (d_sh_empl_mfg on d_tradeusch_pw, instrument d_tradeotch_pw_lag,
weights timepwt48, clusters statefip).

 1. Weak-IV diagnostics: Olea-Pflueger effective F, cluster-robust Anderson-Rubin CI
 2. WRE wild cluster bootstrap (Davidson-MacKinnon) for the IV coefficient
 3. Shift-share inference: Adao-Kolesar-Morales (2019) shock-level SEs + AKM0 CI
 4. Borusyak-Hull-Jaravel (2022) equivalent shock-level IV regression
 5. Goldsmith-Pinkham-Sorkin-Swift (2020) Rotemberg weights

References checked against: Stata (ivreg2/weakivtest/weakiv/boottest; Program/modern_reference_stata.do),
R ShiftShareSE (Program/statspai/akm_reference.R), BHJ (2022) and GPSS (2020) published replication output.
Industry shares/shocks: BHJ replication archive (Data/external/bhj_shift_share), which reproduces the
ADH instrument to 3.5e-6.
Run: /usr/local/bin/python3.13 Program/statspai/modern_extensions.py
"""
from __future__ import annotations

import re
import time
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyfixest as pf
import scipy.linalg as sla
import statspai as sp
from scipy import stats

from common import CL, EXT, FULL, OUT, ROOT, SSC_IVREGRESS, SSC_REGRESS, W, load

warnings.filterwarnings("ignore")
T0 = time.time()
X, Z, Y = "d_tradeusch_pw", "d_tradeotch_pw_lag", "d_sh_empl_mfg"
SPECS = {"c1": ["t2"], "c6": FULL}
ROWS = []


def add(block, spec, stat, statspai, reference=np.nan, source="", note=""):
    ROWS.append(dict(block=block, spec=spec, statistic=stat, statspai=statspai, reference=reference,
                     abs_diff=abs(statspai - reference) if np.isfinite(reference) and np.isfinite(statspai) else np.nan,
                     reference_source=source, note=note))


D = load("workfile_china.dta").sort_values(["czone", "yr"]).reset_index(drop=True)
R = {}
for ln in (ROOT / "Results/log/modern_reference_stata.csv").read_text().splitlines()[1:]:
    sp_, st_, val = ln.split(",", 2)          # confidence sets contain commas
    R[(sp_, st_)] = val.strip()


def rnum(spec, stat):
    try:
        return float(R[(spec, stat)])
    except Exception:
        return np.nan


def cset(spec, stat):
    s = R.get((spec, stat), "")
    v = re.findall(r"-?\.?\d+\.?\d*", s.replace("−", "-"))
    return (float(v[0]), float(v[1])) if len(v) == 2 else (np.nan, np.nan)


def sqrtw(data, cols):
    sw = np.sqrt(data[W])
    t = pd.DataFrame({c: data[c] * sw for c in cols}); t["sw"] = sw; t[CL] = data[CL]
    return t


# ============ 1. weak-IV: effective F and Anderson-Rubin ======================
ar_curves = {}
for spec, ctrl in SPECS.items():
    # (a) exact: single instrument -> F_eff = cluster-robust first-stage Wald F (ivreg2 finite-sample factor)
    fs = sp.feols(f"{X} ~ {Z} + " + " + ".join(ctrl), data=D, weights=W, vcov={"CRV1": CL}, ssc=SSC_REGRESS)
    feff = float(fs.tvalues[Z]) ** 2
    add("weak_IV", spec, "F_eff (Olea-Pflueger) via sp.feols first stage t^2", feff, rnum(spec, "F_eff"), "Stata weakivtest")
    # (b) StatsPAI built-in on sqrt(w)-transformed data (adds its own intercept -> approximation)
    t = sqrtw(D, [X, Z, Y] + ctrl)
    try:
        ef = sp.effective_f_test(t, endog=X, instruments=[Z], exog=["sw"] + ctrl, cluster=CL)
        add("weak_IV", spec, "F_eff via sp.effective_f_test (sqrt-w transform, extra intercept)", float(ef["F_eff"]),
            rnum(spec, "F_eff"), "Stata weakivtest", "no weights= argument in sp.effective_f_test")
    except Exception as e:
        add("weak_IV", spec, "sp.effective_f_test error", np.nan, note=f"{type(e).__name__}: {e}"[:200])

    # (c) exact cluster-robust AR confidence set by test inversion (weighted, sp.feols reduced forms)
    grid = np.round(np.arange(-2.0, 1.0 + 1e-9, 0.0015), 6)
    G = D[CL].nunique()
    stat = []
    for b0 in grid:
        d = D.assign(_ytil=D[Y] - b0 * D[X])
        r = sp.feols(f"_ytil ~ {Z} + " + " + ".join(ctrl), data=d, weights=W, vcov={"CRV1": CL}, ssc=SSC_REGRESS)
        stat.append(float(r.tvalues[Z]) ** 2)
    stat = np.array(stat)
    acc = grid[stat <= stats.chi2.ppf(0.95, 1)]
    ar_curves[spec] = (grid, stat)
    lo_ref, hi_ref = cset(spec, "ar_cset")
    add("weak_IV", spec, "AR 95% CI lower, Wald form (sp.feols reduced-form t^2, unrestricted residuals)", acc.min(),
        note="differs from weakiv by construction (variance at unrestricted residuals)")
    add("weak_IV", spec, "AR 95% CI upper, Wald form", acc.max())
    # LM / score form: cluster variance evaluated at the null-restricted residuals (weakiv convention)
    Cm = np.column_stack([np.ones(len(D)), D[ctrl].to_numpy(float)]); wv_ = D[W].to_numpy(float); sw_ = np.sqrt(wv_)
    def _res(v):
        return v * sw_ - (Cm * sw_[:, None]) @ np.linalg.lstsq(Cm * sw_[:, None], v * sw_, rcond=None)[0]
    zt_ = _res(D[Z].to_numpy(float)); xt_ = _res(D[X].to_numpy(float)); yt_ = _res(D[Y].to_numpy(float))
    cl_ = D[CL].to_numpy()
    lm = []
    for b0 in grid:
        sc = zt_ * (yt_ - b0 * xt_)
        gs = pd.Series(sc).groupby(cl_).sum().to_numpy()
        lm.append(sc.sum() ** 2 / np.sum(gs ** 2))
    lm = np.array(lm); acc_lm = grid[lm <= stats.chi2.ppf(0.95, 1)]
    add("weak_IV", spec, "AR 95% CI lower, score form (null-imposed cluster variance)", acc_lm.min(), lo_ref, "Stata weakiv (same grid)")
    add("weak_IV", spec, "AR 95% CI upper, score form (null-imposed cluster variance)", acc_lm.max(), hi_ref, "Stata weakiv (same grid)")
    ar_curves[spec] = (grid, stat, lm)
    connected = bool(np.all(np.diff(np.where(stat <= stats.chi2.ppf(0.95, 1))[0]) == 1))
    add("weak_IV", spec, "AR set is a single bounded interval (1=yes)", float(connected))
    # (d) StatsPAI built-in AR CI: no weights / no clusters -> reported for contrast only
    try:
        ci = sp.anderson_rubin_ci(Y, X, [Z], exog=ctrl, data=D)
        add("weak_IV", spec, "sp.anderson_rubin_ci lower (UNWEIGHTED, homoskedastic)", float(ci.lower), note="gap: no weights/cluster")
        add("weak_IV", spec, "sp.anderson_rubin_ci upper (UNWEIGHTED, homoskedastic)", float(ci.upper), note="gap: no weights/cluster")
    except Exception as e:
        add("weak_IV", spec, "sp.anderson_rubin_ci error", np.nan, note=f"{type(e).__name__}: {e}"[:200])
    # (e) StatsPAI iv_diag bundle (clustered; sqrt-w transform with extra intercept)
    try:
        dg = sp.iv_diag(t, y=Y, endog=X, instruments=[Z], exog=["sw"] + ctrl, cluster=CL, n_boot=0, random_state=1)
        add("weak_IV", spec, "sp.iv_diag effective F (sqrt-w transform)", float(dg.effective_F), rnum(spec, "F_eff"), "Stata weakivtest")
        tab = dg.to_frame()
        tab.to_csv(OUT / f"iv_diag_{spec}.csv")
    except Exception as e:
        add("weak_IV", spec, "sp.iv_diag error", np.nan, note=f"{type(e).__name__}: {e}"[:200])

# ============ 2. WRE wild cluster bootstrap ==================================
for spec, ctrl in SPECS.items():
    t = sqrtw(D, [X, Z, Y] + ctrl)
    try:
        r = sp.ivreg(f"{Y} ~ ({X} ~ {Z}) + sw + " + " + ".join(ctrl) + " - 1", data=t, cluster=CL,
                     vce="wild", wild_reps=9999, seed=20130601)
        add("wild_bootstrap", spec, "WRE 95% CI lower (sp.ivreg vce='wild', 9999 Rademacher)", float(r.conf_int_lower[X]),
            rnum(spec, "wre_ci_lo"), "Stata boottest (9999 reps)")
        add("wild_bootstrap", spec, "WRE 95% CI upper", float(r.conf_int_upper[X]), rnum(spec, "wre_ci_hi"), "Stata boottest (9999 reps)")
        add("wild_bootstrap", spec, "WRE p-value (H0: beta=0)", float(r.pvalues[X]), rnum(spec, "wre_p"), "Stata boottest")
    except Exception as e:
        add("wild_bootstrap", spec, "sp.ivreg vce='wild' error", np.nan, note=f"{type(e).__name__}: {e}"[:200])
for spec in ("c6u",):
    try:
        r = sp.ivreg(f"{Y} ~ ({X} ~ {Z}) + " + " + ".join(FULL), data=D, cluster=CL, vce="wild", wild_reps=9999, seed=20130601)
        add("wild_bootstrap", spec, "UNWEIGHTED WRE 95% CI lower (sp.ivreg vce='wild')", float(r.conf_int_lower[X]), rnum(spec, "wre_ci_lo"),
            "Stata boottest (unweighted)", "sp CI = null-imposed bootstrap-t percentiles around beta_hat, boottest inverts the test")
        add("wild_bootstrap", spec, "UNWEIGHTED WRE 95% CI upper", float(r.conf_int_upper[X]), rnum(spec, "wre_ci_hi"), "Stata boottest (unweighted)")
        add("wild_bootstrap", spec, "UNWEIGHTED WRE p-value", float(r.pvalues[X]), rnum(spec, "wre_p"), "Stata boottest (unweighted)")
    except Exception as e:
        add("wild_bootstrap", spec, "sp.ivreg vce='wild' error", np.nan, note=f"{type(e).__name__}: {e}"[:200])

# ============ 3. shift-share inference (AKM) =================================
BHJ = EXT / "bhj_shift_share/ADH/Data"
loc = pd.read_stata(BHJ / "location_level.dta").sort_values(["czone", "year"]).reset_index(drop=True)
sh = pd.read_stata(BHJ / "Lshares.dta"); sk = pd.read_stata(BHJ / "shocks.dta")
sh["col"] = sh.year.astype(int).astype(str) + "_" + sh.sic87dd.astype(int).astype(str)
S = sh.pivot_table(index=["czone", "year"], columns="col", values="ind_share", fill_value=0.0).sort_index()
sk["col"] = sk.year.astype(int).astype(str) + "_" + sk.sic87dd.astype(int).astype(str)
g = sk.set_index("col")["g"].reindex(S.columns)
Smat = S.to_numpy()
zc = Smat @ g.to_numpy()
add("shift_share", "data", "max |S g - ADH instrument| (BHJ shares x shocks)", float(np.abs(zc - D[Z].to_numpy()).max()), 0.0, "ADH workfile")
CTRL_BHJ = ["t2", "reg_midatl", "reg_encen", "reg_wncen", "reg_satl", "reg_escen", "reg_wscen", "reg_mount", "reg_pacif",
            "l_sh_popedu_c", "l_sh_popfborn", "l_sh_empl_f", "l_sh_routine33", "l_task_outsource", "l_shind_manuf_cbp"]
Zc = np.column_stack([np.ones(len(loc)), loc[CTRL_BHJ].to_numpy(float)])


def drop_collinear(M, tol=1e-7):
    _, Rq, piv = sla.qr(M, mode="economic", pivoting=True)
    d = np.abs(np.diag(Rq)); rank = int((d > tol * d[0]).sum())
    return np.sort(piv[:rank])


def wls_resid(yv, M, w):
    sw = np.sqrt(w); b = np.linalg.lstsq(M * sw[:, None], yv * sw, rcond=None)[0]
    return yv - M @ b, b


def akm(y1, y2, x, Wsh, Zc, w=None, sector=None, alpha=0.05):
    """Faithful port of ShiftShareSE::ivreg_ss.fit (AKM and AKM0)."""
    w = np.ones(len(y1)) if w is None else np.asarray(w, float)
    ddX, _ = wls_resid(x, Zc, w); ddY1, _ = wls_resid(y1, Zc, w); ddY2, _ = wls_resid(y2, Zc, w)
    _, hX = wls_resid(ddX, Wsh, w)
    mm = np.column_stack([x, Zc])
    r1, b1 = wls_resid(y1, mm, w); r2, b2 = wls_resid(y2, mm, w)
    beta = b1[0] / b2[0]; resid = r1 - r2 * beta
    RX = np.sum(w * ddY2 * ddX)
    u = w * resid * ddX
    se_ehw = np.sqrt(u @ u / RX ** 2)
    cR = hX * ((w * resid) @ Wsh); cW = hX * ((w * ddY2) @ Wsh)
    if sector is not None:
        cR = pd.Series(cR).groupby(sector).sum().to_numpy(); cW = pd.Series(cW).groupby(sector).sum().to_numpy()
    se_akm = np.sqrt(np.sum(cR ** 2) / RX ** 2)
    cv = stats.norm.ppf(1 - alpha / 2)
    Q = RX ** 2 / cv ** 2 - np.sum(cW ** 2); Q2 = np.sum(cR * cW) / Q
    mid = beta - Q2; dis = Q2 ** 2 + np.sum(cR ** 2) / Q
    lo, hi = (mid - np.sqrt(dis), mid + np.sqrt(dis)) if Q > 0 else (-np.inf, np.inf)
    return dict(beta=beta, se_ehw=se_ehw, se_akm=se_akm, akm0_lo=lo, akm0_hi=hi)


keep = drop_collinear(Smat)
Wsh = Smat[:, keep]
sic3_all = (S.columns.str.split("_").str[1].astype(int) // 10).to_numpy()
refR = pd.read_csv(OUT / "akm_reference_R.csv").set_index("case")
bhj_c2 = {"se_akm": 0.126490818972574, "akm0_lo": -1.01807610988811, "akm0_hi": -0.361822342536264}
cases = {"BHJshares_weighted_sic3": (loc.wei.to_numpy(), sic3_all[keep]),
         "BHJshares_weighted_nocluster": (loc.wei.to_numpy(), None),
         "BHJshares_unweighted_nocluster": (None, None)}
for case, (w, sec) in cases.items():
    a = akm(loc.y.to_numpy(float), loc.x.to_numpy(float), loc.z.to_numpy(float), Wsh, Zc, w, sec)
    for k in ("beta", "se_ehw", "se_akm", "akm0_lo", "akm0_hi"):
        add("shift_share_AKM", case, f"{k} (Python port of ShiftShareSE, shares from sp-ready matrix)", float(a[k]),
            float(refR.loc[case, k]), "R ShiftShareSE 1.1.0")
    if case == "BHJshares_weighted_sic3":
        for k, v in bhj_c2.items():
            add("shift_share_AKM", case, f"{k} vs BHJ (2022) Table C2 col 1", float(a[k]), v, "BHJ replication output")
    AKM_MAIN = a if case == "BHJshares_weighted_sic3" else globals().get("AKM_MAIN")

# StatsPAI built-ins (no weights, no sector clusters) vs unweighted reference
ctrl6 = CTRL_BHJ
dfu = loc[["y", "x", "z", "clus"] + ctrl6].copy()
try:
    est = sp.BartikIV(dfu, y="y", endog="x", shares=S.reset_index(drop=True), shocks=g, covariates=ctrl6, leave_one_out=False)
    res = est.fit()
    add("shift_share_statspai", "unweighted", "sp.BartikIV beta", float(res.params["x"]), float(refR.loc["BHJshares_unweighted_nocluster", "beta"]), "R ShiftShareSE")
    add("shift_share_statspai", "unweighted", "sp.BartikIV HC1 SE", float(res.std_errors["x"]), float(refR.loc["BHJshares_unweighted_nocluster", "se_ehw"]), "R ShiftShareSE EHW (no dof adj.)")
    ss = sp.shift_share_se(res, shares=Smat)
    add("shift_share_statspai", "unweighted", "sp.shift_share_se AKM SE", float(ss.diagnostics["SE (AKM)"]),
        float(refR.loc["BHJshares_unweighted_nocluster", "se_akm"]), "R ShiftShareSE", "BUG: uses fitted values as instrument")
    agg = sp.ssaggregate(dfu, y="y", x="x", shares=Smat, shocks=g.to_numpy(), controls=ctrl6)
    add("shift_share_statspai", "unweighted", "sp.ssaggregate beta", float(agg.params["x"]), float(refR.loc["BHJshares_unweighted_nocluster", "beta"]), "R ShiftShareSE")
    add("shift_share_statspai", "unweighted", "sp.ssaggregate AKM SE", float(agg.diagnostics["SE (AKM)"]),
        float(refR.loc["BHJshares_unweighted_nocluster", "se_akm"]), "R ShiftShareSE", "BUG: omits shock-level projection of the instrument")
except Exception as e:
    add("shift_share_statspai", "unweighted", "StatsPAI shift-share error", np.nan, note=f"{type(e).__name__}: {e}"[:200])

# ============ 4. BHJ shock-level equivalent IV ===============================
ind = pd.read_stata(BHJ / "industry_level_ext.dta")
ind["sic3"] = ind["sic3"].astype(int)
bhj_ref = {("c1", "b"): -0.596, ("c1", "se"): 0.114, ("c3", "b"): -0.267, ("c3", "se"): 0.099,
           ("c1", "F"): 185.586, ("c3", "F"): 123.638}
for col, d_, rhs in [("c1", ind, "1"), ("c3", ind[ind.sic87dd != 0], "year")]:
    n = col[-1]
    r = sp.feols(f"y{n} ~ {rhs} | x{n} ~ g", data=d_, weights="s_n", vcov={"CRV1": "sic3"}, ssc=SSC_IVREGRESS)
    add("BHJ_shock_level", col, "beta (industry-level IV, weights s_n)", float(r.params[f"x{n}"]), bhj_ref[(col, "b")], "BHJ (2022) Table 4")
    add("BHJ_shock_level", col, "SE clustered by SIC3", float(r.std_errors[f"x{n}"]), bhj_ref[(col, "se")], "BHJ (2022) Table 4")
    f = sp.feols(f"x{n} ~ {rhs} | z{n} ~ g", data=d_, weights="s_n", vcov={"CRV1": "sic3"}, ssc=SSC_IVREGRESS)
    add("BHJ_shock_level", col, "shock-level first-stage F ((b/se)^2 of x on z instrumented by g)", float(f.tvalues[f"z{n}"]) ** 2, bhj_ref[(col, "F")], "BHJ (2022) Table 4")

# ============ 5. GPSS Rotemberg weights ======================================
wv = loc.wei.to_numpy(float); sw = np.sqrt(wv)
Mres = lambda v: wls_resid(v, Zc, wv)[0]
xt, yt = Mres(loc.x.to_numpy(float)), Mres(loc.y.to_numpy(float))
num_x = (Smat * wv[:, None]).T @ xt        # s_k' W M x
num_y = (Smat * wv[:, None]).T @ yt
gk = g.to_numpy(float)
alpha = gk * num_x / np.sum(gk * num_x)
beta_k = np.where(np.abs(num_x) > 1e-12, num_y / np.where(num_x == 0, 1, num_x), np.nan)
rot = pd.DataFrame({"col": S.columns, "alpha": alpha, "g": gk, "beta_k": beta_k})
rot["year"] = rot.col.str[:4].astype(int); rot["sic87dd"] = rot.col.str[5:].astype(int)
_ai = rot.groupby("sic87dd").alpha.sum()
add("rotemberg", "c6_weighted", "sum of negative alpha_k (industry-collapsed)", float(_ai[_ai < 0].sum()), -0.067, "GPSS (2020) Table (ADH) panel A")
add("rotemberg", "c6_weighted", "sum of positive alpha_k (industry-collapsed)", float(_ai[_ai > 0].sum()), 1.067, "GPSS (2020) Table (ADH) panel A")
add("rotemberg", "c6_weighted", "sum of negative alpha_k (industry x period)", float(rot.alpha[rot.alpha < 0].sum()), note="GPSS panel A uses industry-collapsed weights")
add("rotemberg", "c6_weighted", "sum alpha_k, 1990 shocks", float(rot.alpha[rot.year == 1990].sum()), 0.017, "GPSS panel C")
add("rotemberg", "c6_weighted", "sum alpha_k, 2000 shocks", float(rot.alpha[rot.year == 2000].sum()), 0.983, "GPSS panel C")
add("rotemberg", "c6_weighted", "alpha-weighted sum of beta_k = 2SLS beta", float(np.nansum(rot.alpha * rot.beta_k)), -0.5963601, "Table 3 col 6")
byind = rot.groupby("sic87dd").alpha.sum().sort_values(ascending=False)
gpss_top = {3571: 0.183, 3944: 0.138, 3651: 0.085, 3661: 0.066, 3577: 0.060}
for s_, v in gpss_top.items():
    add("rotemberg", "c6_weighted", f"alpha (summed over periods), SIC {s_}", float(byind.get(s_, np.nan)), v, "GPSS panel D")
desc = pd.read_stata(EXT / "gpss_bartik_weight/sic_code_desc.dta").set_index("sic")["description"]
top10 = byind.head(10).rename("alpha").to_frame()
top10["description"] = [desc.get(int(s_), "") for s_ in top10.index]
top10.to_csv(OUT / "rotemberg_top10_weighted.csv")
# StatsPAI built-in (unweighted): report its top industries for contrast
try:
    rw = est.rotemberg_weights.copy()
    rw["sic87dd"] = rw.industry.str[5:].astype(int)
    su = rw.groupby("sic87dd").weight.sum().sort_values(ascending=False)
    # manual unweighted check of the same formula
    xt_u = wls_resid(loc.x.to_numpy(float), Zc, np.ones(len(loc)))[0]
    au = gk * (Smat.T @ xt_u); au = au / au.sum()
    add("rotemberg", "c6_unweighted", "max |sp.BartikIV.rotemberg_weights - manual| (unweighted)",
        float(np.max(np.abs(rw.set_index("industry").weight.reindex(S.columns).to_numpy() - au))), 0.0, "manual formula")
    add("rotemberg", "c6_unweighted", f"sp.BartikIV top industry alpha (SIC {su.index[0]}, unweighted)", float(su.iloc[0]),
        note="gap: no weights -> different ranking from GPSS")
except Exception as e:
    add("rotemberg", "c6_unweighted", "sp.BartikIV rotemberg error", np.nan, note=f"{type(e).__name__}: {e}"[:200])

# ============ outputs ==========================================================
out = pd.DataFrame(ROWS)
out.to_csv(OUT / "modern_extensions.csv", index=False)

fig, axes = plt.subplots(1, 3, figsize=(16, 4.6))
for ax, spec in zip(axes[:2], ("c1", "c6")):
    grid, st, lmst = ar_curves[spec]
    ax.plot(grid, st, color="#1f4e79", label="Wald form"); ax.plot(grid, lmst, color="#7f7f7f", label="score form (weakiv)"); ax.legend(frameon=False)
    ax.axhline(stats.chi2.ppf(0.95, 1), ls="--", color="#c0504d")
    ax.set_ylim(0, 40); ax.set_xlabel("beta_0"); ax.set_ylabel("cluster-robust AR statistic")
    ax.set_title(f"Anderson-Rubin, Table 3 {spec}")
tt = top10.iloc[::-1]
axes[2].barh([f"{i} {d[:28]}" for i, d in zip(tt.index, tt.description)], tt.alpha, color="#1f4e79")
axes[2].set_title("Top-10 Rotemberg weights (weighted, col. 6)")
fig.tight_layout(); fig.savefig(OUT / "modern_extensions.png", dpi=150); plt.close(fig)

md = ["# Modern-methods extensions (NOT part of the replication)", "",
      "Headline spec: Table 3, cols 1 and 6. StatsPAI values vs external references.", "",
      "| block | spec | statistic | StatsPAI / Python | reference | abs diff | reference source | note |", "|---|---|---|---|---|---|---|---|"]
for r in out.itertuples():
    f = lambda v: "" if not np.isfinite(v) else f"{v:.5g}"
    md.append(f"| {r.block} | {r.spec} | {r.statistic} | {f(r.statspai)} | {f(r.reference)} | {f(r.abs_diff)} | {r.reference_source} | {r.note} |")
md += ["", "Top-10 Rotemberg-weight industries (weighted, full controls):", "", top10.to_markdown(floatfmt=".3f"),
       "", f"Runtime {time.time() - T0:.0f}s"]
(OUT / "modern_extensions.md").write_text("\n".join(md) + "\n")
print(out.to_string(max_colwidth=70))
print(f"runtime {time.time() - T0:.1f}s")
