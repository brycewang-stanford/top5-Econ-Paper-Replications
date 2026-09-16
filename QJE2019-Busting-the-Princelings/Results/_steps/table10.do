*Table 10*
use "$DATA/firm_prov_panel.dta", clear
eststo clear
eststo: xi: reghdfe lnarea princeling pp1, ab(provid year state size) cluster(provid firmid) keepsin 
eststo: xi: reghdfe lnarea princeling inspection pp2, ab(provid year state size) cluster(provid firmid) keepsin 
eststo: xi: reghdfe lnarea princeling xi pp3, ab(provid year state size) cluster(provid firmid) keepsin 
eststo: xi: reghdfe lnarea princeling pp1 inspection pp2 xi pp3, ab(provid year state size) cluster(provid firmid) keepsin 
esttab using table10.csv, b(%12.3fc) se ar2 nogap replace label order(princeling pp1 inspection pp2 xi pp3)


