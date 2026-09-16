*******************************************************************************
* run_original.do — wrapper for Chen & Kung (2019, QJE) "Tables&Figures.do"
*
* The author's do-file is kept UNMODIFIED in Program/Tables&Figures.do.
* This wrapper:
*   1. sets the project root (edit ROOT below, or pass it as argument 1);
*   2. splits the author's file into one step per exhibit (at the "*Table N*",
*      "*Figure N*" markers) and writes them to Results/_steps/;
*   3. applies ONLY path fixes while splitting (documented in README.md):
*        - drops the author's  cd "D:\Dropbox\princeling\"  line
*        - `use X.dta`              -> `use "$DATA/X.dta"`
*        - `graph save Graph "f.gph"` -> `graph save Graph "$FIG/f.gph", replace`
*      esttab writes tableN.csv to the working directory = Results/Tables/;
*   4. runs every step under -capture-, logging rc and seconds to
*      Results/run_original_steps.csv, and exports every saved graph to PNG.
*
* Requires: reghdfe (6.x), ftools, estout, coefplot  (ssc install ...)
*******************************************************************************
version 18
clear all
set more off
set varabbrev on

args ROOTARG
if "`ROOTARG'" == "" local ROOTARG "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2019-Busting-the-Princelings"
global ROOT "`ROOTARG'"
global DATA "$ROOT/Data"
global TAB  "$ROOT/Results/Tables"
global FIG  "$ROOT/Results/Figures"
global STEP "$ROOT/Results/_steps"
capture mkdir "$ROOT/Results"
capture mkdir "$TAB"
capture mkdir "$FIG"
capture mkdir "$STEP"

* optional: run only selected steps, e.g.  global ONLY "table5 figure5"
if "$ONLY" == "" global ONLY ""

*------------------------------------------------------------------------------
* 1. split the author's do-file into steps
*------------------------------------------------------------------------------
* Fix 5 (not a path fix, documented in README): Table 11 has only oprobit
* models, which have no _cons, so the esttab drop list containing _cons aborts
* with r(111) coefficient _cons not found under current estout. The loop below
* removes that one token from the Table 11 esttab call only.
local src "$ROOT/Program/Tables&Figures.do"
tempname fin fout
file open `fin' using "`src'", read text
local step "table3a"
local steps "`step'"
file open `fout' using "$STEP/`step'.do", write text replace
file read `fin' line
while r(eof) == 0 {
    local l `"`macval(line)'"'
    local t = strtrim(`"`macval(l)'"')
    * step markers: *Table 3A*, *Table 5*, ..., *Figure 4*, ...
    if regexm(`"`macval(t)'"', "^\*(Table|Figure) ([0-9]+[A-Z]?)\*$") {
        local new = lower(regexs(1)) + lower(regexs(2))
        if "`new'" != "`step'" {
            file close `fout'
            local step "`new'"
            local steps "`steps' `step'"
            file open `fout' using "$STEP/`step'.do", write text replace
        }
    }
    * path fix 1: drop the author's Windows cd line
    if regexm(`"`macval(t)'"', "^cd ") {
        file write `fout' `"* [wrapper] removed: `macval(t)'"' _n
    }
    else {
        * path fix 2: use X.dta -> use "$DATA/X.dta"
        if regexm(`"`macval(l)'"', "^use ([A-Za-z0-9_]+\.dta)(.*)$") {
            local l = "use " + char(34) + "\$DATA/" + regexs(1) + char(34) + regexs(2)
        }
        * path fix 3: graph save Graph "f.gph"[, replace] -> $FIG/f.gph, replace
        if regexm(`"`macval(l)'"', `"^graph save Graph "([A-Za-z0-9_]+\.gph)"(.*)$"') {
            local l = "graph save Graph " + char(34) + "\$FIG/" + regexs(1) + char(34) + ", replace"
        }
        * path fix 4: graph combine "f.gph" ... -> $FIG/f.gph
        if regexm(`"`macval(l)'"', "^graph combine ") {
            local l = subinstr(`"`macval(l)'"', char(34) + "figure7", char(34) + "\$FIG/figure7", .)
        }
        if "`step'" == "table11" & regexm(`"`macval(l)'"', "^esttab using table11") {
            local l = subinstr(`"`macval(l)'"', " _cons)", ")", 1)
        }
        file write `fout' `"`macval(l)'"' _n
    }
    file read `fin' line
}
file close `fout'
file close `fin'
di as txt "steps: `steps'"

*------------------------------------------------------------------------------
* 2. run every step, logging rc + seconds
*------------------------------------------------------------------------------
* the author's steps call -clear all-, which closes open file handles, so the
* step log is reopened in append mode after every step
if "$APPEND" == "" {
    file open lg using "$ROOT/Results/run_original_steps.csv", write text replace
    file write lg "step,rc,seconds" _n
    file close lg
}
cd "$TAB"
foreach s of local steps {
    if "$ONLY" != "" & strpos(" $ONLY ", " `s' ") == 0 continue
    di as res _n "=================== `s' ==================="
    timer clear 1
    timer on 1
    capture noisily do "$STEP/`s'.do"
    local rc = _rc
    timer off 1
    quietly timer list 1
    local sec = round(r(t1), 0.1)
    file open lg using "$ROOT/Results/run_original_steps.csv", write text append
    file write lg "`s',`rc',`sec'" _n
    file close lg
    cd "$TAB"
    di as res "step `s': rc=`rc'  seconds=`sec'"
    * export any graph saved by the step
    foreach g in figure4 figure5 figure6 figure7 {
        if "`s'" == "`g'" {
            capture graph use "$FIG/`g'.gph"
            if _rc == 0 capture graph export "$FIG/`g'.png", replace width(1600)
        }
    }
}
* (step log is closed after each step)
di as res "done"
