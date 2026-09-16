version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars  {
*** STEPDOWN YES OR NO? ***
	if "`thisvarlist'" == "indices_ppp" global stepdownnow = 1
	else global stepdownnow = 0
	

*** CREATE EMPTY TABLE ***
	clear all	
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/7 {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	

*** DENOTE HOUSEHOLD VS INDIVIDUAL OUTCOMES ***
	
	if "`thisvarlist'" == "psyvars" | "`thisvarlist'" == "psyvars_weighted" | "`thisvarlist'" == "psyvars_weighted2" local hhcase = 0
	else local hhcase = 1
	
	// weighting will be by the number of observations per household, as this is not necessarily balanced.
	if "`thisvarlist'" == "indices_weighted" | "`thisvarlist'" == "psyvars_weighted" local thisweighting "[aw=weight]"
	else if "`thisvarlist'" == "psyvars_weighted2" local thisweighting "[aw=weight2]"
	else local thisweighting ""
	
	
*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	cap drop weight weight2
	gen include = 1
	if `hhcase' == 1 replace include = 0 if maleres == 1
	drop if endlinedate == .
	if "`thisvarlist'" == "entvars_cond_ppp" replace include = 0 if ent_nonagbusiness0 ~= 1 // Conditional on Enterprise Ownership
	xi i.village, pref(fev) // village fixed effects
	tempfile usedata
	save `usedata'

	
	
*** FWER-ADJUSTED P-VALUES USING STEPDOWN ***
	if "`thisvarlist'" == "indices_ppp" {
		use `usedata', clear
		// Varlist for stepdown. Use missing indicator approach with controlstems option
		local thisvarlist1 ""
		local thisvarlist0 ""
		foreach var in $`thisvarlist' {
			if "`var'" ~= "psy_index_z" replace `var'1 = . if maleres
			local thisvarlist1 "`thisvarlist1' `var'1"
			local thisvarlist0 "`thisvarlist0' `var'_full0 `var'_miss0"
			gen `var'1_full0 = `var'_full0
			gen `var'1_miss0 = `var'_miss0
		}
		
		// Stepdown
		set seed 1073741823		
		stepdown reg (`thisvarlist1') treatXlarge treatXsmall fev* if ~purecontrol, options(cluster(surveyid)) iter($stepdowniternow) controlstems(_miss0 _full0) 	
		mat A = r(p)
		stepdown reg (`thisvarlist1') treatXsmall treatXlarge fev* if ~purecontrol, options(cluster(surveyid)) iter($stepdowniternow) controlstems(_miss0 _full0) 
		mat B = r(p)
		stepdown reg (`thisvarlist1') treatXlarge spillover fev* if ~purecontrol, options(cluster(surveyid)) iter($stepdowniternow) controlstems(_miss0 _full0) 
		mat C = r(p)
		stepdown reg (`thisvarlist1') treatXlarge treatXsmall spillover, options(cluster(village)) iter($stepdowniternow) 
		mat D = r(p)
		stepdown reg (`thisvarlist1') treatXsmall treatXlarge spillover, options(cluster(village)) iter($stepdowniternow) 
		mat E = r(p)
		
	}
	
	
*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		
		*** WEIGHTS FOR OUTCOMES AT THE INDIVIDUAL LEVEL ***
		drop if `thisvarname' == .
		bysort surveyid: egen weight = count(`thisvarname')
		bysort village: egen weight2 = count(`thisvarname')
		replace weight2 =  1 / weight2 / weight
		replace weight = 1 / weight	
		
		
		*** COLUMN 1: CONTROL MEAN ***
		sum `thisvarname' if spillover & include == 1 		
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1

		*** COLUMN 2: LARGE WITHIN VILLAGE ***	
		areg `thisvarname' treatXlarge treatXsmall `var'_full0 `var'_miss0 if ~purecontrol & include == 1 `thisweighting', absorb(village) cluster(surveyid)
		pstar treatXlarge
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: SMALL WITHIN VILLAGE ***
		pstar treatXsmall
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3
		
		*** COLUMN 4: LARGE TRANSFER ***
		areg `thisvarname' treatXlarge spillover `var'_full0 `var'_miss0 if ~purecontrol & include == 1 `thisweighting', absorb(village) cluster(surveyid)		
		pstar treatXlarge
		estadd local thisstat`count' = "`r(bstar)'": col4
		estadd local thisstat`countse' = "`r(sestar)'": col4
		
		*** COLUMN 5: LARGE ACROSS VILLAGES ***
		reg `thisvarname' treatXlarge treatXsmall spillover if include == 1 `thisweighting', cluster(village) 
		pstar treatXlarge
		estadd local thisstat`count' = "`r(bstar)'": col5
		estadd local thisstat`countse' = "`r(sestar)'": col5
		
		*** COLUMN 6: SMALL ACROSS VILLAGES ***
		pstar treatXsmall
		estadd local thisstat`count' = "`r(bstar)'": col6
		estadd local thisstat`countse' = "`r(sestar)'": col6

		*** COLUMN 7: N ***
		sum `thisvarname' if include == 1
		local thisN = `r(N)'
		estadd scalar thisstat`count' = `thisN': col7
		
		*** STORE VARIABLE LABELS AND ITERATE ***
		if "`thisvarlist'" ~= "indices_ppp"  {
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			
			local count = `count' + 2
			local countse = `count' + 1
		}
		else { // ADD FROM STEPDOWN MATRICIES IF USING FWER ADJUSTED P-VALUES
			local countp = `countse' +1
			local thisp1 = A[1,`varcount']
			pstar, p(`thisp1') pbracket pstar
			estadd local thisstat`countp' = "`r(pstar)'": col2
			
			local thisp2 = B[1,`varcount']
			pstar, p(`thisp2') pbracket pstar
			estadd local thisstat`countp' = "`r(pstar)'": col3
			
			local thisp3 = C[1,`varcount']
			pstar, p(`thisp3') pbracket pstar
			estadd local thisstat`countp' = "`r(pstar)'": col4
			
			local thisp4 = D[1,`varcount']
			pstar, p(`thisp4') pbracket pstar
			estadd local thisstat`countp' = "`r(pstar)'": col5
			
			local thisp5 = E[1,`varcount']
			pstar, p(`thisp5') pbracket pstar
			estadd local thisstat`countp' = "`r(pstar)'": col6
			
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " " " "
			local statnames "`statnames' thisstat`count' thisstat`countse' thisstat`countp'"
			
			local count = `count' + 3
			local countse = `count' + 1
			local ++varcount 	
		}
	}

*** JOINT ESTIMATION ROW ***

	use `usedata', clear
	
	// Store for suest
	local suestcount = 1
	local suest1 "suest " 
	local suest2 "suest " 
	local suest3 "suest " 
	local suest4 "suest " 
	local suest5 "suest " 
	
	foreach var in $`thisvarlist' {		
		local thisvarname "`var'1"
		
		if `hhcase' == 1 & "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		if `hhcase' == 1 & "`var'" ~= "psy_index_z" replace include = 0 if maleres == 1
		
		cap drop weight weight2
		bysort surveyid: egen weight = count(`thisvarname')
		bysort village: egen weight2 = count(`thisvarname')
		replace weight2 =  1 / weight2 / weight
		replace weight = 1 / weight
	
		reg `thisvarname' treatXlarge treatXsmall `var'_full0 `var'_miss0 fev* if ~purecontrol & include == 1 `thisweighting'
		est store spec1_`suestcount'
		local suest1 "`suest1' spec1_`suestcount'"
		reg `thisvarname' treatXlarge treatXsmall `var'_full0 `var'_miss0 fev* if ~purecontrol & include == 1 `thisweighting'
		est store spec2_`suestcount'
		local suest2 "`suest2' spec2_`suestcount'"
		reg `thisvarname' treatXlarge spillover `var'_full0 `var'_miss0 fev* if ~purecontrol & include == 1 `thisweighting'
		est store spec3_`suestcount'
		local suest3 "`suest3' spec3_`suestcount'"
		reg `thisvarname' treatXlarge treatXsmall spillover if include == 1 `thisweighting'
		est store spec4_`suestcount'
		local suest4 "`suest4' spec4_`suestcount'"
		reg `thisvarname' treatXlarge treatXsmall spillover if include == 1 `thisweighting'
		est store spec5_`suestcount'
		local suest5 "`suest5' spec5_`suestcount'"
		local ++suestcount
	}
	
	// SUR
	`suest1', cluster(surveyid) 
	test treatXlarge
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col2
	
	`suest2', cluster(surveyid) 
	test treatXsmall
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col3
	
	`suest3', cluster(surveyid) 
	test treatXlarge
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col4
	
	`suest4', cluster(village) 
	test treatXlarge
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col5
	
	`suest5', cluster(village) 
	test treatXsmall
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col6
	
	local statnames "`statnames' testp" 
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 
	
	esttab col* using "$output_dir/`thisvarlist'_LargeSmall_Regs.tex",  cells(none) booktabs nonotes compress replace alignment(SSSSSSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Large\\transfer\\(within villages)}" "\specialcell{Small\\transfer\\(within villages)}" "\specialcell{Large vs.\\small transfer\\(within villages)}" "\specialcell{Large\\transfer\\(across villages)}" "\specialcell{Small\\transfer\\(across villages)}" "N" ) stats(`statnames', labels(`varlabels') )
}
