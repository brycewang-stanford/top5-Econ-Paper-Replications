"""Build Results/comparison.md: paper | original Stata (full precision, parsed from
Results/log) | StatsPAI, for every exhibit estimated in replicate_statspai.py."""
from __future__ import annotations

import ast
import re

import numpy as np
import pandas as pd

from common import OUT, ROOT, canon_cmd, lookup, parse_stata_log
from paper_values import AT1_RANKS, P

LOG = ROOT / "Results" / "log"
est = pd.read_csv(OUT / "estimates_statspai.csv")

# ---------------------------------------------------------------- Stata logs
stata = {}
for tag, fn in [("ipw", "czone_analysis_ipw_final.log"), ("pre", "czone_analysis_preperiod.log"),
                ("long", "czone_plot_import_long_final.log")]:
    for c in parse_stata_log(LOG / fn):
        stata.setdefault((tag, canon_cmd(c["cmd"])), c)

txt = (LOG / "czone_analysis_ipw_final.log").read_text(errors="replace")
pct = {}
for yr, block in zip((1990, 2000), re.split(r"-> yr = ", txt)[1:3]):
    for p, v in re.findall(r"^\s*(10|25|50|75|90)%\s+(-?[\d.]+)", block, flags=re.M):
        pct[f"AT1_{yr}_p{p}"] = float(v)
imp_log = (LOG / "import_stats_final.log").read_text(errors="replace")
t1_stata = {}
for kind, v, yr, mean in re.findall(r"(imports|exports) (\w+), year (\d+).*?\n.*?\n.*?-+\n\s*\S+\s+\|\s+\d+\s+(-?[\d.]+)", imp_log, flags=re.S):
    t1_stata[(kind, v, int(yr))] = float(mean)


def stata_val(row):
    key = row["key"]
    if key.startswith("AT1_") and "rank" not in key:
        return pct.get(key, np.nan), np.nan
    if key.startswith("T1_"):
        m = re.match(r"T1_([AB])_(\d+)_c(\d)(?:_pkgvar_(\w+))?", key)
        pan, yr, col, pk = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        ctry = "us" if pan == "A" else "ot"
        v = {1: f"{ctry}ch", 3: f"{ctry}lw", 4: f"{ctry}ce"}.get(col)
        if pk:
            v = pk
        if col == 2:
            return t1_stata.get(("exports", f"{ctry}ch", 1992 if yr == 1991 else yr), np.nan), np.nan
        return (t1_stata.get(("imports", v, yr), np.nan), np.nan) if v else (np.nan, np.nan)
    sk = row["stata_key"]
    if not isinstance(sk, str) or sk in ("None", "nan"):
        return np.nan, np.nan
    c = stata.get((row["stata_log"], ast.literal_eval(sk)))
    if c is None or not c["blocks"]:
        return np.nan, np.nan
    return lookup(c["blocks"][-1], row["stata_var"])


def fs_stata(key):
    """First-stage block of the matching Stata command (ivregress ..., first)."""
    m = re.match(r"(T3)_fs_c(\d)$", key) or re.match(r"(T10_[BCDF])_c1_fs_z(\d)$", key) or re.match(r"(AT4)_fs_c(\d)$", key)
    if not m:
        return np.nan, np.nan
    if key.startswith("T3"):
        main = est.loc[est.key == f"T3_c{m.group(2)}"].iloc[0]; inst_idx = 0
    elif key.startswith("T10"):
        main = est.loc[est.key == key.split("_fs_")[0]].iloc[0]; inst_idx = int(m.group(2)) - 1
    else:
        main = est.loc[est.key == f"AT4_B_c{m.group(2)}"].iloc[0]; inst_idx = 0
    c = stata.get((main.stata_log, ast.literal_eval(main.stata_key)))
    if c is None or len(c["blocks"]) < 2:
        return np.nan, np.nan
    inst = ast.literal_eval(main.stata_key)[2].split()
    order = [z for z in re.search(r"=([^)]+)\)", c["cmd"]).group(1).split()]
    return lookup(c["blocks"][0], order[inst_idx] if inst_idx < len(order) else inst[inst_idx])


def paper_key(key):
    return re.sub(r"_c1_fs_", "_fs_", key)


def decimals(v):
    s = repr(float(v))
    if "e" in s:
        return 3
    return len(s.split(".")[1].rstrip("0")) if "." in s else 0


def status(pv, sv, dec):
    if pv is None or sv is None or np.isnan(sv):
        return "—"
    tol = 0.5 * 10 ** (-dec) + 1e-9
    d = abs(sv - pv)
    return "✅" if d <= tol else ("⚠️" if d <= 2.5 * 10 ** (-dec) else "❌")


def fmt(v, nd=4):
    return "" if v is None or (isinstance(v, float) and np.isnan(v)) else f"{v:.{nd}f}"


