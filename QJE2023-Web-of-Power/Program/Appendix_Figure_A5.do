********************************************************************************
******** Figure A.5. II. Number of National-level Offices and Officials Over Time
********************************************************************************

use Data/OfficialYear.dta,clear

********************************************************************************

use Data/OfficialYear.dta,clear

tsset year

keep if year>=1820
foreach x of varlist tot_ind tot_han_ind tot_senior tot_han_senior {
gen ma5_`x'=(`x'+l.`x'+l2.`x'+l3.`x'+l4.`x')/5
}



twoway (scatter tot_senior year, m(O) msize(small) mc(gs6) xlabel(1820(30)1910)) ///
(line ma5_tot_senior year, lp(solid) lc(gs2) lw(medium ))  ///
(scatter tot_han_senior year, m(Oh) msize(small) mc(gs6)) ///
(line ma5_tot_han_senior year, lp(dash) lc(gs2) lw(medium ) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) xtitle(Year) legend(order(1 "Total number" 2 "5-year moving average"    3 "The Han Chinese" 4 "5-year moving average" ) row(2)) title(A: Number of positions) saving(Results/AllPositions_by_Year, replace)) 

twoway (scatter tot_ind year, m(O) msize(small) mc(gs6) xlabel(1820(30)1910)) ///
(line ma5_tot_ind year, lp(solid) lc(gs2) lw(medium ))  ///
(scatter tot_han_ind year, m(Oh) msize(small) mc(gs6)) ///
(line ma5_tot_han_ind year, lp(dash) lc(gs2) lw(medium ) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) xtitle(Year) legend(order(1 "Total number" 2 "5-year moving average"    3 "The Han Chinese" 4 "5-year moving average" ) row(2))  title(B: Number of officials) saving(Results/AllOfficials_by_Year, replace)) 


graph combine Results/AllPositions_by_Year.gph Results/AllOfficials_by_Year.gph, xsize(9) ysize(4.5) graphregion( color(white) ifcolor(white) ilcolor(white) fcolor(white))
graph export Results/Figure_A5.png, replace 


