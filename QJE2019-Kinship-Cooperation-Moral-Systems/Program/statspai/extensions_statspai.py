#!/usr/bin/env python3.13
"""
Modern-methods EXTENSIONS (not part of the original paper) for Enke (2019 QJE).

  E1  Conley (1999) spatial HAC SEs for the Ethnographic Atlas regressions
      (Table IV), cut-offs 250 / 500 / 1000 / 2000 km, vs language-cluster SEs.
  E2  Oster (2019) delta* and bias-adjusted beta (sp.oster_bounds / oster_delta)
  E3  Cinelli-Hazlett (2020) robustness values (sp.sensemakr)
  E4  E-values for standardized OLS coefficients (sp.evalue, measure="OLS")
  E5  Specification curves over control sets (sp.spec_curve)
  E6  Romano-Wolf step-down FWER adjustment across outcome families (sp.romano_wolf)

Every call is wrapped so that a StatsPAI failure is logged (function, call,
error) to Results/statspai/extensions_api_log.md instead of aborting.

Run:  /usr/local/bin/python3.13 Program/statspai/extensions_statspai.py
"""
from __future__ import annotations

import json
import time
import traceback
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import statspai as sp

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

warnings.filterwarnings("ignore")
ROOT = Path(__file__).resolve().parents[2]
DATA, OUT = ROOT / "Data", ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)
SEED = 20190001
T0 = time.time()
APILOG: list[str] = []


def load(n):
    return pd.read_stata(DATA / n, convert_categoricals=False)


def safe(label, fn, *a, **k):
    try:
        return fn(*a, **k)
    except Exception as e:  # noqa: BLE001
        APILOG.append(f"### {label}\n\n```\n{fn.__name__}(...) -> {type(e).__name__}: {e}\n"
                      f"{traceback.format_exc(limit=3)}\n```\n")
        print("  !!", label, type(e).__name__, str(e)[:200])
        return None


def jsonable(x):
    if isinstance(x, dict):
        return {k: jsonable(v) for k, v in x.items() if not isinstance(v, (pd.DataFrame, pd.Series))}
    if isinstance(x, (np.floating, np.integer)):
        return x.item()
    if isinstance(x, (list, tuple)):
        return [jsonable(v) for v in x]
    return x if isinstance(x, (int, float, str, bool, type(None))) else str(x)


ea = load("EAShort.dta")
CONT = [c for c in ea.columns if c.startswith("cont_")]
cty = load("CountryData.dta")

# =============================================================================
# E1  Conley spatial SEs, Table IV non-bootstrap columns
# =============================================================================
print("E1 Conley")
specs = {
    "IV(3) moral god": ("s_moral_god", ["kinship_score", "small_scale"]),
    "IV(4) moral god +ctrl+cont": ("s_moral_god", ["kinship_score", "small_scale", "s_have_god", "ln_time_obs_ea"] + CONT[:-1]),
    "IV(8) sex taboo": ("s_sex_taboo", ["kinship_score", "small_scale"]),
    "IV(9) sex taboo +ctrl+cont": ("s_sex_taboo", ["kinship_score", "small_scale", "ln_time_obs_ea"] + CONT[:-1]),
    "IV(10) hier. above local": ("s_hierabovelocal", ["kinship_score", "small_scale"]),
    "IV(11) hier. above local +ctrl+cont": ("s_hierabovelocal", ["kinship_score", "small_scale", "ln_time_obs_ea"] + CONT[:-1]),
    "IV(13) village inst.": ("s_hierlocal_village", ["kinship_score", "small_scale"]),
    "IV(14) village inst. +ctrl+cont": ("s_hierlocal_village", ["kinship_score", "small_scale", "ln_time_obs_ea"] + CONT[:-1]),
    "IV(1) violence out-in": ("s_diff_violence", ["kinship_score", "small_scale"]),
    "IV(6) loyalty": ("s_loyalty_local", ["kinship_score", "small_scale"]),
}
rows = []
for lab, (y, xs) in specs.items():
    d = ea.dropna(subset=[y, "lat", "lon", "cluster"] + xs).reset_index(drop=True)
    fml = f"{y} ~ " + " + ".join(xs)
    base = sp.regress(fml, data=d, cluster="cluster")
    rob = sp.regress(fml, data=d, robust="hc1")
    row = dict(spec=lab, N=len(d), coef=base.params["kinship_score"],
               se_cluster=base.std_errors["kinship_score"], se_hc1=rob.std_errors["kinship_score"])
    for km in (250, 500, 1000, 2000):
        r = safe(f"conley {lab} {km}km", sp.conley, rob, d, lat="lat", lon="lon", dist_cutoff=km)
        row[f"se_conley_{km}km"] = float(r.std_errors["kinship_score"]) if r is not None else np.nan
    rows.append(row)
