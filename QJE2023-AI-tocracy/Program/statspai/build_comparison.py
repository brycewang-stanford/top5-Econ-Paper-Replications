"""Build Results/comparison.md: paper (published QJE PDF) vs original Stata code (our re-run,
Results/Tables/*.tex) vs StatsPAI (Results/statspai/*.csv), number by number."""
import re

from common import *

TAB = PROJ / "Results" / "Tables"
RAW = PROJ / "Results" / "Output"      # staging dir used while a run is in progress
SHIP = PROJ / "Materials" / "package" / "Output_shipped"


def texfile(name):
    for d in (TAB, RAW):
        p = d / name
        if p.exists():
            return p
    return None


def parse_tex(name):
    """Return list of (label, [coef strings], [se strings]) from an estout tex fragment."""
    p = texfile(name)
    if p is None:
        return None
    lines = [l for l in p.read_text().splitlines() if "&" in l]
    out = []
    i = 0
    while i < len(lines):
        cells = [c.strip().rstrip("\\").strip() for c in lines[i].split("&")]
        lab = cells[0]
        vals = [re.sub(r"[*\s]", "", c) for c in cells[1:]]
        ses = []
        if i + 1 < len(lines) and lines[i + 1].split("&")[0].strip() == "":
            ses = [re.sub(r"[()\s\\]", "", c) for c in lines[i + 1].split("&")[1:]]
            i += 1
        out.append((lab, vals, ses))
        i += 1
    return out


def num(s):
    try:
        return float(s)
    except Exception:
        return np.nan


