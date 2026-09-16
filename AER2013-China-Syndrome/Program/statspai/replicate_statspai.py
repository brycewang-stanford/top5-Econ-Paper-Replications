"""StatsPAI re-implementation of every main-text table (1-10), Figures 1-2, and
Appendix Tables 1, 3, 4, 5 of Autor, Dorn & Hanson (2013, AER).

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_statspai.py
Output: Results/statspai/estimates_statspai.csv, figure1.png, figure2.png,
        native_iv_crosscheck.csv
"""
from __future__ import annotations

import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statspai as sp

from common import (CL, fit_first_stage, DEMO, FULL, MFG, OUT, REG, TASK, W, fit_iv, fit_ols,
                    load, py_key, stata_pctile, stata_wpctile, wmean_sd)

T0 = time.time()
ROWS: list[dict] = []
X, Z = "d_tradeusch_pw", "d_tradeotch_pw_lag"


def rec(key, b, se=np.nan, n=np.nan, r2=np.nan, stata_key=None, block="main", var=None, log="ipw"):
    ROWS.append(dict(key=key, b=b, se=se, n=n, r2=r2, stata_key=stata_key, stata_block=block,
                     stata_var=var, stata_log=log))


def iv(key, y, ctrl, x=X, z=Z, cond=None, cond_str="", extra_coefs=(), fs=False, log="ipw"):
    r, d, r2 = fit_iv(y, x, z, ctrl, DATA if log == "ipw" else PRE, cond)
    sk = py_key(y, x, z, ctrl, cond_str)
    rec(key, float(r.params[x]), float(r.std_errors[x]), len(d), r2, sk, "main", x, log)
    for c in extra_coefs:
        rec(f"{key}_{c}", float(r.params[c]), float(r.std_errors[c]), len(d), np.nan, sk, "main", c, log)
    if fs:   # first stage, same weights / clusters / (no) small-sample factor
        zs = [z] if isinstance(z, str) else list(z)
        # Published first-stage SEs equal heteroskedasticity-robust (HC1, not clustered) SEs;
        # the state-clustered (ivregress-style, no small-sample factor) SE is kept as an info row.
        rf, dfs, r2f = fit_first_stage(x, zs + list(ctrl), DATA, cond, vcov="HC1")
        rc, _, _ = fit_first_stage(x, zs + list(ctrl), DATA, cond, vcov={"CRV1": CL})
        for k, zz in enumerate(zs, 1):
            kk = f"{key.replace('_c', '_fs_c', 1)}" if len(zs) == 1 and key.startswith("T3") else f"{key}_fs_z{k}"
            rec(kk, float(rf.params[zz]), float(rf.std_errors[zz]), len(dfs), r2f, None)
            rec(kk + "_clusterSE_info", float(rc.params[zz]), float(rc.std_errors[zz]), len(dfs), np.nan, None)
    return r


DATA = load("workfile_china.dta")
PRE = load("workfile_china_preperiod.dta")
LONG = load("workfile_china_long.dta")

# ============================ Table 1 ========================================
imp = load("import_levels.dta").iloc[0]
exp_ = load("export_levels.dta").iloc[0]
tr = load("sic87dd_trade_data.dta")
tot = tr.groupby(["importer", "exporter", "year"]).imports.sum() / 1e6     # thousand $ -> billion $
for yr, eyr in [(1991, 1992), (2000, 2000), (2007, 2007)]:
    rec(f"T1_A_{yr}_c1", imp[f"l_totimp_usch_{yr}"])
    rec(f"T1_A_{yr}_c2", exp_[f"l_totexp_usch_{eyr}"])
    rec(f"T1_A_{yr}_c3", imp[f"l_totimp_uslw_{yr}"])
    rec(f"T1_A_{yr}_c4", imp[f"l_totimp_usce_{yr}"])
    rec(f"T1_A_{yr}_c5", tot["USA", "CAN", yr] + tot["USA", "ROW", yr])        # CAN + rest of world
    rec(f"T1_A_{yr}_c5_pkgvar_ushi", imp[f"l_totimp_ushi_{yr}"])
    rec(f"T1_B_{yr}_c1", imp[f"l_totimp_otch_{yr}"])
    rec(f"T1_B_{yr}_c2", exp_[f"l_totexp_otch_{eyr}"])
    rec(f"T1_B_{yr}_c3", imp[f"l_totimp_otlw_{yr}"])
    rec(f"T1_B_{yr}_c4", imp[f"l_totimp_otce_{yr}"])
    rec(f"T1_B_{yr}_c5", tot["OTH", "CAN", yr] + tot["OTH", "ROW", yr] + tot["OTH", "USA", yr])
    rec(f"T1_B_{yr}_c5_pkgvar_othi", imp[f"l_totimp_othi_{yr}"])

