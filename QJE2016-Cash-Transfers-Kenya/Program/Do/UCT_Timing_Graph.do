clear all
set more off 
set maxvar 12000
use "$data_dir/UCT_FINAL_CLEAN.dta", clear
drop if purecontrol

*** HISTORGRAM OF SURVEYS AND TRANSFERS BY MONTH ***

gen baseline_month = mofd(baselinedate)
format baseline_month %tm
gen endline_month = mofd(endlinedate)
format endline_month %tm
replace firsttransferdate = mofd(firsttransferdate)
replace lasttransferdate = mofd(lasttransferdate)
format firsttransferdate %tm
format lasttransferdate %tm

gen mean_month = mofd(mean_date)
format mean_month %tm
sum mean_month
local mea = r(mean)
gen median_month = mofd(median_date)
format median_month %tm
sum median_month
local med = r(mean)

twoway (hist baseline_month, percent width(.1) color(blue) legend(label(1 "baseline month"))) (hist firsttransferdate, percent width(.1) color(yellow)  legend(label(2 "first transfer"))) (hist lasttransferdate if ~purecontrol, percent width(.1) color(green) legend(label(3 "last transfer"))) (hist endline_month, percent width(.1) color(red) legend(label(4 "endline month"))), graphregion(fcolor(white) lcolor(white)) xline(`mea', lsty(foreground) lp(dash) lc(black) lw(medthick)) xline(`med', lsty(foreground) lp(solid) lc(black) lw(medthick)) ytitle("Pct of Households")

graph export "$figs_dir/individual_timing_histogram.eps", replace


*** HISTORGRAM OF ELAPSED TIME ***
preserve
drop if spillover

//Dbasefirst Dbaselast Dbasemed Dbasemean Dbaseend Dfirstlast Dfirstend Dmedend Dmeanend Dlastend
global histopts "nodraw graphregion(fcolor(white) lcolor(white)) xtitle("") percent"
hist Dbasefirst, saving("$figs_dir/timing_basefirst.gph", replace) title("Months from Baseline to First Transfer", size(medium)) $histopts
hist Dbasemed, saving("$figs_dir/timing_basemed.gph", replace) title("Months from Baseline to Median Transfer", size(medium)) $histopts
hist Dbasemean, saving("$figs_dir/timing_basemean.gph", replace) title("Months from Baseline to Mean Transfer", size(medium)) $histopts
hist Dbaselast, saving("$figs_dir/timing_baselast.gph", replace) title("Months from Baseline to Last Transfer", size(medium)) $histopts
hist Dbaseend, saving("$figs_dir/timing_baseend.gph", replace) title("Months from Baseline to Endline", size(medium)) $histopts
hist Dfirstlast, saving("$figs_dir/timing_firstlast.gph", replace) title("Months from First to Last Transfer", size(medium)) $histopts
hist Dfirstend, saving("$figs_dir/timing_firstend.gph", replace) title("Months from First Transfer to Endline", size(medium)) $histopts
hist Dmeanend, saving("$figs_dir/timing_meanend.gph", replace) title("Months from Mean Transfer to Endline", size(medium)) $histopts
hist Dmedend, saving("$figs_dir/timing_medend.gph", replace) title("Months from Median Transfer to Endline", size(medium)) $histopts
hist Dlastend, saving("$figs_dir/timing_lastend.gph", replace) title("Months from Last Transfer to Endline", size(medium)) $histopts
graph combine "$figs_dir/timing_basefirst.gph" "$figs_dir/timing_basemed.gph" "$figs_dir/timing_basemean.gph" "$figs_dir/timing_baselast.gph" "$figs_dir/timing_baseend.gph" "$figs_dir/timing_firstlast.gph" "$figs_dir/timing_firstend.gph" "$figs_dir/timing_meanend.gph" "$figs_dir/timing_medend.gph" "$figs_dir/timing_lastend.gph", graphregion(fcolor(white) lcolor(white)) scheme(s2mono) rows(5) col(2)
graph export "$figs_dir/elapsed_timing_histograms.eps", replace
restore
