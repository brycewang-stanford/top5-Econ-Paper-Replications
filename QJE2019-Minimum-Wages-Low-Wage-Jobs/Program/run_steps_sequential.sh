#!/bin/bash
# Run author do-files one Stata batch per step (Stata -b names its log after the full argument
# string; long step lists exceed the 255-char filename limit and Stata exits silently).
# Usage: bash Program/run_steps_sequential.sh <batchdir> step1 step2 ...
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/Results/logs/$1"; shift
mkdir -p "$DIR"; cd "$DIR"
for s in "$@"; do
  /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do "$ROOT/Program/run_original.do" "$s"
done
echo ALLSTEPSDONE > "$DIR/ALLSTEPSDONE"
