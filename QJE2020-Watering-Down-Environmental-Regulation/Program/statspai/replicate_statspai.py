#!/usr/bin/env python3.13
"""StatsPAI re-implementation of He, Wang & Zhang (2020, QJE)
"Watering Down Environmental Regulation in China".

Run from anywhere:  python3.13 Program/statspai/replicate_statspai.py

Outputs (Results/statspai/):
  statspai_rd_cells.csv      every rdrobust cell of Tables I, III-VII
                             (native StatsPAI bandwidth AND author-matched bandwidth)
  statspai_table2_did.csv    Table II difference-in-discontinuities
  statspai_table8_costs.csv  Table VIII cost calculation
  figure4_rdplot.png         Figure IV
  figure5_by_year.png        Figure V
  ext_*.csv / ext_*.png      modern-method extensions (NOT replication)

Specification notes (see README.md next to this file):
  * Author: rdrobust y distance_new, masspoints(off) kernel(k) all vce(cluster site_id).
  * StatsPAI's sp.rdrobust has no `masspoints` switch: its MSE bandwidth selector
    always applies the mass-point adjustment (== Stata default masspoints(adjust)).
    The running variable has heavy mass points (787 unique values / 6,224 obs), so
    native bandwidths differ. "matched" cells therefore take h and b from the
    official rdpackages Python `rdrobust.rdbwselect(masspoints='off')` and pass
    them to sp.rdrobust(h=, b=, cluster=) -- the estimator itself is StatsPAI's.
"""
from __future__ import annotations

import contextlib
import io
import re
import warnings
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
import statspai as sp  # noqa: E402

warnings.filterwarnings("ignore")

# --- StatsPAI 1.28.0 workaround -------------------------------------------------
# sp.rdrobust's signature accepts h/b as Tuple[float, float] (asymmetric bandwidths,
# needed for bwselect='certwo'/'msecomb2' cells), and the estimator (_rd_estimate)
# handles tuples, but the input validator _require_positive_float() calls float() on
# the tuple and raises MethodIncompatibility("`h` must be a finite number").
# Patch the validator to validate element-wise. Documented as a bug in Materials/.
import importlib  # noqa: E402
import sys  # noqa: E402

importlib.import_module("statspai.rd.rdrobust")
_sprd = sys.modules["statspai.rd.rdrobust"]  # package re-exports a function of the same name

_orig_pos = _sprd._require_positive_float


def _pos_float_or_pair(value, name):
    if isinstance(value, (tuple, list)) and len(value) == 2:
        return tuple(_orig_pos(v, name) for v in value)
    return _orig_pos(value, name)


_sprd._require_positive_float = _pos_float_or_pair

ROOT = Path(__file__).resolve().parents[2]
PKG = ROOT / "Data" / "Replication Materials"
OUT = ROOT / "Results" / "statspai"
OUT.mkdir(parents=True, exist_ok=True)

KERN = {"tri": "triangular", "epa": "epanechnikov", "uni": "uniform", "uniform": "uniform"}

try:  # official rdpackages port, only used to obtain masspoints='off' bandwidths
    import rdrobust as rdpkg
except ImportError:  # pragma: no cover
    rdpkg = None


# Stata e(h_l,h_r,b_l,b_r) exported by Program/statspai/export_stata_estimates.do (fallback)
_st = ROOT / "Results" / "statspai" / "stata_estimates.csv"
STATA_BW = (pd.read_csv(_st).set_index(["exhibit", "row", "col"]).sort_index() if _st.exists() else None)

# ----------------------------------------------------------------------------
# data helpers
# ----------------------------------------------------------------------------
_cache: dict[str, pd.DataFrame] = {}


def load(rel: str) -> pd.DataFrame:
    if rel not in _cache:
        _cache[rel] = pd.read_stata(PKG / rel, convert_categoricals=False)
    return _cache[rel]


