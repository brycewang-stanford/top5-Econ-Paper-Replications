version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"


*** CREATE EMPTY TABLE ***
clear all
set obs 10
gen x = 1
gen y = 1

forvalues x = 1/4 {
	eststo col`x': reg x y
}


local count = 1
local countse = `count'+1
local varlabels ""
local statnames ""


*** REGRESSIONS ***
use "$data_dir/UCT_FINAL_CLEAN.dta", clear 
drop if maleres == 1
drop if endlinedate == .
foreach var in $mpesavars {

	*** COLUMN 1: CONTROL MEAN ***
	sum `var' if spillover
	estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
	estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1

	*** COLUMN 2: TREATMENT ***
	areg `var' treat if ~purecontrol, cluster(surveyid) absorb(village) 
	pstar treat
	estadd local thisstat`count' = "`r(bstar)'": col2
	estadd local thisstat`countse' = "`r(sestar)'": col2
	
	*** COLUMN 3: SPILLOVER ***
	reg `var' treat spillover, cluster(village)
	pstar spillover
	estadd local thisstat`count' = "`r(bstar)'" : col3
	estadd local thisstat`countse' = "`r(sestar)'" : col3
	
	*** COLUMN 4: N ***
	local thisN = `e(N)'
	estadd scalar thisstat`count' = `thisN': col4
								
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1

}

esttab col* using "$output_dir/mpesa_use_comparison.tex",  cells(none) booktabs nonotes compress replace alignment(SSSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Treatment}" "Spillover" "N" ) stats(`statnames', labels(`varlabels') ) nonumbers  





	
	
	
	
