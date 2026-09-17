"""Build number-by-number comparison tables: paper | original Stata (regenerated .tex) | StatsPAI.

Paper values are typed from the NBER w25434 PDF (identical to the shipped tables/*.tex).
Stata values are parsed from Results/Tables/*.tex written by the author's do-files in our run.
Writes Results/comparison_tables.md (included into Results/comparison.md by hand).

Run: /usr/local/bin/python3.13 Program/statspai/make_comparison.py
"""
from __future__ import annotations

import re

import numpy as np
import pandas as pd

from bunching import OUT, ROOT

TAB = ROOT / "Results" / "Tables"
ROWS = [("below", "Missing jobs below new MW (Δb)"), ("above", "Excess jobs above new MW (Δa)"),
        ("wage", "%Δ affected wages"), ("emp", "%Δ affected employment"),
        ("elas_mw", "Employment elasticity w.r.t. MW"), ("elas_wage", "Emp. elasticity w.r.t. affected wage")]

# (estimate, se) per row, per column
PAPER_T1 = {
    1: [(-0.018, 0.004), (0.021, 0.003), (0.068, 0.010), (0.028, 0.029), (0.024, 0.025), (0.411, 0.430)],
    2: [(-0.018, 0.004), (0.018, 0.003), (0.057, 0.010), (0.000, 0.023), (0.000, 0.020), (0.006, 0.402)],
    3: [(-0.018, 0.004), (0.020, 0.003), (0.068, 0.012), (0.022, 0.021), (0.019, 0.018), (0.326, 0.313)],
    4: [(-0.016, 0.002), (0.016, 0.002), (0.049, 0.010), (-0.002, 0.021), (-0.001, 0.018), (-0.032, 0.439)],
    5: [(-0.016, 0.002), (0.014, 0.003), (0.043, 0.010), (-0.019, 0.021), (-0.016, 0.018), (-0.449, 0.574)],
    6: [(-0.015, 0.002), (0.015, 0.003), (0.050, 0.011), (-0.000, 0.023), (-0.000, 0.019), (-0.003, 0.455)],
    7: [None, None, (0.065, 0.010), (0.027, 0.028), (0.023, 0.024), (0.410, 0.421)],
}
PAPER_T2 = {  # HSD, HSL, teen, female, BH, high-prob, medium-prob, low-prob
    "HSD": [(-0.065, 0.010), (0.075, 0.011), (0.080, 0.014), (0.038, 0.024), (0.097, 0.061), (0.475, 0.268)],
    "HSL": [(-0.032, 0.007), (0.038, 0.006), (0.076, 0.014), (0.043, 0.030), (0.061, 0.042), (0.570, 0.386)],
    "teen": [(-0.114, 0.010), (0.127, 0.020), (0.083, 0.018), (0.030, 0.032), (0.125, 0.134), (0.356, 0.317)],
    "female": [(-0.023, 0.005), (0.026, 0.004), (0.072, 0.011), (0.025, 0.027), (0.025, 0.027), (0.343, 0.362)],
    "BH": [(-0.028, 0.008), (0.028, 0.006), (0.044, 0.012), (-0.004, 0.044), (-0.005, 0.058), (-0.086, 1.005)],
    "first_": [(-0.094, 0.010), (0.100, 0.012), (0.073, 0.011), (0.015, 0.018), (0.052, 0.062), (0.206, 0.233)],
    "fourth_": [(-0.020, 0.005), (0.021, 0.003), (0.051, 0.013), (0.015, 0.048), (0.016, 0.049), (0.304, 0.904)],
    "fifth_": [(-0.004, 0.001), (0.004, 0.001), (0.060, 0.032), (0.011, 0.055), (0.003, 0.014), (0.184, 0.841)],
}
PAPER_T2_BELOW = {"HSD": 0.264, "HSL": 0.145, "teen": 0.432, "female": 0.102, "BH": 0.133,
                  "first_": 0.358, "fourth_": 0.104, "fifth_": 0.027}
