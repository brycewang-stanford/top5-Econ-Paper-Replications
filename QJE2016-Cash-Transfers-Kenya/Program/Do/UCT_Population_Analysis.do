version 13.1 
clear all
set more off 
sysdir set PERSONAL "${ado_dir}"

/* 
OVERVIEW: The purpose of this analysis is to create a table of summary statistics
by village on the total population, the percent of the population included in the 
study, and the percent of the population receiving transfers. In treatment villages,
we targeted ALL households with thatched roofs at baseline. Thus, for the purpose
of this analysis, we should consider the number of households in our dataset to 
be the total number of thatched roof households. In practice, there were descrepancies 
between the original GD census and our census, but they were quite small. We ultimately
dropped any households that did not show up in both censuses. Unfortunately, the original
GD census was lost. 

Additionally, neither census counted the metal roof households in the village. So,
estimates of the total village population come from two other sources:

1. Village elder "estimates" of the number of individuals in their village. We can
divide these by 5 (the average number of individuals per household) to get an estimate
of the total number of households in each village. Using these estimates, it appears
we surveyed ~20% of each village. Unfortunately, the estimates are very imprecise,
and for some village the estimate is >100%. 

2. Original GD population estimates. These are contained in the "village populations"
folder. Although when using the estimate of total households, we again get ~20%
of households included in the sample, the variable for the number of 
thatched households in this dataset is significantly higher than the number of households 
in our sample (remember that we surveyed ALL thatched, so we should trust OUR 
estimate.) Additionally, some of the population estimates are imputed based on
sublocation averages, so these aren't always accurate either.

Ultimately, for total population estimates I go with #2. However, I ignore the 
estimates in that dataset of the number of thatched households in each village, 
instead preferring to use the number of households in our sample. 

One weakness, is I don't count the number of households that refused to take the
baseline survey, as I don't know how many this is. However, this should be the difference
between the number of thtached households included in our census and the number 
in the baseline survey. 
*/


*** MERGE WITH VILLAGE LEVEL DATASET ***
use "$data_dir/UCT_Village_Collapsed.dta", clear
drop if treat == 0 // drop pure control villages
keep village approx_population total_hh total_thatch //approx_population is the village elder of the total number of individuals in the village at baseline
recode approx_population -99 =. // replace with median population
sum approx_population, detail
replace approx_population = r(p50) if approx_population == .
gen approx_hh = approx_population/5
merge 1:m village using "$data_dir/UCT_FINAL_CLEAN.dta", gen(popmerge)
drop if maleres == 1
drop if ~treat & ~spillover

*** APPEND BASELINE METAL ROOF SURVEYS ***
append using "$data_dir/UCT_MetalRoofHHs.dta", gen(metalroof)
drop if village == .
replace treat = 0 if metalroof == 1


*** CREATE PCT SURVEYED AND PCT TREATED ***
gen thatch = metalroof == 0
egen vil_sample = total(thatch), by(village)
egen total_treat = total(treat), by(village)
gen pct_surveyed = vil_sample / total_hh
gen pct_treated = total_treat / total_hh



*** TOTAL TRANSFER VARIABLE ***
egen total_transfers = total(1525 * treatXlarge + 404 * treatXsmall), by(village)

*** COLLAPSE BY VILLAGE AND GENERATE AVERAGE TOTAL WEALTH VARIABLE ***
collapse total_hh pct_surveyed pct_treated asset_total_ppp0 total_transfers, by(village metalroof)
recode asset_total_ppp0 0 = .
bysort village: gen total_wealth = (pct_surveyed * total_hh * asset_total_ppp0[1]) + ((1 - pct_surveyed) * total_hh * asset_total_ppp0[2])
collapse total_hh pct_surveyed pct_treated total_wealth total_transfers, by(village)
sum total_wealth, detail
replace total_wealth = r(p50) if total_wealth == .
gen transfers_pct_total = total_transfers / total_wealth

label var total_hh "Total number of households"
label var pct_surveyed "Proportion of households surveyed"
label var pct_treated "Proportion of households receiving transfers"
label var transfers_pct_total "Transfers as percent of total village wealth"


gen fakex = 1
gen fakey = 1

forvalues i = 1/5 {
	qui eststo col`i': reg fakex fakey
}

local count = 1
local varlabels ""
local statnames ""

foreach var in total_hh pct_surveyed pct_treated transfers_pct_total {

	sum `var', detail

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
			
	*** LABELS ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisspace`count'"
	local ++count
} 

esttab col* using "$output_dir/UCT Village Summary Stats.tex", replace cells(none) booktabs nonotes compress  alignment(ccccc) mtitle("Mean" "SD" "Median" "Minimum" "Maximum") stats(`statnames', labels(`varlabels') ) nonum

