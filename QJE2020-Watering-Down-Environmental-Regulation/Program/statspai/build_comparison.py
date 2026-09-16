#!/usr/bin/env python3.13
"""Build Results/comparison.md: paper vs original Stata vs StatsPAI, cell by cell.

Inputs: Results/statspai/stata_estimates.csv (export_stata_estimates.do),
        Results/statspai/statspai_rd_cells.csv, statspai_table2_did.csv,
        statspai_table8_costs.csv (replicate_statspai.py).
Paper values were transcribed from the published QJE PDF (pdftotext -layout).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
R = ROOT / "Results" / "statspai"

st = pd.read_csv(R / "stata_estimates.csv")
sp = pd.read_csv(R / "statspai_rd_cells.csv")
spm = sp[sp.version == "statspai_matched"]
spn = sp[sp.version == "statspai_native"]

# ---------------------------------------------------------------------------
# Published values: (coef tuple, se tuple, N, decimals, estimate type)
# est: "cl" = conventional, "bc" = bias-corrected point estimate with conventional SE
# ---------------------------------------------------------------------------
P: list[dict] = []


def add(ex, panel, label, row, cols, b, se, N, dp=2, est="cl", bw=None):
    for i, c in enumerate(cols):
        P.append(dict(exhibit=ex, panel=panel, label=label, row=row, col=c, b=b[i], se=se[i],
                      N=N[i] if isinstance(N, (list, tuple)) else N, dp=dp, est=est,
                      bw=None if bw is None else bw[i]))


# Table I
add("T1", "A: no control", "TFP polluting", "tfpop_s", [1, 2, 3], (.34, .37, .32), (.57, .59, .56), 6224, bw=(4.203, 3.889, 3.622))
add("T1", "A: no control", "TFP nonpolluting", "tfpop_s", [4, 5, 6], (-.03, .04, .01), (.15, .18, .18), 11502, bw=(5.887, 5.168, 4.522))
add("T1", "B: station+industry FE", "TFP polluting", "resid1_tfpop_s", [1, 2, 3], (.36, .38, .34), (.17, .17, .15), 6224, bw=(5.723, 5.523, 5.144))
add("T1", "B: station+industry FE", "TFP nonpolluting", "resid1_tfpop_s", [4, 5, 6], (.03, .04, -.02), (.09, .09, .09), 11502, bw=(5.890, 5.479, 6.091))
add("T1", "C: station x industry FE", "TFP polluting", "resid2_tfpop_s", [1, 2, 3], (.27, .29, .29), (.15, .15, .14), 6224, bw=(4.496, 4.333, 4.689))
add("T1", "C: station x industry FE", "TFP nonpolluting", "resid2_tfpop_s", [4, 5, 6], (.02, .04, .03), (.06, .06, .07), 11502, bw=(5.692, 5.204, 4.430))
# Table III (after 2003: conventional; before 2003: bias-corrected coef with conventional SE)
T3 = [("profit (10k RMB)", "resid1_lrze", (478.59, 441.18, 693.76), (470.49, 524.34, 595.49), (-207.19, -233.60, 250.92), (386.84, 410.51, 494.19)),
      ("value added (log)", "resid1_lnv", (.05, .07, .11), (.19, .19, .18), (-.11, -.09, .03), (.13, .14, .16)),
      ("employees (log)", "resid1_lnl", (-.22, -.19, -.09), (.16, .16, .16), (-.07, .01, .05), (.19, .19, .20)),
      ("capital (log)", "resid1_lnk", (-.40, -.45, -.61), (.22, .27, .29), (-.06, -.04, -.04), (.21, .22, .26)),
      ("intermediate (log)", "resid1_lnm", (-.05, -.04, -.05), (.24, .24, .18), (-.03, -.01, .05), (.16, .16, .20)),
      ("VA/employee (log)", "resid1_lnv_l", (.08, .08, .05), (.08, .08, .08), (.00, .02, .01), (.06, .06, .05)),
      ("VA/capital (log)", "resid1_lnv_k", (.25, .27, .28), (.10, .10, .10), (.04, .04, -.00), (.08, .09, .10))]
for lab, v, b1, s1, b0, s0 in T3:
    add("T3", "after 2003", lab, v, [1, 2, 3], b1, s1, 5520 if v == "resid1_lrze" else None)
    add("T3", "before 2003 (paper reports BC coef)", lab, v, [4, 5, 6], b0, s0, 2282 if v == "resid1_lrze" else None, est="bc")
# Table IV
add("T4", "A", "operating hours", "resid1_hours", [1, 2, 3], (288, 256, 171), (101, 105, 92), 7302, dp=0)
add("T4", "B", "log water input", "resid1_log_water", [1, 2, 3], (.62, .60, .40), (.23, .25, .28), 6606)
add("T4", "C", "# treatment facilities", "resid1_machine", [1, 2, 3], (-1.15, -1.07, -1.29), (.62, .62, .69), 7265)
add("T4", "D", "treatment capacity (t/day)", "resid1_total_capacity", [1, 2, 3], (-7381, -8594, -7849), (3733, 3855, 3714), 4624, dp=0)
# Table V
T5 = [("A", "COD (log)", "resid_log_cod", (.84, .75, .73), (.43, .39, .35), 9797),
      ("A", "COD intensity (log)", "resid_log_cod_intensity", (.77, .70, .84), (.29, .27, .33), 9797),
      ("B", "NH3-N (log)", "resid_log_nh", (.87, .76, .46), (.90, .76, .62), 4772),
      ("B", "NH3-N intensity (log)", "resid_log_nh_intensity", (1.23, 1.01, .73), (.45, .44, .44), 4772),
      ("C", "wastewater (log)", "resid_log_waste_water", (.34, .33, .06), (.31, .33, .26), 9797),
      ("C", "wastewater intensity (log)", "resid_log_waste_water_intensity", (.43, .38, .56), (.21, .20, .26), (9797, 9797, 9796)),
      ("D", "SO2 (log)", "resid_log_so2", (.03, .06, -.16), (.29, .30, .25), 4740),
      ("D", "NOx (log)", "resid_log_nox", (.09, .14, -.05), (.28, .29, .20), 4740)]
for pan, lab, v, b, s, N in T5:
    add("T5", pan, lab, v, [1, 2, 3], b, s, N)
# Table VI
add("T6", "A: double standard", "waste discharge fee (log)", "fee", [1, 2, 3], (-.91, -1.12, -.91), (.44, .45, .48), 3050)
add("T6", "B: strong incentive", "TFP polluting", "party_inc1", [1, 2, 3], (.56, .58, .59), (.20, .20, .20), 5305)
add("T6", "B: strong incentive", "TFP nonpolluting", "party_inc1", [4, 5, 6], (.12, .09, .07), (.13, .14, .10), 9382)
add("T6", "B: weak incentive", "TFP polluting", "party_inc0", [1, 2, 3], (.13, .19, .18), (.19, .25, .27), 2450)
add("T6", "B: weak incentive", "TFP nonpolluting", "party_inc0", [4, 5, 6], (.04, .01, .26), (.19, .19, .22), 4738)
add("T6", "C: automatic stations", "TFP polluting", "automatic1", [1, 2, 3], (1.18, 1.22, 1.21), (.55, .55, .47), 932)
add("T6", "C: automatic stations", "TFP nonpolluting", "automatic1", [4, 5, 6], (-1.07, -.48, -.43), (1.44, .76, .32), 1815)
add("T6", "C: manual stations", "TFP polluting", "automatic0", [1, 2, 3], (.30, .35, .41), (.15, .17, .20), 4953)
add("T6", "C: manual stations", "TFP nonpolluting", "automatic0", [4, 5, 6], (.10, .11, .10), (.08, .08, .08), 9523)
# Table VII
add("T7", "A: ownership", "private, polluting", "soe0", [1, 2, 3], (.45, .48, .43), (.18, .18, .17), 6149)
add("T7", "A: ownership", "private, nonpolluting", "soe0", [4, 5, 6], (.05, .05, .07), (.09, .09, .10), 11510)
add("T7", "A: ownership", "SOE, polluting", "soe1", [1, 2, 3], (-.11, .00, -.01), (.44, .51, .61), 513)
add("T7", "A: ownership", "SOE, nonpolluting", "soe1", [4, 5, 6], (.11, .09, .06), (.35, .33, .41), 1169)
add("T7", "B: size", "small, polluting", "firm_big0", [1, 2, 3], (.06, .13, .17), (.41, .36, .39), 1829)
add("T7", "B: size", "small, nonpolluting", "firm_big0", [4, 5, 6], (-.01, -.04, .04), (.16, .16, .18), 3981)
add("T7", "B: size", "large, polluting", "firm_big1", [1, 2, 3], (.49, .52, .52), (.16, .17, .17), 4818)
add("T7", "B: size", "large, nonpolluting", "firm_big1", [4, 5, 6], (.02, .03, .02), (.11, .11, .10), 8765)
add("T7", "C: SNWD (code kernel order epa/tri/uni)", "SNWD, polluting", "nsbd1", [1, 2, 3], (.89, .69, .94), (.31, .32, .31), 933)
add("T7", "C: SNWD (code kernel order epa/tri/uni)", "SNWD, nonpolluting", "nsbd1", [4, 5, 6], (.17, .23, -.19), (.18, .15, .52), 1429)
add("T7", "C: SNWD (code kernel order epa/tri/uni)", "other, polluting", "nsbd0", [1, 2, 3], (.38, .35, .36), (.19, .18, .18), 4998)
add("T7", "C: SNWD (code kernel order epa/tri/uni)", "other, nonpolluting", "nsbd0", [4, 5, 6], (.13, .11, .11), (.11, .10, .11), 9739)

paper = pd.DataFrame(P)


def pick(df, ex, row, col, est):
    r = df[(df.exhibit == ex) & (df.row == row) & (df.col == col)]
    if r.empty:
        return None
    r = r.iloc[0]
    return dict(b=r.tau_bc if est == "bc" else r.tau_cl, se=r.se_cl, N=r.N, h=r.h_l)


def ok(val, ref, dp):
    if val is None or ref is None or (isinstance(ref, float) and np.isnan(ref)):
        return None
    return abs(round(val, dp) - ref) <= 0.5 * 10 ** (-dp) + 1e-9


def status(val_b, val_se, pb, pse, dp):
    a, s = ok(val_b, pb, dp), ok(val_se, pse, dp)
    if a and s:
        return "✅"
    tol = max(0.02, 0.05 * abs(pb)) if dp == 2 else max(1.0, 0.02 * abs(pb))
    if abs(val_b - pb) <= tol and abs(val_se - pse) <= max(tol, 0.1 * pse):
        return "⚠️"
    return "❌"


def f(x, dp):
    return "" if x is None or (isinstance(x, float) and np.isnan(x)) else f"{x:,.{dp}f}"


VARIANT = {("T5", 3): "@msecomb1", ("T6", None): "@mserd"}
lines: list[str] = []
summary = []
for ex, title in [("T1", "Table I — Upstream–downstream TFP gap"), ("T3", "Table III — Inputs and outputs"),
                  ("T4", "Table IV — Abatement efforts"), ("T5", "Table V — Emissions"),
                  ("T6", "Table VI — Political economy"), ("T7", "Table VII — Heterogeneity")]:
    lines += [f"### {title}", "",
              "| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \\|Δ\\| Stata−paper | status |",
              "|---|---|---|---|---|---|---|---|---|---|"]
    for _, p in paper[paper.exhibit == ex].iterrows():
        dp = int(p.dp)
        s0 = pick(st, ex, p.row, p.col, p.est)
        m0 = pick(spm, ex, p.row, p.col, p.est)
        n0 = pick(spn, ex, p.row, p.col, p.est)
        stat = status(s0["b"], s0["se"], p.b, p.se, dp)
        alt = ""
        # published-spec variants for cells where the shipped code differs from the paper
        vrow = None
        if ex == "T5" and p.col == 3:
            vrow = f"{p.row}@msecomb1"
        if ex == "T6" and p.row == "fee":
            vrow = "fee@mserd"
        if vrow is not None and stat != "✅":
            sv = pick(st, ex, vrow, p.col, p.est)
            if sv is not None:
                sv_stat = status(sv["b"], sv["se"], p.b, p.se, dp)
                if sv_stat == "✅":
                    mv = pick(spm, ex, vrow, p.col, p.est)
                    alt = f" → with `{vrow.split('@')[1]}`: Stata {f(sv['b'], dp)} ({f(sv['se'], dp)}), StatsPAI {f(mv['b'], dp)} ({f(mv['se'], dp)})"
                    stat = "⚠️"
                    s_match = mv
        ms = status(m0["b"], m0["se"], p.b, p.se, dp) if m0 else ""
        bw = "" if p.bw is None or (isinstance(p.bw, float) and np.isnan(p.bw)) else f"; paper h={p.bw:.3f}, Stata h={s0['h']:.3f}"
        ncheck = "" if p.N is None or (isinstance(p.N, float) and np.isnan(p.N)) else ("" if int(p.N) == int(s0["N"]) else f" (paper {int(p.N):,})")
        lines.append(f"| {p.panel} | {p.label} | {p.col} | {f(p.b, dp)} ({f(p.se, dp)}) | {f(s0['b'], dp)} ({f(s0['se'], dp)}){alt}{bw} | "
                     f"{int(s0['N']):,}{ncheck} | {f(m0['b'], dp)} ({f(m0['se'], dp)}) | {f(n0['b'], dp)} ({f(n0['se'], dp)}) [{n0['h']:.2f}] | "
                     f"{abs(s0['b'] - p.b):.{max(dp, 2)}f} | {stat} |")
        summary.append(dict(exhibit=ex, status=stat,
                            statspai_vs_stata=abs(m0["b"] - s0["b"]) <= 1e-5 * max(1, abs(s0["b"])) and abs(m0["se"] - s0["se"]) <= 1e-5 * max(1, abs(s0["se"]))))
    lines.append("")

# Table II
t2 = pd.read_csv(R / "statspai_table2_did.csv")
pb = [(.21, .07, 10.39), (.21, .07, 10.20), (.20, .07, 9.89), (.03, .06, 8.96), (.01, .06, 8.87), (-.06, .06, 9.17)]
pN = [20588] * 3 + [34892] * 3
lines += ["### Table II — Difference in discontinuities (`mdrd`, bias-corrected coef, conventional SE)", "",
          "| col | kernel | paper b (se) [h] | Stata mdrd b (se) [h] | N (sample) | StatsPAI b (se) | \\|Δ\\| b | status |", "|---|---|---|---|---|---|---|---|"]
for i, r in t2.iterrows():
    b, s, h = pb[i]
    stt = "✅" if ok(r.mdrd_bc, b, 2) and ok(r.mdrd_se_conv, s, 2) else ("⚠️" if abs(r.mdrd_bc - b) <= 0.02 and abs(r.mdrd_se_conv - s) <= 0.02 else "❌")
    lines.append(f"| {r.col} | {r.kernel} | {b:.2f} ({s:.2f}) [{h:.2f}] | {r.mdrd_bc:.4f} ({r.mdrd_se_conv:.4f}) [{r.h_l:.2f}] | {int(r.N):,} (paper {pN[i]:,}) | "
                 f"{r.sp_bc:.4f} ({r.sp_se_conv:.4f}) | {abs(r.mdrd_bc - b):.3f} | {stt} |")
    summary.append(dict(exhibit="T2", status=stt, statspai_vs_stata=abs(r.sp_bc - r.mdrd_bc) < 1e-4))
lines.append("")

# Table VIII
t8 = pd.read_csv(R / "statspai_table8_costs.csv")
pA = [3.38, 3.81, 3.53, 2.12, 2.28, 2.22]
pB = [1342, 1527, 1408, 816, 882, 858]
pC1 = [261, 294, 273, 162, 174, 170]
pC2 = [1303, 1472, 1364, 808, 872, 849]
lines += ["### Table VIII — Economic costs (spreadsheet `8_Cost_Estimates.xlsx`; re-computed in Python)", "",
          "| col | Panel A MRS % (paper / xlsx / StatsPAI) | Panel B 2001–07 bn CNY (paper / xlsx / StatsPAI) | Panel C annual (paper / xlsx / StatsPAI) | Panel C 5-yr (paper / xlsx / StatsPAI) | status |",
          "|---|---|---|---|---|---|"]
for i, r in t8.iterrows():
    good = (abs(round(r.mrs_xlsx_per10pct, 2) - pA[i]) <= 0.011 and abs(round(r.loss_00_07_bn) - pB[i]) <= 1
            and abs(round(r.annual_16_20_bn) - pC1[i]) <= 1 and abs(round(r.loss_16_20_bn) - pC2[i]) <= 1)
    stt = "✅" if good else "⚠️"
    lines.append(f"| {i+1} | {pA[i]:.2f} / {r.mrs_xlsx_per10pct:.2f} / {r.mrs_statspai_per10pct:.2f} | {pB[i]:,} / {r.loss_00_07_bn:,.0f} / {r.loss_00_07_bn_statspai:,.0f} | "
                 f"{pC1[i]} / {r.annual_16_20_bn:.0f} / {r.annual_16_20_bn_statspai:.0f} | {pC2[i]:,} / {r.loss_16_20_bn:,.0f} / {r.loss_16_20_bn_statspai:,.0f} | {stt} |")
    summary.append(dict(exhibit="T8", status=stt, statspai_vs_stata=False))
lines.append("")

S = pd.DataFrame(summary)
tab = S.groupby("exhibit").status.value_counts().unstack(fill_value=0)
for c in ["✅", "⚠️", "❌"]:
    if c not in tab.columns:
        tab[c] = 0
tab["cells"] = tab[["✅", "⚠️", "❌"]].sum(axis=1)
tab = tab[["cells", "✅", "⚠️", "❌"]]
eq = S[S.exhibit.isin(["T1", "T3", "T4", "T5", "T6", "T7", "T2"])].groupby("exhibit").statspai_vs_stata.mean()
head = ["# Comparison: paper vs original Stata code vs StatsPAI", "",
        "He, Wang & Zhang (2020, QJE). Paper values transcribed from the published PDF. Original Stata = author's do-files run with",
        "Stata 18 MP + rdrobust 10.0.0 (`Program/run_original.do`; per-cell e() export via `Program/statspai/export_stata_estimates.do`).",
        "StatsPAI = `statspai` 1.28.0 (`Program/statspai/replicate_statspai.py`).", "",
        "* **StatsPAI matched** — `sp.rdrobust(h=, b=, cluster='site_id')` with the author's `masspoints(off)` bandwidth (from the official rdrobust Python port; Stata e(h,b) fallback).",
        "* **StatsPAI native** — `sp.rdrobust(bwselect=..., cluster='site_id')`; StatsPAI always applies the mass-point adjustment in bandwidth selection (= Stata's default `masspoints(adjust)`), so h differs.",
        "* Status compares the original Stata output with the paper at the paper's reported precision: ✅ identical after rounding; ⚠️ small difference or matches only under a documented spec variant; ❌ unexplained.", "",
        "## Summary", "", "| exhibit | cells | ✅ | ⚠️ | ❌ | share of cells where StatsPAI(matched) == Stata (b, se; rel. tol 1e-5) |", "|---|---|---|---|---|---|"]
for ex, r in tab.iterrows():
    e = eq.get(ex, np.nan)
    head.append(f"| {ex} | {r.cells} | {r['✅']} | {r['⚠️']} | {r['❌']} | {'' if np.isnan(e) else f'{e:.0%}'} |")
head += ["| F4 (Figure IV) | 2 panels | author's `rdplot` ran (Results/Figures/F3_TFP.png); StatsPAI `sp.rdplot` re-draw in Results/statspai/figure4_rdplot.png | | | |",
         "| F5 (Figure V) | 8 years | plotted from pre-computed `graph_by_year.dta` (year-by-year RD data not shipped); identical inputs in both | | | |", ""]
notes = (ROOT / "Program" / "statspai" / "comparison_notes.md")
body = head + (notes.read_text().splitlines() + [""] if notes.exists() else []) + ["## Cell-by-cell", ""] + lines
(ROOT / "Results" / "comparison.md").write_text("\n".join(body), encoding="utf-8")
print(tab)
print(eq)