P = {}  # paper values: key -> (coef list, se list)
P["II.A"] = ([.199, .196, .199, .204, .205], [.043, .046, .044, .046, .044])
P["II.B"] = ([.377, .377, .377, .349, .348], [.084, .084, .084, .080, .080])
P["III.A"] = ([.436, .420, .436, .425, .425], [.084, .083, .085, .080, .080])
P["III.B"] = ([.593, .599, .593, .559, .559], [.175, .174, .175, .167, .167])
P["III.C"] = ([.681, .669, .680, .671, .671], [.154, .157, .155, .148, .148])
P["III.D"] = ([1.054, 1.070, 1.054, .967, .966], [.374, .376, .374, .334, .334])
P["IV.A.cw"] = ([.9176, .9523, .9183, .9511], [.1609, .1597, .1613, .1543])
P["IV.A.st"] = ([-.0080, -.0032, -.0079, -.0020], [.0039, .0050, .0038, .0050])
P["IV.A.in"] = ([-.2265, -.2729, -.2260, -.2662], [.1153, .1306, .1156, .1250])
P["IV.B.cw"] = ([.9113, .9446, .9118, .9449], [.1585, .1560, .1587, .1517])
P["IV.B.st"] = ([.2462, .2734, .2455, .2638], [.1074, .0997, .1073, .0945])
P["IV.B.in"] = ([-.5688, -.6598, -.5735, -.6403], [.2281, .2401, .2304, .2229])
P["V.A.cw"] = ([.9378, .9768, .9385, .9747], [.1678, .1666, .1682, .1608])
P["V.A.st"] = ([-.0021, -.0022, -.0021, -.0019], [.0012, .0014, .0012, .0012])
P["V.A.in"] = ([-.0441, -.0513, -.0444, -.0473], [.0299, .0338, .0305, .0301])
P["V.B.cw"] = ([.9770, .9813, .9777, .9798], [.1660, .1711, .1664, .1656])
P["V.B.st"] = ([.0002, -.0006, .0038, .0013], [.0672, .0706, .0684, .0664])
P["V.B.in"] = ([-.0110, -.0114, -.0120, -.0114], [.0187, .0195, .0189, .0186])
P["VI.A"] = ([10.671, 11.153, 13.111, 9.287, 9.711, 11.124], [3.664, 3.103, 2.957, 2.127, 2.119, 1.948])
P["VI.B"] = ([3.465, 3.566, 4.198, 3.099, 3.170, 3.745], [1.543, 1.415, 1.375, .920, .916, .952])
P["VI.C"] = ([5.098, 5.310, 6.009, 3.718, 3.898, 4.373], [2.409, 1.956, 1.856, 1.146, 1.157, .945])
P["VII.A.b"] = ([5.239, 4.170, .646, 1.509, .564, -1.043], [3.427, 2.805, 1.318, 1.539, 1.519, .926])
P["VII.A.a"] = ([.823, 4.625, 6.330, 1.893, 4.041, 5.452], [1.644, 1.946, 1.696, 1.029, 1.322, 1.285])
P["VII.A.bp"] = ([-1.897, -2.221, -1.941, .246, .464, -.055], [1.239, 1.665, 1.221, 1.250, 1.453, 1.286])
P["VII.A.ap"] = ([9.825, 4.024, 7.896, 7.460, 4.071, 6.385], [3.368, 3.829, 2.439, 1.863, 1.670, 1.560])
P["VII.B.b"] = ([1.697, .951, .065, .230, -.259, -.712], [1.067, .706, .514, .491, .631, .508])
P["VII.B.a"] = ([1.278, 3.196, 3.205, .700, 1.465, 2.048], [.778, 1.054, .885, .490, .702, .639])
P["VII.B.bp"] = ([-.158, .154, -.222, .429, .883, .250], [.463, .602, .457, .498, .643, .477])
P["VII.B.ap"] = ([2.180, -.128, 1.360, 2.408, 1.453, 1.963], [1.284, 1.455, 1.079, .771, .906, .756])
P["VII.C.b"] = ([2.267, 1.694, .304, .689, .285, -.263], [1.510, 1.015, .490, .742, .555, .276])
P["VII.C.a"] = ([-.420, .759, 1.883, .476, 1.174, 1.820], [.821, .637, .703, .551, .410, .456])
P["VII.C.bp"] = ([-.754, -.937, -.823, -.171, -.169, -.274], [.511, .550, .563, .360, .393, .415])
P["VII.C.ap"] = ([5.482, 1.979, 4.521, 3.225, 1.552, 2.805], [2.168, 1.616, 1.522, 1.037, .636, .803])
P["VIII"] = ([.032, .036, .039, .036], [.018, .017, .019, .018])
P["IX.A"] = ([23.968, 1.372, 9.812], [10.122, 1.102, 4.709])
P["IX.B"] = ([.003, .028, .047], [.071, .033, .046])
P["IX.C"] = ([-.498, -.102, 1.365], [.381, .391, .310])

# (paper key) -> (tex file, row index in tex, digits)
TEXMAP = {
    "II.A": ("Table2_PanelA_ols.tex", 0, 3), "II.B": ("Table2_PanelB_iv.tex", 0, 3),
    "III.A": ("Table3_PanelA.1_olscam.tex", 0, 3), "III.B": ("Table3_PanelA.2_ivcam.tex", 0, 3),
    "III.C": ("Table3_PanelB.1_olsaicam.tex", 0, 3), "III.D": ("Table3_PanelB.2_ivaicam.tex", 0, 3),
    "IV.A.cw": ("Table4_PanelA_ai.tex", 0, 4), "IV.A.st": ("Table4_PanelA_ai.tex", 1, 4), "IV.A.in": ("Table4_PanelA_ai.tex", 2, 4),
    "IV.B.cw": ("Table4_PanelB_aicam.tex", 0, 4), "IV.B.st": ("Table4_PanelB_aicam.tex", 1, 4), "IV.B.in": ("Table4_PanelB_aicam.tex", 2, 4),
    "V.A.cw": ("Table5_PanelA_nonpublic.tex", 0, 4), "V.A.st": ("Table5_PanelA_nonpublic.tex", 1, 4), "V.A.in": ("Table5_PanelA_nonpublic.tex", 2, 4),
    "V.B.cw": ("Table5_PanelB_pastunrest.tex", 0, 4), "V.B.st": ("Table5_PanelB_pastunrest.tex", 1, 4), "V.B.in": ("Table5_PanelB_pastunrest.tex", 2, 4),
    "VI.A": ("Table6_PanelA_total.tex", 0, 3), "VI.B": ("Table6_PanelB_gov.tex", 0, 3), "VI.C": ("Table6_PanelC_commercial.tex", 0, 3),
    "VIII": ("Table8_export.tex", 0, 3),
    "IX.A": ("Table9_PanelA_unrestlocality.tex", 0, 3), "IX.B": ("Table9_PanelB_contractHQ.tex", 0, 3), "IX.C": ("Table9_PanelC_motherfirm.tex", 0, 3),
}
for pan, f in (("A", "Table7_PanelA_total.tex"), ("B", "Table7_PanelB_gov.tex"), ("C", "Table7_PanelC_commercial.tex")):
    for j, s in enumerate(("b", "a", "bp", "ap")):
        TEXMAP[f"VII.{pan}.{s}"] = (f, j, 3)

