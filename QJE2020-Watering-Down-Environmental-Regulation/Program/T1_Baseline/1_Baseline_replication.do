
* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close


***** Tabble 1. Baseline Results *****

use "$data/tfp_small_QJE_final.dta",clear

* Authomatic bandwidth models: 
local kernelfn "tri epa uni"   


cap erase $result/T2_localRD.txt 
cap erase $result/T2_localRD.xml 


foreach y of var tfpop_s resid1_tfpop_s resid2_tfpop_s{	
	foreach kvar of local kernelfn { 
		
		rdrobust `y' distance_new if neg_ind0==1,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T2_localRD, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
	}
}



local kernelfn "tri epa uni" 
foreach y of var tfpop_s resid1_tfpop_s resid2_tfpop_s {
	
	foreach kvar of local kernelfn { 
		
		rdrobust `y' distance_new if neg_ind0==0,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T2_localRD, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_np) dec(2) append 
	}
}


****** Insert Table *****

xmluse $result/T2_localRD.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T2_localRD", replace) 
