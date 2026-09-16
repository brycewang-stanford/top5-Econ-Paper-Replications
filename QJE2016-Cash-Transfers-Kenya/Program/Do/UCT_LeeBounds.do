version 13.1
set more off
sysdir set PERSONAL "${ado_dir}"
/* ssc install leebounds, replace */

foreach thisvarlist in $regvars  {


*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/2 {
		eststo col`x': reg x y
	}

	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""


*** DATASET ***
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	drop if purecontrol == 1
	drop if baselinedate ==.
	tempfile usedata
	save `usedata'


*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {
		use `usedata', clear
		if "`var'" != "psy_index_z" drop if maleres == 1
		replace `var'1 = . if endlinedate == .
		replace `var'0 = . if baselinedate == .
		gen attrition = (`var'1 == . & `var'0 ~= .)

		gen selection = attrition == 0

		// The Psych Index is individual level, so it is treated different from other variables in the index list.


		*** LEE BOUNDS ***
		leebounds `var'1 treat, select(selection) cieffect

		*** COLUMN 1: LOWER LEE BOUND ***
		pstar lower, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col1
		estadd loc thisstat`countse' = "`r(sestar)'": col1

		*** COLUMN 2: UPPER LEE BOUND ***
		pstar upper, prec(2)
		estadd loc thisstat`count' = "`r(bstar)'": col2
		estadd loc thisstat`countse' = "`r(sestar)'": col2

		*** ITERATE ***
		local thisvarlabel: variable label `var'1
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		local count = `count' + 2
		local countse = `count' + 1
	}
	esttab * using "$output_dir/leebounds_`thisvarlist'.tex",  cells(none) booktabs nonotes compress replace alignment(SS) mtitle("\specialcell{Lower\\bound}" "\specialcell{Upper\\bound}" ) stats(`statnames', labels(`varlabels') ) nonumbers
}
