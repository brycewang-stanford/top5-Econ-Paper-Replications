*Table 3B*
use "$DATA/province_panel.dta", clear
tab promote if ps==1
tab promote if ps==0
tabstat princeling discount lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear if ps==1, stat(n mean sd)
tabstat princeling discount lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear if ps==0, stat(n mean sd)

use "$DATA/prefecture_panel.dta", clear
tab promote if ps==1
tab promote if ps==0
tabstat princeling discount lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear if ps==1, stat(n mean sd)
tabstat princeling discount lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear if ps==0, stat(n mean sd)


**REGRESSIONS**

use "$DATA/price.dta", clear
