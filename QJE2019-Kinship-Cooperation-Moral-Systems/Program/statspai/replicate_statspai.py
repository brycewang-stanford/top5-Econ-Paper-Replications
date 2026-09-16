#!/usr/bin/env python3.13
"""
StatsPAI re-implementation of Enke (2019, QJE) "Kinship, Cooperation, and the
Evolution of Moral Systems".  Replication package: doi:10.7910/DVN/JX1OIU.

Re-estimates every column of main-text Tables III-XI (Table X cols 1-3; cols
4-6 need restricted Gallup data) and re-draws Figures II-IX, starting from the
same .dta files the author's Stata code reads.

Stata -> StatsPAI mapping
  reg y x, cluster(c)          sp.feols("y ~ x", vcov={"CRV1": "c"})
  reg y x, ro                  sp.feols("y ~ x", vcov="hetero")          (HC1)
  reg y x i.isonum             sp.feols("y ~ x | isonum")               (absorbed)
  areg y x, a(match) cl(c)     sp.feols("y ~ x | match", vcov={"CRV1": "c"})
  bs, reps(500): reg ..., cl(c) sp.bootstrap(cluster="c", n_boot=500)   (cluster bootstrap)

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_statspai.py
Outputs: Results/statspai/
"""
from __future__ import annotations

import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import statspai as sp
import pyfixest as pf

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "Data"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)
SEED = 20190001
T0 = time.time()


def load(name: str) -> pd.DataFrame:
    return pd.read_stata(DATA / name, convert_categoricals=False)


ROWS: list[dict] = []


def fit(table, col, fml, df, vcov, key="kinship_score", ssc=None, note=""):
    """Estimate with sp.feols and record the coefficient(s) of interest."""
    kw = {}
    if ssc is not None:
        kw["ssc"] = ssc
    r = sp.feols(fml, data=df, vcov=vcov, **kw)
    keys = [key] if isinstance(key, str) else key
    for k in keys:
        ROWS.append(dict(
            table=table, col=col, term=k, coef=float(r.params[k]),
            se=float(r.std_errors[k]), N=int(r.data_info["nobs"]),
            r2=float(r.diagnostics["R-squared"]), se_type=str(vcov), formula=fml, note=note,
        ))
    return r


def fit_boot(table, col, y, xs, df, cluster, key="kinship_score", reps=500):
    """Stata `bs, reps(500): reg y xs, cluster(c)` = cluster (pairs) bootstrap of OLS.

    Point estimate and N/R2 from the full-sample OLS; SE = sd of the bootstrap
    distribution of the coefficient, resampling whole clusters (sp.bootstrap).
    """
    cols = [y] + xs + [cluster]
    d = df.dropna(subset=cols).copy()
    fml = f"{y} ~ " + " + ".join(xs)
    r = sp.feols(fml, data=d, vcov={"CRV1": cluster})
    keys = [key] if isinstance(key, str) else key
    X = np.column_stack([np.ones(len(d))] + [d[x].to_numpy(float) for x in xs])
    yv = d[y].to_numpy(float)
    names = ["Intercept"] + xs
    out = {}
    for k in keys:
        j = names.index(k)

        def stat(sub, j=j):
            Xs = np.column_stack([np.ones(len(sub))] + [sub[x].to_numpy(float) for x in xs])
            b, *_ = np.linalg.lstsq(Xs, sub[y].to_numpy(float), rcond=None)
            return float(b[j])

        br = sp.bootstrap(d, stat, n_boot=reps, cluster=cluster, seed=SEED)
        se = _boot_se(br)
        out[k] = se
        ROWS.append(dict(
            table=table, col=col, term=k, coef=float(r.params[k]), se=se,
            N=int(r.data_info["nobs"]), r2=float(r.diagnostics["R-squared"]),
            se_type=f"cluster bootstrap({cluster}, {reps})", formula=fml,
            note=f"analytic CRV1 SE = {float(r.std_errors[k]):.4f}",
        ))
    return r, out


def _boot_se(br) -> float:
    for a in ("se", "std_error", "boot_se"):
        if hasattr(br, a):
            return float(getattr(br, a))
    for a in ("boot_distribution", "distribution", "boot_stats", "estimates"):
        if hasattr(br, a):
            return float(np.nanstd(np.asarray(getattr(br, a)), ddof=1))
    raise AttributeError(f"cannot find bootstrap SE in {type(br)}: {dir(br)}")