LABEL = {
    "T1": "Table 1 — Trade with China (bn 2007 US$)", "T2": "Table 2 — 2SLS by period incl. pre-exposure falsification",
    "T3": "Table 3 — Manufacturing emp/pop, stacked FD 2SLS (+ first stage)", "T4": "Table 4 — Working-age population",
    "T5": "Table 5 — Employment status", "T6": "Table 6 — Wages", "T7": "Table 7 — Mfg vs non-mfg employment & wages",
    "T8": "Table 8 — Transfers", "T9": "Table 9 — Household income", "T10": "Table 10 — Alternative exposure measures",
    "F2": "Figure 2 — First stage / reduced form (long difference 1990–2007)", "AT1": "Appendix Table 1 — Exposure percentiles & ranks",
    "AT3": "Appendix Table 3 — Pre-period test (1990s outcome on 2000s exposure)", "AT4": "Appendix Table 4 — Alternative exporters",
    "AT5": "Appendix Table 5 — Employment status by sex and age",
}

lines, summary = [], {}
for ex, lab in LABEL.items():
    sub = est[est.key.str.match(rf"^{ex}_")]
    if sub.empty:
        continue
    lines += [f"\n## {lab}\n", "| cell | paper b | Stata b | StatsPAI b | \\|Stata−SP\\| | paper SE | Stata SE | StatsPAI SE | N | status |",
              "|---|---|---|---|---|---|---|---|---|---|"]
    for _, r in sub.iterrows():
        key = r.key
        if "rank" in key:
            yr, rk = re.match(r"AT1_(\d+)_rank(\d+)", key).groups()
            city = key.split("|", 1)[1]
            pc, pv = AT1_RANKS[int(yr)][int(rk)]
            st = "✅" if (pc[:3].lower() == city[:3].lower() and abs(r.b - pv) <= 0.005 + 1e-9) else "❌"
            lines.append(f"| {key.split('|')[0]} ({pc} / {city}) | {pv} | (log) | {r.b:.4f} |  |  |  |  |  | {st} |")
            summary.setdefault(ex, []).append(st)
            continue
        if (key.startswith(("T3_fs", "AT4_fs")) or "_fs_z" in key) and "_info" in key:
            sb, ss = fs_stata(key.replace("_clusterSE_info", ""))
        elif key.startswith(("T3_fs", "AT4_fs")) or "_fs_z" in key:
            sb, ss = fs_stata(key)
        else:
            sb, ss = stata_val(r)
        pk = paper_key(key)
        pv = P.get(pk)
        pb, pse = (pv if pv else (None, None))
        stb = status(pb, r.b, decimals(pb)) if pb is not None else "—"
        sts = status(pse, r.se, decimals(pse)) if pse is not None else "—"
        st = "—" if (stb == "—" and sts == "—") else (max([s for s in (stb, sts) if s != "—"], key=["✅", "⚠️", "❌"].index))
        diff = abs(sb - r.b) if not np.isnan(sb) else np.nan
        note = ""
        if "pkgvar" in key or "_info" in key or "unreported" in key or "note" in key or key.endswith("_N_strong"):
            st, note = "info", " (not a published cell)"
        lines.append(f"| {key}{note} | {'' if pb is None else pb} | {fmt(sb)} | {r.b:.4f} | {fmt(diff, 7)} | "
                     f"{'' if pse is None else pse} | {fmt(ss)} | {fmt(r.se)} | {'' if np.isnan(r.n) else int(r.n)} | {st} |")
        if st not in ("—", "info"):
            summary.setdefault(ex, []).append(st)
        r2p = P.get(pk + "_r2")
        if r2p is not None and not np.isnan(r.r2):
            s2 = status(r2p[0], r.r2, 2)
            lines.append(f"| {key} R² | {r2p[0]} |  | {r.r2:.4f} |  |  |  |  |  | {s2} |")
            summary.setdefault(ex, []).append(s2)

head = ["# Comparison: published paper vs original Stata code vs StatsPAI",
        "", "Autor, Dorn & Hanson (2013), AER 103(6). Paper values transcribed from the AER PDF; "
        "\"Stata\" = full-precision coefficients parsed from the logs produced by `Program/run_original.do` "
        "(Stata 18 MP, author code unmodified except paths); \"StatsPAI\" = `Program/statspai/replicate_statspai.py` "
        "(statspai 1.28.0, `sp.feols` IV/OLS with analytic weights `timepwt48`, CRV1 by `statefip`).",
        "", "Status compares StatsPAI with the paper at the paper's reported precision: ✅ identical after rounding; "
        "⚠️ off by ≤2.5 units in the last reported digit (explained below); ❌ larger gap. `info` rows are auxiliary.",
        "", "All 16 esttab tables written by the author's code (`Results/log/*.scsv`) are **byte-identical** to the author's "
        "own 2013 logs shipped in the archive (`Materials/package/author_logs_2013`).",
        "", "## Summary", "", "| exhibit | cells compared | ✅ | ⚠️ | ❌ |", "|---|---|---|---|---|"]
for ex, sts in summary.items():
    head.append(f"| {ex} | {len(sts)} | {sts.count('✅')} | {sts.count('⚠️')} | {sts.count('❌')} |")
