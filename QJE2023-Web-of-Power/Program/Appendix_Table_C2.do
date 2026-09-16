
*********************************************************************************
* Table C.2. The Impact of Elite Networks on Elite Power: Inside and Outside the Network
*********************************************************************************


use Data/NationalCntyYr.dta,clear



********************************************************************************
********** gen interactions


gen nhXZenghu_all_invdist=nonhunan*Zenghu_all_invdist
gen hXZenghu_all_invdist=hunan*Zenghu_all_invdist

gen nhXZeng_all0_invdist=nonhunan*Zeng_all0_invdist
gen hXZeng_all0_invdist=hunan*Zeng_all0_invdist


foreach x of varlist hunan  Zenghu_all_invdist   Zeng_all0_invdist Zeng_all0_invdist_pc  invdist0_L1 invdist0_F1    Zeng_exam0_invdist  Zeng_Extraexam_invdist   Zeng_BMF_invdist    Zeng_juren0_invdist  nhXZenghu_all_invdist nhXZeng_all0_invdist  hXZenghu_all_invdist hXZeng_all0_invdist{
gen `x'Xperiod=`x'*period

}


foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea mainriv dist2canal lnrice lnwheat dist_nanjing Taiping_route1 {
gen `x'Xperiod=`x'*period

}
foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea mainriv dist2canal lnrice lnwheat dist_nanjing  Taiping_route1 {
gen h`x'Xperiod=hunan*`x'*period
}



********************************************************************************

keep if year>=1820

foreach x of varlist alloff ZengConnected NotZengConnected entry reentry {
sum `x'
gen `x'_byavg=`x'/r(mean)
}



********************************************************************************


********* 


reghdfe alloff_byavg        lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid ) cluster(prefid  )
outreg2 using Results/Appendix_Table_C2.doc, keep( hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons replace 


 
*********
reghdfe ZengConnected_byavg       lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid ) cluster(prefid )
outreg2 using Results/Appendix_Table_C2.doc, keep( hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons append 

 
*********

reghdfe NotZengConnected_byavg       lnurbanpopXperiod-Taiping_route1Xperiod   hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid) cluster(prefid  )
outreg2 using Results/Appendix_Table_C2.doc, keep( hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod)  se  bdec(3) rdec(3) nocons append











