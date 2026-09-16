* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close


use "$data/abatement_QJE_final.dta",clear
cap erase $result/T_abatement.txt 
cap erase $result/T_abatement.xml 	


********Abatement in production process********
** reduced production hours 
rdrobust resid1_hours distance_new,masspoints(off) kernel(tri) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid prod hours) dec(0) replace
rdrobust resid1_hours distance_new,masspoints(off) kernel(epa) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid prod hours) dec(0) append
rdrobust resid1_hours distance_new,masspoints(off) kernel(uni) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid prod hours) dec(0) append



** reduced water usage (changing towards less water-intensive technologies)
rdrobust resid1_log_water distance_new,masspoints(off) kernel(tri) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid log water input) dec(2) append
rdrobust resid1_log_water distance_new,masspoints(off) kernel(epa) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid log water input) dec(2) append
rdrobust resid1_log_water distance_new,masspoints(off) kernel(uni) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid log water input) dec(2) append

 
 ********End-of-the-Pipe Technology********
 **upstream firms own more abatement machines
rdrobust resid1_machine distance_new ,masspoints(off) kernel(tri) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate machine) dec(2) append
rdrobust resid1_machine distance_new ,masspoints(off) kernel(epa) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate machine) dec(2) append
rdrobust resid1_machine distance_new ,masspoints(off) kernel(uni) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate machine) dec(2) append

 
 **upstream firms have higher abatement capacity
rdrobust resid1_total_capacity distance_new ,masspoints(off) kernel(tri) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate capacity) dec(0) append
rdrobust resid1_total_capacity distance_new ,masspoints(off) kernel(epa) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate capacity) dec(0) append
rdrobust resid1_total_capacity distance_new ,masspoints(off) kernel(uni) all vce(cluster site_id)
outreg2 using $result/T_abatement, excel addtext(Kernel Type, `e(kernel)') ctitle(resid abate capacity) dec(0) append


****** Insert Table *****
xmluse $result/T_abatement.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_abatement", replace) 


