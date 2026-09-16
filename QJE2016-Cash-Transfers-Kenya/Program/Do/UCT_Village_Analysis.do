version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

*** SET MACROS ***
//Food
local fruit "avocadoscost guavacost largebananacost mangoscost orangescost passionfruitcost pawpawcost pineapplecost smallbananacost watermeloncost"
local veg "cabbagecost eggplantcost kalecost onionscost pumpkincost spinachcost tomatoescost traditionalveggiescost"
local starch "arrowrootcost cassavacost cookingbananacost maizecost potatocost sweetpotatocost"
local fish "mudfishcost omenafishcost tilapiacost"
local other_food "beanscost cowpeascost dairycost eggscost pilipilicost sugarcost"

///Non-food
local durable "ironroofgeneral ironrepaircostgen thatchroof"
local nondurable "firewoodvalue haircutsvalue parafinvalue soapvalue" 
local non_food "ironroofgeneral ironrepaircostgen thatchroof firewoodvalue haircutsvalue parafinvalue soapvalue"

//Labor
local wages "v_ave_dailywage farm_dailywage livestock_dailywage other_dailywage"

//Crime
local crime "assault assaultfrequency conflictcount crimelastyear drugabuse drugabusefrequency murder murderfrequency othercrimes othercrimesfrequency rape rapefrequency robbery robberyfrequency vandalism vandalismfrequency"

//Indices
local price_list "`fruit' `veg' `starch' `fish' `other_food' `durable' `nondurable'"
local food_list "`fruit' `veg' `starch' `fish' `other_food'"
local wages_list "farm_dailywage livestock_dailywage other_dailywage"
local crime_dummy_list "assault drugabuse murder othercrimes rape robbery vandalism"
local crime_freq_list "assaultfrequency drugabusefrequency murderfrequency othercrimesfrequency rapefrequency robberyfrequency vandalismfrequency"
local food_price "fish_ind fruit_ind starch_ind veg_ind dairy_eggs_ind other_food_ind"
local indices_new "food_ind non_food_ind wages_ind crime_freq_ind"


*** ANALYSIS ***

foreach thisvarlist in "fruit" "veg" "starch" "fish" "other_food" "durable" "nondurable" "wages" "crime" "indices" "food_price" "non_food" "indices_new" {


	*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/3 {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""

	
	*** REGRESSIONS ***
	foreach thisvarname in ``thisvarlist'' {
		
		use "$data_dir/UCT_Village_Collapsed.dta", clear
		drop if `thisvarname' == .
			
		*** COLUMN 1: CONTROL MEAN ***
		sum `thisvarname' if ~treat
		estadd local thisstat`count' = string(`r(mean)', "%9.2f") : col1
		estadd local thisstat`countse' = "(" + string(`r(sd)', "%9.2f") + ")" : col1
		
		*** COLUMN 2: TREATMENT VILLAGE ***
		reg `thisvarname' treat, r 
		pstar treat
		estadd local thisstat`count' = "`r(bstar)'": col2
		estadd local thisstat`countse' = "`r(sestar)'": col2
	
		*** COLUMN 3: N ***
		local thisN = e(N)
		estadd scalar thisstat`count' = `thisN': col3
							
		*** ITERATE ***
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"
		local count = `count' + 2
		local countse = `count' + 1
		local ++varcount 			
	}
	
	esttab col* using "$output_dir/`thisvarlist'_treat_village.tex",  cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Control\\mean (SD)}" "\specialcell{Treatment}" "N" ) stats(`statnames', labels(`varlabels') )  

}




