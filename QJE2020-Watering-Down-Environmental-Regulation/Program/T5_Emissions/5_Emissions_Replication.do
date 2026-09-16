* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close

use "$data/water_emission_QJE_final.dta", clear
** Local Linear RD Results for Emission **

cap erase  $result/T_localRD_emission.xml
cap erase  $result/T_localRD_emission.txt

foreach y of var resid_log_cod resid_log_cod_intensity resid_log_nh resid_log_nh_intensity resid_log_waste_water resid_log_waste_water_intensity {


rdrobust `y' distance_new ,masspoints(off) kernel(tri) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

rdrobust `y' distance_new ,masspoints(off) kernel(epa) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

rdrobust `y' distance_new ,masspoints(off) kernel(uni) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

}

***** Placebo Pollutants ***** 
use "$data/air_emission_QJE_final.dta", clear


foreach y of var resid_log_so2 resid_log_nox {

rdrobust `y' distance_new ,masspoints(off) kernel(tri) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

rdrobust `y' distance_new ,masspoints(off) kernel(epa) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

rdrobust `y' distance_new ,masspoints(off) kernel(uni) all vce(cluster site_id)				
outreg2 using $result/T_localRD_emission, excel addtext(Kernel Type, `e(kernel)') ctitle(`y') dec(2) append 

}


****** Insert Table *****
*** Insert all the Tables ***

xmluse $result/T_localRD_emission.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_localRD_emission", replace) 







