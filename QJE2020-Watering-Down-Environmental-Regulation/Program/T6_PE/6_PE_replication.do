
use "$data/pwf_QJE_final.dta",clear


***************************** Emission Fee *****************************
cap erase $result/TS_Fee.txt 
cap erase $result/TS_Fee.xml 	


* Authomatic bandwidth models: 

foreach y of var resid1_l_pwf {
	rdrobust  `y' distance_new ,masspoints(off) bwselect(certwo) kernel(tri) all vce(cluster site_id) 			
	outreg2 using $result/TS_Fee, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new ,masspoints(off) bwselect(certwo) kernel(epa) all vce(cluster site_id) 			
	outreg2 using $result/TS_Fee, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

	rdrobust  `y' distance_new,masspoints(off) bwselect(certwo) kernel(uni) all vce(cluster site_id) 			
	outreg2 using $result/TS_Fee, excel addtext(Kernel Type, `e(kernel)') ctitle( `y') dec(2) append 

}


xmluse $result/TS_Fee.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("TS_Fee", replace) 




***************************** Table Political Incentive ***********************
use "$data/PE_QJE_final.dta",clear

cap erase $result/T_political.txt 
cap erase $result/T_political.xml 	

* in years when the prefecture party secretary has strong promotion incentives, effect size is larger


local kernelfn "tri epa uni"   
* Authomatic bandwidth models: 

foreach y of var resid1_tfpop_s {	
	foreach kvar of local kernelfn { 
		
		rdrobust `y' distance_new if neg_ind0==1 & party_inc ==1,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T_political, excel addtext(Kernel Type,masspoints(off) `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_high) dec(2) append 

		}
}


foreach y of var resid1_tfpop_s {	
	foreach kvar of local kernelfn { 
		rdrobust `y' distance_new if neg_ind0==1 & party_inc ==0,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T_political, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_low) dec(2) append 

		}
}

foreach y of var resid1_tfpop_s {	
	foreach kvar of local kernelfn { 
		
		rdrobust `y' distance_new if neg_ind0==0 & party_inc ==1,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T_political, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_high) dec(2) append 

		}
}


foreach y of var resid1_tfpop_s {	
	foreach kvar of local kernelfn { 
		rdrobust `y' distance_new if neg_ind0==0 & party_inc ==0,masspoints(off) kernel(`kvar') all vce(cluster site_id)	
		outreg2 using $result/T_political, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_low) dec(2) append 

		}
}


xmluse $result/T_political, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_political", replace) 



***************************** Table Political Incentive *****************************
***** Auto vs. Manual Stations *****
use "$data/auto_QJE_final.dta",clear
cap erase $result/T_auto.txt 
cap erase $result/T_auto.xml 	

* Authomatic bandwidth models: 

foreach y of var resid1_tfpop_s {	
		
		rdrobust `y' distance_new if neg_ind0==1 & automatic==1,masspoints(off) kernel(tri) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==1 & automatic==1,masspoints(off) kernel(epa) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==1 & automatic==1,masspoints(off) kernel(uni) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 

}

foreach y of var resid1_tfpop_s {	

		rdrobust `y' distance_new if neg_ind0==1 & automatic==0,masspoints(off) kernel(tri) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==1 & automatic==0,masspoints(off) kernel(epa) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==1 & automatic==0,masspoints(off) kernel(uni) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 

}

foreach y of var resid1_tfpop_s {	

		rdrobust `y' distance_new if neg_ind0==0 & automatic==1,masspoints(off) kernel(tri) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==0 & automatic==1,masspoints(off) kernel(epa) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==0 & automatic==1,bwselect(msecomb1) kernel(uni) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 

}

foreach y of var resid1_tfpop_s {	

		rdrobust `y' distance_new if neg_ind0==0 & automatic==0,masspoints(off) kernel(tri) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==0 & automatic==0,masspoints(off) kernel(epa) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 
		
		rdrobust `y' distance_new if neg_ind0==0 & automatic==0,masspoints(off) kernel(uni) all vce(cluster site_id)	
		outreg2 using $result/T_auto, excel addtext(Kernel Type, `e(kernel)') addstat(bandwidth, e(h_l)) ctitle(`y'_p) dec(2) append 

}


xmluse $result/T_auto.xml, doctype(excel) sheet(Sheet1) cells(A2:FZ100) allstring missing nocompress clear 
export excel using $result/Tables_TFP.xlsx, sheet("T_auto", replace) 