LABEL = {
    "II.A": "Table II A (OLS) unrest_{t-1}", "II.B": "Table II B (LASSO IV) unrest_{t-1}",
    "III.A": "Table III A (OLS, cameras)", "III.B": "Table III B (LASSO IV, cameras)",
    "III.C": "Table III C (OLS, AI x cameras)", "III.D": "Table III D (LASSO IV, AI x cameras)",
}
for t, p in (("IV", "A"), ("IV", "B"), ("V", "A"), ("V", "B")):
    for s, lab in (("cw", "conducive weather"), ("st", "stock_{t-1}"), ("in", "weather x stock_{t-1}")):
        LABEL[f"{t}.{p}.{s}"] = f"Table {t} {p}: {lab}"
for p, lab in (("A", "total"), ("B", "government"), ("C", "commercial")):
    LABEL[f"VI.{p}"] = f"Table VI {p} ({lab}) 8q after"
    for s, l2 in (("b", "8q before"), ("a", "8q after"), ("bp", "8q before x PS"), ("ap", "8q after x PS")):
        LABEL[f"VII.{p}.{s}"] = f"Table VII {p} ({lab}) {l2}"
LABEL["VIII"] = "Table VIII public security"
for p, lab in (("A", "unrest locality"), ("B", "contract HQ"), ("C", "mother firm")):
    LABEL[f"IX.{p}"] = f"Table IX {p} ({lab}) 8q after"


def stata_vals(key):
    f, row, dg = TEXMAP[key]
    rows = parse_tex(f)
    if rows is None or row >= len(rows):
        return None, None
    lab, vals, ses = rows[row]
    vals = [v for v in vals if v != ""]
    ses = [s for s in ses if s != ""]
    return [num(v) for v in vals], [num(s) for s in ses]


def sp_vals():
    S = {}
    def load(n):
        p = OUT / n
        return pd.read_csv(p) if p.exists() else None
    t = load("table2_table3_ols.csv")
    if t is not None:
        for (tab, pan), g in t.groupby(["table", "panel"]):
            key = {"II": "II.A"}.get(tab) if tab == "II" else ("III.A" if "cameras)" in pan and "AI" not in pan else "III.C")
            g = g.sort_values("column"); S[key] = (list(g.coef), list(g.se), "exact")
    t = load("table2_table3_lassoiv_approx.csv")
    if t is not None:
        for (tab, pan), g in t.groupby(["table", "panel"]):
            key = "II.B" if tab == "II" else ("III.B" if pan.startswith("B") else "III.D")
            g = g.sort_values("column"); S[key] = (list(g.coef), list(g.se), "approx")
    t = load("table4_table5.csv")
    if t is not None:
        m = {"Conducive weather": "cw", "Stock_{t-1}": "st", "Conducive weather x stock_{t-1}": "in"}
        for (tab, pan, term), g in t.groupby(["table", "panel", "term"]):
            g = g.sort_values("column"); S[f"{tab}.{pan}.{m[term]}"] = (list(g.coef), list(g.se), "exact")
    t = load("table6_table7.csv")
    if t is not None:
        for (tab, pan, term), g in t.groupby(["table", "panel", "term"]):
            g = g.sort_values("column")
            if tab == "VI":
                S[f"VI.{pan}"] = (list(g.coef), list(g.se), "exact")
            else:
                s = {"8 quarters before contract": "b", "8 quarters after contract": "a",
                     "8 quarters before contract x public security": "bp", "8 quarters after contract x public security": "ap"}[term]
                S[f"VII.{pan}.{s}"] = (list(g.coef), list(g.se), "exact")
    t = load("table8.csv")
    if t is not None:
        g = t.sort_values("column"); S["VIII"] = (list(g.coef), list(g.se), "exact")
    t = load("table9.csv")
    if t is not None:
        for pan, g in t.groupby("panel"):
            g = g.sort_values("column"); S[f"IX.{pan}"] = (list(g.coef), list(g.se), "exact")
    return S


