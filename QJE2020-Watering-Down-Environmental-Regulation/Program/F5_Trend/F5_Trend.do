
* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close




***** Figure 5 .Estimates by Year *****
use "$data/graph_by_year",clear

replace b_lower = b-1.83*std_err
replace b_upper = b+1.83*std_err
keep if group ==1

twoway (rspike b_upper b_lower year, lp(dash) lc(red)) ///
	   (scatter b year, sort mc(red)) ///   
	   (line zero year , sort)  , ylabel(-0.8(.4)1.2, labsize(*1)) xlabel(2000(1)2007) ///
	   xline(2002.5, lp(dash_dot)) xline(2005.5, lp(dash)) ///
	   text(1.15 2001 "Scientific Outlook of Development", place(se) box just(left) margin(l+2 t+1 b+1) width(53) bcolor(bluishgray)) ///	   
	   text(-0.45 2004.5 "11th 5-Year Plan", place(se) box just(left) margin(l+2 t+1 b+1) width(28) bcolor(bluishgray)) ///	
	   ytitle("Estimated TFP Effect" " ") title("") yline(0) xtitle("Year") ///
	   legend(order(2 "Estimated Coefficient" 1 "90% CI") pos(6) size(small) symx(medium)) scheme(plotplainblind)
	
	
graph save $figure/F5_by_year, replace
graph export $figure/F5_by_year.png, replace