# ============================ Table 2 ========================================
PRE["t1980"] = PRE["t1980"].astype(float); PRE["t2000"] = PRE["t2000"].astype(float)
iv("T2_c1", "d_sh_empl_mfg", [], cond=PRE.yr == 1990, cond_str="yr==1990", log="pre")
iv("T2_c2", "d_sh_empl_mfg", [], cond=PRE.yr == 2000, cond_str="yr==2000", log="pre")
iv("T2_c3", "d_sh_empl_mfg", ["t2000"], cond=PRE.yr >= 1990, cond_str="yr>=1990", log="pre")
XF, ZF = "d_tradeusch_pw_future", "d_tradeotch_pw_lag_future"
iv("T2_c4", "d_sh_empl_mfg", [], XF, ZF, PRE.yr == 1970, "yr==1970", log="pre")
iv("T2_c5", "d_sh_empl_mfg", [], XF, ZF, PRE.yr == 1980, "yr==1980", log="pre")
iv("T2_c6", "d_sh_empl_mfg", ["t1980"], XF, ZF, (PRE.yr >= 1970) & (PRE.yr < 1990), "yr>=1970&yr<1990", log="pre")

# ============================ Table 3 ========================================
T3 = {1: ["t2"], 2: MFG + ["t2"], 3: MFG + REG + ["t2"], 4: MFG + REG + DEMO + ["t2"],
      5: MFG + REG + TASK + ["t2"], 6: MFG + REG + DEMO + TASK + ["t2"]}
for k, ctrl in T3.items():
    iv(f"T3_c{k}", "d_sh_empl_mfg", ctrl, extra_coefs=[c for c in ctrl if c in MFG + DEMO + TASK], fs=True)

# ============================ Table 4 ========================================
POP = ["lnchg_popworkage", "lnchg_popworkage_edu_c", "lnchg_popworkage_edu_nc",
       "lnchg_popworkage_age1634", "lnchg_popworkage_age3549", "lnchg_popworkage_age5064"]
for pan, ctrl in {"A": ["t2"], "B": REG + ["t2"], "C": FULL}.items():
    for k, y in enumerate(POP, 1):
        iv(f"T4_{pan}_c{k}", y, ctrl)

# ============================ Table 5 ========================================
for k, y in enumerate(["lnchg_no_empl_mfg", "lnchg_no_empl_nmfg", "lnchg_no_unempl", "lnchg_no_nilf", "lnchg_no_ssadiswkrs"], 1):
    iv(f"T5_A_c{k}", y, FULL)
for k, y in enumerate(["d_sh_empl_mfg", "d_sh_empl_nmfg", "d_sh_unempl", "d_sh_nilf", "d_sh_ssadiswkrs"], 1):
    iv(f"T5_Ball_c{k}", y, FULL)
for grp, suf in [("Bcol", "_edu_c"), ("Bnc", "_edu_nc")]:
    for k, y in enumerate(["d_sh_empl_mfg", "d_sh_empl_nmfg", "d_sh_unempl", "d_sh_nilf"], 1):
        iv(f"T5_{grp}_c{k}", y + suf, FULL)
for tag, y in [("all", "d_sh_empl"), ("col", "d_sh_empl_edu_c"), ("nc", "d_sh_empl_edu_nc")]:
    iv(f"T5_note_emppop_{tag}", y, FULL)

