#!/bin/bash
# Build the regression-ready analysis datasets used by the StatsPAI scripts.
# usage: Program/statspai/run_export.sh "10 11 12 8 9 2 14"
# Writes Data/Intermediate/statspai/*.dta ; Stata log in Data/Intermediate/statspai/_logs/
HERE="$(cd "$(dirname "$0")" && pwd)"; PROJ="$(cd "$HERE/../.." && pwd)"
STATA=/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp
/usr/local/bin/python3.13 "$HERE/make_export_do.py"
X="$PROJ/Data/Intermediate/statspai"; mkdir -p "$X/_root/Output" "$X/_logs"
ln -sfn "$PROJ/Data" "$X/_root/Data"; ln -sfn "$PROJ/Program/Analysis" "$X/_root/Analysis"
secs="${1:-10 11 12 8 9 2 14}"
for s in $secs; do
  d="$X/_logs/sec$s"; mkdir -p "$d"
  printf 'global AITOC_ROOT "%s"\nadopath ++ "%s"\ndo "%s" %s\n' "$X/_root" "$PROJ/Program/ado" "$HERE/export_analysis_data.do" "$s" > "$d/run.do"
  t0=$(date +%s); (cd "$d" && "$STATA" -b do run.do); echo "export section $s: $(( $(date +%s)-t0 ))s, errors: $(grep -c '^r([0-9]*);' "$d/run.log")"
done
