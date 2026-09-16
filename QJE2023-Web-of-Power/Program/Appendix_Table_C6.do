
*********************************************************************************
*Table C6.The Impact of Elite Networks and Elite Power: Controlling for Placebo Networks
*********************************************************************************


use Data/NationalCntyYr.dta,clear



********************************************************************************
********** gen interactions


gen hXZeng_exam0_invdist=hunan*Zeng_exam0_invdist

gen hXinvdist0_F1=invdist0_F1*hunan
gen hXinvdist0_L1=invdist0_L1*hunan



foreach x of varlist hunan  Zeng_all0_invdist Zenghu_all_invdist Zeng_exam0_invdist Zeng_Extraexam_invdist hXZeng_exam0_invdist martyrs_tot_post hXinvdist0_F1 hXinvdist0_L1  invdist0_L1  invdist0_F1{
gen `x'Xperiod=`x'*period

}

foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea  mainriv dist2canal lnrice lnwheat dist_nanjing Taiping_route1 {
gen `x'Xperiod=`x'*period

}



********************************************************************************

keep if year > =1820

********************************************************************************


ivreghdfe alloff  (martyrs_tot_postXperiod  = hXZeng_exam0_invdistXperiod )  Zeng_exam0_invdistXperiod hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod , absorb(year samcntyid ) cluster(prefid )

outreg2 using Results/Appendix_Table_C6.doc, keep( hXZeng_exam0_invdistXperiod  martyrs_tot_postXperiod   Zeng_exam0_invdistXperiod hXinvdist0_L1Xperiod  invdist0_L1Xperiod  hXinvdist0_F1Xperiod  invdist0_F1Xperiod hunanXperiod )  se  bdec(3) rdec(3) nocons replace   



ivreghdfe alloff  (martyrs_tot_postXperiod  = hXZeng_exam0_invdistXperiod )  Zeng_exam0_invdistXperiod hXinvdist0_L1Xperiod  invdist0_L1Xperiod  hXinvdist0_F1Xperiod  invdist0_F1Xperiod  hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod  , absorb(year samcntyid ) cluster(prefid  )

outreg2 using Results/Appendix_Table_C6.doc, keep( hXZeng_exam0_invdistXperiod  martyrs_tot_postXperiod   Zeng_exam0_invdistXperiod hXinvdist0_L1Xperiod  invdist0_L1Xperiod  hXinvdist0_F1Xperiod  invdist0_F1Xperiod hunanXperiod )  se  bdec(3) rdec(3) nocons append  