def fmt(x, dg):
    return "" if x is None or not np.isfinite(x) else f"{x:.{dg}f}"


def mark(pv, st, spv, dg, approx=False):
    tol = 0.5 * 10 ** (-dg) + 1e-9
    if st is None or not np.isfinite(st):
        m_st = "—"
    else:
        m_st = "✅" if abs(pv - st) <= tol else ("⚠️" if abs(pv - st) <= max(0.05 * abs(pv), 3 * 10 ** (-dg)) else "❌")
    if spv is None or not np.isfinite(spv):
        m_sp = "—"
    elif approx:
        m_sp = "⚠️"
    else:
        ref = st if (st is not None and np.isfinite(st)) else pv
        d_ = abs(ref - round(spv, dg))
        m_sp = "✅" if d_ <= 1e-9 + 10 ** (-dg) * 0.01 else ("⚠️" if d_ <= max(0.05 * abs(ref), 3 * 10 ** (-dg)) else "❌")
    return m_st, m_sp


def main():
    S = sp_vals()
    lines = ["# Comparison: paper vs original Stata code vs StatsPAI", "",
             "Paper = published QJE PDF (Materials/AI-tocracy (QJE 2023).pdf). Original Stata = our re-run of the author's "
             "`Analysis.do` (Stata 18 MP, reghdfe 6.13.1, ivreghdfe 1.1.4, xtevent 1.0.0; `Results/Tables/*.tex`). "
             "StatsPAI = `Program/statspai/*.py` (statspai 1.28.0; `Results/statspai/*.csv`).",
             "Marks: Stata column vs paper; StatsPAI column vs our Stata run (vs paper if Stata missing). "
             "✅ equal at reported precision · ⚠️ small difference, explained below / approximation · ❌ material difference, explained below.", ""]
    order = ["II.A", "II.B", "III.A", "III.B", "III.C", "III.D"] + \
            [f"{t}.{p}.{s}" for t, p in (("IV", "A"), ("IV", "B"), ("V", "A"), ("V", "B")) for s in ("cw", "st", "in")] + \
            ["VI.A", "VI.B", "VI.C"] + [f"VII.{p}.{s}" for p in "ABC" for s in ("b", "a", "bp", "ap")] + ["VIII", "IX.A", "IX.B", "IX.C"]
    counts = {"st": {"✅": 0, "⚠️": 0, "❌": 0, "—": 0}, "sp": {"✅": 0, "⚠️": 0, "❌": 0, "—": 0}}
    cur = None
    for key in order:
        tab = key.split(".")[0]
        if tab != cur:
            lines += ["", f"## Table {tab}", "", "| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |",
                      "|---|---|---|---|---|---|---|---|---|"]
            cur = tab
        pb, ps = P[key]
        dg = TEXMAP[key][2]
        sb, ss = stata_vals(key)
        spb, sps, kind = S.get(key, (None, None, None))
        for j in range(len(pb)):
            b1 = sb[j] if sb and j < len(sb) else None
            s1 = ss[j] if ss and j < len(ss) else None
            b2 = spb[j] if spb and j < len(spb) else None
            s2 = sps[j] if sps and j < len(sps) else None
            m1b, m2b = mark(pb[j], b1, b2, dg, kind == "approx")
            m1s, m2s = mark(ps[j], s1, s2, dg, kind == "approx")
            worst = lambda a, b: "❌" if "❌" in (a, b) else ("⚠️" if "⚠️" in (a, b) else ("✅" if "✅" in (a, b) else "—"))
            mst, msp = worst(m1b, m1s), worst(m2b, m2s)
            counts["st"][mst] += 1; counts["sp"][msp] += 1
            d1 = f"{fmt(abs(pb[j]-b1), dg) if b1 is not None and np.isfinite(b1) else ''} / {fmt(abs(ps[j]-s1), dg) if s1 is not None and np.isfinite(s1) else ''}"
            ref_b, ref_s = (b1, s1) if (b1 is not None and np.isfinite(b1)) else (pb[j], ps[j])
            d2 = f"{fmt(abs(ref_b-b2), dg) if b2 is not None else ''} / {fmt(abs(ref_s-s2), dg) if s2 is not None and ref_s is not None else ''}"
            lines.append(f"| {LABEL[key]} | {j+1} | {pb[j]:.{dg}f} ({ps[j]:.{dg}f}) | {fmt(b1, dg)} ({fmt(s1, dg)}) | "
                         f"{fmt(b2, dg)} ({fmt(s2, dg)}) | {d1} | {d2} | {mst} | {msp}{' (approx.)' if kind == 'approx' else ''} |")
    lines += ["", "## Tally (coefficient rows)", "",
              f"- Original Stata vs paper: ✅ {counts['st']['✅']} · ⚠️ {counts['st']['⚠️']} · ❌ {counts['st']['❌']} · not run {counts['st']['—']}",
              f"- StatsPAI vs Stata: ✅ {counts['sp']['✅']} · ⚠️ {counts['sp']['⚠️']} · ❌ {counts['sp']['❌']} · not available {counts['sp']['—']}", ""]
    # ---- every .tex exhibit: our re-run vs the author's shipped Output/ (includes all appendix tables)
    lines += ["", "## All tabular exhibits: re-run vs the author's shipped `Output/*.tex`", "",
              "Cell-by-cell comparison of every number in each estout/file-write fragment (the shipped files are the "
              "authors' own January 2023 outputs, i.e. the online-appendix numbers).", "",
              "| File | cells | identical | max abs diff | status |", "|---|---|---|---|---|"]
    numre = re.compile(r"-?\d[\d,]*\.?\d*")
    for sp_ in sorted(SHIP.glob("*.tex")):
        mine = texfile(sp_.name)
        if mine is None:
            lines.append(f"| {sp_.name} | | | | not produced (see notes) |")
            continue
        a = [float(x.replace(",", "")) for x in numre.findall(sp_.read_text())]
        b = [float(x.replace(",", "")) for x in numre.findall(mine.read_text())]
        if len(a) != len(b):
            lines.append(f"| {sp_.name} | {len(a)} vs {len(b)} | | | layout differs (extra/missing columns) |")
            continue
        diffs = [abs(x - y) for x, y in zip(a, b)]
        same = sum(d == 0 for d in diffs)
        mx = max(diffs) if diffs else 0
        st = "✅ identical" if mx == 0 else ("⚠️ last-digit" if mx <= 0.0011 else "❌ differs")
        lines.append(f"| {sp_.name} | {len(a)} | {same} | {mx:.4g} | {st} |")
    logs = SHIP / "TableA3_xpoivregress.log"
    notes = PROJ / "Results" / "comparison_notes.md"
    if notes.exists():
        lines += ["", notes.read_text()]
    (PROJ / "Results" / "comparison.md").write_text("\n".join(lines))
    print("\n".join(lines[-8:]))


if __name__ == "__main__":
    main()
