
********************************************************************************
***** Table 3: The Impact of Elite Connections on Soldier Deaths: Types of Links 
***** Sample: Hunan counties, 1850–1864
********************************************************************************
 
 
**This part produces Table 3 column (1)-(4)
 

use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864



foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice {
gen `y'_Post=`y'*Post

}

**************************

egen  prefidXyear=group(prefid year)


 
********************************************* Types of networks with Pref X Year FE


reghdfe  lnmartyr1  Zenghu_all_invdist_Post  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   , absorb(year cntyid  prefidXyear)  cluster(cntyid)
outreg2 using Results/Table_3.doc, keep(Zenghu_all_invdist_Post Zeng_BMF_invdist_Post Zeng_Juren_invdist_Post Zeng_exam0_invdist_Post)    se  bdec(3) rdec(3) nocons replace


********
reghdfe  lnmartyr1    Zeng_BMF_invdist_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    , absorb(year cntyid  prefidXyear)  cluster( cntyid)
outreg2 using Results/Table_3.doc, keep( Zenghu_all_invdist_Post Zeng_BMF_invdist_Post Zeng_Juren_invdist_Post Zeng_exam0_invdist_Post)    se  bdec(3) rdec(3) nocons append 


********
reghdfe  lnmartyr1     Zeng_Juren_invdist_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post    , absorb(year cntyid  prefidXyear)  cluster( cntyid)
outreg2 using Results/Table_3.doc, keep( Zenghu_all_invdist_Post Zeng_BMF_invdist_Post Zeng_Juren_invdist_Post Zeng_exam0_invdist_Post)    se  bdec(3) rdec(3) nocons append 


********
reghdfe  lnmartyr1     Zeng_exam0_invdist_Post   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     , absorb(year cntyid  prefidXyear)  cluster( cntyid)
outreg2 using Results/Table_3.doc, keep( Zenghu_all_invdist_Post Zeng_BMF_invdist_Post Zeng_Juren_invdist_Post Zeng_exam0_invdist_Post)    se  bdec(3) rdec(3) nocons append 








********************************************************************************
********************************************************************************
********************************************************************************
******************************* This part produces Table 3 column (5)-(7)


use Data/HunanSurname.dta,clear


 
********************** ********************** ********************** **********
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864

**
foreach y of varlist  sur_invdis_zeng_all0  capital  lnurbanpop  lnjinshi  lnquotas route1  dist_nanjing mainriv dist2canal  lnwheat lnrice  lnarea  lnhh  {
gen `y'_Post=`y'*Post
}



***************************************** gen FE effect


*****

egen  prefXyear=group(prefid year)

gen cntyXyear=cntyid*100+(year-1850)
gen surXyear=surname_id*100+(year-1850)
gen cntyXsur=cntyid*1000+surname_id


**************************************** gen subsample when either connected surname or martyr surname does not equal to 0

sort cntyXsur
by cntyXsur: egen mean_sur_invdis_zeng_all0=mean(sur_invdis_zeng_all0)
by cntyXsur: egen mean_martyr_surname=mean(martyr_surname)

gen subsample=(mean_sur_invdis_zeng_all0!=0|mean_martyr_surname!=0)
gen subsample_network=(mean_sur_invdis_zeng_all0!=0)
gen subsample_martyr=(mean_martyr_surname!=0)



*************************************** gen diff.-Surname baseline connections
sort cntyid year
by cntyid year: egen sum_sur_invdis_zeng_all0=sum(sur_invdis_zeng_all0)
gen oth_sur_invdis_zeng_all0=sum_sur_invdis_zeng_all0-sur_invdis_zeng_all0

gen oth_sur_invdis_zeng_all0_Post=oth_sur_invdis_zeng_all0*Post


*****************************************
***************************************** Regressions


reghdfe  lnmartyr_surname1 sur_invdis_zeng_all0_Post ///
lnjinshi_Post lnquotas_Post capital_Post  lnurbanpop_Post route1_Post dist_nanjing_Post mainriv_Post lnhh_Post lnarea_Post  lnwheat_Post lnrice_Post dist2canal_Post if subsample==1, ///
absorb(prefXyear surXyear cntyXsur cntyid year  ) cluster(cntyid surname_id)
outreg2 using Results/Table_3.doc, keep(sur_invdis_zeng_all0_Post)   se  bdec(3) rdec(3) nocons append


reghdfe  lnmartyr_surname1 sur_invdis_zeng_all0_Post oth_sur_invdis_zeng_all0_Post  ///
lnjinshi_Post lnquotas_Post capital_Post  lnurbanpop_Post route1_Post dist_nanjing_Post mainriv_Post  lnhh_Post lnarea_Post lnwheat_Post lnrice_Post dist2canal_Post if subsample==1, ///
absorb(prefXyear surXyear cntyXsur cntyid year  ) cluster(cntyid surname_id)
outreg2 using Results/Table_3.doc, keep(sur_invdis_zeng_all0_Post oth_sur_invdis_zeng_all0_Post)   se  bdec(3) rdec(3) nocons append


reghdfe  lnmartyr_surname1 sur_invdis_zeng_all0_Post if subsample==1, ///
absorb(cntyXyear surXyear cntyXsur cntyid year) cluster(cntyid surname_id)
outreg2 using Results/Table_3.doc, keep(sur_invdis_zeng_all0_Post)   se  bdec(3) rdec(3) nocons append




