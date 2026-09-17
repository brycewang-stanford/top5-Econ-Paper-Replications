#!/bin/bash
# Launch groups of Analysis.do sections as parallel Stata batch jobs.
# usage: Program/run_original.sh "7 8 9" "4 10" ...   (each quoted list = one Stata process)
# Each group logs to Results/logs/group_<list>/run.log ; per-section rc/seconds -> Results/logs/run_original_steps.csv
PROG="$(cd "$(dirname "$0")" && pwd)"
STATA=/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp
[ $# -eq 0 ] && set -- "7 8 9 2 4 10 5 6 11 12 13 14 15 16 18 19 20 21 1 3 17"
for grp in "$@"; do
  d="$PROG/../Results/logs/group_${grp// /_}"; mkdir -p "$d"
  printf 'global AITOC_PROG "%s"\ndo "%s/run_original.do" "%s"\n' "$PROG" "$PROG" "$grp" > "$d/run.do"
  (cd "$d" && "$STATA" -b do run.do) &
done
wait
# sort author outputs: tables/logs -> Results/Tables, figures -> Results/Figures
cd "$PROG/../Results/Output" && for f in *; do
  case "$f" in *.tex|*.log|*.csv) mv -f "$f" ../Tables/ ;; *.png|*.pdf|*.gph) mv -f "$f" ../Figures/ ;; esac
done 2>/dev/null
# maps (Figure 1, A.5)