def cont_fe(df: pd.DataFrame) -> pd.Series:
    """Collapse the seven World Bank region dummies cont_* into one categorical.

    Stata's `reg y x cont_*` keeps rows whose seven dummies are all zero (they
    form the base group, and none of the dummies is dropped because they are not
    collinear with the constant).  We reproduce that by giving all-zero rows
    their own category (code 7); only rows with a missing dummy are dropped.
    """
    c = [x for x in df.columns if x.startswith("cont_")]
    m = df[c].to_numpy(float)
    code = np.where(np.nansum(m, 1) == 0, len(c), np.nanargmax(np.nan_to_num(m), 1)).astype(float)
    code[np.isnan(m).any(1)] = np.nan
    return pd.Series(code, index=df.index)


def stata_age_fe(df):
    # Stata `i.age` : one dummy per distinct age value
    return df["age"]


# =============================================================================
# EA data (Ethnographic Atlas)
# =============================================================================
ea = load("EAShort.dta")
ea["cont"] = cont_fe(ea)
CL = {"CRV1": "cluster"}

# ---- Table III: determinants of kinship tightness ---------------------------
t = "III"
fit(t, 1, "kinship_score ~ s_malariaindex", ea, CL, key="s_malariaindex")
fit(t, 2, "kinship_score ~ small_scale + s_malariaindex", ea, CL, key=["s_malariaindex", "small_scale"])
fit(t, 3, "kinship_score ~ small_scale + s_malariaindex + ln_time_obs_ea | cont", ea, CL, key=["s_malariaindex", "small_scale"])
af = ea[ea["malaria_sample"] == 1]
fit_boot(t, 4, "kinship_score", ["s_malariaindex"], af, "cluster", key="s_malariaindex")
fit_boot(t, 5, "kinship_score", ["s_malariaindex", "small_scale", "ln_time_obs_ea"], af, "cluster", key=["s_malariaindex", "small_scale"])
fit_boot(t, 6, "kinship_score", ["s_distance_mutation"], af, "cluster", key="s_distance_mutation")
fit_boot(t, 7, "kinship_score", ["s_distance_mutation", "small_scale", "ln_time_obs_ea"], af, "cluster", key=["s_distance_mutation", "small_scale"])
fit_boot(t, 8, "kinship_score", ["s_tsi"], af, "cluster", key="s_tsi")
fit_boot(t, 9, "kinship_score", ["s_tsi", "small_scale", "ln_time_obs_ea"], af, "cluster", key=["s_tsi", "small_scale"])
fit_boot(t, 10, "kinship_score", ["s_malariaindex", "s_tsi", "small_scale", "ln_time_obs_ea"], af, "cluster", key=["s_malariaindex", "s_tsi", "small_scale"])
fit_boot(t, 11, "kinship_score", ["s_distance_mutation", "s_tsi", "small_scale", "ln_time_obs_ea"], af, "cluster", key=["s_distance_mutation", "s_tsi", "small_scale"])
print(f"Table III done  {time.time()-T0:.0f}s")

# ---- Table IV: enforcement devices in historical ethnic groups --------------
t = "IV"
fit_boot(t, 1, "s_diff_violence", ["kinship_score", "small_scale"], ea, "cluster")
fit_boot(t, 2, "s_diff_violence", ["kinship_score", "small_scale", "ln_time_obs_ea"], ea, "cluster")
fit(t, 3, "s_moral_god ~ kinship_score + small_scale", ea, CL)
fit(t, 4, "s_moral_god ~ kinship_score + small_scale + s_have_god + ln_time_obs_ea | cont", ea, CL, key=["kinship_score", "s_have_god"])
fit(t, 5, "s_moral_god ~ kinship_score + small_scale + s_have_god + ln_time_obs_ea | isonum", ea, CL, key=["kinship_score", "s_have_god"])
fit_boot(t, 6, "s_loyalty_local", ["kinship_score", "small_scale"], ea, "cluster")
fit_boot(t, 7, "s_loyalty_local", ["kinship_score", "small_scale", "ln_time_obs_ea"], ea, "cluster")
fit(t, 8, "s_sex_taboo ~ kinship_score + small_scale", ea, CL)
fit(t, 9, "s_sex_taboo ~ kinship_score + small_scale + ln_time_obs_ea | cont", ea, CL)
fit(t, 10, "s_hierabovelocal ~ kinship_score + small_scale", ea, CL)
fit(t, 11, "s_hierabovelocal ~ kinship_score + small_scale + ln_time_obs_ea | cont", ea, CL)
fit(t, 12, "s_hierabovelocal ~ kinship_score + small_scale + ln_time_obs_ea | isonum", ea, CL)
fit(t, 13, "s_hierlocal_village ~ kinship_score + small_scale", ea, CL)
fit(t, 14, "s_hierlocal_village ~ kinship_score + small_scale + ln_time_obs_ea | cont", ea, CL)
fit(t, 15, "s_hierlocal_village ~ kinship_score + small_scale + ln_time_obs_ea | isonum", ea, CL)
print(f"Table IV done  {time.time()-T0:.0f}s")