# ============================ Table 6 ========================================
for pan, stem in [("A", "d_avg_lnwkwage"), ("B", "d_avg_lnwkwage_c"), ("C", "d_avg_lnwkwage_nc")]:
    sfx = ["", "_m", "_f"]
    for k, s in enumerate(sfx, 1):
        iv(f"T6_{pan}_c{k}", stem + s, FULL)

# ============================ Table 7 ========================================
for k, y in enumerate(["lnchg_no_empl_mfg", "lnchg_no_empl_mfg_edu_c", "lnchg_no_empl_mfg_edu_nc",
                       "lnchg_no_empl_nmfg", "lnchg_no_empl_nmfg_edu_c", "lnchg_no_empl_nmfg_edu_nc"], 1):
    iv(f"T7_A_c{k}", y, FULL)
for k, y in enumerate(["d_avg_lnwkwage_mfg", "d_avg_lnwkwage_mfg_c", "d_avg_lnwkwage_mfg_nc",
                       "d_avg_lnwkwage_nmfg", "d_avg_lnwkwage_nmfg_c", "d_avg_lnwkwage_nmfg_nc"], 1):
    iv(f"T7_B_c{k}", y, FULL)

# ============================ Table 8 ========================================
TR = ["totindiv", "taaimp", "unemp", "ssaret", "ssadis", "totmed", "fedinc", "totedu"]
for pan, pre in [("A", "lnchg_trans_"), ("B", "d_trans_")]:
    for k, s in enumerate(TR, 1):
        iv(f"T8_{pan}_c{k}", f"{pre}{s}_pc", FULL)
    iv(f"T8_{pan}_othinc_unreported", f"{pre}othinc_pc", FULL)

# ============================ Table 9 ========================================
HH = ["avg_hhincsum", "avg_hhincwage", "avg_hhincbusinv", "avg_hhinctrans", "med_hhincsum", "med_hhincwage"]
for pan, pre in [("A", "relchg_"), ("B", "d_")]:
    for k, s in enumerate(HH, 1):
        iv(f"T9_{pan}_c{k}", f"{pre}{s}_pc_pw", FULL)

# ============================ Table 10 =======================================
OUT10 = ["d_sh_empl_mfg", "d_sh_empl_nmfg", "d_avg_lnwkwage_mfg", "d_avg_lnwkwage_nmfg",
         "lnchg_trans_totindiv_pc", "relchg_avg_hhincwage_pc_pw"]
PAN10 = {"A": (X, Z), "B": ("d_tradex_usch_pw", "d_tradex_otch_pw_lag"),
         "C": ("d_tradeusch_netinput_pw", ["d_tradeotch_pw_lag", "d_inputotch_pw_lag"]),
         "D": ("d_netimpusch_pw", ["d_tradeotch_pw_lag", "d_expotch_pw_lag"]),
         "F": ("d_nettradefactor_usch_io", ["d_tradefactor_otch_lag_io", "d_expfactor_otch_lag_io"])}
for pan, (xx, zz) in PAN10.items():
    for k, y in enumerate(OUT10, 1):
        iv(f"T10_{pan}_c{k}", y, FULL, xx, zz, fs=(k == 1 and pan != "A"))
    m, s = wmean_sd(DATA[xx], DATA[W]); rec(f"T10_{pan}_meansd", m, s)
for k, y in enumerate(OUT10, 1):      # panel E: OLS reduced form on gravity residual
    r, d, r2 = fit_ols(y, ["d_traderes_pw_lag"] + FULL, DATA)
    rec(f"T10_E_c{k}", float(r.params["d_traderes_pw_lag"]), float(r.std_errors["d_traderes_pw_lag"]), len(d), r2,
        py_key(y, "d_traderes_pw_lag", None, FULL), "main", "d_traderes_pw_lag")
m, s = wmean_sd(DATA["d_traderes_pw_lag"], DATA[W]); rec("T10_E_meansd", m, s)

