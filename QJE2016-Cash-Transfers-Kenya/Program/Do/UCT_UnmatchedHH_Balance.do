set more off
sysdir set PERSONAL "${ado_dir}"

/* NOTE: Village fixed effects won't work here because of the small number of observations */

foreach thisvarlist in $regvars {

*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen fakex = 1
	gen fakey = 1
	local totalcols = 3
	forvalues x = 1/`totalcols' {
		eststo col`x': reg fakex fakey
	}


*** TRACK ITERATIONS ***
	local count = 1
	local countse = `count'+ 1
	local statnames ""
	local varlabels ""
	
	
*** DATASET *** 
	use "$data_dir/UCT_UNMATCHED.dta",clear
	drop if baselinedate == .
	gen include = 1
	replace include = 0 if maleres == 1
	drop if purecontrol == 1
	tempfile usedata
	save `usedata'


*** REGRESSION TABLES *** 
	foreach var in $`thisvarlist' {
	
		use `usedata', clear
		if "`thisvarlist'" == "indices_ppp" local thisvar "`var'0"
		else local thisvar "`var'"
		
		// Weighting for Psychological Outcomes
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		
		*** COLUMN 1: SAMPLE MEAN ***
		sum `thisvar' if unmatched == 0	& include == 1	
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1		
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
		esttab col1, stats(thisstat`count' thisstat`countse')
		
		*** COLUMN 2: UNMATCHED ***
		reg `thisvar' unmatched if include == 1, cluster(surveyid) 
		pstar unmatched
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: OBSERVATIONS ***
		sum `thisvar' if include == 1
		local thisN = `r(N)'
		estadd scalar thisstat`count' = `thisN': col3
		
		*** ITERATE ***
		local thisvarlabel: variable label `thisvar'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		local count = `count' + 2
		local countse = `count' + 1
	}
	
*** JOINT ESTIMATION ROW ***

	use `usedata', clear
	drop if purecontrol == 1
	// Store for suest
	local suestcount = 1
	local suest1 "suest " 
	foreach var in $`thisvarlist' {
		if "`thisvarlist'" == "indices_ppp" local thisvar "`var'0"
		else local thisvar "`var'"
		
		// Weighting for Psychological Outcomes
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		else replace include = 0 if maleres == 1
		
		reg `thisvar' unmatched if include == 1
		est store spec1_`suestcount'
		local suest1 "`suest1' spec1_`suestcount'"
		local ++suestcount
	}
	
	// SUR
	`suest1', cluster(surveyid)
	test unmatched
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col2
	
	local statnames "`statnames' testp" 
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 
	
*** OUTPUT ***
	esttab col* using "$output_dir/unmatched_baseline_`thisvarlist'.tex",  cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Sample\\mean (SD)}" "\specialcell{Unmatched\\Household}" "N" ) stats(`statnames', labels(`varlabels') )

	
}

