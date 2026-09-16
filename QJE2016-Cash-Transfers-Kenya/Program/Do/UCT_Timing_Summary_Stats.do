version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"


*** Panel 1: HOUSEHOLD TIMING ***
foreach treat in "basic" "large" "femaleXmarried" "monthly" {
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
if "`treat'" == "basic" local colnum = 5
else  local colnum = 10
gen fakex = 1
gen fakey = 1
forvalues i = 1/`colnum' {
	eststo col`i': reg fakex fakey
}


local count = 1
local varlabels ""
local statnames ""

foreach var in Dbasefirst Dbaselast Dbasemed Dbasemean Dbaseend Dfirstlast Dfirstend Dmedend Dmeanend Dlastend {
	
	if "`treat'" == "basic" { 
	
		sum `var' if treat, detail

		*** COLUMN 1: MEAN ***
		local mean = string(r(mean), "%9.2f")
		estadd local thisstat`count' = "`mean'": col1
		estadd local thisspace`count' = " ": col1

		*** COLUMN 2: SD ***
		local sd = string(r(sd), "%9.2f")
		estadd local thisstat`count' = "`sd'": col2
		estadd local thisspace`count' = " ": col2
		
		*** COLUMN 3: MEDIAN ***
		local med = string(r(p50), "%9.2f")
		estadd local thisstat`count' = "`med'": col3
		estadd local thisspace`count' = " ": col3
		
		*** COLUMN 4: MIN  ***
		local min = string(r(min), "%9.2f")
		estadd local thisstat`count' = "`min'": col4
		estadd local thisspace`count' = " ": col4
		
		*** COLUMN 5: MAX ***
		local max = string(r(max), "%9.2f")
		estadd local thisstat`count' = "`max'": col5
		estadd local thisspace`count' = " ": col5
		
	}
	
	if "`treat'" == "large" {
		local cat1 "treatXlarge"
		local cat1lab "Large Transfer"
		local cat2 "treatXsmall"
		local cat2lab "Small Transfer"
	}
	
	if "`treat'" == "femaleXmarried" {
		local cat1 "treatXfemalerecXmarried"
		local cat1lab "Female Recipient"
		local cat2 "treatXmalerecXmarried"
		local cat2lab "Male Recipient"
	}
	
	if "`treat'" == "monthly" {
		local cat1 "treatXmonthlyXsmall"
		local cat1lab "Monthly"
		local cat2 "treatXlumpXsmall"
		local cat2lab "Lump Sum"
	}
	
	if "`treat'" == "large" | "`treat'" == "femaleXmarried" | "`treat'" == "monthly"  { 
	local co = 1
	forvalue i = 1/2 {
		sum `var' if `cat`i'' == 1, detail

		*** COLUMN 1: MEAN ***
		local mean = string(r(mean), "%9.2f")
		estadd local thisstat`count' = "`mean'": col`co'
		estadd local thisspace`count' = " ": col`co'
		local ++co

		*** COLUMN 2: SD ***
		local sd = string(r(sd), "%9.2f")
		estadd local thisstat`count' = "`sd'": col`co'
		estadd local thisspace`count' = " ": col`co'
		local ++co
		
		*** COLUMN 3: MEDIAN ***
		local med = string(r(p50), "%9.2f")
		estadd local thisstat`count' = "`med'": col`co'
		estadd local thisspace`count' = " ": col`co'
		local ++co
		
		*** COLUMN 4: MIN  ***
		local min = string(r(min), "%9.2f")
		estadd local thisstat`count' = "`min'": col`co'
		estadd local thisspace`count' = " ": col`co'
		local ++co
		
		*** COLUMN 5: MAX ***
		local max = string(r(max), "%9.2f")
		estadd local thisstat`count' = "`max'": col`co'
		estadd local thisspace`count' = " ": col`co'
		local ++co
		}

	}
	
	*** LABELS ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisspace`count'"
	local ++count
		
	
				
	
} 
if "`treat'" == "basic" esttab col* using "$output_dir/UCT_Timing_SumStats_`treat'.tex", replace cells(none) booktabs nonotes compress  alignment(ccccc) mtitle("Mean" "SD" "Median" "Min" "Max") stats(`statnames', labels(`varlabels') ) nonum
if "`treat'" ~= "basic"  esttab col* using "$output_dir/UCT_Timing_SumStats_`treat'.tex", replace cells(none) booktabs nonotes compress mgroups("`cat1lab'" "`cat2lab'", pattern(1 0 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  alignment(ccccc) mtitle("Mean" "SD" "Median" "Min" "Max" "Mean" "SD" "Median" "Min" "Max") stats(`statnames', labels(`varlabels') ) nonum
}
