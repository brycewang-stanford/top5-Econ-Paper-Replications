version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"


*** DEFINE LISTS ***
local b_f_cesd "b_f_cesd1-b_f_cesd20"
local b_m_cesd "b_m_cesd1-b_m_cesd20"
local b_f_scheier "b_f_scheier1 b_f_scheier3 b_f_scheier4 b_f_scheier7 b_f_scheier9 b_f_scheier10"
local b_m_scheier "b_m_scheier1 b_m_scheier3 b_m_scheier4 b_m_scheier7 b_m_scheier9 b_m_scheier10"
local b_f_rosenberg "b_f_rosenberg1-b_f_rosenberg10"
local b_m_rosenberg "b_m_rosenberg1-b_m_rosenberg10"
local b_f_cohen "b_f_cohen_2 b_f_cohen_6 b_f_cohen_7 b_f_cohen_14"
local b_m_cohen "b_m_cohen_2 b_m_cohen_6 b_m_cohen_7 b_m_cohen_14"
local b_f_rotter "b_f_rotter4 b_f_rotter6 b_f_rotter11 b_f_rotter13 b_f_rotter15 b_f_rotter16 b_f_rotter17 b_f_rotter18 b_f_rotter20 b_f_rotter25"
local b_m_rotter "b_m_rotter4 b_m_rotter6 b_m_rotter11 b_m_rotter13 b_m_rotter15 b_m_rotter16 b_m_rotter17 b_m_rotter18 b_m_rotter20 b_m_rotter25"
local scores "cesd scheier rosenberg cohen rotter"


*** CREATE EMPTY TABLE ***
clear all
set obs 10
gen x = 1
gen y = 1
forvalues i = 1/3 {
	eststo col`i': reg x y
}

local count = 1
local statnames ""
local scorelabels ""


*** CREATE ALPHAS ***
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
foreach score in `scores' {
	
	*** COLUMN 1: ALPHA, MALE ***
	alpha `b_m_`score'', item
	local thisalpha = `r(alpha)'
	estadd local thisstat`count' = string(`thisalpha', "%9.3f") : col1
	
	*** COLUMN 1: ALPHA, FEMALE ***
	alpha `b_f_`score'', item
	local thisalpha = `r(alpha)'
	estadd local thisstat`count' = string(`thisalpha', "%9.3f") : col2
	
	*** ITEMS ***
	local thisk = `r(k)'
	estadd local thisstat`count' = `thisk' : col3
		
	local statnames "`statnames' thisstat`count'"
	local ++count
}

esttab col* using "$output_dir/psych_alpha.tex", cells(none) booktabs nonotes compress replace alignment(SSc) mtitle("\specialcell{Male\\respondents}" "\specialcell{Female\\respondents}" "\specialcell{Number of items\\in scale}") stats(`statnames', labels("Depression (CESD)" "Optimism (Scheier)" "Self-esteem (Rosenberg)" "Stress (Cohnen)" "Locus of Control")) nonumbers




