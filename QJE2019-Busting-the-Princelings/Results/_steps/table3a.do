

clear all
* [wrapper] removed: cd "D:\Dropbox\princeling\"



*Table 3A*
use "$DATA/price.dta", clear
tabstat lnprice princeling quality lnarea, stat(n mean)
tab salemethod
tabstat lnprice princeling quality lnarea if near1500==1, stat(n mean)
tab salemethod if near1500==1
tabstat lnprice princeling quality lnarea if near500==1, stat(n mean)
tab salemethod if near500==1