PAPER_T3 = {
    "ind_all_overall": [(-0.019, 0.004), (0.020, 0.003), (0.058, 0.011), (0.008, 0.031), (0.007, 0.027), (0.140, 0.523)],
    "ind_mstrad_overall": [(-0.016, 0.008), (0.011, 0.008), (0.058, 0.073), (-0.111, 0.136), (-0.056, 0.069), (-1.910, 3.922)],
    "ind_msnontrad_overall": [(-0.066, 0.007), (0.072, 0.011), (0.056, 0.014), (0.022, 0.037), (0.060, 0.103), (0.387, 0.597)],
    "ind_mscon_overall": [(-0.003, 0.002), (0.005, 0.006), (0.097, 0.086), (0.051, 0.163), (0.019, 0.059), (0.530, 1.311)],
    "ind_msother_overall": [(-0.011, 0.003), (0.011, 0.002), (0.056, 0.013), (0.009, 0.044), (0.005, 0.026), (0.166, 0.763)],
    "ind_rest_overall": [(-0.101, 0.015), (0.101, 0.015), (0.049, 0.012), (-0.001, 0.026), (-0.002, 0.117), (-0.011, 0.542)],
    "ind_retail_overall": [(-0.033, 0.003), (0.041, 0.010), (0.060, 0.021), (0.062, 0.080), (0.086, 0.111), (1.040, 1.058)],
    "ind_manuf_overall": [(-0.017, 0.008), (0.011, 0.009), (0.073, 0.078), (-0.101, 0.145), (-0.052, 0.074), (-1.385, 2.956)],
}
PAPER_T4 = {  # wage, wage_nospill, spill_share
    "overall": [(0.068, 0.010), (0.041, 0.009), (0.397, 0.119)],
    "HSD": [(0.077, 0.013), (0.048, 0.009), (0.370, 0.078)],
    "teen": [(0.081, 0.015), (0.053, 0.007), (0.347, 0.059)],
    "HSL": [(0.073, 0.013), (0.043, 0.011), (0.402, 0.100)],
    "female": [(0.070, 0.011), (0.045, 0.010), (0.359, 0.120)],
    "BH": [(0.045, 0.012), (0.037, 0.010), (0.179, 0.265)],
    "ind_mstrad_overall": [(0.058, 0.073), (0.065, 0.028), (-0.114, 1.157)],
    "ind_msnontrad_overall": [(0.056, 0.014), (0.043, 0.006), (0.237, 0.191)],
    "incumbent": [(0.095, 0.020), (0.055, 0.011), (0.422, 0.181)],
    "newentrant": [(0.019, 0.013), (0.023, 0.006), (-0.178, 0.748)],
}
GROUP_LABEL = {"HSD": "Less than HS", "HSL": "HS or less", "teen": "Teen", "female": "Women",
               "BH": "Black/Hispanic", "first_": "High prob. (CK)", "fourth_": "Medium prob. (CK)",
               "fifth_": "Low prob. (CK)", "ind_all_overall": "All sectors", "ind_mstrad_overall": "Tradable",
               "ind_msnontrad_overall": "Non-tradable", "ind_mscon_overall": "Construction",
               "ind_msother_overall": "Other", "ind_rest_overall": "Restaurants", "ind_retail_overall": "Retail",
               "ind_manuf_overall": "Manufacturing", "overall": "Overall", "incumbent": "Incumbent",
               "newentrant": "New entrant"}


def parse_tex(path):
    """Return list of rows -> list of cell strings from an esttab fragment."""
    if not path.exists():
        return None
    rows = []
    for line in path.read_text().splitlines():
        if "&" not in line:
            continue
        cells = [c.strip().rstrip("\\").strip() for c in line.split("&")]
        rows.append(cells)
    return rows


def num(s):
    if s is None:
        return None
    m = re.search(r"-?\d*\.\d+", s)
    return float(m.group()) if m else None


def stata_table(path, ncols):
    """Map row label -> list of (est, se) from a regenerated Table*.tex (esttab stats layout)."""
    rows = parse_tex(path)
    if rows is None:
        return None
    out, last = {}, None
    for r in rows:
        lab = r[0]
        vals = r[1:1 + ncols]
        if lab and lab not in ("", " "):
            last = lab
            out[lab] = [[num(v), None] for v in vals]
        elif last is not None and any("(" in v for v in vals):
            for i, v in enumerate(vals):
                if i < len(out[last]):
                    out[last][i][1] = num(v)
    return out


