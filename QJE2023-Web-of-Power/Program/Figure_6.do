

*********************************************************************************************************
**** Figure 6: The dynamic impacts of elite network on national-level office
*********************************************************************************************************


use Data/NationalCntyYr.dta,clear


********************************************************************************
********** gen interactions


gen nhXZenghu_all_invdist=nonhunan*Zenghu_all_invdist
gen hXZenghu_all_invdist=hunan*Zenghu_all_invdist

gen nhXZeng_all0_invdist=nonhunan*Zeng_all0_invdist
gen hXZeng_all0_invdist=hunan*Zeng_all0_invdist


foreach x of varlist hunan  Zenghu_all_invdist   Zeng_all0_invdist Zeng_all0_invdist_pc  invdist0_L1 invdist0_F1    Zeng_exam0_invdist  Zeng_Extraexam_invdist   Zeng_BMF_invdist    Zeng_juren0_invdist  nhXZenghu_all_invdist nhXZeng_all0_invdist  hXZenghu_all_invdist hXZeng_all0_invdist{
gen `x'Xperiod1=`x'*period1
gen `x'Xperiod2=`x'*period2
gen `x'Xperiod=`x'*period

}


foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea  mainriv dist2canal lnrice lnwheat dist_nanjing Taiping_route1 {
gen `x'Xperiod1=`x'*period1
gen `x'Xperiod2=`x'*period2
gen `x'Xperiod=`x'*period

}

foreach x of varlist  lnurbanpop prefcap lnjinshi lncntyquota0 lncntypop lncntyarea  mainriv dist2canal lnrice lnwheat dist_nanjing  Taiping_route1 {
gen h`x'Xperiod1=hunan*`x'*period1
gen h`x'Xperiod2=hunan*`x'*period2
gen h`x'Xperiod=hunan*`x'*period
}




********************************************************************************
********** gen year dummy & interactions


drop if year==.
tab year, gen(year)


foreach x of varlist year2-year111 {
gen hunanX`x'=hunan*`x'


}

***************************************************************
foreach x of varlist year2-year111 {
gen Zeng_all0_invdistX`x'=Zeng_all0_invdist*`x'
}

********
foreach x of varlist year2-year111 {
gen hXZeng_all0_invdistX`x'=hXZeng_all0_invdist*`x'
}


********
foreach x of varlist year2-year111 {
gen nhXZeng_all0_invdistX`x'=nhXZeng_all0_invdist*`x'
}


***************************************************************
foreach x of varlist year2-year111 {
gen Zenghu_all_invdistX`x'=Zenghu_all_invdist*`x'
}

********
foreach x of varlist year2-year111 {
gen hXZenghu_all_invdistX`x'=hXZenghu_all_invdist*`x'
}


********
foreach x of varlist year2-year111 {
gen nhXZenghu_all_invdistX`x'=nhXZenghu_all_invdist*`x'
}


********************************************************************************


reghdfe alloff   hXZeng_all0_invdistXyear22-hXZeng_all0_invdistXyear111  nhXZeng_all0_invdistXyear22-nhXZeng_all0_invdistXyear111  hunanXyear22-hunanXyear111   lnurbanpopXperiod-Taiping_route1Xperiod   ,  absorb(year samcntyid  ) cluster(prefid )
parmest, saving( Results/ConnectionOnSenior_all0_yearly_01, replace)



reghdfe alloff  hXZeng_all0_invdistXyear22-hXZeng_all0_invdistXyear111  Zeng_all0_invdistXyear22-Zeng_all0_invdistXyear111 hunanXyear22-hunanXyear111  lnurbanpopXperiod-Taiping_route1Xperiod   ,  absorb(year samcntyid ) cluster(prefid )
parmest, saving( Results/ConnectionOnSenior_all0_yearly_02, replace)



preserve

**************
 
use Results/ConnectionOnSenior_all0_yearly_01, clear


gen i=_n
keep if i<=91
gen time=i



gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero


replace time=1820+time
replace time=1820 if time==1911
 