def subset(df: pd.DataFrame, cond: str, y: str) -> pd.DataFrame:
    """Apply a Stata-style `if` condition and drop rows rdrobust would drop."""
    s = df if cond == "1" else df.query(cond.replace("&", " and "))
    # Stata: missing values are +inf, so `x==1` never selects missing; same in pandas
    keep = ["distance_new", y] + (["site_id"] if "site_id" in s.columns else [])
    return s.dropna(subset=keep).copy()


# ----------------------------------------------------------------------------
# spec list: mirrors Program/*/**.do exactly (and export_stata_estimates.do)
# ----------------------------------------------------------------------------
def build_specs() -> list[dict]:
    S: list[dict] = []
    K3 = ["tri", "epa", "uni"]

    def add(ex, row, col, file, y, cond, kern, bw="mserd", mp="off"):
        S.append(dict(exhibit=ex, row=row, col=col, file=file, y=y, cond=cond,
                      kernel=kern, bwselect=bw, masspts=mp))

    for y in ["tfpop_s", "resid1_tfpop_s", "resid2_tfpop_s"]:
        c = 0
        for g in [1, 0]:
            for k in K3:
                c += 1
                add("T1", y, c, "T1_Baseline/tfp_small_QJE_final.dta", y, f"neg_ind0=={g}", k)
    for y in ["resid1_lrze", "resid1_lnv", "resid1_lnl", "resid1_lnk", "resid1_lnm",
              "resid1_lnv_l", "resid1_lnv_k"]:
        c = 0
        for f in ["channels_QJE_final", "channels_Pre_QJE_final"]:
            for k in K3:
                c += 1
                add("T3", y, c, f"T3_Channels/{f}.dta", y, "neg_ind0==1", k)
    for y in ["resid1_hours", "resid1_log_water", "resid1_machine", "resid1_total_capacity"]:
        for c, k in enumerate(K3, 1):
            add("T4", y, c, "T4_Abatement/abatement_QJE_final.dta", y, "1", k)
    for y in ["resid_log_cod", "resid_log_cod_intensity", "resid_log_nh", "resid_log_nh_intensity",
              "resid_log_waste_water", "resid_log_waste_water_intensity"]:
        for c, k in enumerate(K3, 1):
            add("T5", y, c, "T5_Emissions/water_emission_QJE_final.dta", y, "1", k)
    for y in ["resid_log_so2", "resid_log_nox"]:
        for c, k in enumerate(K3, 1):
            add("T5", y, c, "T5_Emissions/air_emission_QJE_final.dta", y, "1", k)
    for c, k in enumerate(K3, 1):
        add("T6", "fee", c, "T6_PE/pwf_QJE_final.dta", "resid1_l_pwf", "1", k, bw="certwo")
    for inc in [1, 0]:
        c = 0
        for g in [1, 0]:
            for k in K3:
                c += 1
                add("T6", f"party_inc{inc}", c, "T6_PE/PE_QJE_final.dta", "resid1_tfpop_s",
                    f"neg_ind0=={g} & party_inc=={inc}", k)
    for a in [1, 0]:
        c = 0
        for g in [1, 0]:
            for k in K3:
                c += 1
                special = a == 1 and g == 0 and k == "uni"
                add("T6", f"automatic{a}", c, "T6_PE/auto_QJE_final.dta", "resid1_tfpop_s",
                    f"neg_ind0=={g} & automatic=={a}", k,
                    bw="msecomb1" if special else "mserd", mp="adjust" if special else "off")
    for var, lev in [("soe", [0, 1]), ("firm_big", [0, 1])]:
        fname = "soe_vs_private_QJE_final" if var == "soe" else "big_vs_small_QJE_final"
        for s in lev:
            c = 0
            for g in [1, 0]:
                for k in ["tri", "epa", "uniform"]:
                    c += 1
                    add("T7", f"{var}{s}", c, f"T7_Burden/{fname}.dta", "resid1_tfpop_s",
                        f"neg_ind0=={g} & {var}=={s}", k)
    for s in [1, 0]:
        c = 0
        for g in [1, 0]:
            for k in ["epa", "tri", "uni"]:  # author's order
                c += 1
                add("T7", f"nsbd{s}", c, "T7_Burden/NSBD_QJE_final.dta", "resid1_tfpop_s",
                    f"neg_ind0=={g} & nsbd_c=={s}", k)
    # published-spec variants (the shipped do-files differ from what the paper reports)
    for y, f in [(v, "water") for v in ["resid_log_cod", "resid_log_cod_intensity", "resid_log_nh",
                                         "resid_log_nh_intensity", "resid_log_waste_water",
                                         "resid_log_waste_water_intensity"]] + [(v, "air") for v in ["resid_log_so2", "resid_log_nox"]]:
        add("T5", f"{y}@msecomb1", 3, f"T5_Emissions/{f}_emission_QJE_final.dta", y, "1", "uni", bw="msecomb1")
    for c, k in enumerate(K3, 1):
        add("T6", "fee@mserd", c, "T6_PE/pwf_QJE_final.dta", "resid1_l_pwf", "1", k)
    return S


