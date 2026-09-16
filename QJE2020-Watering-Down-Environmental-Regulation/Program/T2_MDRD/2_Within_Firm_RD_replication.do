* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close




use "$data/T2_MDRD.dta", clear

****Table 2. Within Firm RD ****

*****Install MDRD package
* [path fix] mdrd site offline; archived copy loaded from Program/ado by run_original.do
* net describe mdrd, from(https://sites.google.com/site/r4ribas/codes/packages)
* net install mdrd, force from(https://sites.google.com/site/r4ribas/codes/packages)

****Polluting industries
cap erase $result/DID_tfp_p.xml
cap erase $result/DID_tfp_p.txt
mdrd resid2_tfpop_s distance_new if neg_ind0==1, time(post03) all kernel(tri)
outreg2 using $result/DID_tfp_p, excel addtext(Kernel Type, `e(kernel)') ctitle(p_tfp) dec(2) append 
mdrd resid2_tfpop_s distance_new if neg_ind0==1, time(post03) all kernel(epa)
outreg2 using $result/DID_tfp_p, excel addtext(Kernel Type, `e(kernel)') ctitle(p_tfp) dec(2) append 
mdrd resid2_tfpop_s distance_new if neg_ind0==1, time(post03) all kernel(uni)
outreg2 using $result/DID_tfp_p, excel addtext(Kernel Type, `e(kernel)') ctitle(p_tfp) dec(2) append 


****Non-Polluting industries
cap erase $result/DID_tfp_np.xml
cap erase $result/DID_tfp_np.txt
mdrd resid2_tfpop_s distance_new if neg_ind0==0, time(post03) all kernel(tri)
outreg2 using $result/DID_tfp_np, excel addtext(Kernel Type, `e(kernel)') ctitle(np_tfp) dec(2) append 
mdrd resid2_tfpop_s distance_new if neg_ind0==0, time(post03) all kernel(epa)
outreg2 using $result/DID_tfp_np, excel addtext(Kernel Type, `e(kernel)') ctitle(np_tfp) dec(2) append 
mdrd resid2_tfpop_s distance_new if neg_ind0==0, time(post03) all kernel(uni)
outreg2 using $result/DID_tfp_np, excel addtext(Kernel Type, `e(kernel)') ctitle(np_tfp) dec(2) append 



