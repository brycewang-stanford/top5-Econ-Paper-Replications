"""Build Results/comparison.md: paper (corrected, April-2017 erratum version) vs original Stata
re-run vs StatsPAI, number by number.

"Paper" values = the authors' shipped LaTeX tables (Materials/package_outputs/Tables, April 2017),
which this script first verifies token-by-token against the text of the paper PDF shipped in the
package (Materials/Paper/Haushofer_Shapiro_UCT.pdf, the erratum-corrected version) via pdftotext.

Run: /usr/local/bin/python3.13 Program/statspai/build_comparison.py
"""
from __future__ import annotations

import re
import subprocess
from collections import Counter
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
PKG = ROOT / "Materials" / "package_outputs" / "Tables"
STATA = ROOT / "Results" / "Tables"
SP = ROOT / "Results" / "statspai"

ARMS = ["treat", "female", "monthly", "large"]


def norm(s: str) -> str:
    s = re.sub(r"\\(midrule|hspace\{[^}]*\}|textbf|emph)", "", s)
    s = s.replace("\\&", "&").replace("{", "").replace("}", "")
    return re.sub(r"\s+", " ", s).strip().lower()


def parse_tex(path: Path):
    """esttab booktabs table -> dict[(row_label, kind, col)] = float; kind in b/se/p."""
    out, cur, seen = {}, None, Counter()
    for line in path.read_text().splitlines():
        if "&" not in line or "multicolumn" in line:
            continue
        cells = [c.strip().replace("<AMP>", "\\&") for c in line.replace("\\&", "<AMP>").rstrip().rstrip("\\").split("&")]
        lab = norm(cells[0])
        if lab:
            if not any(re.search(r"\d", c) for c in cells[1:]):
                cur = None
                continue
            seen[lab] += 1
            cur = lab if seen[lab] == 1 else f"{lab} #{seen[lab]}"
            kind = "b"
        elif cur is None:
            continue
        for j, c in enumerate(cells[1:], start=1):
            c = re.sub(r"\$\^\{\*+\}\$", "", c).strip()
            if not c or c == "{ }":
                continue
            k = "b"
            if c.startswith("("):
                k = "se"
            elif c.startswith("["):
                k = "p"
            try:
                out[(cur, k, j)] = float(c.strip("()[]"))
            except ValueError:
                pass
    return out


# ---------------------------------------------------------------- verification against PDF text
def verify_pdf():
    pdf = ROOT / "Materials" / "Paper" / "Haushofer_Shapiro_UCT.pdf"
    txt = subprocess.run(["pdftotext", "-layout", str(pdf), "-"], capture_output=True, text=True).stdout
    heads = [("Table I:", "baseline_indices_ppp_maintable.tex"), ("Table II:", "indices_ppp_maintable.tex"),
             ("Table III:", "indices_ppp_spillover_table.tex"), ("Table IV:", "psyvars_maintable.tex"),
             ("Table V:", "cons_final_maintable.tex"), ("Table VI:", "assets+ent_final_maintable.tex"),
             ("Table A.1:", "indices_ppp_power_calcs.tex")]
    res = []
    for h, f in heads:
        i = txt.index(h)
        j = txt.index("Notes:", i)
        block = re.sub(r"^\s*\d{2}\s*$", "", txt[i:j], flags=re.M)  # page numbers
        pdf_tok = Counter(re.findall(r"\d+\.\d\d", block))
        tex_tok = Counter(f"{abs(v):.2f}" for (lab, k, c), v in parse_tex(PKG / f).items()
                          if not float(v).is_integer() or abs(v) < 100)
        common = sum((pdf_tok & tex_tok).values())
        res.append({"table": h.rstrip(":"), "tex file": f, "numbers in shipped tex": sum(tex_tok.values()),
                    "numbers in PDF block": sum(pdf_tok.values()), "matched": common})
    return pd.DataFrame(res)


# ---------------------------------------------------------------- StatsPAI -> tex-cell mapping
def sp_maintable(csv, joint_label="joint test (p-value)"):
    d = pd.read_csv(csv)
    out = {}
    for _, r in d.iterrows():
        lab = norm(r.label)
        out[(lab, "b", 1)] = r.control_mean
        out[(lab, "se", 1)] = r.control_sd
        out[(lab, "b", 6)] = r.N
        for j, a in enumerate(ARMS, start=2):
            out[(lab, "b", j)] = r[f"{a}_b"]
            out[(lab, "se", j)] = r[f"{a}_se"]
            if f"{a}_fwer" in d:
                out[(lab, "p", j)] = r[f"{a}_fwer"]
    for j, a in enumerate(ARMS, start=2):
        out[(joint_label, "b", j)] = d[f"{a}_joint_p"].iloc[0]
    return out