# ----------------------------------------------------------------------------
# estimation
# ----------------------------------------------------------------------------
def official_bw(d: pd.DataFrame, y: str, kern: str, bw: str, mp: str):
    """h=(h_l,h_r), b=(b_l,b_r) from the official rdrobust port (masspoints control)."""
    with contextlib.redirect_stdout(io.StringIO()):
        r = rdpkg.rdbwselect(d[y].values, d["distance_new"].values, kernel=KERN[kern],
                             bwselect=bw, cluster=d["site_id"].values, masspoints=mp)
    v = r.bws.values.ravel()
    return (float(v[0]), float(v[1])), (float(v[2]), float(v[3]))


def sp_cell(d: pd.DataFrame, y: str, kern: str, bw: str, h=None, b=None) -> dict:
    kw = dict(y=y, x="distance_new", kernel=KERN[kern], cluster="site_id",
              manipulation_test=False, warn_mass_points=False)
    if h is None:
        kw["bwselect"] = bw
    else:
        kw["h"] = h[0] if isinstance(h, tuple) and h[0] == h[1] else h
        kw["b"] = b[0] if isinstance(b, tuple) and b[0] == b[1] else b
    r = sp.rdrobust(d, **kw)
    mi = r.model_info
    hh = mi["bandwidth_h"]
    bb = mi["bandwidth_b"]
    hl, hr = (hh if isinstance(hh, (tuple, list)) else (hh, hh))
    bl, br = (bb if isinstance(bb, (tuple, list)) else (bb, bb))
    return dict(N=len(d), h_l=hl, h_r=hr, b_l=bl, b_r=br,
                tau_cl=mi["conventional"]["estimate"], se_cl=mi["conventional"]["se"],
                tau_bc=mi["robust"]["estimate"], se_rb=mi["robust"]["se"],
                N_h_l=mi["n_effective_left"], N_h_r=mi["n_effective_right"])


