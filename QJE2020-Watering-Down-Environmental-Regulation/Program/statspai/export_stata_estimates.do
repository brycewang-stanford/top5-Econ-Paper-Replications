*******************************************************************************
* export_stata_estimates.do
*   Re-runs every rdrobust cell of the author's do-files (Tables I, III-VII) with
*   the author's exact options and posts e() results to a tidy CSV, so that the
*   original-Stata numbers can be compared cell-by-cell with the paper and with
*   StatsPAI (outreg2's .txt output drops columns and rounds to 2 decimals).
*   Not part of the author's package. Run from the project root:
*     stata-mp -b do Program/statspai/export_stata_estimates.do
*******************************************************************************
clear all
set more off
global root "`c(pwd)'"
global pkg  "$root/Data/Replication Materials"
cap mkdir "$root/Results/statspai"

tempname P
postfile `P' str8 exhibit str40 row int col str60 file str40 y str60 cond ///
    str12 kernel str10 bwselect str8 masspts ///
    double N h_l h_r b_l b_r tau_cl se_cl tau_bc se_rb N_h_l N_h_r ///
    using "$root/Results/statspai/stata_estimates.dta", replace

capture program drop onerd
program define onerd
    syntax, P(string) EX(string) ROW(string) COL(integer) FILE(string) Y(string) ///
            COND(string) KERN(string) [BW(string) MP(string)]
    use "$pkg/`file'", clear
    local mpopt "masspoints(off)"
    if "`mp'" == "adjust" local mpopt ""
    local bwopt ""
    if "`bw'" != "" local bwopt "bwselect(`bw')"
    qui rdrobust `y' distance_new if `cond', `mpopt' `bwopt' kernel(`kern') all vce(cluster site_id)
    local bwl = cond("`bw'" == "", "mserd", "`bw'")
    local mpl = cond("`mp'" == "", "off", "`mp'")
    post `p' ("`ex'") ("`row'") (`col') ("`file'") ("`y'") ("`cond'") ("`kern'") ("`bwl'") ("`mpl'") ///
        (e(N)) (e(h_l)) (e(h_r)) (e(b_l)) (e(b_r)) (e(tau_cl)) (e(se_tau_cl)) (e(tau_bc)) (e(se_tau_rb)) (e(N_h_l)) (e(N_h_r))
end

local K3 "tri epa uni"

* ---------------- Table I ----------------
foreach y in tfpop_s resid1_tfpop_s resid2_tfpop_s {
    local c = 0
    foreach g in 1 0 {
        foreach k of local K3 {
            local ++c
            onerd, p(`P') ex(T1) row(`y') col(`c') file(T1_Baseline/tfp_small_QJE_final.dta) y(`y') cond(neg_ind0==`g') kern(`k')
        }
    }
}

* ---------------- Table III ----------------
foreach y in resid1_lrze resid1_lnv resid1_lnl resid1_lnk resid1_lnm resid1_lnv_l resid1_lnv_k {
    local c = 0
    foreach f in channels_QJE_final channels_Pre_QJE_final {
        foreach k of local K3 {
            local ++c
            onerd, p(`P') ex(T3) row(`y') col(`c') file(T3_Channels/`f'.dta) y(`y') cond(neg_ind0==1) kern(`k')
        }
    }
}

* ---------------- Table IV ----------------
foreach y in resid1_hours resid1_log_water resid1_machine resid1_total_capacity {
    local c = 0
    foreach k of local K3 {
        local ++c
        onerd, p(`P') ex(T4) row(`y') col(`c') file(T4_Abatement/abatement_QJE_final.dta) y(`y') cond(1) kern(`k')
    }
}

* ---------------- Table V ----------------
foreach y in resid_log_cod resid_log_cod_intensity resid_log_nh resid_log_nh_intensity resid_log_waste_water resid_log_waste_water_intensity {
    local c = 0
    foreach k of local K3 {
        local ++c
        onerd, p(`P') ex(T5) row(`y') col(`c') file(T5_Emissions/water_emission_QJE_final.dta) y(`y') cond(1) kern(`k')
    }
}
foreach y in resid_log_so2 resid_log_nox {
    local c = 0
    foreach k of local K3 {
        local ++c
        onerd, p(`P') ex(T5) row(`y') col(`c') file(T5_Emissions/air_emission_QJE_final.dta) y(`y') cond(1) kern(`k')
    }
}

* ---------------- Table VI ----------------
local c = 0
foreach k of local K3 {
    local ++c
    onerd, p(`P') ex(T6) row(fee) col(`c') file(T6_PE/pwf_QJE_final.dta) y(resid1_l_pwf) cond(1) kern(`k') bw(certwo)
}
foreach inc in 1 0 {
    local c = 0
    foreach g in 1 0 {
        foreach k of local K3 {
            local ++c
            onerd, p(`P') ex(T6) row(party_inc`inc') col(`c') file(T6_PE/PE_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & party_inc==`inc') kern(`k')
        }
    }
}
foreach a in 1 0 {
    local c = 0
    foreach g in 1 0 {
        foreach k of local K3 {
            local ++c
            * author's code: nonpolluting x automatic x uniform uses bwselect(msecomb1) and no masspoints(off)
            if `a' == 1 & `g' == 0 & "`k'" == "uni" {
                onerd, p(`P') ex(T6) row(automatic`a') col(`c') file(T6_PE/auto_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & automatic==`a') kern(`k') bw(msecomb1) mp(adjust)
            }
            else {
                onerd, p(`P') ex(T6) row(automatic`a') col(`c') file(T6_PE/auto_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & automatic==`a') kern(`k')
            }
        }
    }
}

* ---------------- Table VII ----------------
foreach s in 0 1 {
    local c = 0
    foreach g in 1 0 {
        foreach k in tri epa uniform {
            local ++c
            onerd, p(`P') ex(T7) row(soe`s') col(`c') file(T7_Burden/soe_vs_private_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & soe==`s') kern(`k')
        }
    }
}
foreach s in 0 1 {
    local c = 0
    foreach g in 1 0 {
        foreach k in tri epa uniform {
            local ++c
            onerd, p(`P') ex(T7) row(firm_big`s') col(`c') file(T7_Burden/big_vs_small_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & firm_big==`s') kern(`k')
        }
    }
}
* author's kernel order here is "epa tri uni" (the paper labels these columns Triangle/Epanech./Uniform)
foreach s in 1 0 {
    local c = 0
    foreach g in 1 0 {
        foreach k in epa tri uni {
            local ++c
            onerd, p(`P') ex(T7) row(nsbd`s') col(`c') file(T7_Burden/NSBD_QJE_final.dta) y(resid1_tfpop_s) cond(neg_ind0==`g' & nsbd_c==`s') kern(`k')
        }
    }
}

postclose `P'
use "$root/Results/statspai/stata_estimates.dta", clear
export delimited using "$root/Results/statspai/stata_estimates.csv", replace
erase "$root/Results/statspai/stata_estimates.dta"
di as result "exported " _N " rdrobust cells"