def sp_table6():
    d = pd.read_csv(SP / "table6.csv")
    out = {}
    for k, (panel, g) in enumerate(d.groupby("panel", sort=False), start=1):
        for _, r in g.iterrows():
            lab = norm(r.label)
            out[(lab, "b", 1)], out[(lab, "se", 1)], out[(lab, "b", 6)] = r.control_mean, r.control_sd, r.N
            for j, a in enumerate(ARMS, start=2):
                out[(lab, "b", j)], out[(lab, "se", j)] = r[f"{a}_b"], r[f"{a}_se"]
        jl = "joint test (p-value)" + ("" if k == 1 else " #2")
        for j, a in enumerate(ARMS, start=2):
            out[(jl, "b", j)] = g[f"{a}_joint_p"].iloc[0]
    return out


def sp_table3():
    d = pd.read_csv(SP / "table3.csv")
    out = {}
    for _, r in d.iterrows():
        lab = norm(r.label)
        for c in (1, 2, 3, 4, 7, 8, 9, 10):
            out[(lab, "b", c)], out[(lab, "se", c)] = r[f"c{c}_b"], r[f"c{c}_se"]
        out[(lab, "b", 5)], out[(lab, "b", 6)] = r.c5_p, r.c6_p
    for c in (1, 2, 3, 4):
        out[("joint test (p-value)", "b", c)] = d[f"c{c}_joint_p"].iloc[0]
    return out


def sp_tableA1():
    d = pd.read_csv(SP / "tableA1.csv")
    out = {}
    for _, r in d.iterrows():
        lab = norm(r.label)
        out[(lab, "b", 1)], out[(lab, "se", 1)] = r.control_mean, r.control_sd
        for k, a in enumerate(ARMS):
            out[(lab, "b", 2 + 2 * k)] = r[f"{a}_mde"]
            if not np.isnan(r[f"{a}_pct"]):
                out[(lab, "b", 3 + 2 * k)] = r[f"{a}_pct"]
    return out


def sp_lee():
    d = pd.read_csv(SP / "oa_leebounds_attrition.csv")
    out = {}
    for _, r in d.iterrows():
        lab = norm(r.label)
        out[(lab, "b", 1)], out[(lab, "se", 1)] = r.lower, r.se_lower
        out[(lab, "b", 2)], out[(lab, "se", 2)] = r.upper, r.se_upper
    return out


def sp_qreg():
    d = pd.read_csv(SP / "ext_quantile_effects.csv")
    return {(norm(r.label), "b", int(round(r.q * 10))): r.b for _, r in d.iterrows()}


# ---------------------------------------------------------------- comparison
MC_CELLS = {  # Monte-Carlo cells: bootstrap/permutation based
    "table1": lambda lab, k, c: k == "p",
    "table2": lambda lab, k, c: k == "p",
    "table3": lambda lab, k, c: k == "se" and c in (7, 8),
    "lee": lambda lab, k, c: False,
    "qreg": lambda lab, k, c: k == "se",
}


def compare(tag, texfile, spdict, title, colnames, note=""):
    paper = parse_tex(PKG / texfile)
    stata = parse_tex(STATA / texfile)
    rows = []
    for key, pv in paper.items():
        lab, k, c = key
        prec = 0 if float(pv).is_integer() and abs(pv) >= 100 else 2
        sv = stata.get(key, np.nan)
        spv = spdict.get(key, np.nan) if spdict is not None else np.nan
        mc = MC_CELLS.get(tag, lambda *a: False)(lab, k, c)
        d_st = abs(round(sv, prec) - pv) if not np.isnan(sv) else np.nan
        d_sp = abs(round(spv, prec) - pv) if not np.isnan(spv) else np.nan
        tol = 10 ** (-prec) * 0.5 + 1e-9

        def flag(dv):
            if np.isnan(dv):
                return "–"
            if dv <= tol:
                return "✅"
            return "⚠️" if (mc or dv <= 0.011 + 1e-9) else "❌"
        rows.append({"row": lab, "column": colnames.get(c, str(c)), "stat": {"b": "coef/value", "se": "(SE/SD)", "p": "[FWER p]"}[k],
                     "paper": pv, "Stata re-run": sv, "StatsPAI": spv,
                     "abs diff Stata": d_st, "abs diff StatsPAI": d_sp,
                     "Stata": flag(d_st), "SP": flag(d_sp), "MC": mc})
    df = pd.DataFrame(rows)
    return df