def run_rd_cells() -> pd.DataFrame:
    rows = []
    for s in build_specs():
        d = subset(load(s["file"]), s["cond"], s["y"])
        base = {k: s[k] for k in ["exhibit", "row", "col", "file", "y", "cond", "kernel", "bwselect", "masspts"]}
        nat = sp_cell(d, s["y"], s["kernel"], s["bwselect"])
        rows.append({**base, "version": "statspai_native", **nat})
        if rdpkg is not None or STATA_BW is not None:
            src = "rdrobust_py_masspoints_off"
            try:
                if rdpkg is None:
                    raise RuntimeError("no rdrobust port")
                h, b = official_bw(d, s["y"], s["kernel"], s["bwselect"], s["masspts"])
            except Exception:  # official port crashes (ZeroDivisionError) on some cells
                key = (s["exhibit"], s["row"], s["col"])
                st = STATA_BW.loc[key]
                h, b = (float(st.h_l), float(st.h_r)), (float(st.b_l), float(st.b_r))
                src = "stata_e(h,b)"
            mat = sp_cell(d, s["y"], s["kernel"], s["bwselect"], h=h, b=b)
            rows.append({**base, "version": "statspai_matched", "bw_source": src, **mat})
        print(f"  {s['exhibit']} {s['row']:<34} col{s['col']} {s['kernel']:<7} "
              f"native={nat['tau_cl']:.3f}({nat['se_cl']:.3f}) "
              + f"matched={mat['tau_cl']:.3f}({mat['se_cl']:.3f}) h={mat['h_l']:.3f} [{src}]")
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "statspai_rd_cells.csv", index=False)
    return df


# ----------------------------------------------------------------------------
# Table II: difference in discontinuities (mdrd) = RD(post03) - RD(pre03)
# ----------------------------------------------------------------------------
def parse_mdrd_log(log: Path) -> list[dict]:
    """Pull h, b and the three estimates of each mdrd call from run_original.log."""
    txt = log.read_text(errors="ignore")
    blocks = txt.split("Estimates using local polynomial regression.")[1:]
    out = []
    num = r"(-?\d*\.\d+|-?\d+)"
    for blk in blocks:
        h = re.search(r"BW loc\. poly\. \(h\) \|\s+" + num + r"\s+" + num, blk)
        b = re.search(r"BW bias \(b\) \|\s+" + num + r"\s+" + num, blk)
        conv = re.search(r"Conventional \|\s+" + num + r"\s+" + num, blk)
        bc = re.search(r"Bias-corrected \|\s+" + num + r"\s+" + num, blk)
        rob = re.search(r"Robust \|\s+" + num + r"\s+" + num, blk)
        n = re.search(r"Number of obs =\s+([\d,]+)", blk.replace("\n>", ""))
        ker = re.search(r"Kernel type\s+=\s+(\w+)", blk.replace("\n>   ", "").replace("\n> ", ""))
        if h and conv:
            out.append(dict(h_l=float(h.group(1)), h_r=float(h.group(2)),
                            b_l=float(b.group(1)), b_r=float(b.group(2)),
                            mdrd_conv=float(conv.group(1)), mdrd_se_conv=float(conv.group(2)),
                            mdrd_bc=float(bc.group(1)), mdrd_se_rb=float(rob.group(2)),
                            mdrd_N=int(n.group(1).replace(",", "")) if n else np.nan,
                            mdrd_kernel=ker.group(1) if ker else ""))
    return out


def run_table2() -> pd.DataFrame | None:
    log = ROOT / "Results" / "run_original.log"
    parsed = parse_mdrd_log(log) if log.exists() else []
    if len(parsed) < 6:
        print("  [Table II] mdrd output not found in Results/run_original.log -- run Program/run_original.do first")
        return None
    m = load("T2_MDRD/T2_MDRD.dta")
    rows = []
    for i, (g, k) in enumerate([(1, "tri"), (1, "epa"), (1, "uni"), (0, "tri"), (0, "epa"), (0, "uni")]):
        p = parsed[i]
        d = m[m.neg_ind0 == g].dropna(subset=["resid2_tfpop_s", "distance_new", "post03"])
        res = {}
        for t in [0, 1]:
            s = d[d.post03 == t]
            r = sp.rdrobust(s, y="resid2_tfpop_s", x="distance_new", kernel=KERN[k],
                            h=(p["h_l"], p["h_r"]), b=(p["b_l"], p["b_r"]),
                            manipulation_test=False, warn_mass_points=False)
            res[t] = r.model_info
        conv = res[1]["conventional"]["estimate"] - res[0]["conventional"]["estimate"]
        bc = res[1]["robust"]["estimate"] - res[0]["robust"]["estimate"]
        se_c = float(np.hypot(res[1]["conventional"]["se"], res[0]["conventional"]["se"]))
        se_r = float(np.hypot(res[1]["robust"]["se"], res[0]["robust"]["se"]))
        rows.append(dict(exhibit="T2", row="polluting" if g == 1 else "nonpolluting", col=i + 1,
                         kernel=k, N=len(d), **p, sp_conv=conv, sp_se_conv=se_c, sp_bc=bc, sp_se_rb=se_r))
        print(f"  T2 col{i+1} {k}: mdrd BC={p['mdrd_bc']:.4f} (se {p['mdrd_se_conv']:.4f}) | "
              f"StatsPAI BC={bc:.4f} (se {se_c:.4f})  conv {p['mdrd_conv']:.4f} vs {conv:.4f}")
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "statspai_table2_did.csv", index=False)
    return df


