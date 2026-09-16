version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in  $regvars {

*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/9 {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	

*** DENOTE HOUSEHOLD VS INDIVIDUAL OUTCOMES ***
	
	if "`thisvarlist'" == "psyvars" | "`thisvarlist'" == "psyvars_weighted" | "`thisvarlist'" == "politicalvars" local hhcase = 0
	else local hhcase = 1
	
	// weighting will be by the number of observations per household, as this is not necessarily balanced.
	if "`thisvarlist'" == "indices_weighted" | "`thisvarlist'" == "psyvars_weighted" local thisweighting "[aw=weight]"
	else local thisweighting ""
	
	
*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	drop if endlinedate == .
	drop if purecontrol == 1
	tempfile usedata
	save `usedata'

	
*** REGRESSIONS AND POWER CALCULATIONS ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if `hhcase' == 1 & "`var'" ~= "psy_index_z" drop if maleres
		
		*** COLUMNS 1: CONTROL MEAN ***
		sum `thisvarname' if spillover
		local controlmean = round(r(mean),.01)
		if "`var'" == "psy_lncort_mean_clean" local controlmean = 2.46
		estadd local thisstat`count' = string(`controlmean', "%9.2f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
		
		*** COLUMNS 2-3: TREATMENT EFFECT ***
		areg `thisvarname' treat `var'_full0 `var'_miss0, absorb(village) cluster(surveyid)
		local MDE = _se[treat] * 2.8
		local pctMDE = abs(`MDE' / `controlmean')
		estadd local thisstat`count' = string(`MDE', "%9.2f"): col2
		if abs(`controlmean') > 0 estadd local thisstat`count' = string(`pctMDE', "%9.2f"): col3
		else estadd local thisstat`count' = "{ }": col3
		
		*** COLUMNS 4-5: FEMALE RECIPIENT ***
		areg `thisvarname' treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0, absorb(village) cluster(surveyid)
		local MDE = _se[treatXfemalerecXmarried] * 2.8
		local pctMDE = abs(`MDE' /`controlmean')
		estadd local thisstat`count' = string(`MDE', "%9.2f"): col4
		if abs(`controlmean') > 0 estadd local thisstat`count' = string(`pctMDE', "%9.2f"): col5
		else estadd local thisstat`count' = "{ }": col5
		
		*** COLUMNS 6-7: MONTHLY TRANSFER ***
		areg `thisvarname' treatXmonthlyXsmall treatXlarge spillover `var'_full0 `var'_miss0 if ~purecontrol, absorb(village) cluster(surveyid)
		local MDE = _se[treatXmonthlyXsmall] * 2.8
		local pctMDE = abs(`MDE' /`controlmean')
		estadd local thisstat`count' = string(`MDE', "%9.2f"): col6
		if abs(`controlmean') > 0 estadd local thisstat`count' = string(`pctMDE', "%9.2f"): col7
		else estadd local thisstat`count' = "{ }": col7
		
		*** COLUMNS 8-9: LARGE TRANSFER ***
		areg `thisvarname' treatXlarge spillover `var'_full0 `var'_miss0, absorb(village) cluster(surveyid)
		local MDE = _se[treatXlarge] * 2.8
		local pctMDE = abs(`MDE' /`controlmean')
		estadd local thisstat`count' = string(`MDE', "%9.2f"): col8
		if abs(`controlmean') > 0 estadd local thisstat`count' = string(`pctMDE', "%9.2f"): col9
		else estadd local thisstat`count' = "{ }": col9
		
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		
		local count = `count' + 2
		local countse = `count' + 1

		}
	
	
	esttab col* using "$output_dir/`thisvarlist'_power_calcs.tex",  cells(none) booktabs nonotes compress replace mgroups("" "Treatment Effect" "Female Recipient" "Monthly Transfer" "Large Transfer", pattern(1 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) alignment(SSSSSSSSSSSS) mtitle("\specialcell{Control\\Mean}" "\specialcell{MDE}" "\specialcell{Percent of\\Control Mean}" "\specialcell{MDE}" "\specialcell{Percent of\\Control Mean}" "\specialcell{MDE}" "\specialcell{Percent of\\Control Mean}" "\specialcell{MDE}" "\specialcell{Percent of\\Control Mean}") stats(`statnames', labels(`varlabels') ) 
}