# ============================ Figure 1 =======================================
f1 = load("figure1_data.dta").query("year>1986 & year<2008")
fig, ax = plt.subplots(figsize=(8, 4.8))
ax.plot(f1.year, f1.impr, "-", color="#1f4e79", label="China import penetration ratio")
ax2 = ax.twinx(); ax2.plot(f1.year, f1.cpsmanufemppop, "--", color="#c0504d", label="Manufacturing employment/Population")
ax.set_xticks(range(1987, 2008, 2)); ax.set_ylabel("Import penetration"); ax2.set_ylabel("Mfg emp / pop")
h = ax.get_legend_handles_labels(); h2 = ax2.get_legend_handles_labels()
ax.legend(h[0] + h2[0], h[1] + h2[1], loc="upper center", frameon=False)
ax.set_title("Figure 1 (StatsPAI replication): Import penetration and US manufacturing employment")
fig.tight_layout(); fig.savefig(OUT / "figure1.png", dpi=160); plt.close(fig)

# ============================ Figure 2 =======================================
def fwl(v, d):  # weighted residual on l_shind_manuf_cbp + constant (avplot)
    r = sp.feols(f"{v} ~ l_shind_manuf_cbp", data=d, weights=W)
    return d[v] - (r.params["Intercept"] + r.params["l_shind_manuf_cbp"] * d["l_shind_manuf_cbp"])

fig, axes = plt.subplots(2, 1, figsize=(7, 10))
for pan, yv, ax in [("A", X, axes[0]), ("B", "d_pct_manuf", axes[1])]:
    r, d, _ = fit_ols(yv, [Z, "l_shind_manuf_cbp"], LONG)
    b, se = float(r.params[Z]), float(r.std_errors[Z])
    rec(f"F2_{pan}", b, se, len(d), np.nan, py_key(yv, Z, None, ["l_shind_manuf_cbp"]), "main", Z, "long")
    ex, ey = fwl(Z, LONG), fwl(yv, LONG)
    ax.scatter(ex, ey, s=4000 * LONG[W], facecolors="none", edgecolors="#1f4e79", linewidths=0.6)
    xs = np.linspace(ex.min(), ex.max(), 10); ax.plot(xs, b * xs, color="#c0504d")
    ax.set_xlabel("Change in predicted import exposure per worker (kUSD), residualized")
    ax.set_ylabel("Change in import exposure per worker" if pan == "A" else "Change % mfg emp in working-age pop")
    ax.set_title(f"Panel {pan}: coef = {b:.2f}, cluster SE = {se:.2f}, t = {b / se:.2f}")
fig.tight_layout(); fig.savefig(OUT / "figure2.png", dpi=160); plt.close(fig)

# ============================ Appendix Table 1 =================================
for yr in (1990, 2000):
    d = DATA[DATA.yr == yr]
    for p in (90, 75, 50, 25, 10):
        rec(f"AT1_{yr}_p{p}", stata_wpctile(d[X], d[W], p))
pop90 = DATA.loc[DATA.yr == 1990, ["czone", "l_popcount"]].sort_values("l_popcount", ascending=False)
top40 = set(pop90.czone.iloc[:40])
for yr in (1990, 2000):
    d = DATA[(DATA.yr == yr) & DATA.czone.isin(top40)].sort_values(X, ascending=False).reset_index(drop=True)
    for rank in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40):
        rec(f"AT1_{yr}_rank{rank}|{d.city[rank - 1]}", float(d[X][rank - 1]))

# ============================ Appendix Table 3 =================================
A3 = DATA.copy()
for nm, var, y0 in [("exposure9000", X, 1990), ("instrument9000", Z, 1990), ("exposure0007", X, 2000), ("instrument0007", Z, 2000)]:
    A3[nm] = A3.czone.map(A3.loc[A3.yr == y0].set_index("czone")[var])
A3["growth"] = A3.exposure0007 / A3.exposure9000
g4 = stata_pctile(A3.loc[A3.yr == 1990, "growth"], 75)
DATA_SAVE = DATA; DATA = A3
strong = (A3.yr == 1990) & (A3.growth > g4)
for pan, (xx, zz) in {"A": ("exposure9000", "instrument9000"), "B": ("exposure0007", "instrument0007")}.items():
    iv(f"AT3_{pan}_c1", "d_sh_empl_mfg", [], xx, zz, strong, "yr==1990&growth>g4")
    iv(f"AT3_{pan}_c2", "d_sh_empl_mfg", MFG, xx, zz, strong, "yr==1990&growth>g4", extra_coefs=MFG)
    iv(f"AT3_{pan}_c3", "d_sh_empl_mfg", [], xx, zz, A3.yr == 1990, "yr==1990")
    iv(f"AT3_{pan}_c4", "d_sh_empl_mfg", MFG, xx, zz, A3.yr == 1990, "yr==1990", extra_coefs=MFG)