e1 = pd.DataFrame(rows)
e1.to_csv(OUT / "ext_E1_conley_TableIV.csv", index=False)
print(e1.round(3).to_string())

# =============================================================================
# E2-E4  Oster, sensemakr, E-value for headline coefficients
# =============================================================================
print("E2-E4 sensitivity")
cty_cont = [c for c in cty.columns if c.startswith("cont_")]
headline = {
    # label: (data, y, treat, controls, R2-based benchmark)
    "EA moral god (IV 3->4)": (ea, "s_moral_god", "kinship_score", ["small_scale", "s_have_god", "ln_time_obs_ea"] + CONT[:-1]),
    "EA village inst. (IV 13->14)": (ea, "s_hierlocal_village", "kinship_score", ["small_scale", "ln_time_obs_ea"] + CONT[:-1]),
    "EA sex taboo (IV 8->9)": (ea, "s_sex_taboo", "kinship_score", ["small_scale", "ln_time_obs_ea"] + CONT[:-1]),
    "Country trust out-in (VI 1->2)": (cty, "s_diff_trust_out_in", "kinship_score", ["ln_time_obs_ea", "small_scale"] + cty_cont[:-1]),
    "Country trust family (VI 3->4)": (cty, "s_diff_trust_family", "kinship_score", ["ln_time_obs_ea", "small_scale"] + cty_cont[:-1]),
    "Country belief in hell (VII 1->4)": (cty, "s_religion_hell", "kinship_score", ["s_religion_god", "ln_time_obs_ea", "small_scale"] + cty_cont[:-1]),
    "Country revenge punish (X 1->3)": (cty, "s_gps_punish_revenge", "kinship_score", ["ln_time_obs_ea", "small_scale"] + cty_cont[:-1]),
}
sens_rows = []
for lab, (df, y, tr, ctr) in headline.items():
    d = df.dropna(subset=[y, tr] + ctr).reset_index(drop=True)
    short = sp.regress(f"{y} ~ {tr}", data=d, robust="hc1")
    long_ = sp.regress(f"{y} ~ {tr} + " + " + ".join(ctr), data=d, robust="hc1")
    b_s, b_l = float(short.params[tr]), float(long_.params[tr])
    r2_s, r2_l = float(short.diagnostics["R-squared"]), float(long_.diagnostics["R-squared"])
    row = dict(spec=lab, N=len(d), beta_short=b_s, r2_short=r2_s, beta_long=b_l, r2_long=r2_l,
               se_long=float(long_.std_errors[tr]))
    ob = safe(f"oster_bounds {lab}", sp.oster_bounds, beta_short=b_s, r2_short=r2_s, beta_long=b_l,
              r2_long=r2_l, r_max=min(1.0, 1.3 * r2_l), delta=1.0)
    if ob is not None:
        for k in ("delta_for_zero", "beta_adjusted", "robust", "identified_set"):   # delta_for_zero = Oster delta*
            if k in ob:
                row[f"oster_{k}"] = jsonable(ob[k])
        row["oster_raw"] = json.dumps(jsonable(ob))[:400]
    od = safe(f"oster_delta {lab}", sp.oster_delta, d, y=y, x_base=[tr], x_controls=ctr, r_max=min(1.0, 1.3 * r2_l), n_boot=200)
    if od is not None:
        for a in ("delta_star", "lower", "upper", "identified_set"):
            if hasattr(od, a):
                row[f"osterdelta_{a}"] = jsonable(getattr(od, a))
    bm = ["small_scale"] if "small_scale" in ctr else ctr[:1]
    sm = safe(f"sensemakr {lab}", sp.sensemakr, d, y=y, treat=tr, controls=ctr, benchmark=bm)
    if sm is not None:
        row["rv_q"] = jsonable(sm.get("rv_q"))
        row["rv_qa"] = jsonable(sm.get("rv_qa"))
        if isinstance(sm.get("benchmark_table"), pd.DataFrame):
            sm["benchmark_table"].assign(spec=lab).to_csv(OUT / f"ext_E3_sensemakr_benchmark_{len(sens_rows)}.csv", index=False)
    # E-value: effect of moving kinship tightness 0 -> 1 (a full unit), outcome in SD units
    ev = safe(f"evalue {lab}", sp.evalue, estimate=b_l, se=float(long_.std_errors[tr]), measure="OLS", sd=float(d[y].std()))
    if ev is not None:
        for k in ("evalue_estimate", "evalue_ci", "e_value", "e_value_ci", "evalue"):
            if k in ev:
                row[f"E_{k}"] = jsonable(ev[k])
        row["evalue_raw"] = json.dumps(jsonable(ev))[:400]
    sens_rows.append(row)
