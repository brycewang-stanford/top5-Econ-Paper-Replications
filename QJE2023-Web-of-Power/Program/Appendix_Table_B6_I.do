
*This dofile produces Table B6.I column (1)-(3)

************************************************************************************
****** Table B.6. I. What Does the Number of Soldier Deaths Measure?
************************************************************************************


*This part produces Table B6.I column (1)-(3)


use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist invdist0_L1 invdist0_F1 lnarea capital lnurbanpop  lnpop lnhh  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  dist_xiangxiang LangSimilarity{
gen `y'_Post=`y'*Post

}
 
 
********************************************************************************
********************** gen interactions


sum lnhh 
gen ZengXlnhhXPost=Zeng_all0_invdist_Post*(lnhh-r(mean))
gen ZenghuXlnhhXPost=Zenghu_all_invdist_Post*(lnhh-r(mean))


sum lnquotas
gen ZengXlnquotasXPost=Zeng_all0_invdist_Post*(lnquotas_Post-r(mean))


sum lnjinshi
gen ZengXlnjinshiXPost=Zeng_all0_invdist_Post*(lnjinshi-r(mean))

 

**************************

egen  prefidXyear=group(prefid year)


************************************************************************************************
*************************** regression 
 
 
reghdfe   lnmartyr1  capital_Post lnurbanpop_Post lnjinshi_Post  lnquotas_Post  route1_Post   dist_nanjing_Post mainriv_Post dist2canal_Post lnrice_Post lnwheat_Post   lnhh_Post lnarea_Post Zeng_all0_invdist_Post  ZengXlnquotasXPost ZengXlnhhXPost, absorb(year cntyid prefidXyear) cluster(cntyid)
outreg2 using Results/Appendix_Table_B6_I.doc, keep(Zeng_all0_invdist_Post ZengXlnquotasXPost  ZengXlnhhXPost)    se  bdec(3) rdec(3) nocons replace 


***************

reghdfe   lnmartyr1  capital_Post lnurbanpop_Post lnjinshi_Post  lnquotas_Post  route1_Post   dist_nanjing_Post mainriv_Post dist2canal_Post lnrice_Post lnwheat_Post   lnhh_Post lnarea_Post Zeng_all0_invdist_Post   ZengXlnjinshiXPost ZengXlnhhXPost, absorb(year cntyid prefidXyear) cluster(cntyid)
outreg2 using Results/Appendix_Table_B6_I.doc, keep(Zeng_all0_invdist_Post ZengXlnquotasXPost ZengXlnjinshiXPost ZengXlnhhXPost)    se  bdec(3) rdec(3) nocons append 


***************

reghdfe   lnmartyr1  capital_Post lnurbanpop_Post lnjinshi_Post  lnquotas_Post  route1_Post   dist_nanjing_Post mainriv_Post dist2canal_Post lnrice_Post lnwheat_Post   lnhh_Post lnarea_Post Zeng_all0_invdist_Post  ZengXlnquotasXPost ZengXlnjinshiXPost ZengXlnhhXPost, absorb(year cntyid prefidXyear) cluster( cntyid)
outreg2 using Results/Appendix_Table_B6_I.doc, keep(Zeng_all0_invdist_Post ZengXlnquotasXPost ZengXlnjinshiXPost ZengXlnhhXPost)    se  bdec(3) rdec(3) nocons append 
  
 

 
 
 
********************************************************************************
********************************************************************************
********************************************************************************
************************************ This dofile creats Table B.6.I Column (4-5)



use Data/HunanBattleField.dta,clear



********************** ********************** ********************** **********
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


******

gen Zeng_all0_invdist_P=Zeng_all0_invdist*Post

foreach y of varlist  lnarea capital lnurbanpop lnhh  dist_nanjing  lnjinshi lnquotas  mainriv route1  dist2canal lnrice lnwheat {
gen `y'_Post=`y'*Post
}


******

gen cntyXyear=cntyid*100+(year-1850)

egen  prefidXyear=group(prefid year)



******** Table B.6 Column (4): Without Battle FE

reghdfe lnmartyrs_battle1 Zeng_all0_invdist_P ///
capital_Post lnurbanpop_Post lnjinshi_Post  lnquotas_Post  route1_Post   dist_nanjing_Post mainriv_Post dist2canal_Post lnrice_Post lnwheat_Post  lnhh_Post lnarea_Post ///
, absorb(cntyid year prefidXyear) cluster(cntyid)

outreg2 using Results/Appendix_Table_B6_I.doc, keep(Zeng_all0_invdist_P)  se  bdec(3) rdec(3) nocons append
 

********* Table B.6 Column (5): With Battle FE

reghdfe lnmartyrs_battle1 Zeng_all0_invdist_P ///
capital_Post lnurbanpop_Post lnjinshi_Post  lnquotas_Post  route1_Post  dist_nanjing_Post mainriv_Post  dist2canal_Post lnrice_Post lnwheat_Post   lnhh_Post lnarea_Post ///
, absorb(battleid  cntyid year prefidXyear) cluster(cntyid )

outreg2 using Results/Appendix_Table_B6_I.doc, keep(Zeng_all0_invdist_P)  se  bdec(3) rdec(3) nocons append


 
 
 
 
 
 
 
