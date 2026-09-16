*******************************************************************************
* modern_reference_stata.do — Stata reference values for the "modern methods"
* extensions (NOT part of the author's package). Used to validate the StatsPAI
* weak-IV / wild-bootstrap numbers in Program/statspai/modern_extensions.py.
*
*   Table 3 col 1 (time dummy only) and col 6 (full controls):
*   - ivreg2: Kleibergen-Paap rk Wald F, Anderson-Rubin Wald test (cluster-robust)
*   - weakivtest: Montiel Olea-Pflueger effective F
*   - weakiv: cluster-robust AR / CLR / K confidence sets
*   - boottest: WRE wild cluster bootstrap (Davidson-MacKinnon) p-value and CI
* Requires: ivreg2 ranktest weakivtest weakiv avar boottest (all SSC)
*******************************************************************************
version 18
clear all
set more off
if "$ROOT" == "" global ROOT "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/AER2013-China-Syndrome"
cap log close _all
log using "$ROOT/Results/log/modern_reference_stata.log", replace text name(modref)

use "$ROOT/Data/dta/workfile_china.dta", clear
local full l_shind_manuf_cbp l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen reg_mount reg_pacif t2

tempname fh
file open `fh' using "$ROOT/Results/log/modern_reference_stata.csv", write replace text
file write `fh' "spec,stat,value" _n

foreach spec in c1 c6 c6u {
    if "`spec'" == "c1" local ctrl t2
    else local ctrl `full'
    local wgt "[aw=timepwt48]"
    if "`spec'" == "c6u" local wgt ""   // unweighted variant: isolates weight handling across software

    * --- ivreg2: same point estimate as ivregress; KP F; AR test ---------------
    ivreg2 d_sh_empl_mfg (d_tradeusch_pw = d_tradeotch_pw_lag) `ctrl' `wgt', cluster(statefip)
    file write `fh' "`spec',b," %20.12g (_b[d_tradeusch_pw]) _n
    file write `fh' "`spec',se_ivreg2," %20.12g (_se[d_tradeusch_pw]) _n
    file write `fh' "`spec',kp_rk_wald_F," %20.12g (e(widstat)) _n
    file write `fh' "`spec',ar_F," %20.12g (e(arf)) _n
    file write `fh' "`spec',ar_p," %20.12g (e(arfp)) _n

    * --- Olea-Pflueger effective F ------------------------------------------
    cap noisily weakivtest
    if !_rc {
        return list
        file write `fh' "`spec',F_eff," %20.12g (r(F_eff)) _n
        cap file write `fh' "`spec',F_eff_crit_tau10_5pct," %20.12g (r(c_TSLS_10)) _n
    }

    * --- weak-IV robust confidence sets ---------------------------------------
    cap noisily weakiv ivreg2 d_sh_empl_mfg (d_tradeusch_pw = d_tradeotch_pw_lag) `ctrl' `wgt', cluster(statefip) usegrid gridpoints(2001) gridmin(-2) gridmax(1)
    if !_rc {
        ereturn list
        cap file write `fh' "`spec',ar_cset,`e(ar_cset)'" _n
        cap file write `fh' "`spec',clr_cset,`e(clr_cset)'" _n
        cap file write `fh' "`spec',k_cset,`e(k_cset)'" _n
        cap file write `fh' "`spec',wald_cset,`e(wald_cset)'" _n
    }

    * --- WRE wild cluster bootstrap ----------------------------------------------
    qui ivreg2 d_sh_empl_mfg (d_tradeusch_pw = d_tradeotch_pw_lag) `ctrl' `wgt', cluster(statefip)
    cap noisily boottest d_tradeusch_pw, reps(9999) seed(20130601) nograph
    if !_rc {
        return list
        file write `fh' "`spec',wre_p," %20.12g (r(p)) _n
        cap mat CI = r(CI)
        cap file write `fh' "`spec',wre_ci_lo," %20.12g (CI[1,1]) _n
        cap file write `fh' "`spec',wre_ci_hi," %20.12g (CI[1,2]) _n
    }
}
file close `fh'
log close modref