e2 = pd.DataFrame(sens_rows)
e2.to_csv(OUT / "ext_E2_E4_sensitivity.csv", index=False)
print(e2.drop(columns=[c for c in e2.columns if c.endswith("_raw")]).round(3).to_string())

# =============================================================================
# E5  Specification curves over control sets
# =============================================================================
print("E5 spec curve")
geo = ["abslat", "precip", "tempmean", "rugged"]
ea_sets = [[], ["small_scale"], ["small_scale", "ln_time_obs_ea"], ["small_scale", "ln_time_obs_ea"] + geo,
           ["small_scale", "ln_time_obs_ea"] + CONT[:-1], ["small_scale", "ln_time_obs_ea"] + geo + CONT[:-1],
           ["small_scale", "animalhusbandry", "agriculture"], ["small_scale", "ln_time_obs_ea", "animalhusbandry", "agriculture"] + geo + CONT[:-1]]
sc_rows = []
for y in ["s_moral_god", "s_hierlocal_village", "s_hierabovelocal", "s_sex_taboo"]:
    need = sorted(set(sum(ea_sets, [])) | {y, "kinship_score", "cluster"})
    d = ea.dropna(subset=need).reset_index(drop=True)          # common sample across specs
    res = safe(f"spec_curve {y}", sp.spec_curve, d, y=y, x="kinship_score", controls=ea_sets,
               se_types=["cluster", "hc1"], cluster_var="cluster")
    if res is None:
        continue
    tab = None
    for a in ("results", "specs", "table", "df", "results_df"):
        if hasattr(res, a) and isinstance(getattr(res, a), pd.DataFrame):
            tab = getattr(res, a); break
    if tab is not None:
        tab = tab.assign(outcome=y, N=len(d))
        sc_rows.append(tab)
    if hasattr(res, "plot"):
        fig = safe(f"spec_curve.plot {y}", res.plot)
        f = fig if hasattr(fig, "savefig") else (fig.get_figure() if hasattr(fig, "get_figure") else plt.gcf())
        f.savefig(OUT / f"ext_E5_spec_curve_{y}.png", dpi=130, bbox_inches="tight"); plt.close("all")
