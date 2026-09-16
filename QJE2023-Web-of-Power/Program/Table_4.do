

************************************************************************************************
******************************** Table 4: Placebo tests: change the year of exam_column(1)-(6)
************************************************************************************************

use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864



foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist invdist0_L1 invdist0_F1 lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  {
gen `y'_Post=`y'*Post

}

**************************

egen  prefidXyear=group(prefid year)


************************************* Change the year of exam

reghdfe   lnmartyr1 Zeng_exam0_invdist_Post invdist0_L1_Post    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    if cntyid!=25 , absorb(year cntyid prefidXyear) cluster(cntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons replace 


reghdfe   lnmartyr1  Zeng_exam0_invdist_Post invdist0_F1_Post     capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    if cntyid!=25 , absorb(year cntyid prefidXyear) cluster(  cntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons append


reghdfe   lnmartyr1 Zeng_exam0_invdist_Post invdist0_L1_Post  invdist0_F1_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    if cntyid!=25 , absorb(year cntyid prefidXyear) cluster( cntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons append




************************************* IV estimates


 
ivreghdfe lnmartyr1   (Zeng_all0_invdist_Post=Zeng_exam0_invdist_Post) invdist0_L1_Post     capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  if cntyid!=25 ,  absorb(year cntyid  prefidXyear) cluster(  cntyid)
 outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons append

 
ivreghdfe  lnmartyr1   (Zeng_all0_invdist_Post=Zeng_exam0_invdist_Post)   invdist0_F1_Post  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  if cntyid!=25 ,  absorb(year cntyid  prefidXyear) cluster(  cntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons append

 
ivreghdfe  lnmartyr1   (Zeng_all0_invdist_Post=Zeng_exam0_invdist_Post)  invdist0_L1_Post   invdist0_F1_Post capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  if cntyid!=25 ,  absorb(year cntyid  prefidXyear) cluster(cntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post Zeng_exam0_invdist_Post invdist0_L1_Post invdist0_F1_Post)    se  bdec(3) rdec(3) nocons append








************************************************************************************************
************************************************************************************************
******************************** Table 4: Placebo tests: change the year of exam_column(7)-(11)
************************************************************************************************
************************************************************************************************


use Data/HuaiYr.dta,clear



****************************


gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


*********
foreach y of varlist  Zeng_all0_invdist   Zeng_exam0_invdist invdist0_L1 invdist0_F1  lncntyarea lncntypop    lnrice lnwheat  mainriv dist2canal   prefcap     lnurbanpop   lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1 {
gen `y'_Post=`y'*Post
}
 
  

********************* Table 4, columns (7)-(11)

xi: reghdfe  lnmartyr_yr  prefcap_Post  lnurbanpop_Post  lnjinshi_Post  lncntyquota0_Post  Taiping_route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post    lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post  Zeng_all0_invdist_Post , absorb(year samcntyid   prefidXyear)  cluster(  samcntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post)   se  bdec(3) rdec(3) nocons append 


xi: reghdfe  lnmartyr_yr  prefcap_Post  lnurbanpop_Post  lnjinshi_Post  lncntyquota0_Post  Taiping_route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post    lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post  Zeng_exam0_invdist_Post , absorb(year samcntyid   prefidXyear)  cluster(  samcntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_exam0_invdist_Post)   se  bdec(3) rdec(3) nocons append   


xi: reghdfe  lnmartyr_yr  prefcap_Post  lnurbanpop_Post  lnjinshi_Post  lncntyquota0_Post  Taiping_route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post    lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post  Zeng_exam0_invdist_Post invdist0_L1_Post, absorb(year samcntyid   prefidXyear)  cluster(  samcntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post  Zeng_exam0_invdist_Post invdist0_L1_Post )   se  bdec(3) rdec(3) nocons append  


xi: reghdfe  lnmartyr_yr  prefcap_Post  lnurbanpop_Post  lnjinshi_Post  lncntyquota0_Post  Taiping_route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post    lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post  Zeng_exam0_invdist_Post  invdist0_F1_Post , absorb(year samcntyid   prefidXyear)  cluster(  samcntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_all0_invdist_Post  Zeng_exam0_invdist_Post invdist0_F1_Post)   se  bdec(3) rdec(3) nocons append  


xi: reghdfe  lnmartyr_yr  prefcap_Post  lnurbanpop_Post  lnjinshi_Post  lncntyquota0_Post  Taiping_route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post    lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post Zeng_exam0_invdist_Post invdist0_L1_Post  invdist0_F1_Post , absorb(year samcntyid   prefidXyear)  cluster(  samcntyid)
outreg2 using Results/Table_4.doc, keep(Zeng_exam0_invdist_Post  Zeng_exam0_invdist_Post invdist0_L1_Post  invdist0_F1_Post)   se  bdec(3) rdec(3) nocons append  
