# ---- Table V: neighbouring ethnic groups (match FE) --------------------------
t = "V"
con = load("EA_contiguous.dta")
con = con[con["geodist"] <= 500].copy()
for v in ["moral_god", "hierabovelocal", "hierlocal_village", "have_god"]:
    con[f"s_{v}"] = (con[v] - con[v].mean()) / con[v].std()   # egen std() on the kept sample
# Stata areg counts the absorbed match dummies in the small-sample df correction
AREG = pf.ssc(adj=True, fixef_k="full", cluster_adj=True)
fit(t, 1, "s_moral_god ~ kinship_score + small_scale | match", con, CL, ssc=AREG)
fit(t, 2, "s_moral_god ~ kinship_score + small_scale + ln_time_obs_ea + s_have_god | match", con, CL, ssc=AREG, key=["kinship_score", "s_have_god"])
fit(t, 3, "s_hierabovelocal ~ kinship_score + small_scale | match", con, CL, ssc=AREG)
fit(t, 4, "s_hierabovelocal ~ kinship_score + small_scale + ln_time_obs_ea | match", con, CL, ssc=AREG)
fit(t, 5, "s_hierlocal_village ~ kinship_score + small_scale | match", con, CL, ssc=AREG)
fit(t, 6, "s_hierlocal_village ~ kinship_score + small_scale + ln_time_obs_ea | match", con, CL, ssc=AREG)
print(f"Table V done  {time.time()-T0:.0f}s")

# ---- Table XI: preindustrial development -----------------------------------
t = "XI"
for c, y in [(1, "s_ln_popd"), (3, "s_settlement_patterns"), (5, "s_size_community")]:
    fit(t, c, f"{y} ~ kinship_score", ea, CL)
    fit(t, c + 1, f"{y} ~ kinship_score + small_scale + ln_time_obs_ea | cont", ea, CL, key=["kinship_score", "small_scale"])
print(f"Table XI done  {time.time()-T0:.0f}s")

# =============================================================================
# Country-level and within-country data
# =============================================================================
cty = load("CountryData.dta")
cty["cont"] = cont_fe(cty)
HC1 = "hetero"
wvs = load("WVS_EA_Ind.dta")
# Author uses dum_country* (33 dummies), not isonum (32 codes): one ISO country is split in two.
wd = [c for c in wvs.columns if c.startswith("dum_country")]
wvs["wctry"] = np.argmax(wvs[wd].fillna(0).to_numpy(float), 1)
GR = {"CRV1": "group"}

# ---- Table VI: trust ---------------------------------------------------------
t = "VI"
fit(t, 1, "s_diff_trust_out_in ~ kinship_score", cty, HC1)
fit(t, 2, "s_diff_trust_out_in ~ kinship_score + ln_time_obs_ea + small_scale | cont", cty, HC1)
fit(t, 3, "s_diff_trust_family ~ kinship_score", cty, HC1)
fit(t, 4, "s_diff_trust_family ~ kinship_score + ln_time_obs_ea + small_scale | cont", cty, HC1)
fit(t, 5, "s_diff_trust_out_in ~ kinship_score | wctry + wave", wvs, GR)
fit(t, 6, "s_diff_trust_out_in ~ kinship_score + female + ln_time_obs_ea_e + small_scale | wctry + wave + age", wvs, GR)
fit(t, 7, "s_diff_trust_family ~ kinship_score | wctry + wave", wvs, GR)
fit(t, 8, "s_diff_trust_family ~ kinship_score + female + ln_time_obs_ea_e + small_scale | wctry + wave + age", wvs, GR)

