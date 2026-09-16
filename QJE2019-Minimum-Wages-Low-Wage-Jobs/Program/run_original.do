********************************************************************************
* run_original.do — wrapper for the Cengiz, Dube, Lindner & Zipperer (QJE 2019)
* replication package (Harvard Dataverse doi:10.7910/DVN/TJCTC7).
*
* It replaces the empty globals at the top of Program/dofiles/master_QJE.do,
* runs create_programs.do (required every session), and then runs each
* exhibit do-file in master order, logging return code + seconds per step to
* Results/run_original_steps.csv. The author's do-files are left untouched.
*
* Usage (from any directory):
*   do "<project root>/Program/run_original.do"
*   Optional: set global RUNSTEPS before calling to run a subset, e.g.
*     global RUNSTEPS "Table1_for_QJE Figure2_for_QJE"
*   Batch: stata-mp -b do Program/run_original.do Table1_for_QJE Figure2_for_QJE
*   Optional: global BUILDDATA 1  -> also re-run the data-construction steps
*     (default 0: start from the shipped intermediate datasets in Data/data/).
********************************************************************************

local cmdargs `"`0'"'
clear all
eststo clear
set more off
set matsize 11000
set rmsg off
version 18

* ---- project root ------------------------------------------------------------
global ROOT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2019-Minimum-Wages-Low-Wage-Jobs"

* ---- globals expected by master_QJE.do (trailing slash required) ------------
global data      "${ROOT}/Data/data/"
global dofiles   "${ROOT}/Program/dofiles/"
global tables    "${ROOT}/Results/Tables/"
global figures   "${ROOT}/Results/Figures/"
global estimates "${ROOT}/Results/estimates/"
global stn_bsamples "${ROOT}/Results/bsamples/"
cap mkdir "${ROOT}/Results/estimates"
cap mkdir "${ROOT}/Results/bsamples"
cap mkdir "${ROOT}/Results/logs"

* ---- treatment definition block copied verbatim from master_QJE.do ----------
local treatdef3 "D.MW_real>0.25  & D.MW_real<. & D.MW>0"
global ifclause "`treatdef3'"
if "$ifclause" == "`treatdef3'"{
global graphtablename "exceed25cents"
global distifclause "L.D.MW_real>0.25  & L.D.MW_real<.& L.D.MW>0"
global missedevents "D.MW_real> 0  & D.MW_real<.& D.MW>0 & D.MW_real<=0.25"
}
global Wmax 4
global Wmin 4
global Tmax 16
global Tmin 12
global Tmaxcont = $Tmax
global Tmincont = $Tmin
global numberquant=3
global limittreat "stateonly"
global disagg 	""
global controlmethod  "Absorb"
global contlead ""

if "$BUILDDATA" == "" global BUILDDATA 0

* ---- step lists (master order) ----------------------------------------------
local datasteps state_panels_cents_new_QJE state_panels_cents_balanced_QJE ///
	state_panels_cents_demogadd_QJE clean_VZmwdata_QJE QCEW_multiplier ///
	state_panels_tercile1979_QJE simplermethod_microdata_QJE QCEW_multiplier ///
	create_stacked_events state_panels_cents_new_ind_QJE CK_predicted_probabilities_for_QJE ///
	matchedCPS_QJE state_panels_cents_matched_QJE create_to_combine_consecutive_events_QJE ///
	stacked_data_event_specific_estimates_QJE median_wage_state_quarter_QJE ///
	create_groupdata_QJE clean_administrativedata_QJE create_data_appendix_real ///
	clean_admin_cps_workingdata_allind_5cents clean_admin_cps_workingdata_allind_5cents_nominal ///
	CPS_nominal_1979onwards measurement_error_calculation_all_CPS_QJE create_quarterly_state_panel

local mainsteps Table1_for_QJE Table2_for_QJE Table3_for_QJE Table4_for_QJE ///
	Figure2_for_QJE Figure4_for_QJE Figure5_for_QJE Figure6_for_QJE

local appsteps Appendix_Figure_A1 Appendix_imputation_rate Appendix_self_employment_rate ///
	Appendix_Figure_A4 Appendix_Figure_A6 Appendix_Figure_A7 Appendix_Figure_A8 ///
	Appendix_Figures_A9_A10 Appendix_Table_A1_A2_CK Appendix_Table_A1_A2_demog ///
	Appendix_Table_A4 Appendix_Table_A4_col9 Appendix_Table_A5 Appendix_Table_A6 Appendix_Table_A7 ///
	Appendix_Figures_C1_C3 Appendix_Figure_C2 Appendix_Figure_C4 ///
	Appendix_Figure_D1 Appendix_Figure_D2 Appendix_Figure_D3_Table_D1_cols2_4 Appendix_Table_D1 ///
	Appendix_Figure_F1_Table_F1_rows_3_4_5 Appendix_Table_F1_cols_1_2 Appendix_Figure_F2 ///
	Appendix_Figure_F3 Appendix_Table_F2 create_me_corrected_logwages_data_QJE ///
	Appendix_Figure_F4 Appendix_Table_F3 ///
	Appendix_Figures_G1_A_G3_A_C_G6 Appendix_Figures_G1_B_G3_B_D Appendix_Figures_G2_A_C ///
	Appendix_Figures_G2_B_D Appendix_Figure_G4_Table_G6 Appendix_Figure_G5 ///
	Appendix_TableG2_col1 Appendix_TableG2_cols_2_3_4 Appendix_Tables_G3_G4_G7 ///
	Appendix_Table_G5 Appendix_Table_G5_EB Appendix_Table_G8

if `"`cmdargs'"' != "" local steps `cmdargs'
else if "$RUNSTEPS" != "" local steps $RUNSTEPS
else {
	if $BUILDDATA == 1 local steps `datasteps' `mainsteps' `appsteps'
	else local steps `mainsteps' `appsteps'
}

* ---- step log ----------------------------------------------------------------
cap file close steplog
local steplogfile "${ROOT}/Results/run_original_steps.csv"
cap confirm file "`steplogfile'"
if _rc {
	file open steplog using "`steplogfile'", write text replace
	file write steplog "timestamp,step,rc,seconds" _n
}
else file open steplog using "`steplogfile'", write text append

foreach s of local steps {
	* programs + globals must exist in every step (steps call clear all / macro drop)
	quietly do "${dofiles}create_programs.do"
	timer clear 1
	timer on 1
	cap log close steplogsmcl
	log using "${ROOT}/Results/logs/`s'.log", text replace name(steplogsmcl)
	capture noisily do "${dofiles}`s'.do"
	local rc = _rc
	cap log close steplogsmcl
	timer off 1
	quietly timer list 1
	local secs = r(t1)
	di as result "STEP `s' rc=`rc' seconds=`secs'"
	file write steplog "`c(current_date)' `c(current_time)',`s',`rc',`secs'" _n
	file flush steplog
	* restore globals possibly wiped by the step
	global data      "${ROOT}/Data/data/"
	global dofiles   "${ROOT}/Program/dofiles/"
	global tables    "${ROOT}/Results/Tables/"
	global figures   "${ROOT}/Results/Figures/"
	global estimates "${ROOT}/Results/estimates/"
}
file close steplog
