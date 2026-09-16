
*********************************************************************************
*** Table B.2. Yearly Effects of Elite Connections
*********************************************************************************


use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864



foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice {
gen `y'_Post=`y'*Post

}


********************** ********************** ********************** **********************
********************** gen year dummies


tab year, gen(year)
local r=1 
while `r'<16 {
local s=`r'+1849
rename year`r' yr`s'
local r=`r'+1
}

**
foreach y of varlist    Zeng_all0_invdist Zeng_all0 Zeng_all0_invdist_pc Zeng_all0_pc{
foreach x of varlist yr1850-yr1852 yr1854-yr1864 {
gen `y'_`x'=`y'*`x'
}
}


**************************

egen  prefidXyear=group(prefid year)


*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** Weighted


xi: reghdfe  lnmartyr1 Zeng_all0_invdist_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post      , absorb(year cntyid  prefidXyear)   cluster( cntyid)

outreg2 using Results/Appendix_Table_B2.doc, keep(Zeng_all0_invdist_yr* )   se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  replace 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_invdist, replace)



*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** unweighted

xi: reghdfe  lnmartyr1 Zeng_all0_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     , absorb(year cntyid  prefidXyear)   cluster( cntyid)

outreg2 using Results/Appendix_Table_B2.doc, keep(Zeng_all0_yr* )   se  bdec(3) rdec(3) nocons  addtext(Observations, `e(N_full)') noobs append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0, replace)


*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** per capita weighted

xi: reghdfe  lnmartyr1 Zeng_all0_invdist_pc_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post      , absorb(year cntyid  prefidXyear)   cluster( cntyid)

outreg2 using Results/Appendix_Table_B2.doc, keep(Zeng_all0_invdist_pc_yr* )   se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_invdist_pc, replace)



*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** per capita unweighted


xi: reghdfe  lnmartyr1 Zeng_all0_pc_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     , absorb(year cntyid  prefidXyear)   cluster(cntyid)

outreg2 using Results/Appendix_Table_B2.doc, keep(Zeng_all0_pc_yr* )   se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_pc, replace)

