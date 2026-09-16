version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars  {


*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/2 {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	
*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	cap drop weight
	drop if purecontrol == 1
	//GENERATE VILLAGE MEAN TRANSFER AMOUNT
	gen treat_amount = 1525*treatXlarge + 404*treatXsmall
	egen mean_chg = mean(treat_amount), by(village)
	replace mean_chg = mean_chg / 100
	drop if endlinedate == .
	drop if treat == 1
	gen include = 1
	replace include = 0 if maleres == 1
	tempfile usedata
	save `usedata'
	
	
*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {
	
		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
	
		
		*** COLUMN 1: MEAN CHANGE ***
		reg `thisvarname' mean_chg `var'_full0 `var'_miss0 if include == 1, cluster(village)
		pstar mean_chg
		estadd local thisstat`count' = "`r(bstar)'": col1
		estadd local thisstat`countse' = "`r(sestar)'": col1
		
		*** Column 2: N ***
		local thisN = e(N)
		estadd scalar thisstat`count' = `thisN': col2
		
		*** SAVE AND ITERATE ***
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		
		local count = `count' + 2
		local countse = `count' + 1
	}

	
*** JOINT ESTIMATION ROW ***
use `usedata', clear
	
// store individual regressions for suest
local suestcount = 1
local suest1 "suest " 	
foreach var in $`thisvarlist' {

	local thisvarname "`var'1"
		
	if "`var'" == "psy_index_z" replace include = 1 if maleres == 1
	if "`var'" ~= "psy_index_z" replace include = 0 if maleres == 1
	
	reg `thisvarname' mean_chg `var'_full0 `var'_miss0 if include == 1
	estimate store spec1_`suestcount'
	local suest1 "`suest1' spec1_`suestcount'" 
	local ++suestcount

}

// run joint test and store
`suest1', cluster(village)

test mean_chg
pstar, p(`r(p)') pstar pnopar
estadd local testp "`r(pstar)'": col1

local statnames "`statnames' testp" 
local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 


*** OUTPUT ***
esttab col* using "$output_dir/InVillage_Spillover.tex",  cells(none) booktabs nonotes compress replace alignment(Sc) mtitle("\specialcell{Village Mean\\Change}" "N" ) stats(`statnames', labels(`varlabels') )

}
		
		
