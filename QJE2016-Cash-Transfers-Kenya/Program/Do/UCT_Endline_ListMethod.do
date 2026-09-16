version 13.1 
set more off
clear all
sysdir set PERSONAL "${ado_dir}"
use "$data_dir/UCT_FINAL_CLEAN.dta", clear

*** COLUMN 1: ALCOHOL ***
areg listmethod_total listmethod1 listmethodXtreat1 if ~listmethod2, cluster(surveyid) absorb(village)
estimates store model1

*** COLUMN 2: TOBACCO ***
areg listmethod_total listmethod2 listmethodXtreat2 if ~listmethod1, cluster(surveyid) absorb(village)
estimates store model2
	
*** OUTPUT ***
esttab * using "$output_dir/listmethod.tex", b(%9.2f) se(%9.2f) booktabs nonotes compress label replace mtitle("\specialcell{Number of\\Activities}" "\specialcell{Number of\\Activities}") star(* 0.10 ** 0.05 *** 0.01)
