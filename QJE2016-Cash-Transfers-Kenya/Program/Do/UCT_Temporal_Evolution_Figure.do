clear all
version 13.1 
set more off
sysdir set PERSONAL "${ado_dir}"

foreach thisvarlist in $regvars {
	
	
*** DATASET *** 
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	drop if purecontrol == 1
	drop if endlinedate == .
	xi i.village, pref(fev) // village fixed effects
	
	*** TIME OF TRANSFER ***
	gen treatend_0 = (Dlastend <= 1 & treat == 1)
	gen treatend_1_4 = (Dlastend > 1 & Dlastend <= 4 & treat == 1)
	gen treatend_4_14 = (Dlastend > 4 & treat == 1)
	
	foreach treatx in treatXlumpXsmall treatXmonthlyXsmall {
		foreach end in 0 1_4 4_14 {
			gen tend_`end'`treatx' = (`treatx' == 1 & treatend_`end' == 1)
		}
	}
	
	tempfile usedata
	save `usedata'

	
*** TRACK ITERATIONS ***
	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	local statnames_abbrev ""
	local varlabels_abbrev ""	
	
	
*** CYCLE THROUGH VARIABLES ***
	foreach var in $`thisvarlist' {
	
	use `usedata', clear
	local thisvarname "`var'1"

	// The Psych Index is individual level, so it is treated different from other variables in the index list.
	if "`var'" ~= "psy_index_z" drop if maleres == 1
	drop if `thisvarname' == .

	
	*** BASIC RESULTS ***
	areg `thisvarname' treat treatXlarge `var'_full0 `var'_miss0, cluster(surveyid) absorb(village) 
	gen b_`thisvarname' = . 
	gen se_`thisvarname' = . 
	replace b_`thisvarname' = _b[treat] in 1
	replace se_`thisvarname' = _se[treat] in 1
	
	
	*** TEMPORAL DYNAMICS ***
	areg `thisvarname' tend* treatXlarge `var'_full0 `var'_miss0, absorb(village) cluster(surveyid) 
	local coeffcount = 2
	foreach thisdelay of varlist tend* { 
		replace b_`thisvarname' = _b[`thisdelay'] in `coeffcount'
		replace se_`thisvarname' = _se[`thisdelay'] in `coeffcount'
		local N_`thisvarname' = e(N)
		local ++coeffcount
	}
	
	test tend_0treatXlumpXsmall tend_0treatXmonthlyXsmall
	local `thisvarname'p0 = string(round(r(p),.01),"%9.2f")
	test tend_1_4treatXlumpXsmall tend_1_4treatXmonthlyXsmall
	local `thisvarname'p1_4 = string(round(r(p),.01),"%9.2f")
	test tend_4_14treatXlumpXsmall tend_4_14treatXmonthlyXsmall 
	local `thisvarname'p4_14 = string(round(r(p),.01),"%9.2f")

	*** GRAPH IT ***
	cap drop b_hi  b_lo
	gen b_hi = b_`thisvarname' + 1.64 * se_`thisvarname'
	gen b_lo = b_`thisvarname' - 1.64 * se_`thisvarname'

	cap drop order
	gen order = ((_n-1)+_n)*.6 if b_`thisvarname' ~=.
	forvalues j = 1/13 {
		local order`j' = order[`j']
	}

	local lab: variable label `thisvarname'
	#delimit ;

	local ylabel "";
	if strpos("cons_total ent_totalincome","`var'") >0 {;
		local ylabel "-3000 0 3000 6000";
	};
	
	twoway 
		(bar b_`thisvarname' order in 1, color(black)) 
		(bar b_`thisvarname' order in 2/4, color(blue)) 
		(bar b_`thisvarname' order in 5/7, color(dkgreen)) 
		(bar b_`thisvarname' order in 8/10, color(midblue)) 
		(bar b_`thisvarname' order in 11/13, color(midgreen)) 
		(rcap b_hi b_lo order in 1/13, lcolor(black)) ,
	title("`lab'", size(medium))
	ytitle("Coefficient", size(vsmall))
	xtitle("Months since end of transfer", size(small))
	xlabel(`order1' "Overall" `order2' "Lump&Small <1" `order3' "Lump&Small 1 - 4" `order4' "Lump&Small >4" `order5' "Month&Small <1" `order6' "Month&Small 1 - 4" `order7' "Month&Small >4" , labsize(small)angle(45))
	ylabel(`ylabel',labsize(vsmall))
	note("Joint significance: <1 month p = ``thisvarname'p0'," "1-4 month p = ``thisvarname'p1_4', >4 month p = ``thisvarname'p4_14', N = `N_`thisvarname''", size(vsmall))
	legend(off)
	xsize(10) ysize(7.5)
	graphregion(color(white)) ;

	#delimit cr	;
	
	graph save "$figs_dir/temp_`thisvarname'.gph", replace
	graph export "$figs_dir/temp_`thisvarname'.eps", as(eps) preview(on) replace
	
	}
graph combine "$figs_dir/temp_asset_total_ppp1.gph" "$figs_dir/temp_cons_nondurable_ppp1.gph" "$figs_dir/temp_fs_hhfoodindexnew1.gph" "$figs_dir/temp_ent_total_rev_ppp1.gph" "$figs_dir/temp_med_hh_healthindex1.gph" "$figs_dir/temp_ed_index1.gph" "$figs_dir/temp_psy_index_z1.gph" "$figs_dir/temp_ih_overall_index_z1.gph", iscale(.5) graphregion(color(white)) rows(4) cols(4)
graph export "$figs_dir/temp_indices_combined.eps", as(eps) preview(on) replace
}