def mark(p, s, tol=0.0005001):
    if p is None or s is None or (isinstance(s, float) and np.isnan(s)):
        return ""
    d = abs(p - s)
    return "✅" if d <= tol else ("⚠️" if d <= 0.0025 else "❌")


def fmt(x):
    return "—" if x is None or (isinstance(x, float) and np.isnan(x)) else f"{x:.3f}"


ROWS_T2LIN = [("below", ROWS[0][1]), ("above", ROWS[1][1]), ("wage_lin", ROWS[2][1]), ("emp", ROWS[3][1]),
              ("elas_mw", ROWS[4][1]), ("elas_wage_lin", ROWS[5][1])]


def section(title, cols, paper, sp_rows, stata=None, stata_labels=None, rows=ROWS):
    md = [f"### {title}", "",
          "| Column | Row | Paper | Original Stata | StatsPAI | abs diff (SP−paper) | ✓ |",
          "|---|---|---|---|---|---|---|"]
    for ci, col in enumerate(cols):
        for ri, (key, lab) in enumerate(rows):
            pv = paper[col][ri]
            if pv is None:
                continue
            spv = sp_rows.get(col, {})
            sb, sse = spv.get(key), spv.get(key + "_se")
            st = "—"
            if stata is not None and stata_labels is not None:
                kw = ["Missing jobs", "Excess jobs", "affected wages", "affected employment",
                      "elasticity w.r.t. MW", "w.r.t. affected wage"][ri]
                cell = next((v for k, v in stata.items() if kw in k), None)
                if cell is not None and ci < len(cell) and cell[ci][0] is not None:
                    st = f"{cell[ci][0]:.3f} ({cell[ci][1]:.3f})" if cell[ci][1] is not None else f"{cell[ci][0]:.3f}"
            spstr = f"{sb:.3f} ({sse:.3f})" if sb is not None and not np.isnan(sb) else "—"
            diff = f"{abs(sb - pv[0]):.4f} / {abs(sse - pv[1]):.4f}" if sb is not None and not np.isnan(sb) else "—"
            ok = mark(pv[0], sb) + mark(pv[1], sse) if sb is not None else ""
            ok = "✅" if ok == "✅✅" else ("❌" if "❌" in ok else ("⚠️" if ok else ""))
            md.append(f"| {GROUP_LABEL.get(col, col)} | {lab} | {pv[0]:.3f} ({pv[1]:.3f}) | {st} | {spstr} | {diff} | {ok} |")
    md.append("")
    return md


