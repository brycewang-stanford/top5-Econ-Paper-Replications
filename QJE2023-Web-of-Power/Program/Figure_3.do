
***************************************************************************************
************************** Figure 3: Motivational Evidence on Elite Networks and Soldier Deaths
****************************************************************************************

use Data/HunanCntyYr.dta,clear

*********************************************************************************

gen connect=(Zeng_all0_invdist>0)

 
**** **** **** 
gen year0=year
tabout year0 connect using Results/Figure_3.txt, replace  cells(mean martyr) format(3)  sum


**** **** **** **** **** **** ******* **** **** **** **** **** ******* **** **** **** **** **** ***
**** **** **** **** **** **** **** graphing: parallel
 
clear
import delimited "Results/Figure_3.txt"
drop in 1/3
drop in 16
destring v1, force gen(year)
destring v2, force gen(NonConnect_martyr)
destring v3, force gen(Connect_martyr)
destring v4, force gen(tot_martyr)

drop v1 v2 v3 v4 
sum
sort year

twoway  connect  Connect_martyr year,  msymbol(O) mc(gs6)  lp(solid) lc(gs6) lw(medthick)  || ///
 connect  NonConnect_martyr year,  legend(order(1 "Connected" 2 "Unconnected") row(2))    ylabel(0(40)120) msymbol(Oh) mc(gs6)   lp(dash) lc(gs6) lw(medthick)     ///
xsize(8) ysize(6) xline(1853, lc(blue) lp(solid)) graphregion( color(white) ifcolor(white) ilcolor(white) fcolor(white))  title("Number of soldier deaths:" "connected & unconnected counties in Hunan", size(median) )  

  
graph export Results/Figure_3.png, replace
 
 