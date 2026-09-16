version 13.1 
clear all
set more off 
sysdir set PERSONAL "${ado_dir}"

use "$data_dir/UCT_MetalRoofHHs.dta", clear
append using "$data_dir/UCT_FINAL_CLEAN.dta", force
drop if purecontrol
replace metal_roof = 0 if treat | spillover

gen fakex = 1
gen fakey = 1
forvalues i = 1/3 {
	eststo col`i': reg fakex fakey
}

local count = 1
local varlabels ""
local statnames ""

foreach var in asset_total_ppp0 cons_nondurable_ppp0 { 

	*** COLUMN 1: THATCHED ROOF MEAN ***
	sum `var' if ~metal_roof
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col1
	local sd = string(r(sd), "%9.2f")
	local sd = "(`sd')"
	estadd local thissd`count' = "`sd'": col1
	
	*** COLUMN 2: METAL ROOF MEAN ***
	sum `var' if metal_roof
	local mean = string(r(mean), "%9.2f")
	estadd local thisstat`count' = "`mean'": col2
	local sd = string(r(sd), "%9.2f")
	local sd = "(`sd')"
	estadd local thissd`count' = "`sd'": col2
	
	*** COLUMN 3: Difference ***
	reg `var' metal_roof, r
	pstar metal_roof
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thissd`count' = "`r(sestar)'": col3

	*** LABELS ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thissd`count'"
	local ++count
}
	
	esttab col* using "$output_dir/UCT_MetalRoof_Baseline_Wealth_Comparison.tex", replace cells(none) booktabs nonotes compress  alignment(SSS) mtitle("\specialcell{Thatched Roof\\Mean (SD)} ""\specialcell{Metal Roof\\Mean (SD)}" "Difference") stats(`statnames', labels(`varlabels') ) nonum
