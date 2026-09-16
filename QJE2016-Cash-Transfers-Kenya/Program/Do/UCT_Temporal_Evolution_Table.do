version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars  {
	
*** CREATE EMPTY TABLE ***	
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/8 {
		eststo col`x': reg x y
		}

	local count = 1
	local countse = `count'+ 1
	local varlabels ""
	local statnames ""
	
	
*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	gen include = 1
	drop if purecontrol == 1
	drop if endlinedate == .
	replace include = 0 if maleres == 1
	xi i.village, pref(fev) // village fixed effects
	
	*** TIME OF TRANSFER ***
	gen treatend_0 = (Dlastend <= 1 & treat == 1)
	gen treatend_1_4 = (Dlastend > 1 & Dlastend <= 4 & treat == 1)
	gen treatend_4_14 = (Dlastend > 4 & treat == 1)
	
	foreach treatx in treatXlumpXsmall treatXmonthlyXsmall {
		foreach end in 0 1_4 4_14 {
			gen tend_`end'`treatx' = (`treatx' == 1 & treatend_`end' == 1)
		}
	}
	
	tempfile usedata
	save `usedata'

	
*** CYCLE THROUGH VARIABLES ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
		drop if `thisvarname' == .
		
		*** COLUMN 1: CONTROL MEAN ***
		sum `thisvarname' if spillover
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
		
		*** COLUMN 2: OVERALL ***
		areg `thisvarname' treatXsmall treatXlarge if include == 1 , absorb(village) cluster(surveyid)
		pstar treatXsmall
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2

		*** COLUMN 3: MONTHLY <1 MONTH ***
		areg `thisvarname' tend_0treatXlumpXsmall tend_0treatXmonthlyXsmall tend_1_4treatXlumpXsmall tend_1_4treatXmonthlyXsmall tend_4_14treatXlumpXsmall tend_4_14treatXmonthlyXsmall treatXlarge `var'_full0 `var'_miss0 if include == 1, absorb(village) cluster(surveyid)
		pstar tend_0treatXmonthlyXsmall
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3
		
		*** COLUMN 4: LUMP <1 MONTH ***
		pstar tend_0treatXlumpXsmall
		estadd local thisstat`count' = "`r(bstar)'": col4
		estadd local thisstat`countse' = "`r(sestar)'": col4
		
		*** COLUMN 5: MONTHLY 1-4 MONTHS ***
		pstar tend_1_4treatXmonthlyXsmall
		estadd local thisstat`count' = "`r(bstar)'": col5
		estadd local thisstat`countse' = "`r(sestar)'": col5
		
		*** COLUMN 6: LUMP 1-4 MONTHS ***
		pstar tend_1_4treatXlumpXsmall
		estadd local thisstat`count' = "`r(bstar)'": col6
		estadd local thisstat`countse' = "`r(sestar)'": col6
		
		*** COLUMN 7: 4+ MONTHS ***
		pstar tend_4_14treatXmonthlyXsmall
		estadd local thisstat`count' = "`r(bstar)'": col7
		estadd local thisstat`countse' = "`r(sestar)'": col7
		
		*** COLUMN 8: 4+ MONTHS ***
		pstar tend_4_14treatXlumpXsmall
		estadd local thisstat`count' = "`r(bstar)'": col8
		estadd local thisstat`countse' = "`r(sestar)'": col8

		
		*** ITERATE ***
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		local count = `count' + 2
		local countse = `count' + 1
	}
		esttab col* using "$output_dir/`thisvarlist'_temp.tex",  cells(none) booktabs nonotes compress replace alignment(SSS) mtitle("\specialcell{Control\\mean}" "\specialcell{Overall}" "\specialcell{Monthly\\<1 Month}" "\specialcell{Lump Sum\\<1 Month}"  "\specialcell{Monthly\\1 - 4 Months}" "\specialcell{Lump Sum\\1 - 4 Months}" "\specialcell{Monthly\\>4 Months}" "\specialcell{Lump Sum\\>4 Months}")  stats(`statnames', labels(`varlabels') ) nonumbers 
}

