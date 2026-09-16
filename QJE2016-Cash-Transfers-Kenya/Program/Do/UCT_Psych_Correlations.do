version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"


*** RESHAPE FOR TWO TIME PERIODS PER OBSERVATION ***
global index_nopsy "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index ih_overall_index_z"
global psy_nocort "psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z" 
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
xi i.village, pref(fev)
tempfile use_wide
save `use_wide'
gen id = _n
reshape long $index_nopsy $psy_nocort psy_lncort_mean_clean, i(id) j(time)
tempfile use_long
save `use_long'


*** TABLES FOR PSYCH INDEX AND CORTISOL ***
foreach depvar in "psy_index_z" "psy_lncort_mean_clean" {
	if "`depvar'" == "psy_index_z" local ivarlist "$index_nopsy"
	else if "`depvar'" == "psy_lncort_mean_clean" local ivarlist "$psy_nocort" 
	
*** EMPTY TABLE ***
	clear all
	local numvars: list sizeof ivarlist
	set obs 10 
	gen x = 1
	gen y = 1

	forvalues x = 1/`numvars' {
		eststo col`x': reg x y
	}
	
	local varcount = 1
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""

*** PSYCH INDEX CORRELATIONS ***
	if "`depvar'" == "psy_index_z" {
		foreach var in `ivarlist' {
			*** COLUMN 1: CONTEMPORANEOUS ***
			use `use_long', clear
			reg psy_index_z `var' fev* $spillovercontrols, cluster(village) 
			pstar `var'
			estadd local thisstat1 = "`r(bstar)'": col`varcount'
			estadd local thisstat2 = "`r(sestar)'": col`varcount'
			
			*** COLUMN 2: ACROSS TIME ***
			use `use_wide', clear
			reg psy_index_z1 `var'0 fev* $spillovercontrols, cluster(village) 
			pstar `var'0
			estadd local thisstat3 = "`r(bstar)'": col`varcount'
			estadd local thisstat4 = "`r(sestar)'": col`varcount'
			local ++varcount 
		}
		esttab col* using "$output_dir/reg_psy_index_z_indices_nopsych_z.tex",  cells(none) booktabs nonotes compress replace alignment(S) mtitle("Assets" "Expenditure" "Income" "Food Security" "Health" "Education" "Female Empowerment") stats(thisstat1 thisstat2 thisstat3 thisstat4, labels("Contemporaneous" " " "Across time" " ") ) nonumbers 
	}

*** CORTISOL CORRELATIONS ***
	else if "`depvar'" == "psy_lncort_mean_clean" {	
		foreach var in `ivarlist' {
			*** COLUMN 1: CONTEMPORANEOUS ***
			use `use_long', clear
			reg psy_lncort_mean_clean `var' fev* $spillovercontrols, cluster(village) 
			pstar `var'
			estadd local thisstat1 = "`r(bstar)'": col`varcount'
			estadd local thisstat2 = "`r(sestar)'": col`varcount'
			
			*** COLUMN 2: ACROSS TIME ***
			use `use_wide', clear
			reg psy_lncort_mean_clean1 `var'0 fev* $spillovercontrols, cluster(village) 
			pstar `var'0
			estadd local thisstat3 = "`r(bstar)'": col`varcount'
			estadd local thisstat4 = "`r(sestar)'": col`varcount'
			local ++varcount 
		}
		esttab col* using "$output_dir/reg_psy_lncort_mean_clean_psyvars_nocort_z.tex",  cells(none) booktabs nonotes compress replace alignment(S) mtitle("Depression" "Worries" "Stress" "Happiness" "Satisfaction" "Trust" "Locus of control" "Optimism" "Self-esteem" "Index") stats(thisstat1 thisstat2 thisstat3 thisstat4, labels("Contemporaneous" " " "Across time" " ") ) nonumbers 
	}
}