foreach x of varlist estimate   {
replace `x'=0 if  time==1820
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==1820
}


gen year=time 

****
sort time
label var time "Year"

 
sum estimate if year<=1849
gen bench=r(mean)

 
***** 
twoway  (rarea max95 min95 time, lstyle(ci)  msize(tiny) fc(gs12) c(none) lc(gs12))   (connect estimate time, msize(vsmall) lp(solid) lw(medthick) lc(gs7)  xline(1850, lpattern(dash) lcolor(blue))  xline(1853, lpattern(solid) lcolor(blue)) xline(1864, lpattern(dash) lcolor(blue)) ) (line zero time , lp(dash) lw(medthick) lc(gs0) )   /// 
, leg(region(lp(blank)) rows(3))   title("A. Hunan", size(medium) )  xlabel(1820(30)1910) ylabel(-0.2(0.2)0.4)   legend(order(1 "95% CI" 2 "Effects of connections" ) row(2) region(color(none)))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving("Results/AllCnty_hunan_conn_All0_ctrl_0.gph", replace) xsize(3) ysize(3)
 
restore 









*********************************************************************************************************
****  the connection effects in non-Hunan 

preserve

**************
 
use Results/ConnectionOnSenior_all0_yearly_01, clear


gen i=_n
keep if i>=91&i<=181
gen time=i-90


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero


replace time=1820+time
replace time=1820 if time==1911
 

foreach x of varlist estimate   {
replace `x'=0 if  time==1820
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==1820
}



gen year=time 

****
sort time
label var time "Year"

 
sum estimate if year<=1849
gen bench=r(mean)
***** 
twoway  (rarea max95 min95 time, lstyle(ci)  msize(tiny) fc(gs12) c(none) lc(gs12))   (connect estimate time, msize(vsmall) lp(solid) lw(medthick) lc(gs7)  xline(1850, lpattern(dash) lcolor(blue))  xline(1853, lpattern(solid) lcolor(blue)) xline(1864, lpattern(dash) lcolor(blue)) )   (line zero time , lp(dash) lw(medthick) lc(gs0) )   /// 
, leg(region(lp(blank)) rows(3))   title("B. Non-Hunan", size(medium) )  xlabel(1820(30)1910) ylabel(-0.2(0.2)0.4)   legend(order(1 "95% CI" 2 "Effects of connections"  ) row(2) region(color(none)))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving("Results/AllCnty_nhunan_conn_All0_ctrl_0.gph", replace) xsize(3) ysize(3)
 
restore 






*********************************************************************************************************
****  the difference in connection effects, hunan vs. non-hunan 


preserve

**************
 
use Results/ConnectionOnSenior_all0_yearly_02, clear


gen i=_n
keep if i<=91
gen time=i


gen zero=0
label var zero "the effect = 0"
label var estimate "the coefficent of logged total deaths"

keep time max95 min95 time estimate zero


replace time=1820+time
replace time=1820 if time==1911
 

foreach x of varlist estimate   {
replace `x'=0 if  time==1820
}

foreach x of varlist   max95 min95  {
replace `x'=0 if  time==1820
}


gen year=time 

****
sort time
label var time "Year"

 
sum estimate if year<=1849
gen bench=r(mean)

 
***** 
twoway  (rarea max95 min95 time, lstyle(ci)  msize(tiny) fc(gs12) c(none) lc(gs12))   (connect estimate time, msize(vsmall) lp(solid) lw(medthick) lc(gs7)  xline(1850, lpattern(dash) lcolor(blue))  xline(1853, lpattern(solid) lcolor(blue)) xline(1864, lpattern(dash) lcolor(blue)) ) (line zero time , lp(dash) lw(medthick) lc(gs0) )   /// 
, leg(region(lp(blank)) rows(3))   title("C. Difference between Hunan and non-Hunan", size(medium) )  xlabel(1820(30)1910) ylabel(-0.2(0.2)0.4)   legend(order(1 "95% CI" 2 "Effects of connections * Hunan" ) row(2) region(color(none)))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving("Results/AllCnty_hXconn_All0_ctrl_0.gph", replace) xsize(3) ysize(3)
 
restore 





*********************************************************************************************************
************************************************** Yearly effect of connections in Hunan, non-hunan, and the difference 
************************************************** 

graph combine   Results/AllCnty_hunan_conn_All0_ctrl_0.gph Results/AllCnty_nhunan_conn_All0_ctrl_0.gph  Results/AllCnty_hXconn_All0_ctrl_0.gph  , row(1) xsize(9) ysize(4.5) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))

graph export Results/Figure_6.png, replace