# ----------------------------------------------------------------------------
# Figures
# ----------------------------------------------------------------------------
def stata_pctile(x: np.ndarray, p: float) -> float:
    """Stata's default (_pctile / winsor2) percentile definition."""
    x = np.sort(x[~np.isnan(x)])
    n = len(x)
    P = n * p / 100.0
    i = int(np.floor(P))
    if abs(P - i) < 1e-12:
        return float((x[i - 1] + x[i]) / 2) if 0 < i < n else float(x[min(max(i - 1, 0), n - 1)])
    return float(x[i])


def figure4() -> None:
    d = load("F4_RD/tfp_small_QJE_final.dta").copy()
    lo, hi = stata_pctile(d.resid1_tfpop_s.values, 0.5), stata_pctile(d.resid1_tfpop_s.values, 99.5)
    d.loc[(d.resid1_tfpop_s < lo) | (d.resid1_tfpop_s > hi), "resid1_tfpop_s"] = np.nan  # winsor2 ... trim
    fig, axes = plt.subplots(2, 1, figsize=(6, 8), sharex=True, sharey=True)
    for ax, g, ttl in [(axes[0], 1, "Panel A. TFP in Polluting Industries"),
                       (axes[1], 0, "Panel B. TFP in Non-Polluting Industries")]:
        s = d[(d.neg_ind0 == g) & (d.distance_new.abs() < 10)].dropna(subset=["resid1_tfpop_s"])
        sp.rdplot(s, y="resid1_tfpop_s", x="distance_new", p=3, kernel="uniform", nbins=7,
                  ci_level=0.90, ax=ax, title=ttl, x_label="Distance from Monitoring Station",
                  y_label="Residualized TFP (log)")
    fig.tight_layout()
    fig.savefig(OUT / "figure4_rdplot.png", dpi=150)
    plt.close(fig)


def figure5() -> None:
    g = load("F5_Trend/graph_by_year.dta")
    g = g[g.group == 1].sort_values("year")
    lo, hi = g.b - 1.83 * g.std_err, g.b + 1.83 * g.std_err  # author's multiplier
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.vlines(g.year, lo, hi, colors="red", linestyles="dashed", label="90% CI (b ± 1.83·se, as coded)")
    ax.scatter(g.year, g.b, color="red", zorder=3, label="Estimated coefficient")
    ax.axhline(0, color="black", lw=0.8)
    ax.axvline(2002.5, ls="-.", color="grey")
    ax.axvline(2005.5, ls="--", color="grey")
    ax.set_ylim(-0.8, 1.2)
    ax.set_xlabel("Year")
    ax.set_ylabel("Estimated TFP Effect")
    ax.legend(loc="lower right", fontsize=8)
    fig.tight_layout()
    fig.savefig(OUT / "figure5_by_year.png", dpi=150)
    plt.close(fig)
    g.to_csv(OUT / "figure5_by_year_data.csv", index=False)


