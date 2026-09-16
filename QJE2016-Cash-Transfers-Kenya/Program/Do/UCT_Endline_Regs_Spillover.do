version 13.1
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars {

*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	local totalcols = 10
	forvalues x = 1/`totalcols' {
		qui eststo col`x': reg x y
	}

	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""

*** DENOTE HOUSEHOLD VS INDIVIDUAL OUTCOMES ***
	local indcase = 0
	local hhcase = 0
	// weighting will be by the number of observations per household, as this is not balanced.
	if "`thisvarlist'" == "psyvars" | "`thisvarlist'" == "psyvars_weighted" | "`thisvarlist'" == "psyvars_weighted2" | "`thisvarlist'" == "politicalvars" local indcase = 1
	else local hhcase = 1
	if "`thisvarlist'" == "psyvars_weighted2" local thisweighting "[aw=weight2]"
	else if "`thisvarlist'" == "psyvars_weighted" local thisweighting "[aw=weight]"
	else local thisweighting ""


*** DATASET ***
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	cap drop weight weight2
	drop if treat
	drop if endlinedate == .
	gen include = 1
	if `hhcase' == 1 replace include = 0 if maleres
	if "`thisvarlist'" == "entvars_cond_ppp" replace include = 0 if ent_nonagbusiness0 ~= 1 // Conditional on Enterprise Ownership
	xi i.village, pref(fev) // village fixed effects
	replace asset_total_ppp1 =  asset_total_ppp1 - asset_valroof_ppp1 if asset_niceroof1 == 1 // Exclude metal roof value from comparisons with metal roof households
	replace asset_lntotal_ppp1 = asset_lntotal_noroof_ppp1 if asset_niceroof1 == 1
	tempfile usedata
	save `usedata'


*** WHICH COLUMNS HAVE CONTROLS? ***

	estadd local ctrl "{No}" : col1
	estadd local ctrl "{No}" : col3
	estadd local ctrl "{No}" : col5
	estadd local ctrl "{No}" : col7
	estadd local ctrl "{No}" : col8
	estadd local ctrl "{No}" : col9
	estadd local ctrl "{No}" : col10

	estadd local ctrl "{Yes}" : col2
	estadd local ctrl "{Yes}" : col4
	estadd local ctrl "{Yes}" : col6

	local statnames "`statnames' ctrl"
	local varlabels "`varlabels' "Includes controls""



