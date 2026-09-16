version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

/* ANALYSES:
1) Variable attrition by treatment status 
2) Baseline balance of attriters vs. non-attriters
3) Treatment group balance conditional on attrition */

foreach analysis in attrit1 attrit2 attrit3 {
	foreach thisvarlist in $regvars {
	
	
*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	local totalcols = 3
	forvalues x = 1/`totalcols' {
		eststo col`x': reg x y
	}

	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	

*** 1) VARIABLE ATTRITION BY TREATMENT STATUS ***
	if "`analysis'" == "attrit1" {
		use "$data_dir/UCT_FINAL_CLEAN.dta", clear
		drop if baselinedate ==. 
		drop if purecontrol == 1
		drop if maleres == 1
		gen attrition = (endlinedate == .)

		*** COLUMN 1: CONTROL MEAN ***
		sum attrition if ~treat 
		estadd local thisstat`count' = string(`r(mean)', "%9.3f"): col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.3f") + ")" : col1
		
		*** COLUMN 2: TREATMENT ***
		areg attrition treat, cluster(surveyid) absorb(village)
		pstar treat
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: N ***
		local thisN = e(N)
		estadd scalar thisstat1 = `thisN': col3
		
		*** OUTPUT ***
		esttab * using "$output_dir/attrition_treat.tex",  cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Control\\mean (SD)}" "Treatment" "N" ) stats(thisstat1 thisstat2, labels("Attrition" " ") ) nonumbers 
	}
	
	
*** 2) BASELINE BALANCE FOR ATTRITERS ***	
	else if "`analysis'" == "attrit2" {
	foreach var in $`thisvarlist' {
		use "$data_dir/UCT_FINAL_CLEAN.dta", clear
		local thisvarname "`var'0"
		drop if `thisvarname' == .
		drop if baselinedate ==. 
		drop if purecontrol == 1
		gen attrition = (endlinedate == .)
		if "`var'" ~= "psy_index_z" drop if maleres == 1
	
		*** COLUMN 1: NON-ATTRITION MEAN ***
		sum `thisvarname' if ~attrition 
		estadd local thisstat`count' = string(`r(mean)', "%9.3f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.3f") + ")" : col1
		
		*** COLUMN 2: ATTRITION ***
		areg `thisvarname' attrition, absorb(village) cluster(surveyid)
		pstar attrition
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: N ***
		local thisN = e(N)
		estadd scalar thisstat`count' = `thisN': col3
		
		*** ITERATE *** 
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
			
		local count = `count' + 2
		local countse = `count' + 1			
	} 
	esttab * using "$output_dir/attrition_`thisvarlist'_plain.tex",  cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Non-attrition\\mean (SD)}" "Attrition" "N" ) stats(`statnames', labels(`varlabels') ) nonumbers 
	}
	
	
*** 3) TREATMENT GROUP BALANCE CONDITIONAL ON ATTRITION ***	
	else if "`analysis'" == "attrit3" {
	foreach var in $`thisvarlist' {
		use "$data_dir/UCT_FINAL_CLEAN.dta", clear
		local thisvarname "`var'0"
		drop if `thisvarname' == .
		drop if baselinedate ==. 
		drop if purecontrol == 1
		gen attrition = (endlinedate == .)
		keep if attrition == 1
		if "`var'" ~= "psy_index_z" drop if maleres == 1
	
		*** COLUMN 1: NON-ATTRITION MEAN ***
		sum `thisvarname'
		estadd local thisstat`count' = string(`r(mean)', "%9.3f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.3f") + ")" : col1
		
		*** COLUMN 2: ATTRITION ***
		areg `thisvarname' treat, absorb(village) cluster(surveyid)
		pstar treat
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: N ***
		local thisN = e(N)
		estadd scalar thisstat`count' = `thisN': col3
		
		*** ITERATE *** 
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
			
		local count = `count' + 2
		local countse = `count' + 1			
	} 
	esttab * using "$output_dir/attrition_cond_`thisvarlist'.tex",  cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Treatment\\mean (SD)}" "Treatment" "N" ) stats(`statnames', labels(`varlabels') ) nonumbers 
	}

	
}
}
