
*********************************************************************************************************
***************** Figure 5: Motivational Evidence for the Power Effect
*********************************************************************************************************

use Data/NationalCntyYr.dta,clear


********************************************************************************

gen connect=(Zenghu_all_invdist>0)
gen death=(martyrs_tot_post>0)

table hunan connect
gen hunanXconnect=1
replace hunanXconnect=4 if hunan==1&connect==1
replace hunanXconnect=3 if hunan==0&connect==1
replace hunanXconnect=2 if hunan==1&connect==0
table year hunanXconnect

keep if year>=1820

****************************************************************************************  
preserve
tabout year hunanXconnect using Results/Official_HunanXconn_1800_1910.txt, replace  cells(mean alloff) format(3)  sum

clear
import delimited "Results/Official_HunanXconn_1800_1910.txt"
drop in 1/3
drop in 92
sum
destring v1, force gen(year)
destring v2, force gen(UnXnonHunan)
destring v3, force gen(UnXHunan)
destring v4, force gen(ConnXnonHunan)
destring v5, force gen(ConnXHunan)



drop v1 v2 v3 v4 v5 v6
sort year

twoway (connect ConnXHunan  year, m(O) msize(vsmall) mc(gs6) lp(solid) lc(gs6) ylabel(0(0.2)0.8) ) ///
(connect ConnXnonHunan  year, m(Oh) msize(vsmall) mc(gs6) lp(dash) lc(gs6)   ) ///
(line UnXHunan year,  lp(solid) lc(gs6) xlabel(1820(10)1910) )  ///
 (line UnXnonHunan year,  lp(dash) lc(gs6) xsize(8) ysize(6) xline(1850, lc(blue) lp(dash))  xline(1853, lc(blue) lp(solid))   xline(1864, lc(blue) lp(dash))   graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) xtitle(Year) ytitle(Number of natioinal-offices) legend(order(1 "Connected, Hunan (38)" 2 "Connected, non-Hunan (670)" 3 "Unconnected, Hunan (37)" 4 "Unconnected, non-Hunan (901)") row(2) size(small)) title("Number of national-offices" "Connected & unconnected counties in Hunan and non-Hunan", size(median)) )

 
graph export Results/Figure_5.png, replace 
 


