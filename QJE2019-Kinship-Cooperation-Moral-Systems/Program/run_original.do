*******************************************************************************
* run_original.do  --  wrapper for Enke (2019, QJE) replication package
*   Harvard Dataverse doi:10.7910/DVN/JX1OIU
*
* The author's code (Program/do-files/, UNMODIFIED) expects to be run from a
* directory that contains
*     Data_programs/Data         the .dta inputs
*     Data_programs/Do-files     the do-files themselves
*     Source_files/Tables and Source_files/Figs   outputs
* (NB: never write a slash followed by an asterisk in this header -- Stata
*  treats it as the start of a block comment.)
* Instead of editing paths, this wrapper builds that tree under
* Results/_run/ with symbolic links into the project folders:
*     Results/_run/Data_programs/Data      -> Data/
*     Results/_run/Data_programs/Do-files  -> Program/do-files/
*     Results/_run/Source_files/Tables     -> Results/Tables/
*     Results/_run/Source_files/Figs       -> Results/Figures/
*
* Other differences from the author's Generate_results.do (documented in README):
*   1. The global macros are copied verbatim from Generate_results.do.
*   2. Each do-file is executed with -do- (not -run-) inside -capture noisily-
*      so that the log shows every regression, and rc + seconds are recorded.
*   3. -set seed 20190001- before every step: the author sets no seed, so the
*      bootstrap SEs (Tables 3, 4 and Figure 4) differ slightly run to run.
*   4. Table 10: the author's file runs columns (1)-(3) but never calls esttab
*      (the esttab line is commented out because columns (4)-(6) need restricted
*      Gallup data). The wrapper writes cols (1)-(3) to Results/Tables/GPS_punish_cols1_3.tex.
*
* Usage:  stata-mp -b do Program/run_original.do   (from the project root)
*         or edit the root global below.
*******************************************************************************

clear all
set more off
version 18

* ---- project root -----------------------------------------------------------
global ROOT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2019-Kinship-Cooperation-Moral-Systems"

* ---- build author-expected directory tree via symlinks ----------------------
cd "$ROOT"
capture mkdir "Results"
capture mkdir "Results/Tables"
capture mkdir "Results/Figures"
shell rm -rf "$ROOT/Results/_run"
shell mkdir -p "$ROOT/Results/_run/Data_programs" "$ROOT/Results/_run/Source_files"
shell ln -s "$ROOT/Data"              "$ROOT/Results/_run/Data_programs/Data"
shell ln -s "$ROOT/Program/do-files"  "$ROOT/Results/_run/Data_programs/Do-files"
shell ln -s "$ROOT/Results/Tables"    "$ROOT/Results/_run/Source_files/Tables"
shell ln -s "$ROOT/Results/Figures"   "$ROOT/Results/_run/Source_files/Figs"
cd "$ROOT/Results/_run"

capture log close _all
log using "$ROOT/Results/run_original.log", replace text name(main)

* ---- required user-written packages -----------------------------------------
foreach p in estout binscatter {
    capture which `p'
    if _rc ssc install `p', replace
}

* ---- globals copied verbatim from Generate_results.do -----------------------
global controls_country "ln_time_obs_ea small_scale"
global controls_country_drop "small_scale"
global controls_country_migrant "corigin_ln_time_obs_ea corigin_small_scale"
global controls_country_migrant_drop "corigin_small_scale"
global controls_ind "i.age female"
global controls_ind_drop "*age"
global controls_ethnic "ln_time_obs_ea_e small_scale"
global controls_ethnic_drop "small_scale"
global controls_history_origins "ln_time_obs_ea"
global controls_history "ln_time_obs_ea"
global controls_history_drop ""

* ---- steps, in the order of Generate_results.do -----------------------------
local steps ///
    EA/Table_3 EA/Table_4 EA/Table_5 EA/Figures_2_3 EA/Figure_4 EA/Table_11 ///
    Country/Tables_6_7_9_10 Country/Figure_5 Country/Figures_6_8 Country/Figure_9 ///
    MFQ/Table_8 MFQ/Figure_7

tempname steplog
postfile `steplog' str40 step rc seconds using "$ROOT/Results/run_original_steps.dta", replace

local i = 0
foreach s of local steps {
    local ++i
    display as text _n "{hline 78}" _n "STEP `i': `s'" _n "{hline 78}"
    set seed 20190001
    timer clear 1
    timer on 1
    capture noisily do "Data_programs/Do-files/`s'.do"
    local rc = _rc
    timer off 1
    quietly timer list 1
    local secs = r(t1)
    post `steplog' ("`s'") (`rc') (`secs')
    display as result "STEP `s' finished: rc=`rc'  seconds=" %9.1f `secs'

    * Table 10 cols (1)-(3): estimates are left in memory by Tables_6_7_9_10.do
    if "`s'" == "Country/Tables_6_7_9_10" & `rc' == 0 {
        capture noisily esttab using "$ROOT/Results/Tables/GPS_punish_cols1_3.tex", ///
            booktabs nonotes replace compress label nomtitles ///
            indicate("Country-level controls=ln_time_obs_ea" "Continent FE=*cont*") ///
            drop(_cons $controls_country_drop) se(2) b(a2) r2(2) star(* 0.10 ** 0.05 *** 0.01)
        capture noisily esttab, se b(%9.4f) r2 drop(_cons) star(* 0.10 ** 0.05 *** 0.01)
    }
}
postclose `steplog'

* ---- summary ----------------------------------------------------------------
use "$ROOT/Results/run_original_steps.dta", clear
list, noobs clean
export delimited using "$ROOT/Results/run_original_steps.csv", replace
quietly summarize seconds
display as result "TOTAL seconds: " %9.1f r(sum)

log close main
cd "$ROOT"
shell rm -rf "$ROOT/Results/_run"
