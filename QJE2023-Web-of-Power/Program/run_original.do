*******************************************************************************
* run_original.do — wrapper for the Bai, Jia & Yang (2023, QJE) replication package
*
* Runs every author do-file in the order of Program/All_in_One.do (which itself
* cannot be used as-is: it cds to D:\Dropbox\...), from the project root, and
* records return code + runtime of every step in Results/run_original_steps.csv.
*
* The author code expects the working directory to contain Data/ and Results/;
* it writes outputs straight into Results/. At the end this wrapper moves them
* into Results/Tables/ (tables, parmest .dta, tabout .txt) and Results/Figures/
* (.png/.gph).
*
* Usage (from any directory):
*   stata-mp -b do /path/to/QJE2023-Web-of-Power/Program/run_original.do
* or edit the `root' local below.
*******************************************************************************

version 16          // authors used Stata/MP 16 (needed e.g. for old -table, c()- syntax in Table C7)
clear all
set more off
set rmsg off

local root "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2023-Web-of-Power"
cd "`root'"

* project-local ado: reg2hdfespatial + ols_spatial_HAC (Fetzer 2015; not on SSC)
adopath ++ "`root'/Program/ado"

* SSC dependencies (uncomment on a new machine)
* foreach p in reghdfe ftools ivreghdfe ivreg2 ranktest outreg2 parmest tabout reg2hdfe hdfe tmpdir {
*     ssc install `p', replace
* }

capture log close _all
local sfx = cond("$ONLY"=="", "", "_partial")
log using "Results/run_original`sfx'.log", replace text name(runorig)

local steps Table_1 Appendix_Table_A3 Figure_3 Appendix_Figure_A5 Table_2       ///
    Appendix_Table_B1_I Appendix_Table_B1_II Appendix_Table_B1_III              ///
    Appendix_Table_B1_IV Appendix_Table_B2 Table_3 Table_4 Figure_4             ///
    Appendix_Table_B4 Appendix_Table_B5_I Appendix_Table_B5_II                  ///
    Appendix_Table_B6_I Appendix_Table_B6_II Table_5 Figure_5 Table_6 Figure_6  ///
    Appendix_Figure_C1 Appendix_Table_C2 Appendix_Table_C3 Figure_7             ///
    Appendix_Table_C4 Appendix_Table_C5 Appendix_Table_C6 Appendix_Table_C7     ///
    Figure_8

if "$ONLY" != "" local steps $ONLY

tempname fh
file open `fh' using "Results/run_original_steps`sfx'.csv", write replace
file write `fh' "step,rc,seconds" _n

foreach s of local steps {
    di as txt _n "{hline 78}" _n "==> STEP `s'  (" c(current_time) ")" _n "{hline 78}"
    timer clear 1
    timer on 1
    capture noisily do "Program/`s'.do"
    local rc = _rc
    timer off 1
    quietly timer list 1
    local secs = r(t1)
    capture restore
    quietly cd "`root'"
    graph close _all
    di as res "==> STEP `s' finished: rc=`rc'  seconds=" %9.1f `secs'
    file write `fh' "`s',`rc'," %9.1f (`secs') _n
}
file close `fh'

* sort outputs into Results/Tables and Results/Figures
quietly {
    foreach ext in png gph {
        local fl : dir "Results" files "*.`ext'"
        foreach f of local fl {
            copy "Results/`f'" "Results/Figures/`f'", replace
            erase "Results/`f'"
        }
    }
    foreach ext in doc txt xlsx dta tmp {
        local fl : dir "Results" files "*.`ext'"
        foreach f of local fl {
            copy "Results/`f'" "Results/Tables/`f'", replace
            erase "Results/`f'"
        }
    }
}

log close runorig
