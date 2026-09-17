/* ===========================================================================
   run_original.do -- wrapper for the Beraja-Kao-Yang-Yuchtman (2023, QJE)
   "AI-tocracy" replication package (Harvard Dataverse doi:10.7910/DVN/GCOVGX)

   Usage (from the Program/ folder):
       stata-mp -b do run_original.do            // all 21 sections
       stata-mp -b do run_original.do "8 9"      // selected sections only

   The author's master file Analysis/Analysis.do expects a root folder with
   Analysis/, Data/ and Output/ side by side. Program/_root/ provides exactly
   that through relative symlinks:
       _root/Analysis -> Program/Analysis
       _root/Data     -> Data            (package data, incl. Intermediate/)
       _root/Output   -> Results/Output  (raw author outputs; sorted afterwards)
   Each section (the author's `output' switch 1-21) is run in its own -do-
   call; rc and wall-clock seconds are appended to Results/logs/run_original_steps.csv.
   =========================================================================== */

version 18
set more off
args steps
if "`steps'" == "" local steps "7 8 9 2 4 10 5 6 11 12 13 14 15 16 18 19 20 21 1 3 17"

local prog "`c(pwd)'"
if "$AITOC_PROG" != "" local prog "$AITOC_PROG"   // set by Program/run_original.sh for parallel groups
global AITOC_ROOT "`prog'/_root"
adopath ++ "`prog'/ado"          // carryforward, xtevent (project-local installs)

cap mkdir "`prog'/../Results/logs"
local csv "`prog'/../Results/logs/run_original_steps.csv"
cap confirm file "`csv'"
if _rc {
    file open fh using "`csv'", write text replace
    file write fh "section,rc,seconds,finished" _n
    file close fh
}

foreach s of local steps {
    local t0 = clock(c(current_time), "hms") + 86400000*date(c(current_date), "DMY")
    di as txt _n "{hline 70}" _n "=== Analysis.do section `s' started `c(current_date)' `c(current_time)'" _n "{hline 70}"
    cap noisily do "$AITOC_ROOT/Analysis/Analysis.do" `s'
    local rc = _rc
    cap log close _all
    local t1 = clock(c(current_time), "hms") + 86400000*date(c(current_date), "DMY")
    local secs = round((`t1' - `t0')/1000)
    di as txt "=== section `s' finished rc=`rc' seconds=`secs'"
    file open fh using "`csv'", write text append
    file write fh "`s',`rc',`secs',`c(current_date)' `c(current_time)'" _n
    file close fh
    qui cd "`prog'"
    global AITOC_ROOT "`prog'/_root"
}