# ---- Table VII: belief in hell ----------------------------------------------
t = "VII"
fit(t, 1, "s_religion_hell ~ kinship_score", cty, HC1)
fit(t, 2, "s_religion_hell ~ kinship_score + s_religion_god", cty, HC1, key=["kinship_score", "s_religion_god"])
fit(t, 3, "s_religion_hell ~ kinship_score + ln_time_obs_ea + small_scale + s_religion_god", cty, HC1, key=["kinship_score", "s_religion_god"])
fit(t, 4, "s_religion_hell ~ kinship_score + ln_time_obs_ea + small_scale + s_religion_god | cont", cty, HC1, key=["kinship_score", "s_religion_god"])
fit(t, 5, "s_religion_hell ~ kinship_score | wctry + wave", wvs, GR)
fit(t, 6, "s_religion_hell ~ kinship_score + s_religion_god | wctry + wave", wvs, GR, key=["kinship_score", "s_religion_god"])
fit(t, 7, "s_religion_hell ~ kinship_score + female + s_religion_god | wctry + wave + age", wvs, GR, key=["kinship_score", "s_religion_god"])
fit(t, 8, "s_religion_hell ~ kinship_score + female + ln_time_obs_ea_e + small_scale + s_religion_god | wctry + wave + age", wvs, GR, key=["kinship_score", "s_religion_god"])
print(f"Tables VI-VII done  {time.time()-T0:.0f}s")

# ---- Table VIII: MFQ migrants ------------------------------------------------
t = "VIII"
mfq = load("MFQ_Ind.dta")
dums = [c for c in mfq.columns if c.startswith("dum_country")]
mfq["ctry"] = np.argmax(mfq[dums].to_numpy(float), 1)          # dum_country* -> one FE id
mfq.loc[mfq[dums].isna().any(axis=1) | (mfq[dums].sum(1) != 1), "ctry"] = np.nan
MC = {"CRV1": "isocode_past"}
mfq["isocode_past_id"] = mfq["isocode_past"].astype("category").cat.codes
MC = {"CRV1": "isocode_past_id"}
IND = "female + corigin_ln_time_obs_ea + corigin_small_scale"
fit(t, 1, f"s_mfq_loyalty ~ corigin_kinship_score + {IND} | ctry + year + age", mfq, MC, key="corigin_kinship_score")
fit(t, 2, f"s_mfq_rights ~ corigin_kinship_score + {IND} | ctry + year + age", mfq, MC, key="corigin_kinship_score")
fit(t, 3, "s_values_uniform ~ corigin_kinship_score | ctry + year", mfq, MC, key="corigin_kinship_score")
fit(t, 4, f"s_values_uniform ~ corigin_kinship_score + {IND} | ctry + year + age", mfq, MC, key="corigin_kinship_score")
fit(t, 5, "s_mfq_disgusting ~ corigin_kinship_score | ctry + year", mfq, MC, key="corigin_kinship_score")
fit(t, 6, f"s_mfq_disgusting ~ corigin_kinship_score + {IND} | ctry + year + age", mfq, MC, key="corigin_kinship_score")
fit(t, 7, "s_mfq_decency ~ corigin_kinship_score | ctry + year", mfq, MC, key="corigin_kinship_score")
fit(t, 8, f"s_mfq_decency ~ corigin_kinship_score + {IND} | ctry + year + age", mfq, MC, key="corigin_kinship_score")
print(f"Table VIII done  {time.time()-T0:.0f}s")

# ---- Table IX: emotions (ISEAR, Google Trends) -------------------------------
t = "IX"
ise = load("ISEAR_ind.dta")
ise["iso_id"] = ise["isocode"].astype("category").cat.codes
IC = {"CRV1": "iso_id"}
fit(t, 1, "s_disgust ~ kinship_score", ise, IC)
fit(t, 2, "s_disgust ~ kinship_score + female | age", ise, IC)
fit(t, 3, "s_disgust ~ kinship_score + female + ln_time_obs_ea + small_scale | age", ise, IC)
fit(t, 4, "s_diff_shame_guilt_overall ~ kinship_score", ise, IC)
fit(t, 5, "s_diff_shame_guilt_overall ~ kinship_score + female | age", ise, IC)
fit(t, 6, "s_diff_shame_guilt_overall ~ kinship_score + female + ln_time_obs_ea + small_scale | age", ise, IC)
gt = load("GTrends.dta")
gt["iso_id"] = gt["isocode"].astype("category").cat.codes
gt["lang"] = gt["language"].astype("category").cat.codes if gt["language"].dtype == object else gt["language"]
fit(t, 7, "s_diff_shame_guilt ~ kinship_score | lang", gt, IC)
fit(t, 8, "s_diff_shame_guilt ~ kinship_score + ln_time_obs_ea + small_scale | lang", gt, IC)

