* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close

********** SOE vs. Private Firms **********
use "$data/soe_vs_private_QJE_final", clear

cap erase $result/T_soe_vs_private.txt 
cap erase $result/T_soe_vs_private.xml 



rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 0,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 0,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 0,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 


rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 0,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 0,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 0,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 


rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 1,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 1,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & soe == 1,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 1,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 1,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & soe == 1,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_soe_vs_private, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 


*** Insert all the Tables ***

xmluse $result/T_soe_vs_private.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100)  allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_soe_vs_private", replace) 



********** Big vs. Small Firms **********

use "$data/big_vs_small_QJE_final", clear

cap erase $result/T_big_vs_small.txt 
cap erase $result/T_big_vs_small.xml 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 0,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 0,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 0,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 


rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 0,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 0,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 0,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 


rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 1,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 1,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==1 & firm_big == 1,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_p) dec(2) append 


rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 1,masspoints(off) kernel(tri) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 1,masspoints(off) kernel(epa) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 

rdrobust resid1_tfpop_s distance_new if neg_ind0==0 & firm_big == 1,masspoints(off) kernel(uniform) all vce(cluster site_id) 					
outreg2 using $result/T_big_vs_small, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(pe_tfpop_np) dec(2) append 


xmluse $result/T_big_vs_small.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100)  allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_big_vs_small", replace) 



********** River Basin: South-North Water Diversion Project **********
use "$data/NSBD_QJE_final", clear

cap erase $result/T_localRD_basin.txt 
cap erase $result/T_localRD_basin.xml 

* Authomatic bandwidth models: 
local kernelfn "epa tri uni"   

	foreach y of var resid1_tfpop_s{	
		foreach kvar of local kernelfn { 
		
			rdrobust `y' distance_new if neg_ind0==1 & nsbd==0,masspoints(off) kernel(`kvar') vce(cluster site_id)	
			outreg2 using $result/T_localRD_basin, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		}
	}


	foreach y of var resid1_tfpop_s{	
		foreach kvar of local kernelfn { 
		
			rdrobust `y' distance_new if neg_ind0==0 & nsbd==0,masspoints(off) kernel(`kvar') vce(cluster site_id)	
			outreg2 using $result/T_localRD_basin, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		}
	}
	
	
	foreach y of var resid1_tfpop_s{	
		foreach kvar of local kernelfn { 
		
			rdrobust `y' distance_new if neg_ind0==1 & nsbd==1,masspoints(off) kernel(`kvar') vce(cluster site_id)	
			outreg2 using $result/T_localRD_basin, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		}
	}


	foreach y of var resid1_tfpop_s{	
		foreach kvar of local kernelfn { 
		
			rdrobust `y' distance_new if neg_ind0==0 & nsbd==1,masspoints(off) kernel(`kvar') vce(cluster site_id)	
			outreg2 using $result/T_localRD_basin, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		}
	}
	

xmluse $result/T_localRD_basin.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_localRD_basin", replace) 

	



