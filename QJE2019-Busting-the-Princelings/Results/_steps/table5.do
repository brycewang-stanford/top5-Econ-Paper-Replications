*Table 5*
eststo clear
eststo: xi: reghdfe lnprice princeling quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling quality lnarea if near1500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pscm quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pscm quality lnarea if near1500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling pscm quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling retired quality lnarea, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling retired quality lnarea if near1500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
eststo: xi: reghdfe lnprice princeling retired quality lnarea if near500==1, ab(cityyearusage ind month salemethod state size) cluster(provid firmid) keepsin
esttab using table5.csv, b(%12.3fc) se ar2 nogap replace label order(princeling pscm retired) drop(quality lnarea) 



