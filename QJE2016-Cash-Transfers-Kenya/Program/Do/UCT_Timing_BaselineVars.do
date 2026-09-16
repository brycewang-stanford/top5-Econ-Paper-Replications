version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

*** EMPTY TABLE ***
clear all
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
gen fakex = 1
gen fakey = 1
forvalues i = 1/1 {
	eststo col`i': reg fakex fakey
}

*** COUNT ITERATIONS ***
local varcount = 1
local count = 1
local countse = `count'+1
local varlabels ""
local statnames ""

foreach var in $baselinecontrols  {
	
	*** COLUMN 1: WITHIN VILLAGE TREATMENT ***
	areg endline_timing `var' if ~purecontrol, absorb(village) cluster(surveyid)
	pstar `var', prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col1
	estadd local thisstat`countse' = "`r(sestar)'": col1
	
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1
}

esttab col* using "$output_dir/UCT_Timing_Baseline_Balance.tex", cells(none) booktabs nonotes compress replace alignment(S) mtitle("\specialcell{Endline\\Timing}") stats(`statnames', labels(`varlabels')  )

