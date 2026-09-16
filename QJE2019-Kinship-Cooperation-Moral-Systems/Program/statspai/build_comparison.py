#!/usr/bin/env python3.13
"""Build Results/comparison.md: paper | original Stata | StatsPAI, number by number.

Inputs
  * paper values: typed from the published QJE tables (Materials/*.pdf), below
  * original Stata: Results/Tables/precise/*.csv  (Program/run_precise.do)
  * StatsPAI:       Results/statspai/statspai_main_tables.csv (replicate_statspai.py)

Match rule ("to reported precision"): the Stata / StatsPAI number is rounded to
the number of decimals printed in the paper (coefficients use esttab b(a2) = 2
significant digits, SEs 2 decimals) and must equal the printed value; N must be
identical.  Columns whose SEs are cluster-bootstrapped (500 reps, no seed in the
original code) can legitimately differ by Monte-Carlo noise -> flagged warning.
"""
from pathlib import Path
import csv
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
PREC = ROOT / "Results" / "Tables" / "precise"
SP = pd.read_csv(ROOT / "Results" / "statspai" / "statspai_main_tables.csv")

K, HG, MAL, SIC, TSI, GOD, BG = ("kinship_score", "small_scale", "s_malariaindex", "s_distance_mutation",
                                 "s_tsi", "s_have_god", "s_religion_god")
CK = "corigin_kinship_score"

