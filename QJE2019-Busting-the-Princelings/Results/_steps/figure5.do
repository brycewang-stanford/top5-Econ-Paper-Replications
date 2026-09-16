*Figure 5*
use "$DATA/price.dta", replace

tab year, gen(t)
forvalue x=1/13 {
gen pt`x'=princeling*t`x'
}
label var pt3 "2006"
label var pt4 "2007"
label var pt5 "2008"
label var pt6 "2009"
label var pt7 "2010"
label var pt8 "2011"
label var pt9 "2012"
label var pt10 "2013"
label var pt11 "2014"
label var pt12 "2015"
label var pt13 "2016"

eststo: xi: reghdfe lnprice pt3-pt13, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
 
coefplot, drop(_con) recast(connected) vertical ciopts(recast(rcap)lcol(black))  /// 
   lpattern(solild) mcolor(black) lcolor(black black) lwidth(thin thin) yline(0, lcol(black)) ///
   graphregion(color(white)) ylabel(-1.2(0.2)0.2) legend(label(1 "Coefficient/95% Confidence Interval")) ///
   ytitle("Price Differences between Princeling vs. Non-Princeling" "Land Transactions")
graph save Graph "$FIG/figure5.gph", replace


