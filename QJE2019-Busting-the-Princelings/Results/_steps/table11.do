*Table 11*
eststo clear
use "$DATA/province_panel.dta", clear
eststo: xi: oprobit promote princeling post2012 pp1 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote princeling inspection pp2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
use "$DATA/prefecture_panel.dta", clear
eststo: xi: oprobit promote princeling post2012 pp1 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
eststo: xi: oprobit promote princeling inspection pp2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
use "$DATA/province_panel.dta", clear
eststo: xi: oprobit promote discount post2012 pd1 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote discount inspection pd2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
use "$DATA/prefecture_panel.dta", clear
eststo: xi: oprobit promote discount post2012 pd1 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
eststo: xi: oprobit promote discount inspection pd2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
use "$DATA/province_panel.dta", clear
eststo: xi: oprobit promote lnarea post2012 alp1 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote lnarea post2012 alp2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
use "$DATA/prefecture_panel.dta", clear
eststo: xi: oprobit promote lnarea post2012 alp1 gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
eststo: xi: oprobit promote lnarea post2012 alp2 ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.pref if year>=2004 & ps==1
esttab using table11.csv, b(%12.3fc) se ar2 nogap star(* 0.10 ** 0.05 *** 0.01) label replace order(princeling pp1 pp2 discount pd1 pd2 lnarea alp1 alp2) drop(post2012 inspection ties gdpgrowth lngdppc revgrowth lnpop age age2 eduyear _Iyear_* _Iprefid_*  _Iprovid_*) 


**Figure**

