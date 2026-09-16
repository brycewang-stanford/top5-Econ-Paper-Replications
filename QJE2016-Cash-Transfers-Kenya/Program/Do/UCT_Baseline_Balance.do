version 13.1 
clear all
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars  {

*** CREATE EMPTY TABLE ***
	eststo clear
	est drop _all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/6 {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	


*** DATASET *** 
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
gen include = 1
replace include = 0 if maleres == 1
drop if baselinedate == .
xi i.village, pref(fev) // village fixed effects
tempfile usedata
save `usedata'
		
		
*** FWER-ADJUSTED P-VALUES USING STEPDOWN ***
	if "`thisvarlist'" == "indices_ppp" { 
	
		use `usedata', clear
		local thisvarlist0 ""
		foreach var in $`thisvarlist' {
			if "`var'" ~= "psy_index_z" replace `var'0 = . if maleres == 1
			local thisvarlist0 "`thisvarlist0' `var'0"
		}
		
		set seed 1073741823		
		stepdown reg (`thisvarlist0') treat fev*, options(cluster(surveyid)) iter($stepdowniternow)	
		mat A = r(p)
		stepdown reg (`thisvarlist0') treatXfemalerecXmarried treatXsinglerec spillover fev*, options(cluster(surveyid)) iter($stepdowniternow)	
		mat B = r(p)
		stepdown reg (`thisvarlist0') treatXmonthlyXsmall treatXlarge spillover fev*, options(cluster(surveyid)) iter($stepdowniternow)	
		mat C = r(p)
		stepdown reg (`thisvarlist0') treatXlarge spillover fev*, options(cluster(surveyid)) iter($stepdowniternow)	
		mat D = r(p)
	}
	

*** REGRESSIONS FOR EACH BASELINE VARIABLE ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		if "`thisvarlist'" == "baselinecontrols" local thisvarname "`var'"
		else local thisvarname "`var'0"
		drop if `thisvarname' == .
		
		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1

		
		*** COLUMN 1: CONTROL MEAN ***
		sum `thisvarname' if spillover		
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1

		*** COLUMN 2: TREATMENT EFFECT ***	
		areg `thisvarname' treat if include == 1, absorb(village) cluster(surveyid)
		pstar treat
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: FEMALE RECIPIENT ***
		areg `thisvarname' treatXfemalerecXmarried treatXsinglerec spillover if include == 1, absorb(village) cluster(surveyid) 
		pstar treatXfemalerecXmarried
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3
		
		*** COLUMN 4: MONTHLY TRANSFER ***
		areg `thisvarname' treatXmonthlyXsmall treatXlarge spillover if include == 1, absorb(village) cluster(surveyid) 
		pstar treatXmonthlyXsmall
		estadd local thisstat`count' = "`r(bstar)'": col4
		estadd local thisstat`countse' = "`r(sestar)'": col4
		
		*** COLUMN 5: LARGE TRANSFER ***
		areg `thisvarname' treatXlarge spillover if include == 1, absorb(village) cluster(surveyid) 
		pstar treatXlarge
		estadd local thisstat`count' = "`r(bstar)'": col5
		estadd local thisstat`countse' = "`r(sestar)'": col5

		*** COLUMN 6: N ***
		sum `thisvarname' if include == 1
		local thisN = `r(N)'
		estadd scalar thisstat`count' = `thisN': col6
		
		*** STORE VARIABLE LABELS AND ITERATE ***
		if "`thisvarlist'" ~= "indices_ppp"  {
			local thisvarlabel: variable label `thisvarname'
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			
			local count = `count' + 2
			local countse = `count' + 1
			local ++varcount 	
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
	
	local suestcount = 1
	local suest1 "suest " 
	local suest2 "suest " 
	local suest3 "suest " 
	local suest4 "suest " 
	
	foreach var in $`thisvarlist' {		
		if "`thisvarlist'" == "baselinecontrols" local thisvarname "`var'"
		else local thisvarname "`var'0"
		
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		else replace include = 0 if maleres == 1
	
		reg `thisvarname' treat fev* if include == 1
		est store spec1_`suestcount'
		local suest1 "`suest1' spec1_`suestcount'"
		reg `thisvarname' treatXfemalerecXmarried treatXsinglerec spillover fev* if include == 1
		est store spec2_`suestcount'
		local suest2 "`suest2' spec2_`suestcount'"
		reg `thisvarname' treatXmonthlyXsmall treatXlarge spillover fev* if include == 1
		est store spec3_`suestcount'
		local suest3 "`suest3' spec3_`suestcount'"
		reg `thisvarname' treatXlarge spillover fev* if include == 1
		est store spec4_`suestcount'
		local suest4 "`suest4' spec4_`suestcount'"
		local ++suestcount
	}
	
	// SUR
	`suest1', cluster(surveyid) 
	test treat
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col2
	
	`suest2', cluster(surveyid) 
	test treatXfemalerecXmarried
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col3
	
	`suest3', cluster(surveyid) 
	test treatXmonthlyXsmall
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col4
	
	`suest4', cluster(surveyid) 
	test treatXlarge
	pstar, p(`r(p)') pstar pnopar
	local testp "`r(pstar)'"
	estadd local testp "`testp'": col5
	
	local statnames "`statnames' testp" 
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 
	
	
esttab col* using "$output_dir/baseline_`thisvarlist'_maintable.tex",  cells(none) booktabs nonotes compress replace alignment(SSSSSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Treatment\\effect}" "\specialcell{Female\\recipient}" "\specialcell{Monthly\\transfer}" "\specialcell{Large\\transfer}" "N" ) stats(`statnames', labels(`varlabels') )	
}
		
		
	
	
