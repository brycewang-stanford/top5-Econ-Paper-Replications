clear all
set more off
pause on
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars {

	foreach gender in femaleres maleres {
	
		eststo clear
		est drop _all
		use "$data_dir/UCT_FINAL_CLEAN.dta", clear
		drop if endlinedate ==. 



		*** CREATE EMPTY TABLE ***
		gen fakex = 1
		gen fakey = 1
		local totalcols = 7
		forvalues x = 1/`totalcols' {
			eststo col`x': reg fakex fakey
		}


		*** TRACK ITERATIONS ***
		local count = 1
		local countse = `count'+ 1
		local statnames ""
		local varlabels ""

		*** REGRESSIONS ***
		foreach var in $`thisvarlist' {
		
			*** COLUMN 1: CONTROL MEAN ***
			sum `var'1 if spillover	& `gender' == 1
			estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
			estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
			
			*** COLUMN 2: FEMALE RECIPIENT IN VILLAGE  ***
			areg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spilloverXsingle `var'_full0 `var'_miss0 if `gender' == 1 & purecontrol == 0, absorb(village) cluster(surveyid) 
			pstar treatXfemalerecXmarried
			estadd local thisstat`count' = "`r(bstar)'": col2
			estadd local thisstat`countse' = "`r(sestar)'": col2
			
			*** COLUMN 3: MALE RECIPIENT IN VILLAGE  ***
			areg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spilloverXsingle `var'_full0 `var'_miss0 if `gender' == 1 & purecontrol == 0, absorb(village) cluster(surveyid) 
			pstar treatXmalerecXmarried
			estadd local thisstat`count' = "`r(bstar)'": col3
			estadd local thisstat`countse' = "`r(sestar)'": col3
			
			*** COLUMN 4: FEMALE VS MALE RECIPIENT ***
			areg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0 if `gender' == 1 & purecontrol == 0, absorb(village) cluster(surveyid) 
			pstar treatXfemalerecXmarried
			estadd local thisstat`count' = "`r(bstar)'": col4
			estadd local thisstat`countse' = "`r(sestar)'": col4
			
			*** COLUMN 5: FEMALE RECIPIENT BETWEEN VILLAGE  ***
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spillover purecontrolXsingle if `gender' == 1, cluster(village) 
			pstar treatXfemalerecXmarried
			estadd local thisstat`count' = "`r(bstar)'": col5
			estadd local thisstat`countse' = "`r(sestar)'": col5
			
			*** COLUMN 6: MALE RECIPIENT BETWEEN VILLAGE  ***
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spillover purecontrolXsingle if `gender' == 1, cluster(village) 
			pstar treatXmalerecXmarried
			estadd local thisstat`count' = "`r(bstar)'": col6
			estadd local thisstat`countse' = "`r(sestar)'": col6
			
			*** COLUMN 7: OBSERVATIONS ***
			sum `var'1 if `gender' == 1
			local thisN = `r(N)'
			estadd scalar thisstat`count' = `thisN': col7
			
			*** ITERATE ***
			local thisvarlabel: variable label `var'1
			local varlabels "`varlabels' "`thisvarlabel'" " " "
			local statnames "`statnames' thisstat`count' thisstat`countse'"
			local count = `count' + 2
			local countse = `count' + 1
		}

			
		*** JOINT ESTIMATION ROW ***
		xi i.village, pref(fev)
		local suestcount = 1
		local suest1 "suest " 
		local suest2 "suest " 
		local suest3 "suest " 
		local suest4 "suest " 
		local suest5 "suest " 
		// Store for suest
		foreach var in $`thisvarlist' {
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec `var'_full0 `var'_miss0 fev* if `gender' == 1 & purecontrol == 0
			est store spec1_`suestcount'
			local suest1 "`suest1' spec1_`suestcount'"
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec `var'_full0 `var'_miss0 fev* if `gender' == 1 & purecontrol == 0
			est store spec2_`suestcount'
			local suest2 "`suest2' spec2_`suestcount'"
			reg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0 fev* if `gender' == 1 & purecontrol == 0
			est store spec3_`suestcount'
			local suest3 "`suest3' spec3_`suestcount'"
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spillover if `gender' == 1
			est store spec4_`suestcount'
			local suest4 "`suest4' spec4_`suestcount'"
			reg `var'1 treatXfemalerecXmarried treatXmalerecXmarried treatXsinglerec spillover if `gender' == 1
			est store spec5_`suestcount'
			local suest5 "`suest5' spec5_`suestcount'"
			local ++suestcount
		}

		// SUR
		`suest1', cluster(surveyid) 
		test treatXfemalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		local testp "`r(pstar)'"
		estadd local testp "{`testp'}": col2

		`suest2', cluster(surveyid) 
		test treatXmalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		local testp "`r(pstar)'"
		estadd local testp "{`testp'}": col3

		`suest3', cluster(surveyid) 
		test treatXfemalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		local testp "`r(pstar)'"
		estadd local testp "{`testp'}": col4

		`suest4', cluster(village) 
		test treatXfemalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		local testp "`r(pstar)'"
		estadd local testp "{`testp'}": col5

		`suest5', cluster(village) 
		test treatXmalerecXmarried
		pstar, p(`r(p)') pstar pnopar
		local testp "`r(pstar)'"
		estadd local testp "{`testp'}": col6

		local statnames "`statnames' testp" 
		local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 



		*** OUTPUT ***
		esttab col* using "$output_dir/`thisvarlist'_genderrestricted_`gender'.tex", replace cells(none) booktabs nonotes compress  alignment(SSSSSSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Female\\recipient\\(within villages)}" "\specialcell{Male\\recipient\\(within villages)}" "\specialcell{Female vs.\\male recipient\\(within villages)}" "\specialcell{Female\\recipient\\(across villages)}" "\specialcell{Male\\recipient\\(across villages)}" "N" ) stats(`statnames', labels(`varlabels') )
	}
}
