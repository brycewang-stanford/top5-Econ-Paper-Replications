*********************************************************************************
*Table C5.The Impact of Elite Networks and Elite Power: Varying Comparison Provinces
*********************************************************************************


use Data/NationalCntyYr.dta,clear


********************************************************************************
********** gen interactions

gen hXZeng_all0_invdist=hunan*Zeng_all0_invdist
gen hXZeng_exam0_invdist=hunan*Zeng_exam0_invdist
gen hXZeng_Extraexam_invdist=hunan*Zeng_Extraexam_invdist


foreach x of varlist hunan  Zeng_all0_invdist Zenghu_all_invdist Zeng_exam0_invdist Zeng_Extraexam_invdist hXZeng_all0_invdist hXZeng_exam0_invdist hXZeng_Extraexam_invdist martyrs_tot_post{
gen `x'Xperiod=`x'*period

}

foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea  mainriv dist2canal lnrice lnwheat dist_nanjing Taiping_route1 {
gen `x'Xperiod=`x'*period

}

********************************************************************************

keep if year > =1820


******************************* Hunan vs. Guangxi, Hubei， Jiangxi， Anhui and Jiangsu

reghdfe alloff   hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod  hunanXperiod   lnurbanpopXperiod-Taiping_route1Xperiod   if provcd==11|provcd==5|provcd==16|provcd==10| provcd==3| provcd==2, absorb(year samcntyid) cluster(prefid samcntyid)

outreg2 using Results/Appendix_Table_C5.doc, keep(  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )  se  bdec(3) rdec(3) nocons replace 


reghdfe alloff  martyrs_tot_postXperiod   hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod  hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod  if provcd==11|provcd==5|provcd==16|provcd==10| provcd==3| provcd==2, absorb(year samcntyid ) cluster(prefid samcntyid)


outreg2 using Results/Appendix_Table_C5.doc, keep(martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )   se  bdec(3) rdec(3) nocons append 


******************************* Hunan vs. Guangxi, Hubei and Jiangxi

reghdfe alloff    hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod   if provcd==11|provcd==5|provcd==16|provcd==10, absorb(year samcntyid ) cluster(prefid samcntyid)

outreg2 using Results/Appendix_Table_C5.doc, keep(martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )   se  bdec(3) rdec(3) nocons append 


reghdfe alloff  martyrs_tot_postXperiod    hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod if provcd==11|provcd==5|provcd==16|provcd==10, absorb(year samcntyid ) cluster(prefid samcntyid)


outreg2 using Results/Appendix_Table_C5.doc, keep(martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )   se  bdec(3) rdec(3) nocons append 



******************************* Hunan vs. Anhui and Jiangsu

reghdfe alloff  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod if provcd==11| provcd==3| provcd==2, absorb(year samcntyid) cluster(prefid samcntyid)

outreg2 using Results/Appendix_Table_C5.doc, keep(martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )   se  bdec(3) rdec(3) nocons append 


reghdfe alloff  martyrs_tot_postXperiod hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod  hunanXperiod lnurbanpopXperiod-Taiping_route1Xperiod   if provcd==11| provcd==3| provcd==2, absorb(year samcntyid) cluster(prefid samcntyid)


outreg2 using Results/Appendix_Table_C5.doc, keep(martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod )   se  bdec(3) rdec(3) nocons append 
