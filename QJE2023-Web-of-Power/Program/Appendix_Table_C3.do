
*********************************************************************************
**** Table C.3. The Impact of Elite Networks on Exam Quotas and Numbers of Jinshi
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

keep if year > =1820



*******
 
reghdfe lncntyquota_panel    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod if year==1840|year==1880 , absorb(year samcntyid ) cluster(prefid )
outreg2 using Results/Appendix_Table_C3.doc, keep( hXZeng_all0_invdistXperiod  )  se  bdec(3) rdec(3) nocons replace


*******

reghdfe lnjinshi_panel    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod if year==1840|year==1880, absorb(year samcntyid ) cluster(prefid )
outreg2 using Results/Appendix_Table_C3.doc, keep( hXZeng_all0_invdistXperiod  )  se  bdec(3) rdec(3) nocons  append  


*******

reghdfe alloff   lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod, absorb(year samcntyid ) cluster(prefid   )
outreg2 using Results/Appendix_Table_C3.doc, keep( hXZeng_all0_invdistXperiod  )  se  bdec(3) rdec(3) nocons  append   


*******

reghdfe alloff  lnjinshi_panel lncntyquota_panel    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod  , absorb(year samcntyid ) cluster(prefid )
outreg2 using Results/Appendix_Table_C3.doc, keep( hXZeng_all0_invdistXperiod    lnjinshi_panel lncntyquota_panel)  se  bdec(3) rdec(3) nocons append  


*******

gen lncntyquotaXperiod=lncntyquota*period
gen lnjinshi_aft50Xperiod=lnjinshi_aft50*period

reghdfe alloff  lnjinshi_aft50Xperiod lncntyquotaXperiod    lnurbanpopXperiod-Taiping_route1Xperiod  hXZeng_all0_invdistXperiod    Zeng_all0_invdistXperiod hunanXperiod  , absorb(year samcntyid ) cluster(prefid )
outreg2 using Results/Appendix_Table_C3.doc, keep( hXZeng_all0_invdistXperiod    lnjinshi_aft50Xperiod lncntyquotaXperiod)  se  bdec(3) rdec(3) nocons append  




