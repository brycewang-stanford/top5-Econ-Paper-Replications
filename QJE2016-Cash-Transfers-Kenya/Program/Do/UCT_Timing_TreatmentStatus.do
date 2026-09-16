clear all
version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

*** EMPTY TABLE ***
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
label var endline_timing "Timing of Household Endline Survey"

gen fakex = 1
gen fakey = 1
forvalues i = 1/6 {
	eststo col`i': reg fakex fakey
}


*** COUNT ITERATIONS ***
local varcount = 1
local count = 1
local countse = `count'+1
local varlabels ""
local statnames ""

*** FILL TABLE ***
foreach var in endline_timing  {

	*** COLUMN 1: WITHIN VILLAGE TREATMENT ***
	reg `var' treat if ~purecontrol, cluster(surveyid)
	pstar treat, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col1
	estadd local thisstat`countse' = "`r(sestar)'": col1
	
	*** COLUMN 2: BETWEEN VILLAGE TREATMENT ***
	reg `var' treat spillover, cluster(village)
	pstar treat, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col2
	estadd local thisstat`countse' = "`r(sestar)'": col2
	
	*** COLUMN 3: SPILLOVER ***
	pstar spillover, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thisstat`countse' = "`r(sestar)'": col3
	
	*** COLUMN 4: FEMALE RECIPIENT ***
	reg `var' treatXfemalerecXmarried treatXsinglerec spillover if ~purecontrol, cluster(surveyid)
	pstar treatXfemalerecXmarried, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col4
	estadd local thisstat`countse' = "`r(sestar)'": col4
	
	*** COLUMN 5: MONTHLY TRANSFER ***
	reg `var' treatXmonthlyXsmall treatXlarge spillover if ~purecontrol, cluster(surveyid)
	pstar treatXmonthlyXsmall, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col5
	estadd local thisstat`countse' = "`r(sestar)'": col5
	
	*** COLUMN 6: LARGE TRANSFER ***
	reg `var' treatXlarge spillover if ~purecontrol, cluster(surveyid)
	pstar treatXlarge, prec(2) sestar
	estadd local thisstat`count' = "`r(bstar)'": col6
	estadd local thisstat`countse' = "`r(sestar)'": col6
	
	*** ITERATE ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1
}

esttab col* using "$output_dir/UCT_Timing_Treatment_Status.tex", cells(none) booktabs nonotes compress replace alignment(SSSSS) mtitle("\specialcell{Treatment\\Within Village}" "\specialcell{Treatment\\Between Village}" "\specialcell{Spillover}"  "\specialcell{Female\\Recipient}"  "\specialcell{Monthly\\Transfer}"  "\specialcell{Large\\Transfer}") stats(`statnames', labels(`varlabels')  )