# ----------------------------------------------------------------------------
# Table VIII: cost calculation (spreadsheet logic in Python)
# ----------------------------------------------------------------------------
def table8(cells: pd.DataFrame | None, t2: pd.DataFrame | None) -> pd.DataFrame:
    xl = PKG / "T8_Cost_Estimates" / "8_Cost_Estimates.xlsx"
    raw = pd.read_excel(xl, sheet_name=None, header=None)
    a = raw["va_loss_00_07"]
    b = raw["va_loss_2020"]
    # spreadsheet MRS inputs (TFP loss per 1% COD) for the six columns
    mrs_xl = [float(a.iloc[4, j]) for j in (5, 8, 11, 14, 17, 20)]
    # Paper's rounded coefficients: TFP Table I Panel B (tri/epa/uni), Table II (tri/epa/uni);
    # COD Table V Panel A (tri/epa/uni) for both blocks.
    tfp = [0.36, 0.38, 0.34, 0.21, 0.21, 0.20]
    cod = [0.84, 0.75, 0.73, 0.84, 0.75, 0.73]
    # MRS = (1-exp(-b_TFP)) / (1-exp(-b_COD)) / kappa / 100 ; kappa is an undocumented constant
    kappa = [(1 - np.exp(-t)) / (1 - np.exp(-c)) / m / 100 for t, c, m in zip(tfp, cod, mrs_xl)]

    def va_loss(sheet: pd.DataFrame, mrs: float, rows: range, red_col=2, va_col=4) -> float:
        tot = 0.0
        for i in rows:
            red = float(sheet.iloc[i, red_col])
            va = float(sheet.iloc[i, va_col])
            x = mrs * abs(red) * 100
            tot += va * (1 / (1 - x) - 1)
        return tot / 10.0  # 100 million yuan -> billion yuan

    out = []
    for j in range(6):
        out.append(dict(col=j + 1, mrs_xlsx_per10pct=mrs_xl[j] * 10 * 100, kappa=kappa[j],
                        loss_00_07_bn=va_loss(a, mrs_xl[j], range(4, 11)),
                        loss_16_20_bn=va_loss(b, mrs_xl[j], range(4, 9)),
                        annual_16_20_bn=va_loss(b, mrs_xl[j], range(4, 9)) / 5))
    k = float(np.mean(kappa))
    # same calculation with StatsPAI's unrounded matched estimates
    if cells is not None and t2 is not None:
        m = cells[cells.version == "statspai_matched"]
        tfp_sp = [m[(m.exhibit == "T1") & (m.row == "resid1_tfpop_s") & (m.col == c)].tau_cl.iloc[0] for c in (1, 2, 3)]
        cod_sp = [m[(m.exhibit == "T5") & (m.row == "resid_log_cod") & (m.col == c)].tau_cl.iloc[0] for c in (1, 2)]
        # published Table V uniform column (0.73) was produced with bwselect(msecomb1), not the
        # mserd default in the shipped do-file (0.24) -- use the published specification here
        dc = subset(load("T5_Emissions/water_emission_QJE_final.dta"), "1", "resid_log_cod")
        hh, bb = official_bw(dc, "resid_log_cod", "uni", "msecomb1", "off")
        cod_sp.append(sp_cell(dc, "resid_log_cod", "uni", "msecomb1", h=hh, b=bb)["tau_cl"])
        tfp_sp += list(t2[t2.row == "polluting"].sp_bc.values)
        cod_sp += cod_sp
        for j in range(6):
            mrs = (1 - np.exp(-tfp_sp[j])) / (1 - np.exp(-cod_sp[j])) / k / 100
            out[j].update(mrs_statspai_per10pct=mrs * 1000,
                          loss_00_07_bn_statspai=va_loss(a, mrs, range(4, 11)),
                          loss_16_20_bn_statspai=va_loss(b, mrs, range(4, 9)),
                          annual_16_20_bn_statspai=va_loss(b, mrs, range(4, 9)) / 5)
    df = pd.DataFrame(out)
    df.to_csv(OUT / "statspai_table8_costs.csv", index=False)
    print(df.round(3).to_string(index=False))
    return df


