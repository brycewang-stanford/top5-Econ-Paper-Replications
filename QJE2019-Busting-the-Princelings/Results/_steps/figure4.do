*Figure 4*
use "$DATA/figure4.dta", clear
gen l45=lnprice

twoway (scatter lnpricenear500 lnprice, col(gray) msize(vsmall)) (line l45 lnprice, lcol(black) lwidth(thin)  lpattern(dash)), ///
   graphregion(color(white)) xsize(4) ///
   ytitle("Average Land Price within 500-Meters Radius") ///
   legend(size(small) label(1 "Princeling Land Price") label(2 "45 Degree Line"))
graph save Graph "$FIG/figure4.gph", replace


