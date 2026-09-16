*******************************************************************************
* run_original.do -- wrapper for Haushofer & Shapiro (QJE 2016) package
*
* Usage (from any directory):
*   stata-mp -b do "<PROJECT>/Program/run_original.do" [main|appendix|all]
*   stata-mp -b do "<PROJECT>/Program/run_original.do" <label> step1 step2 ...
*   (the second form is how the package was actually run here: 7 parallel
*    groups, because the 10,000-iteration stepdown steps take hours each)
*
* Runs the author's Program/Do/MASTER.do once per step (MASTER's own flags are
* switched via the global UCT_ONLYSTEP, see the [REPLICATION EDIT] block in
* MASTER.do), logging return code and seconds for each step to
* Results/logs/run_original_steps_<part>.csv and the full Stata output to
* Results/logs/run_original_<part>.log.
*******************************************************************************
version 18
clear all
set more off
* first argument = group name (main|appendix|all|<label>); optional further
* arguments = explicit list of MASTER steps to run under that label
local part : word 1 of `0'
local extra : list 0 - part
if "`part'" == "" local part "all"

* ---- project root: edit if you move the project -----------------------------
global UCT_PROJECT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2016-Cash-Transfers-Kenya"

cap mkdir "$UCT_PROJECT/Results"
cap mkdir "$UCT_PROJECT/Results/Tables"
cap mkdir "$UCT_PROJECT/Results/Figures"
cap mkdir "$UCT_PROJECT/Results/logs"

cap log close uctwrap
log using "$UCT_PROJECT/Results/logs/run_original_`part'.log", replace text name(uctwrap)

local main "maketable1 maketable2 maketable3 maketable4 maketable5 maketable6 maketableA1"
local appendix "primary_effects baselinecontrols spillover_effects acrossvillage femalerec monthly large respondent OASection5_3 OASection6 OASection7_1 OASection8_1 OASection8_2 OASection9_1 OASection9_2 OASection9_3 OASection9_4 OASection9_5 OASection9_6 OASection9_7 OASection10_1 OASection12_1 OASection12_2 OASection13_1 OASection14_1 OASection15_1 OASection16_1 OASection16_2 OASection17_1 OASection19_1"
if "`part'" == "main" local steps "`main'"
else if "`part'" == "appendix" local steps "`appendix'"
else if "`part'" == "all" local steps "`main' `appendix'"
else if "`extra'" != "" local steps "`extra'"   // label + explicit step list
else local steps "`part'"   // a single step name

local csv "$UCT_PROJECT/Results/logs/run_original_steps_`part'.csv"
tempname fh
file open `fh' using "`csv'", write replace text
file write `fh' "step,rc,seconds,finished" _n
file close `fh'

foreach s of local steps {
	global UCT_ONLYSTEP "`s'"
	di as txt _n "{hline 78}" _n "=== STEP `s' ===  `c(current_date)' `c(current_time)'" _n "{hline 78}"
	local t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
	cd "$UCT_PROJECT/Program/Do"    // MASTER.do does `cd ..` and builds all paths from there
	capture noisily do MASTER.do
	local rc = _rc
	local secs = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - `t0')/1000
	* MASTER.do runs -clear all- which closes open file handles, so reopen per step
	file open `fh' using "`csv'", write append text
	file write `fh' "`s',`rc',`secs',`c(current_date)' `c(current_time)'" _n
	file close `fh'
	di as res "=== STEP `s' finished: rc=`rc'  seconds=`secs'"
}
global UCT_ONLYSTEP ""
cd "$UCT_PROJECT"
log close uctwrap
