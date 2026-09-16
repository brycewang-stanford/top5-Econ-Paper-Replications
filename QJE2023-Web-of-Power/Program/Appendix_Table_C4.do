
*********************************************************************************
************************** Table C.4. The Impact of Elite Networks on Elite Power 
*********************************************************************************


use Data/NationalCntyYr.dta,clear


********************************************************************************
********** gen interactions

gen hXZeng_all0_invdist=hunan*Zeng_all0_invdist


foreach x of varlist hunan  Zeng_all0_invdist hXZeng_all0_invdist{
gen `x'Xperiod=`x'*period

}

foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea  mainriv dist2canal lnrice lnwheat dist_nanjing Taiping_route1 {
gen `x'Xperiod=`x'*period

}


********************************************************************************

keep if year > = 1820


*********
*********
*********
*********
*********

reghdfe alloff    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod  Zeng_all0_invdistXperiod hunanXperiod   , absorb(year  samcntyid ) cluster(prefid )

outreg2 using Results/Appendix_Table_C4.doc, keep( hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod )  se  bdec(3) rdec(3) nocons  replace  



reghdfe alloffd    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod hunanXperiod   , absorb(year  samcntyid ) cluster(prefid )

outreg2 using Results/Appendix_Table_C4.doc, keep( hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod )  se  bdec(3) rdec(3) nocons  append  



reghdfe alloff   lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod Zeng_all0_invdistXperiod hunanXperiod   if alloffd==1, absorb(year samcntyid  ) cluster(prefid )

outreg2 using Results/Appendix_Table_C4.doc, keep( hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod )  se  bdec(3) rdec(3) nocons  append  



*********


reghdfe alloff  lnurbanpop prefcap lnjinshi lncntyquota0  lncntypop lncntyarea mainriv dist2canal lnrice lnwheat  dist_nanjing Taiping_route1   lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod  Zeng_all0_invdist hXZeng_all0_invdist  Zeng_all0_invdistXperiod hunanXperiod  hunan, absorb(year   ) cluster(prefid )

outreg2 using Results/Appendix_Table_C4.doc, keep( hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod )  se  bdec(3) rdec(3) nocons  append  



*********
xi: zinb alloff   i.year  lnurbanpop prefcap lnjinshi lncntyquota0  lncntypop lncntyarea mainriv dist2canal lnrice lnwheat  dist_nanjing Taiping_route1   lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod  Zeng_all0_invdist hXZeng_all0_invdist  Zeng_all0_invdistXperiod hunanXperiod  hunan, inflate( i.year  lnurbanpop prefcap lnjinshi lncntyquota0  lncntypop lncntyarea mainriv dist2canal lnrice lnwheat  dist_nanjing Taiping_route1   lnurbanpopXperiod-Taiping_route1Xperiod   Zeng_all0_invdist hXZeng_all0_invdist   hunanXperiod  hunan)  probit  vce(cluster prefid)

margins , dydx(hXZeng_all0_invdistXperiod Zeng_all0_invdistXperiod)

outreg2 using Results/Appendix_Table_C4.doc, keep( hXZeng_all0_invdistXperiod   Zeng_all0_invdistXperiod )  se  bdec(3) rdec(3) nocons  append  