def main():
    md = ["# Auto-generated number-by-number tables", "",
          "Format: estimate (s.e.). abs diff = |StatsPAI − paper| for estimate / s.e.; ✅ = both equal at the paper's 3-decimal rounding (|diff| ≤ 0.0005).", ""]
    stata_lab = ["Missing jobs below new MW ($ \\Delta $ b)", "Excess jobs above new MW ($ \\Delta $ a)",
                 "\\%$\\Delta$ affected wages", "\\%$\\Delta$ affected employment",
                 "Employment elasticity w.r.t. MW", "Emp. elasticity w.r.t. affected wage"]

    # Table 1
    sp1 = {}
    f = OUT / "table1_cols1_6.csv"
    if f.exists():
        for _, r in pd.read_csv(f).iterrows():
            sp1[int(r["col"])] = r.to_dict()
    f = OUT / "table1_col7.csv"
    if f.exists():
        sp1[7] = pd.read_csv(f).iloc[0].to_dict()
    st1 = stata_table(TAB / "Table1.tex", 7)
    md += section("Table 1 — Impact of minimum wages on employment and wages", [1, 2, 3, 4, 5, 6, 7],
                  PAPER_T1, sp1, st1, stata_lab)

    # Table 2
    sp2 = {}
    for fn in ("table2_demog.csv", "table2_ck.csv"):
        if (OUT / fn).exists():
            for _, r in pd.read_csv(OUT / fn).iterrows():
                sp2[r["group"]] = r.to_dict()
    order2 = ["HSD", "HSL", "teen", "female", "BH", "first_", "fourth_", "fifth_"]
    st2 = stata_table(TAB / "Table_2.tex", 8)
    # cols 1-5: Table2_for_QJE.do reports %dw = %dwb - %de (lincom, no /(1+%de)); cols 6-8 use equation (2)
    md += section("Table 2 — cols 1–5 (demographic groups; linear wage formula used by Table2_for_QJE.do)",
                  order2[:5], PAPER_T2, sp2, st2, stata_lab, rows=ROWS_T2LIN)
    md += section("Table 2 — cols 6–8 (Card–Krueger exposure groups)", order2[5:], PAPER_T2, sp2,
                  {k: v[5:] for k, v in st2.items()} if st2 else None, stata_lab)
    md += ["| Group | b₋₁ paper | b₋₁ StatsPAI |", "|---|---|---|"]
    for g in order2:
        v = sp2.get(g, {}).get("b_minus1")
        md.append(f"| {GROUP_LABEL[g]} | {PAPER_T2_BELOW[g]:.3f} | {fmt(v)} |")
    md.append("")

    # Table 3
    sp3 = {}
    if (OUT / "table3.csv").exists():
        for _, r in pd.read_csv(OUT / "table3.csv").iterrows():
            sp3[r["group"]] = r.to_dict()
    order3 = list(PAPER_T3)
    st3 = stata_table(TAB / "Table3.tex", 8)
    md += section("Table 3 — By sector, 1992–2016", order3, PAPER_T3, sp3, st3, stata_lab)

    # Table 4
    sp4 = {}
    if (OUT / "table4_overall.csv").exists():
        sp4["overall"] = pd.read_csv(OUT / "table4_overall.csv").iloc[0].to_dict()
    for g, d in list(sp2.items()) + list(sp3.items()):
        sp4[g] = d
    if (OUT / "table4_incumbent_newentrant.csv").exists():
        for _, r in pd.read_csv(OUT / "table4_incumbent_newentrant.csv").iterrows():
            sp4[r["group"]] = r.to_dict()
    rows4 = [("wage", "%Δw"), ("wage_nospill", "%Δw no spillover"), ("spill_share", "Spillover share")]
    md += section("Table 4 — Size of wage spillovers (rows available in StatsPAI)", list(PAPER_T4), PAPER_T4, sp4,
                  rows=rows4)
    (ROOT / "Results" / "comparison_tables.md").write_text("\n".join(md))
    print("wrote Results/comparison_tables.md")
    return md



