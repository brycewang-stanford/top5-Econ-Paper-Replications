* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close

*********** Post-2003 Results ***********

use "$data/channels_QJE_final.dta", clear

*** Create Table *** 
cap erase $result/TS_Channel.txt 
cap erase $result/TS_Channel.xml 	

foreach y of var resid1_lrze resid1_lnv resid1_lnl  resid1_lnk resid1_lnm resid1_lnv_l resid1_lnv_k{
	rdrobust  `y' distance_new if neg_ind0==1, masspoints(off) kernel(tri) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new if neg_ind0==1,masspoints(off) kernel(epa) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new if neg_ind0==1,masspoints(off) kernel(uni) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

}



xmluse $result/TS_Channel.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("TS_Channel", replace) 



*********** Pre-2003 Results ***********


use "$data/channels_Pre_QJE_final.dta",clear

cap erase $result/TS_Channel_Pre.txt 
cap erase $result/TS_Channel_Pre.xml 	

foreach y of var resid1_lrze resid1_lnv resid1_lnl  resid1_lnk resid1_lnm resid1_lnv_l resid1_lnv_k {
	rdrobust  `y' distance_new if neg_ind0==1,masspoints(off) kernel(tri) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel_Pre, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new if neg_ind0==1,masspoints(off) kernel(epa) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel_Pre, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new if neg_ind0==1,masspoints(off) kernel(uni) all vce(cluster site_id) 			
	outreg2 using $result/TS_Channel_Pre, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

}

xmluse $result/TS_Channel_Pre.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("TS_Channel_Pre", replace) 