# (table, file, bootstrap columns, N per column, {(col, term): (coef_str, se_str)})
PAPER = [
    ("III", "Determinants_EA", {4, 5, 6, 7, 8, 9, 10, 11}, [1226, 1225, 1216, 504, 504, 501, 501, 500, 500, 500, 497], {
        (1, MAL): ("0.12", "0.01"), (2, MAL): ("0.098", "0.01"), (3, MAL): ("0.033", "0.01"), (4, MAL): ("0.031", "0.02"),
        (5, MAL): ("0.030", "0.01"), (10, MAL): ("0.025", "0.01"),
        (2, HG): ("-0.35", "0.09"), (3, HG): ("-0.17", "0.10"), (5, HG): ("-0.42", "0.19"), (7, HG): ("-0.39", "0.16"),
        (9, HG): ("-0.41", "0.18"), (10, HG): ("-0.41", "0.16"), (11, HG): ("-0.37", "0.15"),
        (6, SIC): ("-0.058", "0.02"), (7, SIC): ("-0.053", "0.02"), (11, SIC): ("-0.041", "0.02"),
        (8, TSI): ("0.035", "0.01"), (9, TSI): ("0.041", "0.01"), (10, TSI): ("0.038", "0.01"), (11, TSI): ("0.019", "0.01")}),
    ("IV", "Enforcement_EA", {1, 2, 6, 7}, [61, 61, 776, 770, 770, 83, 83, 371, 371, 1156, 1146, 1146, 1151, 1141, 1141], {
        **{(c, K): v for c, v in zip(range(1, 16), [
            ("1.27", "0.47"), ("1.13", "0.46"), ("-0.77", "0.19"), ("-0.50", "0.13"), ("-0.41", "0.15"), ("1.16", "0.33"),
            ("1.14", "0.32"), ("0.83", "0.20"), ("0.46", "0.19"), ("-0.39", "0.20"), ("-0.37", "0.12"), ("-0.26", "0.14"),
            ("0.83", "0.12"), ("0.87", "0.12"), ("0.76", "0.15")])},
        (4, GOD): ("0.30", "0.05"), (5, GOD): ("0.23", "0.05")}),
    ("V", "Contiguous_EA", set(), [2468, 2465, 7582, 7573, 7601, 7592], {
        **{(c, K): v for c, v in zip(range(1, 7), [("-0.34", "0.13"), ("-0.38", "0.12"), ("-0.0066", "0.09"),
                                                   ("-0.028", "0.08"), ("0.64", "0.20"), ("0.65", "0.19")])},
        (2, GOD): ("0.12", "0.04")}),
    ("VI", "Trust", set(), [72, 70, 72, 70, 21813, 21758, 21813, 21758], {
        (c, K): v for c, v in zip(range(1, 9), [("1.46", "0.33"), ("1.44", "0.36"), ("1.03", "0.35"), ("1.24", "0.46"),
                                                ("0.40", "0.06"), ("0.35", "0.07"), ("0.17", "0.04"), ("0.21", "0.06")])}),
    ("VII", "Religion", set(), [79, 79, 78, 78, 26220, 25752, 25722, 23891], {
        **{(c, K): v for c, v in zip(range(1, 9), [("1.16", "0.35"), ("0.87", "0.24"), ("0.88", "0.25"), ("0.47", "0.24"),
                                                   ("0.26", "0.04"), ("0.18", "0.02"), ("0.17", "0.03"), ("0.20", "0.04")])},
        (2, BG): ("0.67", "0.11"), (3, BG): ("0.69", "0.11"), (4, BG): ("0.70", "0.09"),
        (6, BG): ("0.30", "0.04"), (7, BG): ("0.30", "0.04"), (8, BG): ("0.34", "0.03")}),
    ("VIII", "Moral_values", set(), [27994, 27994, 28432, 27994, 28432, 27994, 28432, 27994], {
        (c, CK): v for c, v in zip(range(1, 9), [("0.11", "0.04"), ("-0.23", "0.13"), ("0.37", "0.13"), ("0.29", "0.12"),
                                                 ("0.36", "0.04"), ("0.39", "0.05"), ("0.41", "0.05"), ("0.41", "0.04")])}),
    ("IX", "Shame", set(), [2570, 2567, 2490, 2626, 2623, 2545, 72, 71], {
        (c, K): v for c, v in zip(range(1, 9), [("0.30", "0.17"), ("0.32", "0.17"), ("0.31", "0.17"), ("0.27", "0.14"),
                                                ("0.27", "0.13"), ("0.20", "0.17"), ("0.79", "0.35"), ("0.88", "0.35")])}),
    ("X", "GPS_punish_cols1_3", set(), [74, 74, 74], {
        (1, K): ("1.20", "0.36"), (2, K): ("1.19", "0.39"), (3, K): ("0.83", "0.49")}),
    ("XI", "Development_EA", set(), [1172, 1171, 1186, 1176, 613, 607], {
        **{(c, K): v for c, v in zip(range(1, 7), [("0.60", "0.30"), ("-0.26", "0.17"), ("0.94", "0.26"),
                                                   ("0.24", "0.15"), ("0.25", "0.35"), ("-0.21", "0.16")])},
        (2, HG): ("-1.41", "0.20"), (4, HG): ("-2.51", "0.20"), (6, HG): ("-2.06", "0.23")}),
]


def read_precise(name):
    rows = list(csv.reader(open(PREC / f"{name}.csv")))
    out, ns = {}, {}
    body = rows[2:]
    i = 0
    while i < len(body):
        r = body[i]
        if r[0] in ("N", "r2"):
            for j, v in enumerate(r[1:], 1):
                if v:
                    ns.setdefault(j, {})[r[0]] = float(v)
            i += 1
            continue
        se = body[i + 1]
        for j, v in enumerate(r[1:], 1):
            if v:
                out[(j, r[0])] = (float(v), float(se[j]))
        i += 2
    return out, ns


def ndec(s):
    return len(s.split(".")[1]) if "." in s else 0


def matches(x, s):
    return abs(round(x, ndec(s)) - float(s)) < 1e-9


