"""Build Results/comparison.md: paper vs original Stata code vs StatsPAI, number by number."""
from __future__ import annotations

import re
from pathlib import Path

import pandas as pd

from common import DATA, OUT, ROOT
from paper_values import PAPER

TAB = ROOT / "Results" / "Tables"
STATA_FILE = {"V": "table5", "VI": "table6", "VIII": "table7", "IX": "table8", "X": "table9",
              "XI": "table10", "XII": "table11"}
DTA_FOR = {"V": ["price"], "X": ["price"], "VI": ["firm_panel"], "XI": ["firm_prov_panel"],
           "VIII": ["province_panel"], "IX": ["prefecture_panel"], "XII": ["province_panel", "prefecture_panel"]}
TITLE = {"V": "Table V — Princeling purchase and land price (do-file Table 5)",
         "VI": "Table VI — Quantity of land purchased, firm-year panel (do-file Table 6)",
         "VIII": "Table VIII — Provincial leaders' promotion (do-file Table 7)",
         "IX": "Table IX — Municipal leaders' promotion (do-file Table 8)",
         "X": "Table X — Land price after Xi took office (do-file Table 9)",
         "XI": "Table XI — Quantity after Xi took office, firm-province-year panel (do-file Table 10)",
         "XII": "Table XII — Promotion after Xi took office (do-file Table 11)"}


def labels(names):
    m = {}
    for n in names:
        p = DATA / f"{n}.dta"
        if p.exists():
            try:
                with pd.io.stata.StataReader(p) as r:
                    for k, v in r.variable_labels().items():
                        if v:
                            m.setdefault(v.strip(), {"xi_assign": "xi"}.get(k, k))
            except Exception:
                pass
    return m


def cell(s):
    return s.strip().lstrip("=").strip('"')


def parse_esttab(path, lab2var):
    rows = [[cell(c) for c in re.findall(r'="[^"]*"|[^,]+', line)] for line in path.read_text().splitlines()]
    out, nobs, adj = {}, {}, {}
    last = None
    for r in rows:
        if not r:
            continue
        name = r[0]
        vals = r[1:]
        if name in lab2var:
            last = lab2var[name]
            for j, v in enumerate(vals, start=1):
                if v:
                    out.setdefault(j, {})[last] = [float(re.sub(r"[*,]", "", v)), None]
        elif name == "" and last is not None and any(v.startswith("(") for v in vals):
            for j, v in enumerate(vals, start=1):
                if v.startswith("("):
                    out[j][last][1] = float(v.strip("()"))
            last = None
        elif name == "Observations":
            nobs = {j: int(float(v)) for j, v in enumerate(vals, start=1) if v}
        elif name.startswith("Adjusted R"):
            adj = {j: float(v) for j, v in enumerate(vals, start=1) if v}
        else:
            last = None
    return out, nobs, adj


def fmt(b, s):
    if b is None or pd.isna(b):
        return "—"
    return f"{b:.3f} ({s:.3f})" if s is not None and not pd.isna(s) else f"{b:.3f}"


def status(ref_b, ref_s, b, s):
    if b is None or pd.isna(b):
        return "—", None
    d = max(abs(b - ref_b), abs((s if s is not None else ref_s) - ref_s))
    # "match to reported precision": rounds to the published 3 decimals
    if round(b + 1e-12, 3) == round(ref_b, 3) or abs(b - ref_b) < 0.0005 + 1e-9:
        if s is None or abs(s - ref_s) < 0.0005 + 1e-9 or round(s + 1e-12, 3) == round(ref_s, 3):
            return "✅", d
    return ("⚠️" if d <= 0.005 else "❌"), d