rec("AT3_N_strong", int(strong.sum()))
DATA = DATA_SAVE

# ============================ Appendix Table 4 =================================
EXP = [("d_tradeusch_pw", "d_tradeotch_pw_lag"), ("d_tradeuschlw_pw", "d_tradeotchlw_pw_lag"),
       ("d_tradeuschce_pw", "d_tradeotchce_pw_lag"), ("d_tradeusce_pw", "d_tradeotce_pw_lag"),
       ("d_tradeushi_pw", "d_tradeothi_pw_lag")]
for k, (xx, zz) in enumerate(EXP, 1):
    r, d, r2 = fit_ols("d_sh_empl_mfg", [xx] + FULL, DATA)
    rec(f"AT4_A_c{k}", float(r.params[xx]), float(r.std_errors[xx]), len(d), r2, py_key("d_sh_empl_mfg", xx, None, FULL), "main", xx)
    r = iv(f"AT4_B_c{k}", "d_sh_empl_mfg", FULL, xx, zz)
    rf, dfs, _ = fit_first_stage(xx, [zz] + FULL, DATA, vcov="HC1")
    rc, _, _ = fit_first_stage(xx, [zz] + FULL, DATA, vcov={"CRV1": CL})
    rec(f"AT4_fs_c{k}", float(rf.params[zz]), float(rf.std_errors[zz]), len(dfs))
    rec(f"AT4_fs_c{k}_clusterSE_info", float(rc.params[zz]), float(rc.std_errors[zz]), len(dfs))
    m, s = wmean_sd(DATA[xx], DATA[W]); rec(f"AT4_C_c{k}", m, s)

# ============================ Appendix Table 5 =================================
for pan, suf in [("A", ""), ("B", "_m"), ("C", "_f"), ("D", "_age1634"), ("E", "_age3549"), ("F", "_age5064")]:
    for k, stem in enumerate(["d_sh_empl_mfg", "d_sh_empl_nmfg", "d_sh_unempl", "d_sh_nilf"], 1):
        iv(f"AT5_{pan}_c{k}", stem + suf, FULL)

# ============================ save =============================================
est = pd.DataFrame(ROWS)
est["stata_key"] = est.stata_key.astype(str)
est.to_csv(OUT / "estimates_statspai.csv", index=False)

# --- cross-check: StatsPAI native k-class IV (sp.iv) on sqrt(w)-transformed data ---
d = DATA.copy(); sw = np.sqrt(d[W])
cols = ["d_sh_empl_mfg", X, Z] + FULL
t = pd.DataFrame({c: d[c] * sw for c in cols}); t["sw"] = sw; t[CL] = d[CL]
chk = []
for tag, ctrl in [("T3_c1", ["t2"]), ("T3_c6", FULL)]:
    r_ign = sp.iv(f"d_sh_empl_mfg ~ ({X} ~ {Z}) + " + " + ".join(ctrl), data=d, cluster=CL, weights=W)
    r_tr = sp.iv(f"d_sh_empl_mfg ~ ({X} ~ {Z}) + sw + " + " + ".join(ctrl) + " - 1", data=t, cluster=CL)
    chk.append(dict(spec=tag, sp_iv_weights_kw_b=float(r_ign.params[X]), sp_iv_weights_kw_se=float(r_ign.std_errors[X]),
                    sp_iv_sqrtw_b=float(r_tr.params[X]), sp_iv_sqrtw_se=float(r_tr.std_errors[X])))
pd.DataFrame(chk).to_csv(OUT / "native_iv_crosscheck.csv", index=False)
print(pd.DataFrame(chk).to_string())
print(f"{len(est)} estimates written; runtime {time.time() - T0:.1f}s")
