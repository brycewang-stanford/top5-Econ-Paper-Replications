*******************************************************************************
* run_original.do — wrapper for He, Wang & Zhang (2020, QJE) replication package
*   Harvard Dataverse doi:10.7910/DVN/LVS8VX
*
* Usage (from the project root):
*   /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do Program/run_original.do
*
* The author's do-files expect three globals: $data, $result, $figure.
* Each exhibit ships its own data folder, so $data is re-pointed before each step.
* Author do-files call `clear all`, which drops programs, timers and file handles,
* so this wrapper only uses globals (which survive `clear all`) for bookkeeping.
*******************************************************************************
clear all
set more off
version 18

* ---- project root: current working directory -------------------------------
global root "`c(pwd)'"
cap confirm file "$root/Program/run_original.do"
if _rc {
    di as error "Run this wrapper from the project root (folder containing Program/ and Data/)."
    exit 601
}

global pkg    "$root/Data/Replication Materials"
global result "$root/Results/Tables"
global figure "$root/Results/Figures"
cap mkdir "$root/Results"
cap mkdir "$result"
cap mkdir "$figure"

* ---- user-written packages ---------------------------------------------------
* rdrobust/rdplot (SSC, tested with v10.0.0), outreg2, winsor2 (SSC),
* blindschemes (SSC; plotplainblind scheme). mdrd (Ribas) is no longer online;
* an archived copy (Wayback Machine, 2020 capture) lives in Program/ado.
adopath ++ "$root/Program/ado"
foreach p in rdrobust outreg2 winsor2 {
    cap which `p'
    if _rc ssc install `p', replace
}
cap findfile scheme-plotplainblind.scheme
if _rc ssc install blindschemes, replace

* ---- step log ----------------------------------------------------------------
global steplog "$root/Results/run_original_steps.csv"
cap erase "$steplog"
file open _sl using "$steplog", write text replace
file write _sl "step,dofile,rc,seconds" _n
file close _sl

global t_all = clock("`c(current_date)' `c(current_time)'", "DMYhms")

*==============================================================================
* Each block: point $data to the exhibit folder, run the author's do-file,
* record rc and wall-clock seconds.
*==============================================================================

* ---- Table I: baseline RD ------------------------------------------------------
global step "T1_Baseline"
global dof  "T1_Baseline/1_Baseline_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Figure IV: RD plots -------------------------------------------------------
global step "F4_RD"
global dof  "F4_RD/F4_RD.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Figure V: RD estimates by year --------------------------------------------
global step "F5_Trend"
global dof  "F5_Trend/F5_Trend.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table III: inputs and outputs ---------------------------------------------
global step "T3_Channels"
global dof  "T3_Channels/3_Channels_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table IV: abatement -------------------------------------------------------
global step "T4_Abatement"
global dof  "T4_Abatement/4_Abatement_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table V: emissions --------------------------------------------------------
global step "T5_Emissions"
global dof  "T5_Emissions/5_Emissions_Replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table VI: political economy -----------------------------------------------
global step "T6_PE"
global dof  "T6_PE/6_PE_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table VII: heterogeneity --------------------------------------------------
global step "T7_Burden"
global dof  "T7_Burden/7_Burden_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table II: difference-in-discontinuities (mdrd; slowest, ~3 min per spec) ---
global step "T2_MDRD"
global dof  "T2_MDRD/2_Within_Firm_RD_replication.do"
global data "$pkg/$step"
global t0 = clock("`c(current_date)' `c(current_time)'", "DMYhms")
cap noi do "$root/Program/$dof"
global rc = _rc
global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t0)/1000
file open _sl using "$steplog", write text append
file write _sl "$step,$dof,$rc,$sec" _n
file close _sl

* ---- Table VIII: Excel only (Program/T8_Cost_Estimates/8_Cost_Estimates.xlsx) ---

global sec = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - $t_all)/1000
file open _sl using "$steplog", write text append
file write _sl "TOTAL,,,$sec" _n
file close _sl
di as result "run_original.do finished in $sec seconds"
