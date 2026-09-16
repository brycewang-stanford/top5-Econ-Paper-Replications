*******************************************************************************
* run_precise.do  --  high-precision coefficient dump of the author's tables
*
* The author's esttab calls round to 2 significant digits (b(a2) se(2)), which
* is enough to compare with the paper but not to measure StatsPAI-vs-Stata
* differences.  This helper re-executes the SAME author do-files, with one
* mechanical change made on the fly with -filefilter- into a temporary copy
* (the files in Program/do-files stay untouched):
*       "esttab using"   ->   "esttab_precise using"
* esttab_precise ignores the author's LaTeX options and writes a csv with
* 6 decimals for the coefficients of interest plus N and R2 to
* Results/Tables/precise/<table>.csv
*
* Same seed as run_original.do, so the bootstrap SEs are identical to that run.
*******************************************************************************
clear all
set more off
version 18
global ROOT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2019-Kinship-Cooperation-Moral-Systems"

capture program drop esttab_precise
program define esttab_precise
    syntax using/ [, *]
    local base = subinstr(`"`using'"', "Source_files/Tables/", "", .)
    local base = subinstr(`"`base'"', ".tex", "", .)
    esttab using `"$ROOT/Results/Tables/precise/`base'.csv"', replace csv plain ///
        b(%12.6f) se(%12.6f) stats(N r2, fmt(%12.0f %12.6f)) nostar nonotes ///
        keep(kinship_score corigin_kinship_score s_malariaindex s_distance_mutation ///
             s_tsi s_have_god s_religion_god small_scale, relax)
end

shell rm -rf "$ROOT/Results/_run"
shell mkdir -p "$ROOT/Results/_run/Data_programs/Do-files" "$ROOT/Results/_run/Source_files" "$ROOT/Results/Tables/precise"
shell ln -s "$ROOT/Data"            "$ROOT/Results/_run/Data_programs/Data"
shell ln -s "$ROOT/Results/Tables"  "$ROOT/Results/_run/Source_files/Tables"
shell ln -s "$ROOT/Results/Figures" "$ROOT/Results/_run/Source_files/Figs"
cd "$ROOT/Results/_run"

capture log close _all
log using "$ROOT/Results/run_precise.log", replace text name(prec)

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

foreach s in EA/Table_3 EA/Table_4 EA/Table_5 EA/Table_11 Country/Tables_6_7_9_10 MFQ/Table_8 {
    local f = subinstr("`s'", "/", "_", .)
    filefilter "$ROOT/Program/do-files/`s'.do" "Data_programs/Do-files/`f'.do", ///
        from("esttab using") to("esttab_precise using") replace
    set seed 20190001
    display as text _n "==== `s' (precise)"
    capture noisily do "Data_programs/Do-files/`f'.do"
    display as result "`s' rc=" _rc
    if "`s'" == "Country/Tables_6_7_9_10" & _rc == 0 {
        esttab_precise using Source_files/Tables/GPS_punish_cols1_3.tex
    }
}

log close prec
cd "$ROOT"
shell rm -rf "$ROOT/Results/_run"