lines = ["# Comparison: paper vs original Stata code vs StatsPAI",
         "",
         "Enke (2019), *Kinship, Cooperation, and the Evolution of Moral Systems*, QJE 134(2): 953–1019.",
         "",
         "* **Paper** = published QJE tables (Materials/ PDF). **Stata** = the author's unmodified do-files run by",
         "  `Program/run_original.do` (Stata 18 MP), coefficients dumped at 6 decimals by `Program/run_precise.do`.",
         "  **StatsPAI** = `Program/statspai/replicate_statspai.py` (statspai 1.28.0, `sp.feols` / `sp.bootstrap`).",
         "* Match rule: value rounded to the decimals printed in the paper must equal the printed value; N identical.",
         "* ✅ match at reported precision · ⚠️ small difference, explained · ❌ failure.",
         "* Bootstrap columns (Table III cols 4–11, Table IV cols 1, 2, 6, 7): 500 cluster-bootstrap reps, and the author",
         "  sets no seed, so SEs are Monte-Carlo draws. Our Stata run uses `set seed 20190001`; StatsPAI uses its own RNG.",
         "  If the coefficient matches exactly and such an SE is within 10% of the printed value it is marked ⚠️",
         "  (rule: |SE − printed| ≤ 0.005 rounding half-width + 10% of printed value; the bootstrap Monte-Carlo s.d. of an SE with B=500 is ~3%), not ❌.",
         ""]
summary = []
for tab, fname, boot, Ns, vals in PAPER:
    st, sn = read_precise(fname)
    sp_t = SP[SP["table"] == tab]
    lines += [f"## Table {tab}", "",
              "| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |",
              "|---|---|---|---|---|---|---|---|"]
    counts = {"✅": 0, "⚠️": 0, "❌": 0}
    for (col, term), (pb, pse) in vals.items():
        sb, sse = st.get((col, term), (float("nan"), float("nan")))
        r = sp_t[(sp_t["col"] == col) & (sp_t["term"] == term)]
        if len(r):
            qb, qse, qn = float(r["coef"].iloc[0]), float(r["se"].iloc[0]), int(r["N"].iloc[0])
        else:
            qb = qse = float("nan"); qn = -1
        n_stata = int(sn.get(col, {}).get("N", -1))
        n_ok = Ns[col - 1] == n_stata == qn
        stata_ok = matches(sb, pb) and matches(sse, pse)
        sp_b_ok = matches(qb, pb)
        sp_se_ok = matches(qse, pse)
        notes = []
        if stata_ok and sp_b_ok and sp_se_ok and n_ok:
            status = "✅"
        elif col in boot and n_ok and matches(sb, pb) and sp_b_ok and abs(sse - float(pse)) <= 0.005 + 0.10 * float(pse) and abs(qse - float(pse)) <= 0.005 + 0.10 * float(pse):
            status = "⚠️"; notes.append("bootstrap SE noise")
        else:
            status = "❌"
            if not n_ok: notes.append("N differs")
        counts[status] += 1
        lines.append(f"| {col} | `{term}` | {pb} ({pse}) | {sb:.4f} ({sse:.4f}) | {qb:.4f} ({qse:.4f}) | "
                     f"{abs(qb - sb):.1e} / {abs(qse - sse):.1e} | {Ns[col-1]:,} / {n_stata:,} / {qn:,} | {status} {' '.join(notes)} |")
    lines.append("")
    summary.append((tab, len(vals), counts))

head = ["## Summary", "", "| Table | Coefficients compared | ✅ | ⚠️ | ❌ |", "|---|---|---|---|---|"]
for tab, n, c in summary:
    head.append(f"| {tab} | {n} | {c['✅']} | {c['⚠️']} | {c['❌']} |")
head.append("")
first = next(i for i, l in enumerate(lines) if l.startswith("## Table"))
extra = (ROOT / "Program" / "statspai" / "comparison_notes.md")
tail = [extra.read_text()] if extra.exists() else []
(ROOT / "Results" / "comparison.md").write_text("\n".join(lines[:first] + head + lines[first:] + tail) + "\n")
for tab, n, c in summary:
    print(tab, n, c)
