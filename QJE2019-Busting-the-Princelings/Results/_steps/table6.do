*Table 6*
use "$DATA/firm_panel.dta", clear
eststo clear
eststo: xi: reghdfe lnarea princeling, ab(year state size) cluster(firmid) keepsin 
eststo: xi: reghdfe lnarea princeling pscm, ab(year state size) cluster(firmid) keepsin 
eststo: xi: reghdfe lnarea princeling retired, ab(year state size) cluster(firmid) keepsin 
esttab using table6.csv, b(%12.3fc) se ar2 nogap replace label order(princeling pscm retired)