# ---- Table X cols 1-3: punishment (GPS, country level) -----------------------
t = "X"
fit(t, 1, "s_gps_punish_revenge ~ kinship_score", cty, HC1)
fit(t, 2, "s_gps_punish_revenge ~ kinship_score + ln_time_obs_ea + small_scale", cty, HC1)
fit(t, 3, "s_gps_punish_revenge ~ kinship_score + ln_time_obs_ea + small_scale | cont", cty, HC1)
print(f"Tables IX-X done  {time.time()-T0:.0f}s")

res = pd.DataFrame(ROWS)
res.to_csv(OUT / "statspai_main_tables.csv", index=False)

# =============================================================================
# Figures
# =============================================================================
NAVY, MAROON = "#1f3a68", "#8b1a1a"


def binscatter(ax, x, y, nq=20):
    d = pd.DataFrame({"x": x, "y": y}).dropna()
    d["bin"] = pd.qcut(d["x"].rank(method="first"), nq, labels=False)
    b = d.groupby("bin")[["x", "y"]].mean()
    ax.scatter(b["x"], b["y"], color=NAVY)
    slope, icpt = np.polyfit(d["x"], d["y"], 1)
    xs = np.linspace(b["x"].min(), b["x"].max(), 50)
    ax.plot(xs, icpt + slope * xs, color=MAROON)
    return slope


# Figure I: distribution of the kinship tightness index across EA societies (no code in the package)
fig, ax = plt.subplots(figsize=(6, 4))
ax.hist(ea["kinship_score"].dropna(), bins=np.arange(-0.0625, 1.07, 0.125), color=NAVY, edgecolor="white")
ax.set(title=f"Fig. I  Kinship tightness in the EA (N={ea['kinship_score'].notna().sum():,})",
       xlabel="Kinship tightness", ylabel="Number of ethnic groups")
fig.tight_layout(); fig.savefig(OUT / "Figure_1_kinship_histogram.png", dpi=150); plt.close(fig)

fig, axs = plt.subplots(1, 2, figsize=(11, 4.2))
s2 = binscatter(axs[0], ea["small_scale"], ea["kinship_score"])
axs[0].set(title="Fig. II  Kinship tightness and hunter-gatherer subsistence",
           xlabel="Dependence on hunting and gathering", ylabel="Kinship tightness")
s3 = binscatter(axs[1], ea["s_distance_mutation"], ea["kinship_score"], nq=15)
axs[1].set(title="Fig. III  Kinship tightness and sickle-cell distance",
           xlabel="Shortest distance to origin of sickle cell mutation [std.]", ylabel="Kinship tightness")
fig.tight_layout(); fig.savefig(OUT / "Figures_2_3_binscatter.png", dpi=150); plt.close(fig)


def bar_panel(means: pd.DataFrame, labels, title, fname):
    fig, ax = plt.subplots(figsize=(9, 4.2))
    for i, (v, lab) in enumerate(zip(means.index, labels)):
        for j, (tp, colr) in enumerate([(1, NAVY), (2, MAROON)]):
            m, se = means.loc[v, (tp, "mean")], means.loc[v, (tp, "se")]
            ax.bar(3 * i + j, m, color=colr, label=["Tight", "Loose"][j] if i == 0 else None)
            ax.errorbar(3 * i + j, m, yerr=se, color="black", capsize=3)
    ax.axhline(0, color="black", ls="--", lw=0.8)
    ax.set_xticks([3 * i + 0.5 for i in range(len(labels))], labels, fontsize=8)
    ax.set(title=title, ylabel="Average ± s.e.m. (z-scores)"); ax.legend()
    fig.tight_layout(); fig.savefig(OUT / fname, dpi=150); plt.close(fig)


