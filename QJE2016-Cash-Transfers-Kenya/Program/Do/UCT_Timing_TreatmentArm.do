version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"


*** ITERATE THROUGH TREATMENT ARMS ***
foreach treat in "large" "femalerec" "monthly"  {


*** EMPTY TABLE ***
	clear all
	set obs 10
	gen fakex = 1
	gen fakey = 1
	forvalues i = 1/2 {
		eststo col`i': reg fakex fakey
	}

*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	cap drop weight
	gen include = 1
	drop if purecontrol == 1
	replace include = 0 if maleres == 1
	drop if endlinedate == .
	xi i.village, pref(fev) // village fixed effects
	tempfile usedata
	save `usedata'


*** COUNT ITERATIONS ***
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""

foreach var in $indices_ppp  {
	
		use `usedata', clear
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		drop if `var'1 == .

		
		if "`treat'" == "large" {
			*** COLUMN 1: NO CONTROLS ***
			areg `var'1 treatXlarge spillover `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatX`treat', prec(2) sestar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1
			
			*** COLUMN 2: TIMING CONTROLS ***
			areg `var'1 treatXlarge spillover $timecontrols `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatX`treat', prec(2) sestar
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2
		}
		
		if "`treat'" == "femalerec" {
			*** COLUMN 1: NO CONTROLS ***
			areg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatXfemalerecXmarried, prec(2) sestar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1
			
			*** COLUMN 2: TIMING CONTROLS ***
			areg `var'1 treatXfemalerecXmarried treatXsinglerec spillover $timecontrols `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatXfemalerecXmarried, prec(2) sestar
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2
		}
		
		if "`treat'" == "monthly" {
		
			*** COLUMN 1: NO CONTROLS ***
			areg `var'1 treatXmonthlyXsmall treatXlarge spillover `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatXmonthlyXsmall, prec(2) sestar
			estadd local thisstat`count' = "`r(bstar)'": col1
			estadd local thisstat`countse' = "`r(sestar)'": col1
			
			*** COLUMN 2: TIMING CONTROLS ***
			areg `var'1 treatXmonthlyXsmall treatXlarge spillover $timecontrols `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
			pstar treatXmonthlyXsmall, prec(2) sestar		
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2
		}
		
		
		*** ITERATE ***
		local thisvarlabel: variable label `var'1
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		local count = `count' + 2
		local countse = `count' + 1
}

*** ADD SUR ROW ***
	use `usedata', clear

	if "`treat'" == "large" {

		local suestcount = 1
		local suest1 "suest " 
		local suest2 "suest " 
		foreach var in $indices_ppp {
			if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
			else replace include = 0 if maleres == 1
			reg `var'1 treatXlarge spillover `var'_full0 `var'_miss0 fev* if include == 1
			est store spec1_`suestcount' 
			local suest1 "`suest1' spec1_`suestcount'"
			reg `var'1 treatXlarge spillover $timecontrols `var'_full0 `var'_miss0 fev* if include == 1
			est store spec2_`suestcount' 
			local suest2 "`suest2' spec2_`suestcount'"
			local ++suestcount
		}	
		//test coefficient of interest
		`suest1', cluster(surveyid) 
		test treatXlarge
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col1

		`suest2', cluster(surveyid) 
		test treatXlarge
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col2
	}

	if "`treat'" == "femalerec" {

		local suestcount = 1
		local suest1 "suest " 
		local suest2 "suest " 
		foreach var in $indices_ppp {
			if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
			else replace include = 0 if maleres == 1
			reg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0 fev* if include == 1
			est store spec1_`suestcount' 
			local suest1 "`suest1' spec1_`suestcount'"
			reg `var'1 treatXfemalerecXmarried treatXsinglerec spillover $timecontrols `var'_full0 `var'_miss0 fev* if include == 1
			est store spec2_`suestcount' 
			local suest2 "`suest2' spec2_`suestcount'"
			local ++suestcount
		}	
		//test coefficient of interest
		`suest1', cluster(surveyid) 
		test treatXfemalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col1

		`suest2', cluster(surveyid) 
		test treatXfemalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col2
	}

	if "`treat'" == "monthly" {

		local suestcount = 1
		local suest1 "suest " 
		local suest2 "suest " 
		foreach var in $indices_ppp {
			if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
			else replace include = 0 if maleres == 1
			reg `var'1 treatXmonthlyXsmall treatXlarge spillover `var'_full0 `var'_miss0 fev* if include == 1
			est store spec1_`suestcount' 
			local suest1 "`suest1' spec1_`suestcount'"
			reg `var'1 treatXmonthlyXsmall treatXlarge spillover $timecontrols `var'_full0 `var'_miss0 fev* if include == 1
			est store spec2_`suestcount' 
			local suest2 "`suest2' spec2_`suestcount'"
			local ++suestcount
		}	
		//test coefficient of interest
		`suest1', cluster(surveyid) 
		test treatXmonthlyXsmall
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col1

		`suest2', cluster(surveyid) 
		test treatXmonthlyXsmall
		pstar, p(`r(p)') pstar pnopar
		estadd local testp "`r(pstar)'": col2
	}

	local statnames "`statnames' testp" 
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "

	if "`treat'" == "large" esttab col* using "$output_dir/UCT_Timing_large_small.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mtitle("\specialcell{Large Transfer\\(No Controls)}" "\specialcell{Large Transfer\\(Timing Controls)}") stats(`statnames', labels(`varlabels')  )

	if "`treat'" == "femalerec" esttab col* using "$output_dir/UCT_Timing_female_male.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mtitle("\specialcell{Female Recipient\\(No Controls)}" "\specialcell{Female Recipient\\(Timing Controls)}") stats(`statnames', labels(`varlabels')  )

	if "`treat'" == "monthly" esttab col* using "$output_dir/UCT_Timing_monthly.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mtitle("\specialcell{Monthly Transfer\\(No Controls)}" "\specialcell{Monthly Transfer\\(Timing Controls)}") stats(`statnames', labels(`varlabels')  )

}