tot = sum(summary.values(), [])
head.append(f"| **total** | {len(tot)} | {tot.count('✅')} | {tot.count('⚠️')} | {tot.count('❌')} |")
maxdiff = []
for _, r in est.iterrows():
    if r.key.startswith(("T3_fs", "AT4_fs")) or "_fs_z" in r.key or "rank" in r.key:
        continue
    sb, ss = stata_val(r)
    if not np.isnan(sb) and not r.key.startswith(("T1", "AT1")):
        maxdiff.append((abs(sb - r.b), abs(ss - r.se) if not np.isnan(ss) else 0.0))
md = np.array(maxdiff)
head += ["", f"Stata-vs-StatsPAI agreement over {len(md)} regression coefficients matched to the Stata log: "
         f"max |Δb| = {md[:, 0].max():.2e}, max |ΔSE| = {md[:, 1].max():.2e} (Stata prints 7 significant digits).", ""]
EXPLAIN = """
## Explanation of ⚠️ and ❌ cells

**Standard-error convention (all ✅ cells).** `ivregress 2sls …, vce(cluster statefip)` without `small` applies *no*
finite-sample factor; StatsPAI reproduces it with `sp.feols(..., ssc=pf.ssc(adj=False, cluster_adj=False))`
(pyfixest's default CRV1 factor G/(G−1)·(N−1)/(N−K) would inflate SEs by 1.1–1.6 %, e.g. 0.0688 vs 0.0680 in T3 c1).
OLS (`regress, cluster`) uses the default factor.

**First-stage SEs (Table 3 panel II, App. Table 4).** The published first-stage SEs are *heteroskedasticity-robust (HC1),
not state-clustered*, despite the table notes: HC1 gives 0.0787/0.0864/0.0870 → 0.079/0.086/0.087 (✅), whereas the
clustered SEs printed by the author's own `ivregress …, first` are 0.0802/0.0891/0.0914 and the no-factor cluster SEs are
0.0793/0.0881/0.0900. The clustered values are kept as `*_clusterSE_info` rows. The Table 10 note's first-stage SEs look
cluster-based for some panels (D, z2: HC1 0.074 vs paper 0.08 vs cluster 0.081) and HC1-based for others (B), hence ⚠️.

**R² ⚠️ (T7 A c4, T7 B c1, T9 A c1).** Our weighted R² equals Stata's `e(r2)` (esttab prints 0.345, 0.215, 0.685); the
paper reports 0.35, 0.22, 0.69, i.e. it rounded the already-rounded 3-decimal esttab number (two-step rounding).
The same two-step rounding explains T8 A c8 SE (1.3146 → 1.315 → 1.32), T10 C c3 SE (0.5146 → 0.52), T10 D c5 SE
(0.3449 → 0.35), T10 E c2 SE (0.0747 → 0.08) and App. T4 B c2 SE (0.0955 → 0.096 vs 0.0955). Stata = StatsPAI in all these cells.

**T10 panel E mean (⚠️).** Mean of the gravity residual is 1.425 in the archive vs 1.40 printed (SD 1.78 vs 1.79); the
regression coefficients of panel E all match, so this is a note-level transcription/vintage difference.

**❌ Table 10 panel B (domestic + international exposure, 6 cells).** The archive's `d_tradex_usch_pw` has exactly the
published mean/SD (2.28/2.17) and the first stage is 0.619 (paper 0.61), but the 2SLS coefficients are −0.415, −0.063,
0.199, −0.429, 0.733, −1.375 vs published −0.51, −0.12, 0.16, −0.60, 0.87, −1.77. **The author's own 2013 log
(`Materials/package/author_logs_2013/tab_expoff_iv.scsv`) contains the same archive numbers**, so the published panel was
produced from a different version of the instrument `d_tradex_otch_pw_lag`; not fixable from the public archive.

**❌ Appendix Table 4 column 5 ("all other exporters", 4 cells).** The archive variable `d_tradeushi_pw` has mean/SD
9.04/9.30 vs published 2.73/4.00, and OLS/2SLS/first-stage coefficients differ accordingly (0.021 vs 0.050, −0.031 vs
−0.042, 0.420 vs 0.445). Again identical in the author's 2013 log → archive-vs-paper vintage difference. Columns 1–4 match.

**Table 1 column 5.** The package's `import_stats_final.do` summarises `l_totimp_ushi_*` / `l_totimp_othi_*`
(905.8 / 3339.3 bn), which is **not** the published "imports from rest of world" column. The published values
(322.4, 650.0, 763.1; 723.6, 822.6, 1329.8) are reproduced exactly as Canada + rest-of-world (+ US for panel B) imports
from `sic87dd_trade_data.dta`, so column 5 is ✅ for StatsPAI but not produced by the original code.

**Appendix Table 1 rank 20 (1990).** The paper prints "Forth Worth"; the archive city is "Fort Worth, TX" (value 0.83 ✅).

**Not re-estimated in StatsPAI:** Appendix Table 2 (descriptive means; produced by the original code, spot-checked:
imports/worker 1991 0.29 (0.32) and 2007 3.58 (2.84) match) and Figure 1 (time series plot; re-drawn, no estimates).
"""
(ROOT / "Results" / "comparison.md").write_text("\n".join(head + [EXPLAIN] + lines) + "\n")
print("\n".join(head))
