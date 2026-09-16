
* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close




************************** Figure 4 RD on TFP *****************************
use "$data/tfp_small_QJE_final.dta",clear

winsor2 resid1_tfpop_s , replace cuts(0.5 99.5) trim


set scheme plotplainblind


preserve
rdplot resid1_tfpop_s distance_new if neg_ind0==1 & abs(distance_new)<10, p(3) kernel(uni) nbins(7 7) ci(90) ///
       graph_options(subtitle("Panel A. TFP in Polluting Industries")  legend(off) ytitle(Residualized TFP (log)) xtitle(Distance from Monitoring Station) scheme(plotplainblind))
restore 
graph save $figure/F3_Polluting_resid1_tfpop_s, replace
graph export $figure/F3_Polluting_resid1_tfpop_s.png, replace


preserve
rdplot resid1_tfpop_s distance_new if neg_ind0==0& abs(distance_new)<10, p(3) kernel(uni) nbins(7 7) ci(90) ///
       graph_options(subtitle("Panel B. TFP in Non-Polluting Industries") legend(off) ytitle(Residualized TFP (log)) xtitle(Distance from Monitoring Station) scheme(plotplainblind))
restore   	   
graph save $figure/F3_Non_Polluting_resid1_tfpop_s, replace
graph export $figure/F3_Non_Polluting_resid1_tfpop_s.png, replace


graph combine $figure/F3_Polluting_resid1_tfpop_s.gph  $figure/F3_Non_Polluting_resid1_tfpop_s.gph, xsize(6) ysize(8) ycommon xcommon col(1) scheme(plotplainblind)

graph save $figure/F3_TFP, replace
graph export $figure/F3_TFP.png, replace