# Figure IV: EA means by tight (>=.25) / loose; s.e. from reg _cons, cluster (bootstrap for two vars)
fig4 = {}
ea["type"] = np.where(ea["kinship_score"] >= .25, 1, np.where(ea["kinship_score"].notna(), 2, np.nan))
f4vars = ["s_diff_violence", "s_moral_god", "s_loyalty_local", "s_sex_taboo", "s_hierlocal_village", "s_hierabovelocal"]
for v in f4vars:
    for tp in (1, 2):
        d = ea[(ea["type"] == tp)].dropna(subset=[v, "cluster"])
        r = sp.feols(f"{v} ~ 1", data=d, vcov=CL)
        se = float(r.std_errors["Intercept"])
        if v in ("s_diff_violence", "s_loyalty_local"):
            br = sp.bootstrap(d, lambda s, v=v: float(s[v].mean()), n_boot=500, cluster="cluster", seed=SEED)
            se = _boot_se(br)
        fig4[(v, tp, "mean")] = float(d[v].mean()); fig4[(v, tp, "se")] = se
f4 = pd.Series(fig4).unstack([1, 2])
f4.to_csv(OUT / "Figure_4_means.csv")
bar_panel(f4, ["Δ Violence\nout- vs in-group", "Moralizing\ngod", "Loyalty\ncommunity", "Purity\nconcerns",
               "Village\ninstitutions", "Global\ninstitutions"], "Fig. IV  Historical moral systems", "Figure_4_overview_ea.png")

# Figure V: country means by type, s.e.m.
cty["type"] = np.where(cty["kinship_score"] >= .25, 1, np.where(cty["kinship_score"].notna(), 2, np.nan))
f5vars = ["s_diff_trust_out_in", "s_religion_hell", "s_values_uniform", "s_mfq_disgusting", "s_diff_shame_guilt_overall", "s_gps_punish_revenge"]
fig5 = {}
for v in f5vars:
    for tp in (1, 2):
        x = cty.loc[cty["type"] == tp, v].dropna()
        fig5[(v, tp, "mean")] = x.mean(); fig5[(v, tp, "se")] = x.std(ddof=1) / np.sqrt(len(x))
f5 = pd.Series(fig5).unstack([1, 2])
f5.to_csv(OUT / "Figure_5_means.csv")
bar_panel(f5, ["Δ Trust\nin- vs out-group", "Belief in\nhell", "Communal vs.\nuniversal", "Disgust",
               "Shame vs.\nguilt", "Revenge vs.\naltr. punishm."], "Fig. V  Contemporary moral systems", "Figure_5_overview_country.png")


def labelled_scatter(ax, d, x, y, lab):
    d = d.dropna(subset=[x, y])
    ax.scatter(d[x], d[y], s=8, color=NAVY)
    for _, r in d.iterrows():
        ax.annotate(r[lab], (r[x], r[y]), fontsize=5)
    b, a = np.polyfit(d[x], d[y], 1)
    xs = np.linspace(d[x].min(), d[x].max(), 50)
    ax.plot(xs, a + b * xs, color=MAROON)
    return b, len(d)


# Figure VI: trust scatter; Figure VIII: PCA kernel
fig, axs = plt.subplots(1, 2, figsize=(11, 4.5))
b6, n6 = labelled_scatter(axs[0], cty, "kinship_score", "s_diff_trust_out_in", "isocode")
axs[0].set(title="Fig. VI  Kinship tightness and in- vs out-group trust", xlabel="Kinship tightness", ylabel="Δ Trust")
pc = cty.dropna(subset=["s_diff_trust_out_in", "s_religion_hell", "s_values_uniform", "s_mfq_disgusting", "s_gps_punish_revenge"]).copy()
Z = pc[["s_diff_trust_out_in", "s_religion_hell", "s_values_uniform", "s_mfq_disgusting", "s_gps_punish_revenge"]]
Zs = (Z - Z.mean()) / Z.std(ddof=1)
evals, evecs = np.linalg.eigh(np.corrcoef(Zs.T))
v1 = evecs[:, -1]; v1 = v1 * np.sign(v1.sum())
pc["communal_kernel"] = Zs.to_numpy() @ v1
cty = cty.merge(pc[["isocode", "communal_kernel"]], on="isocode", how="left")
b8, n8 = labelled_scatter(axs[1], cty, "kinship_score", "communal_kernel", "isocode")
axs[1].set(title="Fig. VIII  Kinship tightness and morality kernel", xlabel="Kinship tightness", ylabel="PCA of moral variables")
fig.tight_layout(); fig.savefig(OUT / "Figures_6_8_scatter.png", dpi=150); plt.close(fig)

