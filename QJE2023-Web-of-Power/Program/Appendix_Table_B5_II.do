
 
************************************************************************************
****** Table B.5. II. The Impact of Elite Connections on Soldier Deaths: Degree-Holders vs. Commoners
************************************************************************************


use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist invdist0_L1 invdist0_F1 lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  dist_xiangxiang LangSimilarity{
gen `y'_Post=`y'*Post

}
 

**************************

egen  prefidXyear=group(prefid year)


************************************************************************************************
*************************** regression

reghdfe  std_lnmartyr1  Zeng_all0_invdist_Post  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post      ,  absorb(year cntyid prefidXyear)  cluster( cntyid)
outreg2 using Results/Appendix_Table_B5_II.doc, keep( Zeng_all0_invdist_Post )   se  bdec(3) rdec(3) nocons replace  

reghdfe   std_lnmartyr1  Zeng_all0_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     ,  absorb(year cntyid  prefidXyear)  cluster( cntyid)
outreg2 using Results/Appendix_Table_B5_II.doc, keep( Zeng_all0_Post )   se  bdec(3) rdec(3) nocons append  

 
*****
reghdfe   std_lnGentryDeath1   Zeng_all0_invdist_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    ,  absorb(year cntyid  prefidXyear)  cluster( cntyid)
outreg2 using Results/Appendix_Table_B5_II.doc, keep( Zeng_all0_invdist_Post )   se  bdec(3) rdec(3) nocons append 

reghdfe  std_lnGentryDeath1   Zeng_all0_Post  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post      ,  absorb(year cntyid   prefidXyear)  cluster(cntyid)
outreg2 using Results/Appendix_Table_B5_II.doc, keep( Zeng_all0_Post )   se  bdec(3) rdec(3) nocons append 

 
 