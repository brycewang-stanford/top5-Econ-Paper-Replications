
***************************************************************************************
************************** Tab B.1. II. The impact of elite connections on soldier deaths
************************** sine transformation
****************************************************************************************

use Data/HunanCntyYr.dta,clear

********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop   dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  {
gen `y'_Post=`y'*Post

}


********************************************************************************
********************** regression

xi: reghdfe  lnmartyr_sine  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_II.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace 
 

 
xi: reghdfe  lnmartyr_sine  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_invdist_pc_Post , absorb(year cntyid )  cluster( cntyid)
outreg2 using Results/Appendix_Table_B1_II.doc, keep(Zeng_all0_invdist_pc_Post )  se  bdec(3) rdec(3) nocons append
 

 
 **** *** *** 
xi: reghdfe  lnmartyr_sine    capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_Post , absorb(year cntyid )  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_II.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append


*** *** ***  
 
xi: reghdfe  lnmartyr_sine  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_pc_Post , absorb(year cntyid  )  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_II.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