def table_md(tab):
    lab = labels(DTA_FOR[tab])
    sf = TAB / f"{STATA_FILE[tab]}.csv"
    st, st_n, st_adj = parse_esttab(sf, lab) if sf.exists() else ({}, {}, {})
    spf = OUT / f"table_{tab}.csv"
    sp_df = pd.read_csv(spf) if spf.exists() else pd.DataFrame(columns=["col", "var", "coef", "se", "N", "adj_r2"])
    lines = [f"### {TITLE[tab]}", "",
             "| col | variable | paper b (se) | Stata b (se) | StatsPAI b (se) | N paper / Stata / StatsPAI | Stata | StatsPAI | max abs diff StatsPAI vs paper |",
             "|---|---|---|---|---|---|---|---|---|"]
    tally = {"stata": [0, 0], "sp": [0, 0]}
    for c, d in PAPER[tab].items():
        for v, (pb, ps) in d["vars"].items():
            sb, ss = (st.get(c, {}).get(v) or [None, None])
            q = sp_df[(sp_df["col"] == c) & (sp_df["var"] == v)]
            qb, qs = (float(q.coef.iloc[0]), float(q.se.iloc[0])) if len(q) else (None, None)
            qn = int(q.N.iloc[0]) if len(q) and not pd.isna(q.N.iloc[0]) else None
            s1, _ = status(pb, ps, sb, ss)
            s2, d2 = status(pb, ps, qb, qs)
            if st_n.get(c) is not None and d["N"] is not None and st_n.get(c) != d["N"]:
                s1 = "❌"
            if qn is not None and d["N"] is not None and qn != d["N"]:
                s2 = "❌"
            for key, s_ in [("stata", s1), ("sp", s2)]:
                if s_ != "—":
                    tally[key][1] += 1
                    tally[key][0] += s_ == "✅"
            lines.append(f"| {c} | {v} | {fmt(pb, ps)} | {fmt(sb, ss)} | {fmt(qb, qs)} | "
                         f"{d['N']:,} / {st_n.get(c, '—') if st_n.get(c) is None else format(st_n[c], ',')} / "
                         f"{'—' if qn is None else format(qn, ',')} | {s1} | {s2} | {'' if d2 is None else f'{d2:.4f}'} |")
    # adjusted R2
    adj_rows = []
    for c, d in PAPER[tab].items():
        if d["adj_r2"] is None:
            continue
        q = sp_df[sp_df["col"] == c]
        qa = q.adj_r2.dropna().iloc[0] if "adj_r2" in q and len(q.adj_r2.dropna()) else None
        adj_rows.append(f"{c}: {d['adj_r2']:.3f} / {st_adj.get(c, float('nan')):.3f} / "
                        f"{'—' if qa is None else f'{qa:.3f}'}")
    if adj_rows:
        lines += ["", "Adjusted R² (paper / Stata / StatsPAI): " + "; ".join(adj_rows)]
    lines += ["", f"Cells matching the paper to 3 d.p. (coef, SE and N): Stata {tally['stata'][0]}/{tally['stata'][1]}, "
                  f"StatsPAI {tally['sp'][0]}/{tally['sp'][1]}.", ""]
    return "\n".join(lines), tally


def event_study_md(fig, stata_log, sp_csv, pattern):
    lines = [f"### {fig}", "", "| year | Stata b (se) | StatsPAI b (se) | abs diff b | status |", "|---|---|---|---|---|"]
    stata = {}
    lp = ROOT / "Results" / stata_log
    if lp.exists():
        txt = lp.read_text(errors="ignore")
        blk = txt[txt.find(pattern):] if pattern in txt else ""
        for m in re.finditer(r"^\s+pt(\d+) \|\s+(-?[\d.]+)\s+([\d.]+)", blk, flags=re.M):
            k = int(m.group(1))
            if 2003 + k not in stata:
                stata[2003 + k] = (float(m.group(2)), float(m.group(3)))
    spf = OUT / sp_csv
    sp_df = pd.read_csv(spf) if spf.exists() else pd.DataFrame(columns=["year", "coef", "se"])
    ok = n = 0
    for _, r in sp_df.iterrows():
        y = int(r.year)
        sb = stata.get(y)
        if sb:
            dd = abs(sb[0] - r.coef)
            stt = "✅" if dd < 0.0005 and abs(sb[1] - r.se) < 0.0005 else ("⚠️" if dd < 0.005 else "❌")
            n += 1; ok += stt == "✅"
        else:
            dd, stt = None, "—"
        lines.append(f"| {y} | {fmt(*sb) if sb else '—'} | {fmt(r.coef, r.se)} | {'' if dd is None else f'{dd:.4f}'} | {stt} |")
    lines += ["", f"The paper shows this exhibit only as a graph; comparison is Stata log vs StatsPAI ({ok}/{n} years match to 3 d.p.).", ""]
    return "\n".join(lines)


def main():
    parts = ["# Comparison: paper vs original Stata code vs StatsPAI", "",
             "Paper values: journal full text (OUP HTML, Materials/). Stata: `Program/run_original.do` "
             "(author's `Tables&Figures.do`, Stata 18 MP, reghdfe 6.13.1, estout). StatsPAI: 1.28.0 "
             "(`Program/statspai/`). ✅ = equal at the published 3 decimals (coef, SE, N); ⚠️ = small "
             "difference (≤0.005), explained below; ❌ = larger difference.", ""]
    summary = []
    for tab in ["V", "VI", "VIII", "IX", "X", "XI", "XII"]:
        md, t = table_md(tab)
        parts.append(md)
        summary.append(f"| {tab} | {t['stata'][0]}/{t['stata'][1]} | {t['sp'][0]}/{t['sp'][1]} |")
    parts.append(event_study_md("Figure V — price event study (pt3–pt13, do-file Figure 5)", "log_price_steps.log",
                                "figure_V_event_study.csv", "reghdfe lnprice pt3-pt13"))
    parts.append(event_study_md("Figure VI — quantity event study (do-file Figure 6)", "log_firm_steps.log",
                                "figure_VI_event_study.csv", "reghdfe lnarea pt3-pt13"))
    extra = ROOT / "Results" / "comparison_notes.md"
    head = ["## Summary (cells matching paper to 3 d.p.)", "", "| Table | Stata | StatsPAI |", "|---|---|---|"] + summary + [""]
    text = "\n".join(parts[:4] + head + parts[4:])
    if extra.exists():
        text += "\n" + extra.read_text()
    (ROOT / "Results" / "comparison.md").write_text(text)
    print("\n".join(head))


if __name__ == "__main__":
    main()