*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres
		if `hhcase' == 1 & "`var'" ~= "psy_index_z" local thisweighting ""

		*** WEIGHTS FOR OUTCOMES AT THE INDIVIDUAL LEVEL ***
		cap drop weight weight2
		bysort surveyid: egen weight = count(`thisvarname') if include == 1
		bysort village: egen weight2 = count(`thisvarname') if include == 1
		replace weight2 =  1 / weight2 / weight
		replace weight = 1 / weight

		*** COLUMN 1: INCLUDES METAL ROOF SPILLOVERS ***
		reg `thisvarname' spillover if include == 1 `thisweighting'
		est store spec1_1
		reg `thisvarname' spillover if include == 1 `thisweighting', cluster(village)
		pstar spillover
		estadd local thisstat`count' = "`r(bstar)'": col1
		estadd local thisstat`countse' = "`r(sestar)'": col1

		*** COLUMN 2: WITH CONTROLS ***
		reg `thisvarname' spillover $spillovercontrols if include == 1 `thisweighting'
		est store spec2_1
		reg `thisvarname' spillover $spillovercontrols if include == 1 `thisweighting', cluster(village)
		pstar spillover
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2

		*** EXCLUDING METAL ROOFS ***
		replace include = 0 if asset_niceroof1 == 1 // Exclude metal roofs from these

		*** COLUMN 3: EXCLUDES METAL ROOF SPILLOVERS ***
		reg `thisvarname' spillover if include == 1 `thisweighting'
		est store spec1_2
		reg `thisvarname' spillover if include == 1 `thisweighting', cluster(village)
		pstar spillover
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3

		*** COLUMN 4: WITH CONTROLS ***
		reg `thisvarname' spillover $spillovercontrols if include == 1 `thisweighting'
		est store spec2_2
		reg `thisvarname' spillover $spillovercontrols if include == 1 `thisweighting', cluster(village)
		pstar spillover
		estadd local thisstat`count' = "`r(bstar)'": col4
		estadd local thisstat`countse' = "`r(sestar)'": col4

		*** COLUMN 5: USING SUR TO TEST EQUIVALENCE ***
		suest spec1_1 spec1_2, cluster(village)
		test [spec1_2_mean]spillover = [spec1_1_mean]spillover
		pstar, p(`r(p)') pstar pnopar
		estadd local thisstat`count' "`r(pstar)'": col5

		*** COLUMN 6: USING SUR TO TEST EQUIVALENCE ***
		suest spec2_1 spec2_2, cluster(village)
		test[spec2_2_mean]spillover = [spec2_1_mean]spillover
		pstar, p(`r(p)') pstar pnopar
		estadd local thisstat`count' "`r(pstar)'": col6

*	NOTE: LEE BOUNDS ARE RUN ON THE DIFFERENTIAL PROPORTION OF UPGRADERS BETWEEN TV AND CV

		*** LEE and Manski bounds BOUNDS MODEL ***
		preserve
		if "`hhcase'" == "1" & "`var'" ~= "psy_index_z" {
			drop if maleres
			local x = _N + 1
			local y = `x' + 4
			set obs `y'
			replace purecontrol = 0 in `x'/`y'
			replace treat = 0 in `x'/`y'
			replace spillover = 1 in `x'/`y'
			replace `thisvarname' = . in `x'/`y'
			replace endlinedate = 1 in `x'/`y'
			gen select = 1 in `x'/`y'
			recode select . = 0
		}
		else if "`indcase'" == "1" | "`var'" == "psy_index_z" {
			local x = _N + 1
			local y = `x' + 9
			set obs `y'
			replace purecontrol = 0 in `x'/`y'
			replace treat = 0 in `x'/`y'
			replace spillover = 1 in `x'/`y'
			replace endlinedate = 1 in `x'/`y'
			replace `thisvarname' = . in `x'/`y'
			gen select = 1 in `x'/`y'
			recode select . = 0
		}

		leebounds `thisvarname' spillover, cieffect vce(bootstrap, reps(100))

		*** COLUMN 7: LOWER LEE BOUND ***
		pstar lower, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col7
		estadd loc thisstat`countse' = "`r(sestar)'": col7

		*** COLUMN 8: UPPER LEE BOUND ***
		pstar upper, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col8
		estadd loc thisstat`countse' = "`r(sestar)'": col8


		**** MANSKI ****
		gen `var'LO1 = `var'1
		gen `var'HI1 = `var'1
		sum `var'LO1 if ~select, detail
		replace `var'LO1 = `r(p5)' if select
		replace `var'HI1 = `r(p95)' if select
		sum `var'LO1 `var'HI1 `var'1

		*** Column 9: UPPER MANSKI BOUND ***
		reg `var'LO1  spillover, r
		pstar spillover, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col9
		estadd loc thisstat`countse' = "`r(sestar)'": col9

		*** Column 10: LOWER MANSKI BOUND ***
		reg `var'HI1 spillover, r
		pstar spillover, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col10
		estadd loc thisstat`countse' = "`r(sestar)'": col10


		restore


		*** SAVE AND ITERATE ***

		local thisvarlabel: variable label `thisvarname'
		if `count' == 1 local varlabels "`varlabels' "\midrule `thisvarlabel'" " " "
		else local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"

		local count = `count' + 2
		local countse = `count' + 1
	}

	*** ADD SUR ROW ***
	use `usedata', clear

	local suestcount = 1
	local suest1 "suest "
	local suest2 "suest "
	local suest3 "suest "
	local suest4 "suest "

	foreach var in $`thisvarlist' {

		local thisvarname "`var'1"
		if `hhcase' == 1 & "`var'" == "psy_index_z" replace include = 1 if maleres
		if `hhcase' == 1 & "`var'" ~= "psy_index_z" replace include = 0 if maleres

		*** WEIGHTS FOR OUTCOMES AT THE INDIVIDUAL LEVEL ***
		cap drop weight weight2
		bysort surveyid: egen weight = count(`thisvarname') if include == 1
		bysort village: egen weight2 = count(`thisvarname') if include == 1
		replace weight2 =  1 / weight2 / weight
		replace weight = 1 / weight

		reg `thisvarname' spillover if include == 1 `thisweighting'
		est store spec1_`suestcount'
		local suest1 "`suest1' spec1_`suestcount'"
		reg `thisvarname' spillover $spillovercontrols if include == 1 `thisweighting'
		est store spec2_`suestcount'
		local suest2 "`suest2' spec2_`suestcount'"
		reg `thisvarname' spillover if include == 1 & asset_niceroof1 ~=1 `thisweighting'
		est store spec3_`suestcount'
		local suest3 "`suest3' spec3_`suestcount'"
		reg `thisvarname' spillover $spillovercontrols if include == 1 & asset_niceroof1 ~=1 `thisweighting'
		est store spec4_`suestcount'
		local suest4 "`suest4' spec4_`suestcount'"
		local ++suestcount

	}

	`suest1', cluster(village)
	test spillover
	pstar, p(`r(p)') pstar pnopar
	estadd local testp "`r(pstar)'": col1

	`suest2', cluster(village)
	test spillover
	pstar, p(`r(p)') pstar pnopar
	estadd local testp "`r(pstar)'": col2

	`suest3', cluster(village)
	test spillover
	pstar, p(`r(p)') pstar pnopar
	estadd local testp "`r(pstar)'": col3

	`suest4', cluster(village)
	test spillover
	pstar, p(`r(p)') pstar pnopar
	estadd local testp "`r(pstar)'": col4


	local statnames "`statnames' testp"
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" "



	esttab col* using "$output_dir/`thisvarlist'_spillover_table.tex",  cells(none) booktabs nonotes compress replace alignment(SSSSS) mgroups("Spillover Effects" "Lee Bounds" "Horowitz-Manski Bounds" "", pattern(1 0 0 0 0 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  mtitle("\specialcell{All HH\\Estimate}" "\specialcell{All HH\\estimate}" "\specialcell{Thatched\\estimate}"  "\specialcell{Thatched\\estimate}" "\specialcell{Test (1)=(3)\\\emph{p}-value}" "\specialcell{Test (2)=(4)\\\emph{p}-value}" "\specialcell{Lower}" "\specialcell{Upper}" "\specialcell{Lower}" "\specialcell{Upper}" "N") stats(`statnames', labels(`varlabels') )
}
