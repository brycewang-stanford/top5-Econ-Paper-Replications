*******************************************************************************
* run_original.do — wrapper for the Autor-Dorn-Hanson (2013) file archive
*
* Runs the author's five do-files in order, from Program/do/ (the author's code
* uses paths relative to its own folder: ../../Data/dta, ../../Results/log,
* ../../Results/Figures after our documented path edit), logs return code and
* runtime of each step to Results/log/run_original_steps.txt, and exports the
* author's .gph figures to PNG.
*
* Usage (from anywhere):
*     do "<project root>/Program/run_original.do"
* or set the global ROOT below. Requires estout (ssc install estout).
*******************************************************************************

version 18
clear all
set more off

* ---- project root ----------------------------------------------------------
if "$ROOT" == "" {
    global ROOT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/AER2013-China-Syndrome"
}
cap mkdir "$ROOT/Results/log"
cap mkdir "$ROOT/Results/Figures"
cap mkdir "$ROOT/Results/Tables"

cap which esttab
if _rc {
    ssc install estout, replace
}

cd "$ROOT/Program/do"

tempname fh
file open `fh' using "$ROOT/Results/log/run_original_steps.txt", write replace text
file write `fh' "step" _tab "exhibits" _tab "rc" _tab "seconds" _n

local steps  import_stats_final figure1 czone_analysis_preperiod_final czone_analysis_ipw_final czone_plot_import_long_final
* (Stata local names are limited to 31 characters, so exhibits are indexed by step number)
local ex1 "Table 1"
local ex2 "Figure 1"
local ex3 "Table 2"
local ex4 "Tables 3-10, Appendix Tables 1-5"
local ex5 "Figure 2 (panels A, B)"

local k = 0
foreach s of local steps {
    local ++k
    timer clear 1
    timer on 1
    cap noisily do `s'.do
    local rc = _rc
    timer off 1
    qui timer list 1
    local sec = r(t1)
    cap log close
    di as result "STEP `s': rc=`rc'  seconds=`sec'"
    file write `fh' "`s'" _tab "`ex`k''" _tab "`rc'" _tab "`sec'" _n
    cd "$ROOT/Program/do"
}
file close `fh'

* ---- export figures to PNG ---------------------------------------------------
foreach g in figure1 mfg_imppw_9007long_2sls1_av mfg_imppw_9007long_olsred_av {
    cap graph use "$ROOT/Results/Figures/`g'.gph"
    if !_rc {
        graph export "$ROOT/Results/Figures/`g'.png", replace width(1600)
        graph drop _all
    }
}

cap erase "$ROOT/Program/do/temp.dta"
cd "$ROOT"
type "$ROOT/Results/log/run_original_steps.txt"
