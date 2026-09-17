"""Generate Program/statspai/export_analysis_data.do from the author's Analysis.do.

The author's master file builds every regression dataset in memory (daily
weather merges, collapses, cumulative software counts under -set sortseed-)
and never saves them.  To let the StatsPAI scripts start from *exactly* the
same analysis samples, this script copies Analysis.do and inserts
`save` hooks immediately before the estimation commands.  The author's code
itself is not modified; the generated file is a derived artefact.

Hooks (all written to Data/Intermediate/statspai/):
  sec 2  : s2_<outcome>.dta            (Figure 2 / A.12 / A.13 lead-lag panel)
  sec 8/9: s8_ols_<outcome>.dta, s8_lasso_<outcome>.dta, s9_...   (Tables 2-3)
  sec 10 : s10_raw_b<k>.dta (before the conducive-weather first stage) and
           s10_<estout-file-stem>.dta (state right before each estout)   (Tables 4-5)
  sec 11 : s11_<t>_<pre>_<i>.dta        (Table 6, Figure 5)
  sec 12 : s12_<t>_<pre>_<i>.dta        (Table 7, Figure 6)
  sec 14 : s14_<panel>_<t>.dta          (Table 9)

The expensive cross-fit LASSO IV (xpoivregress) is replaced by a stub that posts
a dummy e(b) so that the downstream -est sto-/-estout- lines still run.
"""
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "Analysis" / "Analysis.do"
DST = HERE / "export_analysis_data.do"

KEEP_SECTIONS = {2, 8, 9, 10, 11, 12, 14}

lines = SRC.read_text(encoding="utf-8", errors="surrogateescape").split("\n")
out = []
sec = None
lasso = False
b10 = 0
panel = ""
sec_re = re.compile(r'^if "`output\'" == "(\d+)"')
for ln in lines:
    m = sec_re.match(ln)
    if m:
        sec = int(m.group(1))
        lasso = False
        panel = ""
    s = ln.strip()
    save = None
    if sec in KEEP_SECTIONS:
        if s.startswith("****** LASSO"):
            lasso = True
        if s.startswith("****** Panel "):
            panel = s.split()[2]
        if sec == 2 and s.startswith("ivreghdfe `outcome' blank_*"):
            save = "s2_`outcome'"
        elif sec in (8, 9) and s.startswith("*** Col 1:"):
            save = f"s{sec}_{'lasso' if lasso else 'ols'}_`outcome'"
        elif sec == 10 and re.match(r"^ivreghdfe event (event_elsewhere|`i3')", s):
            b10 += 1
            save = f"s10_raw_b{b10}"
        elif sec == 10 and s.startswith("estout a* using"):
            stem = re.search(r'Output/([^"]+)\.tex', s).group(1)
            save = f"s10_{stem}"
        elif sec in (11, 12) and s.startswith("reghdfe n_`ip'_cum"):
            save = f"s{sec}_`t'_`pre'_`i'"
        elif sec == 14 and (s.startswith("xtevent ") or s.startswith("reghdfe n_software")):
            save = f"s14_{panel}_`t'"
    if save:
        out.append(f'qui save "Data/Intermediate/statspai/{save}.dta", replace  // [EXPORT HOOK]')
    if sec in KEEP_SECTIONS and (s.startswith("xpoivregress") or s.startswith("lassocoef")):
        # skip the slow cross-fit LASSO IV; post a trivial estimate so est sto/estout keep working
        out.append("qui regress blank  // [EXPORT] replaces: " + s[:60])
        continue
    out.append(ln)

text = "\n".join(out)
# never touch the author's own intermediate figure files from the export run
text = text.replace('"Data/Intermediate/Fig', '"Data/Intermediate/statspai/_fig_Fig')
# only run the sections we need
text = text.replace('local output = "all"\n', 'local output = "all"\n* [EXPORT] sections restricted below\n', 1)

stub = r'''
* [EXPORT] stub for the cross-fit LASSO IV: posts a dummy coefficient so est sto/estout still work
cap program drop xpoivregress
program define xpoivregress, eclass
    tempname b V
    matrix `b' = (0)
    matrix colnames `b' = blank
    matrix `V' = (1)
    matrix colnames `V' = blank
    matrix rownames `V' = blank
    ereturn post `b' `V'
end
cap program drop lassocoef
program define lassocoef
    di "[EXPORT] lassocoef skipped"
end
cap mkdir "Data/Intermediate/statspai"
'''
marker = "**************** HELPER FUNCTIONS ******************"
assert marker in text
text = text.replace(marker, stub + "\n" + marker, 1)
DST.write_text(text, encoding="utf-8", errors="surrogateescape")
n = sum(1 for l in out if "[EXPORT HOOK]" in l)
print(f"wrote {DST} with {n} save hooks")
