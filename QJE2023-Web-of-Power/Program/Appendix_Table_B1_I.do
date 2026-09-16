
***************************************************************************************
************************** Table B.1. I. The Impact of Elite Connections on Soldier Deaths
************************** Checking Outliers
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


xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_I.doc, keep(Zeng_all0_invdist_Post )  se  bdec(3) rdec(3) nocons replace 

xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post if Zeng_all0_invdist<=10, absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_I.doc, keep(Zeng_all0_invdist_Post )  se  bdec(3) rdec(3) nocons append


xi: reghdfe  lnmartyr1  capital_Post  lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post  if Zeng_all0_invdist<=3, absorb(year cntyid)  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B1_I.doc, keep(Zeng_all0_invdist_Post )  se  bdec(3) rdec(3) nocons append