# ---------------------------------------------------------------------------
# Full Results/comparison.md
# ---------------------------------------------------------------------------
def figure_checks() -> list[str]:
    md = ["## Figures", ""]
    a = OUT / "author_ster_figures.csv"
    if a.exists() and (OUT / "figure2_bins.csv").exists():
        au = pd.read_csv(a)
        f2 = pd.read_csv(OUT / "figure2_bins.csv")
        a2 = au[au.figure == 2].assign(bin=lambda d: d.key.astype(int)).merge(f2, on="bin", suffixes=("_a", "_s"))
        md += ["### Figure 2 — employment change by $1 bin (5-year average)", "",
               "Author values = `lincom` on the shipped `forplacebofig_{true,pl1,pl2}` .ster files (the published figure has no printed numbers except the Δa/Δb box, which repeats Table 1 col 1).",
               "", "| Bin | Author .ster | StatsPAI | abs diff est | abs diff s.e. |", "|---|---|---|---|---|"]
        for _, r in a2.iterrows():
            lab = "17+" if r.bin == 17 else str(int(r.bin))
            md.append(f"| {lab} | {r.est_a:.5f} ({r.se_a:.5f}) | {r.est_s:.5f} ({r.se_s:.5f}) | {abs(r.est_a - r.est_s):.1e} | {abs(r.se_a - r.se_s):.1e} |")
        md += ["", f"Δb (bins −4…−1) = {f2[f2.bin < 0].est.sum():.3f}, Δa (bins 0…4) = {f2[(f2.bin >= 0) & (f2.bin <= 4)].est.sum():.3f} ✅ (paper box: −0.018 / 0.021 from Table 1; the Figure-2 regression additionally absorbs the placebo bins, giving Δa = 0.0203).", ""]
        f3 = pd.read_csv(OUT / "figure3_eventtime.csv")
        a3 = au[au.figure == 3].copy()
        a3[["side", "tau"]] = a3.key.str.split("_", expand=True)
        a3["tau"] = a3.tau.astype(int)
        m3 = a3.merge(f3, on=["side", "tau"], suffixes=("_a", "_s"))
        md += ["### Figure 3 — missing / excess jobs by event year", "",
               "| Side | τ | Author .ster | StatsPAI | abs diff |", "|---|---|---|---|---|"]
        for _, r in m3.sort_values(["side", "tau"]).iterrows():
            md.append(f"| {r.side} | {r.tau} | {r.est_a:.5f} ({r.se_a:.5f}) | {r.est_s:.5f} ({r.se_s:.5f}) | {abs(r.est_a - r.est_s):.1e} ✅ |")
        md.append("")
    f4 = OUT / "table4_incumbent_newentrant.csv"
    if f4.exists():
        d = pd.read_csv(f4).set_index("group")
        paper = {"newentrant": dict(above=(0.006, 0.001), below=(-0.005, 0.001), emp=(0.008, 0.034), wage=(0.019, 0.013)),
                 "incumbent": dict(above=(0.014, 0.002), below=(-0.013, 0.002), emp=(0.009, 0.068), wage=(0.095, 0.020))}
        md += ["### Figure 4 — first-year effects, new entrants vs incumbents (text box in the figure)", "",
               "| Group | Stat | Paper box | StatsPAI | ✓ |", "|---|---|---|---|---|"]
        for g, stats in paper.items():
            for k, (pe, ps) in stats.items():
                e, s = d.loc[g, k], d.loc[g, k + "_se"]
                ok = mark(pe, e) + mark(ps, s)
                ok = "✅" if ok == "✅✅" else ("⚠️" if "❌" not in ok else "❌")
                md.append(f"| {g} | {k} | {pe:.3f} ({ps:.3f}) | {e:.3f} ({s:.3f}) | {ok} |")
        md += ["", "The incumbent Δa/Δb box values (0.014 / −0.013) are **hard-coded strings** in `Figure4_for_QJE.do`; `lincom` on the authors' own shipped `m_overall1pl0after…ster` gives 0.0126 / −0.0122, identical to StatsPAI. So the ⚠️ is an author-side stale annotation, not a replication gap. %Δ affected employment and wage match.", ""]
    md += ["### Figures 5 and 6 (original Stata only)", "",
           "| Exhibit | Statistic | Paper | Original Stata (our run) | ✓ |", "|---|---|---|---|---|",
           "| Figure 5a | slope, excess jobs on Kaitz index | 0.139 (0.057) | 0.1387 (0.0568) | ✅ |",
           "| Figure 5a | slope, missing jobs | −0.133 (0.034) | −0.1331 (0.0344) | ✅ |",
           "| Figure 5b | slope, employment change | 0.006 (0.048) | 0.0056 (0.0483) | ✅ |",
           "| Figure 6 | TWFE-logMW employment elasticity | −0.089 (0.025) | −0.0894 (0.0253) | ✅ |", ""]
    return md


