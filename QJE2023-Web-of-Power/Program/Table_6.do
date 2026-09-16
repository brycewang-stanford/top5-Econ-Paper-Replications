
*********************************************************************************
*************************** Table 6. The Power Effect: the Role of Soldier Deaths 
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



*******

***************  ***************  ***************  ***************
***************  ***************  ***************  *************** DDD Estimates, IV estimates, and Overid
***************  ***************  ***************  ***************

*********
reghdfe alloff    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid )  cluster(prefid )

outreg2 using Results/Table_6.doc, keep( hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons replace 


*********
reghdfe alloff    lnurbanpopXperiod-Taiping_route1Xperiod martyrs_tot_postXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid )  cluster(prefid )

outreg2 using Results/Table_6.doc, keep( hXZeng_all0_invdistXperiod  martyrs_tot_postXperiod  Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons append 


*********
reghdfe alloff    lnurbanpopXperiod-Taiping_route1Xperiod martyrs_tot_postXperiod  hXZeng_all0_invdistXperiod  Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid )  cluster(prefid )

outreg2 using Results/Table_6.doc, keep( hXZeng_all0_invdistXperiod  martyrs_tot_postXperiod  Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons append 


*********

ivreghdfe alloff  (martyrs_tot_postXperiod =     hXZeng_Extraexam_invdistXperiod hXZeng_exam0_invdistXperiod) Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod      lnurbanpopXperiod-Taiping_route1Xperiod       hunanXperiod , absorb(year samcntyid ) cluster(prefid )

outreg2 using Results/Table_6.doc, keep(martyrs_tot_postXperiod  hXZeng_exam0_invdistXperiod hXZeng_Extraexam_invdistXperiod Zenghu_all_invdistXperiod Zenghu_all_invdistXperiod Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod  hunanXperiod )  se  bdec(3) rdec(3) nocons append 

*********
ivreghdfe alloff  (martyrs_tot_postXperiod =     hXZeng_Extraexam_invdistXperiod ) hXZeng_exam0_invdistXperiod Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod     lnurbanpopXperiod-Taiping_route1Xperiod     hunanXperiod  , absorb(year samcntyid) cluster(prefid)

outreg2 using Results/Table_6.doc, keep(martyrs_tot_postXperiod  hXZeng_exam0_invdistXperiod hXZeng_Extraexam_invdistXperiod Zenghu_all_invdistXperiod Zenghu_all_invdistXperiod Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod  hunanXperiod)  se  bdec(3) rdec(3) nocons append 

*********
ivreghdfe alloff  (martyrs_tot_postXperiod =   hXZeng_exam0_invdistXperiod)   hXZeng_Extraexam_invdistXperiod  Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod     hunanXperiod  lnurbanpopXperiod-Taiping_route1Xperiod      , absorb(year samcntyid ) cluster(prefid )

outreg2 using Results/Table_6.doc, keep(martyrs_tot_postXperiod  hXZeng_exam0_invdistXperiod hXZeng_Extraexam_invdistXperiod Zenghu_all_invdistXperiod Zenghu_all_invdistXperiod Zeng_exam0_invdistXperiod   Zeng_Extraexam_invdistXperiod  hunanXperiod)  se  bdec(3) rdec(3) nocons append 



