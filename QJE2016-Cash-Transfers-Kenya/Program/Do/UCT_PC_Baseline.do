version 13.1 
clear all
set more off
sysdir set PERSONAL "${ado_dir}"

use "$data_dir/UCT_FINAL_CLEAN.dta", clear
drop if treat == 1

*** CREATE EMPTY TABLES ***
gen fakex = 1
gen fakey = 1

local totalcols = 3
forvalues i = 1/`totalcols' {
	eststo col`i': reg fakex fakey
}

local count = 1
local countse = `count'+1
local varlabels ""
local statnames ""

*** ADD STATISTICS ***
foreach var in $immutable_baseline {	
	
	*** COLUMN 1: Treatment Village Mean ***
	sum `var' if control_village == 0
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = "(" + string(r(sd), "%9.2f")+ ")"
	estadd local thisstat`countse' = "`sd'": col1
	
	
	*** COLUMN 2: Control Village Mean ***
	sum `var' if control_village == 1
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col2
	local sd = "(" + string(r(sd), "%9.2f")+ ")"
	estadd local thisstat`countse' = "`sd'": col2
	
	
	*** COLUMN 3: Control Village Effect ***
	reg `var' control_village, cluster(village)
	pstar control_village, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thisstat`countse' = "`r(sestar)'": col3
	
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1
}

*** ADD SUR ROW ***
local suestcount = 1
local suest1 "suest " 
local suest2 "suest " 
local suest3 "suest " 
foreach var in $immutable_baseline {
	reg `var' control_village
	est store spec1_`suestcount' 
	local suest1 "`suest1' spec1_`suestcount'"
	
	local ++suestcount
}	
//test coefficient of interest
`suest1', cluster(village) 
test control_village
pstar, p(`r(p)') pstar pnopar
estadd local testp "`r(pstar)'": col3


local statnames "`statnames' testp" 
local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "


*** OUTPUT FILE ***
esttab col* using "$output_dir/PC_Baseline_Balance_Immutables.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mtitle("\specialcell{Treatment Village\\Mean (SD)}" "\specialcell{Control Village\\Mean (SD)}" "\specialcell{Difference}") stats(`statnames', labels(`varlabels')  )