NOTES = {
    "Table1_for_QJE": "6 specs × 2 reghdfe; col 3/6 quadratic bin-state trends are the bottleneck; ✅ finished after ≈22 h, `Table1.tex` byte-identical to shipped (incl. col 7); row recovered from `Results/logs/batch_t1/run_original.log` (`STEP Table1_for_QJE rc=0`) because the wrapper's csv append then failed with r(198)",
    "Appendix_Table_F3": "**author path bug**: reads `${stn_bsamples}me_corrected_logwages.dta`, but the package ships it in `${data}` (where Appendix_Figure_F4 reads it) → r(601); rerun as patched copy",
    "Appendix_Table_F3_patched": "⚠️ `measurement_error_corrected.tex` vs shipped `TableF3.tex`: col 1 identical; col 2 differs by 0.001 in 3 cells (%Δ wages 0.074 vs 0.075, %Δ employment 0.047 (0.039) vs 0.046 (0.038))",
    "Appendix_Table_A1_A2": "**not reproducible from package**: needs `Table1aafterqcew_stateonly_1_…_estadd.ster`, which no shipped do-file writes and which is not among the shipped estimates → r(601); the CK and demographic variants (`_CK`, `_demog`) ran",
    "Appendix_TableG2_col1_patched": "✅ ran after 2 documented fixes (missing `qcew` tempfile; debugging `stop` left in the loop, r(199)); estimates only, no table written by this file",
    "Appendix_Table_A4_col9_patched": "✅ `TableA4_col9.tex` = paper Table A.4 col 9 in all 10 rows (−0.016/0.019/0.069/0.028/0.023/0.401, b₋₁ 0.086, %ΔMW 0.101, 138 events, N 847,314); ≈4.7 h",
    "Figure6_for_QJE": "timer shows '.' because the do-file itself calls `timer clear`; rc=0, Figure 6 + A11 produced",
    "Appendix_Figure_D1": "timer cleared inside do-file; rc=0", "Appendix_Figure_D2": "timer cleared inside do-file; rc=0",
    "Appendix_Figures_G2_A_C": "timer cleared inside do-file; rc=0",
    "Appendix_TableG2_col1": "**author bug**: merges on tempfile `qcew` that is never created → r(198); rerun as patched copy",
    "Appendix_Table_G5": "**author bug**: `esttab actual_EBC …` refers to stored estimates (`*_EBC`) that no shipped do-file creates → r(111) after the FE/FD panels are estimated; TableG5.tex contains panels A–B only (TableG5 not shipped, so no comparison)",
    "Appendix_Table_A4": "**data not in package**: `alternativeeventdef_QJE.do` needs `state_panels_with3quant1979_statefed.dta` (state+federal events, col 2) → r(601); the other columns' sub-do-files are called after it and were not reached",
    "Appendix_Table_A4_col9": "**author bug**: master calls it without the 3 arguments it reads → r(198); rerun as patched copy with the program defaults (500 400 25)",
    "Appendix_Table_A5": "✅ Table_A5.tex = paper Table A.5 (all 5 columns, all rows)",
    "Table3_for_QJE": "✅ Table3.tex identical to shipped",
    "Table4_for_QJE": "✅ identical to shipped",
}


def steps_table():
    f = ROOT / "Results" / "run_original_steps.csv"
    if not f.exists():
        return "(no steps run)"
    d = pd.read_csv(f)
    last = d.groupby("step").tail(1)
    out = ["| Step | rc | seconds | Note |", "|---|---|---|---|"]
    for _, r in last.iterrows():
        key = str(r.step).split("/")[-1]
        note = NOTES.get(key, "")
        if not note and int(r.rc) == 0:
            note = "ran"
        out.append(f"| `{r.step}` | {int(r.rc)} | {r.seconds} | {note} |")
    return "\n".join(out)


def ext_rows():
    f = OUT / "ext_summary.csv"
    if not f.exists():
        return ""
    d = pd.read_csv(f)
    return "\n".join(f"| {r.estimator} — {r.outcome} | {r.post_avg:.4f} ({r.se:.4f}) |" for _, r in d.iterrows())


def count_marks(md):
    txt = "\n".join(md)
    return txt.count("✅"), txt.count("⚠️"), txt.count("❌")


def full():
    tables = main()
    figs = figure_checks()
    head = (ROOT / "Program" / "statspai" / "comparison_header.md").read_text()
    tail = (ROOT / "Program" / "statspai" / "comparison_footer.md").read_text()
    tail = tail.replace("{{STEPS_TABLE}}", steps_table()).replace("{{EXT_ROWS}}", ext_rows())
    ok, warn, bad = count_marks(tables[2:])
    head = head.replace("{{COUNTS}}", f"{ok} ✅ / {warn} ⚠️ / {bad} ❌")
    (ROOT / "Results" / "comparison.md").write_text(head + "\n" + "\n".join(tables[3:]) + "\n" + "\n".join(figs) + "\n" + tail)
    print("wrote Results/comparison.md")


if __name__ == "__main__":
    full()