# ----------------------------------------------------------------------------
# Extensions (modern RD tools) -- NOT part of the replication
# ----------------------------------------------------------------------------
def extensions(cells: pd.DataFrame | None) -> None:
    base = load("T1_Baseline/tfp_small_QJE_final.dta")
    rows = []
    for g, lab in [(1, "polluting"), (0, "nonpolluting")]:
        d = base[base.neg_ind0 == g].dropna(subset=["resid1_tfpop_s", "distance_new", "site_id"])
        y = "resid1_tfpop_s"
        # (1) conventional vs robust bias-corrected (CCT 2014) inference at matched bandwidth
        if rdpkg is not None:
            h, b = official_bw(d, y, "tri", "mserd", "off")
        else:
            h = b = None
        r = sp.rdrobust(d, y=y, x="distance_new", cluster="site_id", h=h, b=b,
                        manipulation_test=False, warn_mass_points=False).model_info
        rows.append(dict(sample=lab, method="rdrobust conventional (paper)", estimate=r["conventional"]["estimate"],
                         se=r["conventional"]["se"], ci_low=r["conventional"]["ci"][0], ci_high=r["conventional"]["ci"][1],
                         h=r["bandwidth_h"], note="cluster site_id; masspoints off bw"))
        rows.append(dict(sample=lab, method="rdrobust robust bias-corrected", estimate=r["robust"]["estimate"],
                         se=r["robust"]["se"], ci_low=r["robust"]["ci"][0], ci_high=r["robust"]["ci"][1],
                         h=r["bandwidth_h"], note="CCT (2014) RBC CI"))
        # native StatsPAI (mass-point adjusted bandwidth)
        r = sp.rdrobust(d, y=y, x="distance_new", cluster="site_id", manipulation_test=False,
                        warn_mass_points=False).model_info
        rows.append(dict(sample=lab, method="rdrobust native (masspoint-adjusted bw)", estimate=r["conventional"]["estimate"],
                         se=r["conventional"]["se"], ci_low=r["robust"]["ci"][0], ci_high=r["robust"]["ci"][1],
                         h=r["bandwidth_h"], note="CI = robust"))
        # (2) Armstrong-Kolesar honest CI
        try:
            hr = sp.rd_honest(d, y=y, x="distance_new")
            mi = hr.model_info
            rows.append(dict(sample=lab, method="rd_honest (Armstrong-Kolesar)", estimate=hr.estimate, se=hr.se,
                             ci_low=mi["honest_ci"][0], ci_high=mi["honest_ci"][1], h=mi["bandwidth"],
                             note=f"M={mi['M']:.4f} estimated; no cluster option"))
        except Exception as e:  # pragma: no cover
            rows.append(dict(sample=lab, method="rd_honest", note=f"ERROR {e}"))
        # (3) donut RD
        for dn in [0.1, 0.25, 0.5, 1.0]:
            r = sp.rdrobust(d, y=y, x="distance_new", cluster="site_id", donut=dn,
                            manipulation_test=False, warn_mass_points=False).model_info
            rows.append(dict(sample=lab, method=f"donut |x|>{dn} km", estimate=r["conventional"]["estimate"],
                             se=r["conventional"]["se"], ci_low=r["robust"]["ci"][0], ci_high=r["robust"]["ci"][1],
                             h=r["bandwidth_h"], note="native bw; CI = robust"))
        # (4) placebo cutoffs (+-5 km, one-sided samples, as in paper's Appendix E)
        for c0 in [-5.0, 5.0]:
            s = d[d.distance_new < 0] if c0 < 0 else d[d.distance_new >= 0]
            r = sp.rdrobust(s, y=y, x="distance_new", c=c0, cluster="site_id",
                            manipulation_test=False, warn_mass_points=False).model_info
            rows.append(dict(sample=lab, method=f"placebo cutoff {c0:+.0f} km", estimate=r["conventional"]["estimate"],
                             se=r["conventional"]["se"], ci_low=r["robust"]["ci"][0], ci_high=r["robust"]["ci"][1],
                             h=r["bandwidth_h"], note="same-side sample only"))
        # (5) density / manipulation test
        dd = sp.rddensity(base[base.neg_ind0 == g].dropna(subset=["distance_new"]), x="distance_new")
        rows.append(dict(sample=lab, method="rddensity (CJM 2020) p-value", estimate=dd.model_info["density_diff"],
                         se=np.nan, ci_low=np.nan, ci_high=np.nan, h=dd.model_info["bandwidth_left"],
                         note=f"p={dd.pvalue:.3f}"))
        # (6) bandwidth sensitivity with clustering (sp.rdbwsensitivity has no cluster arg)
        grid = []
        for hh in np.arange(1.0, 10.5, 0.5):
            r = sp.rdrobust(d, y=y, x="distance_new", h=float(hh), cluster="site_id",
                            manipulation_test=False, warn_mass_points=False).model_info
            grid.append(dict(sample=lab, h=hh, estimate=r["conventional"]["estimate"], se=r["conventional"]["se"],
                             rb_ci_low=r["robust"]["ci"][0], rb_ci_high=r["robust"]["ci"][1]))
        gdf = pd.DataFrame(grid)
        gdf.to_csv(OUT / f"ext_bw_sensitivity_{lab}.csv", index=False)
        fig, ax = plt.subplots(figsize=(6.5, 4))
        ax.fill_between(gdf.h, gdf.estimate - 1.96 * gdf.se, gdf.estimate + 1.96 * gdf.se, alpha=0.25,
                        label="conventional 95% CI (cluster)")
        ax.plot(gdf.h, gdf.estimate, "o-", label="estimate")
        ax.axhline(0, color="k", lw=0.8)
        ax.set_xlabel("bandwidth h (km)")
        ax.set_ylabel("RD in residualized TFP")
        ax.set_title(f"Table I Panel B, {lab}: bandwidth sensitivity")
        ax.legend(fontsize=8)
        fig.tight_layout()
        fig.savefig(OUT / f"ext_bw_sensitivity_{lab}.png", dpi=150)
        plt.close(fig)
        # (7) robustness grid: kernel x bwselect x polynomial, clustered
        try:
            rt = sp.rd_robustness_table(d, y=y, x="distance_new", cluster="site_id")
            rt.insert(0, "sample", lab)
            rt.to_csv(OUT / f"ext_robustness_table_{lab}.csv", index=False)
        except Exception as e:  # pragma: no cover
            print("  rd_robustness_table failed:", e)
    ext = pd.DataFrame(rows)
    ext.to_csv(OUT / "ext_table1_panelB_modern.csv", index=False)
    print(ext.round(4).to_string(index=False))
    # density plot for polluting firms
    try:
        fig, ax = sp.rdplotdensity(base[base.neg_ind0 == 1].dropna(subset=["distance_new"]), x="distance_new")
        fig.savefig(OUT / "ext_rdplotdensity_polluting.png", dpi=150)
        plt.close(fig)
    except Exception as e:  # pragma: no cover
        print("  rdplotdensity failed:", e)


def main() -> None:
    print(f"statspai {sp.__version__}; official rdrobust port available: {rdpkg is not None}")
    print("[1] RD cells (Tables I, III-VII)")
    cells = run_rd_cells()
    print("[2] Table II difference-in-discontinuities")
    t2 = run_table2()
    print("[3] Figures IV and V")
    figure4()
    figure5()
    print("[4] Table VIII costs")
    table8(cells, t2)
    print("[5] Extensions")
    extensions(cells)
    print("done ->", OUT)


if __name__ == "__main__":
    main()