cty_sets = [[], ["small_scale"], ["small_scale", "ln_time_obs_ea"], ["small_scale", "ln_time_obs_ea"] + cty_cont[:-1],
            ["small_scale", "ln_time_obs_ea", "malariaindex"], ["small_scale", "ln_time_obs_ea", "lngdp"],
            ["small_scale", "ln_time_obs_ea", "cath00", "muslim00"], ["small_scale", "ln_time_obs_ea", "lngdp", "cath00", "muslim00"] + cty_cont[:-1]]
for y in ["s_diff_trust_out_in", "s_religion_hell", "s_gps_punish_revenge", "s_values_uniform"]:
    need = sorted(set(sum(cty_sets, [])) | {y, "kinship_score"})
    d = cty.dropna(subset=need).reset_index(drop=True)
    res = safe(f"spec_curve {y}", sp.spec_curve, d, y=y, x="kinship_score", controls=cty_sets, se_types=["hc1"])
    if res is None:
        continue
    for a in ("results", "specs", "table", "df", "results_df"):
        if hasattr(res, a) and isinstance(getattr(res, a), pd.DataFrame):
            sc_rows.append(getattr(res, a).assign(outcome=y, N=len(d))); break
    if hasattr(res, "plot"):
        fig = safe(f"spec_curve.plot {y}", res.plot)
        f = fig if hasattr(fig, "savefig") else (fig.get_figure() if hasattr(fig, "get_figure") else plt.gcf())
        f.savefig(OUT / f"ext_E5_spec_curve_{y}.png", dpi=130, bbox_inches="tight"); plt.close("all")
if sc_rows:
    e5 = pd.concat(sc_rows, ignore_index=True)
    e5.to_csv(OUT / "ext_E5_spec_curve.csv", index=False)
    num = e5.select_dtypes("number").columns
    print(e5.groupby("outcome")[[c for c in num if c.lower() in ("coef", "estimate", "beta", "pvalue", "p_value", "p")]].describe().round(3).T.to_string()[:3000])

# =============================================================================
# E6  Romano-Wolf across outcome families
# =============================================================================
print("E6 Romano-Wolf")
rw_out = []
families = {
    "EA institutions & religion (Table IV, baseline spec)": (ea, ["s_moral_god", "s_sex_taboo", "s_hierabovelocal", "s_hierlocal_village"], ["small_scale"], "cluster"),
    "EA institutions (Table IV, no religion/taboo)": (ea, ["s_hierabovelocal", "s_hierlocal_village"], ["small_scale", "ln_time_obs_ea"], "cluster"),
    "Country moral system (Fig. V variables)": (cty, ["s_diff_trust_out_in", "s_religion_hell", "s_values_uniform", "s_mfq_disgusting", "s_diff_shame_guilt_overall", "s_gps_punish_revenge"], [], None),
}
for lab, (df, ys, ctr, cl) in families.items():
    res = safe(f"romano_wolf {lab}", sp.romano_wolf, df, y=ys, x="kinship_score", controls=ctr or None,
               cluster=cl, n_boot=2000, seed=SEED)
    if res is None:
        continue
    tab = None
    for a in ("results", "table", "summary_df", "df"):
        v = getattr(res, a, None)
        if isinstance(v, pd.DataFrame):
            tab = v; break
    if tab is None and hasattr(res, "to_frame"):
        tab = res.to_frame()
    if tab is None:
        tab = pd.DataFrame({"repr": [repr(res)[:2000]]})
    rw_out.append(tab.assign(family=lab))
if rw_out:
    e6 = pd.concat(rw_out, ignore_index=True)
    e6.to_csv(OUT / "ext_E6_romano_wolf.csv", index=False)
    print(e6.to_string()[:4000])

(OUT / "extensions_api_log.md").write_text(
    "# StatsPAI API friction log (extensions)\n\n" + ("\n".join(APILOG) if APILOG else "No exceptions raised.\n"))
print(f"TOTAL extensions runtime {time.time()-T0:.0f}s")
