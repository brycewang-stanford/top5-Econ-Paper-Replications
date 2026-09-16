
***************************************************************************************
************************** Table 2： The Impact of Elite Connections on Soldier Deaths: DD Estimates 
************************** Sample: Hunan counties, 1850--1864
****************************************************************************************

use Data/HunanCntyYr.dta,clear

********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  {
gen `y'_Post=`y'*Post

}


********************************************************************************
********************** regression


xi: reghdfe  lnmartyr1  Zeng_all0_invdist_Post , absorb(year cntyid )  cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace
 
  
xi: reghdfe  lnmartyr1   lnurbanpop_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append

 

xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post  mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append
 

xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append
 


*** *** *** *** *** ***
*** *** *** *** *** ***

xi: reghdfe  lnmartyr1   Zeng_all0_invdist_pc_Post , absorb(year cntyid)  cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_pc_Post )  se  bdec(3) rdec(3) nocons append
 
xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_invdist_pc_Post , absorb(year cntyid )  cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_pc_Post )  se  bdec(3) rdec(3) nocons append
 


*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** 
*** *** *** 
xi: reghdfe  lnmartyr1     Zeng_all0_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append
 
 **** *** *** 
xi: reghdfe  lnmartyr1    capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_Post , absorb(year cntyid )  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append


*** *** *** 
xi: reghdfe  lnmartyr1  Zeng_all0_pc_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

 
xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_pc_Post , absorb(year cntyid  )  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append





/*
********** The same results using xtreg  


xtreg  lnmartyr1 i.year  Zeng_all0_invdist_Post , fe  cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace
 
  
xtreg  lnmartyr1 i.year   lnurbanpop_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , fe   cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append

 

xtreg  lnmartyr1 i.year  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post  mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , fe   cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append
 

xtreg  lnmartyr1 i.year  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , fe   cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append
 


*** *** *** *** *** ***
*** *** *** *** *** ***

xtreg  lnmartyr1 i.year   Zeng_all0_invdist_pc_Post , fe   cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_pc_Post )  se  bdec(3) rdec(3) nocons append
 
xtreg  lnmartyr1 i.year  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_invdist_pc_Post , fe   cluster( cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_invdist_pc_Post )  se  bdec(3) rdec(3) nocons append
 


*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** 
*** *** *** 
xtreg  lnmartyr1 i.year     Zeng_all0_Post , fe   cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append
 
 **** *** *** 
xtreg  lnmartyr1 i.year    capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_Post , fe  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append


*** *** *** 
xtreg  lnmartyr1 i.year    Zeng_all0_pc_Post , fe   cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

 
xtreg  lnmartyr1 i.year    capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_pc_Post , fe  cluster(  cntyid)
outreg2 using Results/Table_2.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

*/













