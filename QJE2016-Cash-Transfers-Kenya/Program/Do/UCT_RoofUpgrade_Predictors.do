version 13.1 
clear all
set more off
sysdir set PERSONAL "${ado_dir}"

use "$data_dir/UCT_FINAL_CLEAN.dta", clear
drop if ~spillover
gen include = 1

*** SET BASELINE VARIABLES TO TEST ***
global baseline_predictors "asset_total_ppp0 cons_nondurable_ppp0 ent_total_rev_ppp0 fs_hhfoodindexnew0 med_hh_healthindex0 ed_index0 psy_index_z0 ih_overall_index_z0"
global baseline_demos "b_age b_married b_children b_hhsize b_edu"

*** CREATE EMPTY TABLES ***
gen fakex = 1
gen fakey = 1

local totalcols = 3
forvalues i = 1/`totalcols' {
	eststo col`i': reg fakex fakey
}

local count = 1
local countse = `count'+1
local varlabels ""\textbf{Panel A: Baseline Demographics}" " ""
local statnames "title1 title2"

*** EFFECT OF DEMOGRAPHICS ***
foreach var in $baseline_demos {
	replace include = 0 if maleres
	
	*** COLUMN 1: EFFECT ON UPGRADE POOLED ***
	reg asset_niceroof1 `var' if include == 1, cluster(surveyid)
	pstar `var', prec(4) sestar
	estadd local thisstat`count' = "`r(bstar)'": col1
	estadd local thisstat`countse' = "`r(sestar)'": col1
	
	*** COLUMN 2: R-SQUARED ***
	local thisr2 = string(e(r2), "%9.4f")
	estadd local thisstat`count' = "`thisr2'": col2
	
	*** COLUMN 3: Joint Estimation ***
	reg asset_niceroof1 $baseline_demos if include == 1, cluster(surveyid)
	pstar `var', prec(4) sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thisstat`countse' = "`r(sestar)'": col3

	*** LABELS ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1
}
// Joint Test

reg asset_niceroof1 $baseline_demos, cluster(surveyid)
local jointr2 = string(e(r2), "%9.4f")
estadd local jointr2 = "`jointr2'": col3

testparm $baseline_demos

pstar, p(`r(p)') pstar pnopar
estadd local testp "`r(pstar)'": col3
local statnames "`statnames' testp jointr2" 
local varlabels "`varlabels' "\midrule Joint Significance (\emph{p}-value)" "Joint Estimation R-squred" "

*** EFFECT OF BASELINE OUTCOMES ***
local varlabels "`varlabels' "\midrule" "\textbf{Panel B: Baseline Outcome Variables}" " " "
local statnames "`statnames' title0 title1 title2"
local count = `count' + 4
local countse = `count' + 1


foreach var in $baseline_predictors {
	if "`var'" == "psy_index_z0" replace include = 1 if maleres
	else replace include = 0 if maleres
	
	*** COLUMN 1: EFFECT ON UPGRADE POOLED ***
	reg asset_niceroof1 `var' if include, cluster(surveyid)
	pstar `var', prec(4) sestar
	estadd local thisstat`count' = "`r(bstar)'": col1
	estadd local thisstat`countse' = "`r(sestar)'": col1
	
	*** COLUMN 2: R-SQUARED ***
	local thisr2 = string(e(r2), "%9.4f")
	estadd local thisstat`count' = "`thisr2'": col2
	
	*** COLUMN 3: Joint Estimation ***
	reg asset_niceroof1 $baseline_predictors if ~maleres, cluster(surveyid)
	pstar `var', prec(4) sestar
	estadd local thisstat`count' = "`r(bstar)'": col3
	estadd local thisstat`countse' = "`r(sestar)'": col3

	*** LABELS ***
	local thisvarlabel: variable label `var'
	local varlabels "`varlabels' "`thisvarlabel'" " " "
	local statnames "`statnames' thisstat`count' thisstat`countse'"
	local count = `count' + 2
	local countse = `count' + 1
}
// Joint Test


reg asset_niceroof1 $baseline_predictors if ~maleres, cluster(surveyid)
local jointr2_2 = string(e(r2), "%9.4f")
estadd local jointr2_2 = "`jointr2_2'": col3

testparm $baseline_predictors

pstar, p(`r(p)') pstar pnopar
estadd local testp2 "`r(pstar)'": col3
local statnames "`statnames' testp2 jointr2_2" 
local varlabels "`varlabels' "\midrule Joint Significance (\emph{p}-value)" "Joint Estimation R-squared""

*** OUTPUT TABLE ***
esttab col* using "$output_dir/Metal Roof Predictors.tex", cells(none) booktabs nonotes compress replace alignment(SSS)  mtitle("\specialcell{Upgrade Likelihood\\Independent Estimate}" "\specialcell{R-squared}"  "\specialcell{Upgrade Likelihood\\Joint Estimate}") stats(`statnames', labels(`varlabels')  )
