version 13.1 
clear all
set more off
sysdir set PERSONAL "${ado_dir}"
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
drop if maleres == 1
drop if endlinedate ==. 
drop if purecontrol == 1


*** CREATE EMPTY TABLE ***
gen fakex = 1
gen fakey = 1
local totalcols = 6
forvalues x = 1/`totalcols' {
	eststo col`x': reg fakex fakey
}


*** TRACK ITERATIONS ***
local count = 1
local countse = `count'+ 1
local statnames ""
local varlabels ""


*** PANELS ***
foreach group in assets_short ent_short {

// Panel Labels
if "`group'" == "assets_short" {
	local statnames "`statnames' panel1 space1" 
	local varlabels "`varlabels' "\textbf{Panel A: Assets}" " " "
}
else {
	local statnames "`statnames' panel2 space2" 
	local varlabels "`varlabels' "\midrule \textbf{Panel B: Business Activities}" " " "
}

*** REGRESSIONS ***
	foreach var in $`group' {

	
		*** COLUMN 1: CONTROL MEAN ***
		sum `var'1 if spillover		
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1		
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
		
		*** COLUMN 2: TREATMENT EFFECT ***
		areg `var'1 treat `var'_full0 `var'_miss0, absorb(village) cluster(surveyid) 
		pstar treat
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
		
		*** COLUMN 3: FEMALE RECIPIENT ***
		areg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0, absorb(village) cluster(surveyid) 
		pstar treatXfemalerecXmarried
		estadd local thisstat`count' = "`r(bstar)'": col3
		estadd local thisstat`countse' = "`r(sestar)'": col3
		
		*** COLUMN 4: MONTHLY TRANSFER ***
		areg `var'1 treatXmonthlyXsmall treatXlarge spillover `var'_full0 `var'_miss0, absorb(village) cluster(surveyid) 
		pstar treatXmonthlyXsmall
		estadd local thisstat`count' = "`r(bstar)'": col4
		estadd local thisstat`countse' = "`r(sestar)'": col4
		
		*** COLUMN 5: LARGE TRANSFER ***
		areg `var'1 treatXlarge spillover `var'_full0 `var'_miss0, absorb(village) cluster(surveyid) 
		pstar treatXlarge
		estadd local thisstat`count' = "`r(bstar)'": col5
		estadd local thisstat`countse' = "`r(sestar)'": col5
		
		*** COLUMN 6: OBSERVATIONS ***
		sum `var'1
		local thisN = `r(N)'
		estadd scalar thisstat`count' = `thisN': col6
		
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
	// Store for suest
	foreach var in $`group' {
		reg `var'1 treat `var'_full0 `var'_miss0 fev*
		est store spec1_`suestcount'
		local suest1 "`suest1' spec1_`suestcount'"
		reg `var'1 treatXfemalerecXmarried treatXsinglerec spillover `var'_full0 `var'_miss0 fev*
		est store spec2_`suestcount'
		local suest2 "`suest2' spec2_`suestcount'"
		reg `var'1 treatXmonthlyXsmall treatXlarge spillover `var'_full0 `var'_miss0 fev*
		est store spec3_`suestcount'
		local suest3 "`suest3' spec3_`suestcount'"
		reg `var'1 treatXlarge spillover `var'_full0 `var'_miss0 fev*
		est store spec4_`suestcount'
		local suest4 "`suest4' spec4_`suestcount'"
		local ++suestcount
	}
	
	// SUR
	`suest1', cluster(surveyid) 
	test treat
	pstar, p(`r(p)') pstar pnopar
	local testp`group' "`r(pstar)'"
	estadd local testp`group' "`testp`group''": col2
	
	`suest2', cluster(surveyid) 
	test treatXfemalerecXmarried
	pstar, p(`r(p)') pstar pnopar
	local testp`group' "`r(pstar)'"
	estadd local testp`group' "`testp`group''": col3
	
	`suest3', cluster(surveyid) 
	test treatXmonthlyXsmall
	pstar, p(`r(p)') pstar pnopar
	local testp`group' "`r(pstar)'"
	estadd local testp`group' "`testp`group''": col4
	
	`suest4', cluster(surveyid) 
	test treatXlarge
	pstar, p(`r(p)') pstar pnopar
	local testp`group' "`r(pstar)'"
	estadd local testp`group' "`testp`group''": col5
	
	local statnames "`statnames' testp`group'" 
	local varlabels "`varlabels' "\midrule Joint test (\emph{p}-value)" " 
	
}


*** OUTPUT ***
esttab col* using "$output_dir/assets+ent_final_maintable.tex",  cells(none) booktabs nonotes compress replace alignment(SSSSSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Treatment\\effect}" "\specialcell{Female\\recipient}" "\specialcell{Monthly\\transfer}" "\specialcell{Large\\transfer}" "N" ) stats(`statnames', labels(`varlabels') ) 
