version 13.1
set more off
sysdir set PERSONAL "${ado_dir}"
set seed 4191989
local seed 4191989

foreach thisvarlist in $regvars  {


*** CREATE EMPTY TABLE ***
	clear all
	set obs 10
	gen x = 1
	gen y = 1

	forvalues x = 1/9 {
		eststo col`x': reg x y
	}

	local count = 1
	local countse = `count'+1
	local varlabels ""
	local statnames ""
	local qreggraphs ""


*** DATASET ***
	use "$data_dir/UCT_FINAL_CLEAN.dta", clear
	drop if endlinedate ==.
	drop if purecontrol == 1
	gen include = 1
	replace include = 0 if maleres
	tempfile usedata
	save `usedata'

*** REGRESSIONS FOR EACH ENDLINE OUTCOME ***
	foreach var in $`thisvarlist' {

		use `usedata', clear
		local thisvarname "`var'1"

		// The Psych Index is individual level, so it is treated different from other variables in the index list.
		if "`var'" == "psy_index_z" replace include = 1 if maleres


		*** COLUMNS 1-9: QUANTILE REGRESSIONS ***
		sqreg `thisvarname' treat `var'_full0 `var'_miss0 if include == 1, q(.1 .2 .3 .4 .5 .6 .7 .8 .9)
		mat b = e(b)
		mat v = e(V)
		local column = 1
		forvalues i= 1(4)36 {
			local thiscoef = b[1,`i']
			local thisse = sqrt(v[`i',`i'])
			pstar, b(`thiscoef') se(`thisse')
			estadd local thisstat`count' = "`r(bstar)'" : col`column'
			estadd local thisstat`countse' = "`r(sestar)'" : col`column'
			local column = `column' + 1
		}


		*** ITERATE ***
		local thisvarlabel: variable label `thisvarname'
		local varlabels "`varlabels' "`thisvarlabel'" " " "
		local statnames "`statnames' thisstat`count' thisstat`countse'"

		local count = `count' + 2
		local countse = `count' + 1




		*** GRAPH THE QUANTILE TREATMENT EFFECTS ***
		// having some trouble with grqreg2 below, so need to leave _miss0 out if nothing is missing.
		sum  `var'_miss0
		if r(mean) == 0 sqreg `thisvarname' treat `var'_full0 if include, q(.1 .2 .3 .4 .5 .6 .7 .8 .9)
		else sqreg `thisvarname' treat `var'_full0 `var'_miss0 if include, q(.1 .2 .3 .4 .5 .6 .7 .8 .9)

		label var asset_total_ppp1 "Assets"
		label var cons_nondurable_ppp1 "Consumption"
		label var ent_total_rev_ppp1 "Enterprise"
		label var fs_hhfoodindexnew1 "Food_Security"
		label var med_hh_healthindex1 "Health"
		label var ed_index1 "Education"
		label var psy_index_z1 "Psych_Wellbeing"
		label var ih_overall_index_z1 "Intrahousehold"
		local varlab: variable label `thisvarname'

		grqreg3 treat, ci title("`varlab'") format(%9.0g) seed(`seed') options("name(Qreg_`thisvarname')")
		local qreggraphs "`qreggraphs' Qreg_`thisvarname'"
	}

	/* graph combine "$figs_dir/qreg_asset_total_ppp1.gph" "$figs_dir/qreg_cons_nondurable_ppp1.gph" "$figs_dir/qreg_fs_hhfoodindexnew1.gph" "$figs_dir/qreg_ent_total_rev_ppp1.gph" "$figs_dir/qreg_med_hh_healthindex1.gph" "$figs_dir/qreg_ed_index1.gph" "$figs_dir/qreg_psy_index_z1.gph" "$figs_dir/qreg_ih_overall_index_z1.gph", iscale(.5) graphregion(color(white)) rows(2) cols(4) */
	graph combine `qreggraphs', iscale(.5) graphregion(color(white)) rows(2) cols(4)
	graph export "$figs_dir/Qregs_`thisvarlist'.eps", replace

	esttab col* using "$output_dir/`thisvarlist'_qregs.tex",  cells(none) booktabs nonotes nonum compress replace alignment(SSSSSSSSS) mtitle(".1" ".2" ".3" ".4" ".5" ".6" ".7" ".8" ".9") stats(`statnames', labels(`varlabels') )
}