# Figure VII: US migrants, disgust by country of origin (>=20 respondents)
us = mfq[mfq["isocode_current"] == "USA"]
g7 = us.groupby("isocode_past").agg(s_mfq_disgusting=("s_mfq_disgusting", "mean"),
                                    corigin_kinship_score=("corigin_kinship_score", "mean"),
                                    no=("s_mfq_disgusting", "count")).reset_index()
g7 = g7[g7["no"] >= 20]
fig, ax = plt.subplots(figsize=(6, 4.5))
b7, n7 = labelled_scatter(ax, g7, "corigin_kinship_score", "s_mfq_disgusting", "isocode_past")
ax.set(title="Fig. VII  Kinship tightness and moral relevance of disgust (US migrants)", xlabel="Kinship tightness", ylabel="Moral relevance of disgust")
fig.tight_layout(); fig.savefig(OUT / "Figure_7_disgust_us.png", dpi=150); plt.close(fig)

# Figure IX: coefficient of kinship tightness on development over time
f9 = cty[(cty["frac_native"] >= .5) & cty["frac_native"].notna()].copy()
years = [1500, 1600] + list(range(1700, 1951, 10))
rows9 = []
for yr in years:
    f9[f"ln_pd{yr}"] = np.log1p(f9[f"popd{yr}"])
    for dv, lab in [(f"ln_pd{yr}", "pd"), (f"urbfrac{yr}", "urbfrac")]:
        r = sp.feols(f"{dv} ~ kinship_score + small_scale", data=f9, vcov="hetero")
        rows9.append(dict(var=lab, year=yr, coef=float(r.params["kinship_score"]),
                          se=float(r.std_errors["kinship_score"]), p=float(r.pvalues["kinship_score"]),
                          N=int(r.data_info["nobs"])))
f9r = pd.DataFrame(rows9); f9r.to_csv(OUT / "Figure_9_coefs.csv", index=False)
fig, axs = plt.subplots(1, 2, figsize=(11, 4.2))
for ax, lab, ttl in [(axs[0], "pd", "Log population density"), (axs[1], "urbfrac", "Urbanization rate")]:
    s = f9r[f9r["var"] == lab]
    ax.plot(s["year"], s["coef"], color=NAVY)
    colors = np.select([s["p"] < .01, s["p"] < .05, s["p"] < .10], ["red", "blue", "magenta"], "green")
    ax.scatter(s["year"], s["coef"], c=colors, zorder=3)
    ax.axhline(0, color="grey", lw=.8)
    ax.set(title=f"Fig. IX  {ttl} and kinship tightness", xlabel="Year", ylabel="Coefficient on kinship tightness")
fig.tight_layout(); fig.savefig(OUT / "Figure_9_development.png", dpi=150); plt.close(fig)

figs = pd.DataFrame([
    dict(figure="II", stat="OLS slope kinship~small_scale (binscatter fit)", value=s2),
    dict(figure="III", stat="OLS slope kinship~s_distance_mutation", value=s3),
    dict(figure="VI", stat="lfit slope trust~kinship", value=b6, N=n6),
    dict(figure="VII", stat="lfit slope disgust~kinship, US migrants", value=b7, N=n7),
    dict(figure="VIII", stat="lfit slope PCA kernel~kinship", value=b8, N=n8),
])
figs.to_csv(OUT / "statspai_figures_summary.csv", index=False)
print(f"Figures done  {time.time()-T0:.0f}s")

# =============================================================================
# Markdown summary of the replication tables
# =============================================================================
def fmt_md(df):
    lines = ["| Table | Col | Term | Coef | SE | N | R2 | SE type |", "|---|---|---|---|---|---|---|---|"]
    for _, r in df.iterrows():
        lines.append(f"| {r.table} | {r.col} | {r.term} | {r.coef:.4f} | {r.se:.4f} | {r.N:,} | {r.r2:.3f} | {r.se_type} |")
    return "\n".join(lines)


(OUT / "statspai_main_tables.md").write_text(
    "# StatsPAI replication: Enke (2019 QJE) main tables\n\n"
    "Generated by `Program/statspai/replicate_statspai.py`.\n\n" + fmt_md(res) + "\n")
print(f"TOTAL replication runtime {time.time()-T0:.0f}s")