def summary_line(df):
    def cnt(col):
        v = df[col].value_counts()
        return f"✅ {v.get('✅', 0)} / ⚠️ {v.get('⚠️', 0)} / ❌ {v.get('❌', 0)} / – {v.get('–', 0)}"
    return cnt("Stata"), cnt("SP")


def main():
    main_cols = {1: "(1) control mean", 2: "(2) treatment", 3: "(3) female rec.", 4: "(4) monthly", 5: "(5) large", 6: "(6) N"}
    t3_cols = {1: "(1) all HH", 2: "(2) all HH+ctrl", 3: "(3) thatched", 4: "(4) thatched+ctrl", 5: "(5) p(1)=(3)",
               6: "(6) p(2)=(4)", 7: "(7) Lee lower", 8: "(8) Lee upper", 9: "(9) HM lower", 10: "(10) HM upper"}
    a1_cols = {1: "control mean", 2: "treat MDE", 3: "treat %", 4: "female MDE", 5: "female %", 6: "monthly MDE",
               7: "monthly %", 8: "large MDE", 9: "large %"}
    q_cols = {i: f"q=.{i}" for i in range(1, 10)}
    exhibits = [
        ("table1", "baseline_indices_ppp_maintable.tex", sp_maintable(SP / "table1.csv"), "Table I — Baseline differences in index variables", main_cols),
        ("table2", "indices_ppp_maintable.tex", sp_maintable(SP / "table2.csv"), "Table II — Treatment effects: index variables", main_cols),
        ("table3", "indices_ppp_spillover_table.tex", sp_table3(), "Table III — Spillover effects, Lee and Horowitz-Manski bounds", t3_cols),
        ("table4", "psyvars_maintable.tex", sp_maintable(SP / "table4.csv"), "Table IV — Psychological well-being", main_cols),
        ("table5", "cons_final_maintable.tex", sp_maintable(SP / "table5.csv"), "Table V — Consumption", main_cols),
        ("table6", "assets+ent_final_maintable.tex", sp_table6(), "Table VI — Assets and business activities", main_cols),
        ("tableA1", "indices_ppp_power_calcs.tex", sp_tableA1(), "Table A.1 — Ex-post MDEs", a1_cols),
        ("lee", "leebounds_indices_ppp.tex", sp_lee(), "OA Section 8.2 — Lee bounds for endline attrition", {1: "lower", 2: "upper"}),
        ("qreg", "indices_ppp_qregs.tex", sp_qreg(), "OA Section 14 — Quantile treatment effects (sqreg)", q_cols),
    ]
    ver = verify_pdf()
    parts, summ = [], []
    for tag, tex, spd, title, cols in exhibits:
        df = compare(tag, tex, spd, title, cols)
        df.to_csv(SP / f"comparison_{tag}.csv", index=False)
        s_st, s_sp = summary_line(df)
        summ.append({"exhibit": title, "cells": len(df), "original Stata (18 MP) re-run": s_st, "StatsPAI": s_sp})
        show = df.copy()
        for c in ("paper", "Stata re-run", "StatsPAI", "abs diff Stata", "abs diff StatsPAI"):
            show[c] = show[c].map(lambda v: "" if pd.isna(v) else (f"{v:.0f}" if float(v).is_integer() and abs(v) >= 100 else f"{v:.4g}" if "diff" in c else f"{v:.3f}"))
        show = show.drop(columns=["MC"])
        parts.append(f"\n## {title}\n\n<details><summary>{len(df)} cells — Stata: {s_st}; StatsPAI: {s_sp}</summary>\n\n"
                     + show.to_markdown(index=False) + "\n\n</details>\n")
    head = (ROOT / "Program" / "statspai" / "comparison_header.md").read_text()
    with open(ROOT / "Results" / "comparison.md", "w") as f:
        f.write(head)
        f.write("\n## Verification of the reference numbers against the paper PDF\n\n")
        f.write(ver.to_markdown(index=False))
        f.write("\n\n(two-decimal tokens; the PDF text loses minus signs and N counts, so tokens are compared in "
                "absolute value; residual unmatched tokens are header numbers such as '(1)'…'(10)'.)\n")
        f.write("\n## Summary\n\n" + pd.DataFrame(summ).to_markdown(index=False) + "\n")
        f.write("\n# Cell-by-cell comparison\n")
        f.writelines(parts)
    print(ver.to_string())
    print(pd.DataFrame(summ).to_string())


if __name__ == "__main__":
    main()
