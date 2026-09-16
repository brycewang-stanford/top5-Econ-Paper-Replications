*Table 9*
use "$DATA/price.dta", clear
eststo clear
eststo: xi: reghdfe lnprice princeling pp1 quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp1 quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp2 quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp2 quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp3 quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp3 quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp1 pp2 pp3 quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp1 pp2 pp3 quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp4 quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pp4 quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
esttab using table9.csv, b(%12.3fc) se ar2 nogap replace label order(princeling pp1 pp2 pp3 pp4) drop(quality lnarea) 


