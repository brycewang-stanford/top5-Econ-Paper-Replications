
*********************************************************************************
*** Figure 4: The Impact of Elite Connections on Soldier Deaths: Year-by-Year Estimates
*********************************************************************************


use Data/HunanCntyYr.dta,clear


********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864



foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice  {
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

outreg2 using Results/Placebo_Yearly_ctrl_all0_invdist.doc, keep(Zeng_all0_invdist_yr* )   se  bdec(3) rdec(3) nocons replace 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_invdist, replace)



*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** unweighted

xi: reghdfe  lnmartyr1 Zeng_all0_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     , absorb(year cntyid  prefidXyear)   cluster( cntyid)

outreg2 using Results/Placebo_Yearly_ctrl_all0_invdist.doc, keep(Zeng_all0_yr* )   se  bdec(3) rdec(3) nocons append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0, replace)


*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** per capita weighted

xi: reghdfe  lnmartyr1 Zeng_all0_invdist_pc_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post      , absorb(year cntyid  prefidXyear)   cluster( cntyid)

outreg2 using Results/Placebo_Yearly_ctrl_all0_invdist.doc, keep(Zeng_all0_invdist_pc_yr* )   se  bdec(3) rdec(3) nocons append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_invdist_pc, replace)



*** *** *** *** *** *** *** *** *** *** *** 
*** *** *** *** *** *** *** *** *** *** *** per capita unweighted


xi: reghdfe  lnmartyr1 Zeng_all0_pc_yr*    capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     , absorb(year cntyid  prefidXyear)   cluster(cntyid)

outreg2 using Results/Placebo_Yearly_ctrl_all0_invdist.doc, keep(Zeng_all0_pc_yr* )   se  bdec(3) rdec(3) nocons append 
parmest, saving( Results/Placebo_Yearly_ctrl_all0_pc, replace)




********************************* Graphing
*********************************
*********************************
preserve
use Results/Placebo_Yearly_ctrl_all0_invdist, clear


gen i=_n
keep if i<=15
gen time=i


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero



replace time=time+1 if time>3
replace time=4 if time==16

foreach x of varlist estimate   {
replace `x'=0 if  time==4
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==4
}

replace time=1849+time


****
sort time
label var time "Year"
 

twoway (rcap max95 min95 time, ylabel(-0.25(0.25)0.5) lstyle(ci)  xtitle(" ") )   ///
  (connect estimate time, lp(solid) lc(black) lw(medthick) xline(1853, lpattern(solid) lcolor(blue) lw(medthick)) xsize(6) ysize(6)) ///
       (scatter estimate time, mstyle(p1)  yline(0, lpattern(solid) lcolor(red))  ///
	   legend(off) xlabel(1850(5)1865) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))  saving(Results/Yearly1_All0_invdist, replace) title(A. Weighted connections, size(medsmall)))
   
   
restore




*********************************
preserve
use Results/Placebo_Yearly_ctrl_all0, clear


gen i=_n
keep if i<=15
gen time=i


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero



replace time=time+1 if time>3
replace time=4 if time==16

foreach x of varlist estimate   {
replace `x'=0 if  time==4
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==4
}

replace time=1849+time


****
sort time
label var time "Year"
 

twoway (rcap max95 min95 time, ylabel(-0.25(0.25)0.5) lstyle(ci)  xtitle(" ") )   ///
  (connect estimate time, lp(solid) lc(black) lw(medthick) xline(1853, lpattern(solid) lcolor(blue) lw(medthick)) xsize(6) ysize(6)) ///
       (scatter estimate time, mstyle(p1)  yline(0, lpattern(solid) lcolor(red))  ///
	    legend(off) xlabel(1850(5)1865) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))  saving(Results/Yearly1_All0, replace) title(B. Unweighted connections, size(medsmall)))
   
   
restore




*********************************
preserve
use Results/Placebo_Yearly_ctrl_all0_invdist_pc, clear


gen i=_n
keep if i<=15
gen time=i


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero



replace time=time+1 if time>3
replace time=4 if time==16

foreach x of varlist estimate   {
replace `x'=0 if  time==4
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==4
}

replace time=1849+time


****
sort time
label var time "Year"
 
 
twoway (rcap max95 min95 time, ylabel(-0.08(0.08)0.16) lstyle(ci)  xtitle(" ") )   ///
  (connect estimate time, lp(solid) lc(black) lw(medthick) xline(1853, lpattern(solid) lcolor(blue) lw(medthick)) xsize(6) ysize(6)) ///
       (scatter estimate time, mstyle(p1)  yline(0, lpattern(solid) lcolor(red))  ///
	   legend(order(2 "Effects of elite connections")  size(small) row(1) region(color(none)))  xlabel(1850(5)1865) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))  saving(Results/Yearly1_All0_invdist_pc, replace) title(C. Weighted connections per capita, size(medsmall)))
	   
restore




*********************************
preserve
use Results/Placebo_Yearly_ctrl_all0_pc, clear


gen i=_n
keep if i<=15
gen time=i


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero



replace time=time+1 if time>3
replace time=4 if time==16

foreach x of varlist estimate   {
replace `x'=0 if  time==4
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==4
}

replace time=1849+time


****
sort time
label var time "Year"
 
 
  
twoway (rcap max95 min95 time, ylabel(-0.08(0.08)0.16) lstyle(ci)  xtitle(" ") )   ///
  (connect estimate time, lp(solid) lc(black) lw(medthick)  xline(1853, lpattern(solid) lcolor(blue) lw(medthick)) xsize(6) ysize(6)) ///
       (scatter estimate time, mstyle(p1)  yline(0, lpattern(solid) lcolor(red))  ///
	   legend(order(1 "95% CI")  size(small) row(1) region(color(none)))  xlabel(1850(5)1865) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))  saving(Results/Yearly1_All0_pc, replace) title(D. Unweighted connections per capita, size(medsmall)))
   
   
restore


gr combine Results/Yearly1_All0_invdist.gph  Results/Yearly1_All0.gph Results/Yearly1_All0_invdist_pc.gph  Results/Yearly1_All0_pc.gph  , row(2)  ysize(18) xsize(15)  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))
graph export Results/Figure_4.png, replace

