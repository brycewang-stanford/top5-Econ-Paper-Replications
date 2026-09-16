*Table 7*
use "$DATA/province_panel.dta", clear
eststo clear
eststo: xi: oprobit promote princeling i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote princeling ties gdpgrowth lngdppc lnpop revgrowth lnpop age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: reg promote1 princeling ties gdpgrowth lngdppc lnpop revgrowth  age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote discount ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==1
eststo: xi: oprobit promote princeling i.year i.provid if year>=2004 & ps==0
eststo: xi: oprobit promote princeling ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==0
eststo: xi: reg promote1 princeling ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==0
eststo: xi: oprobit promote discount ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==0
eststo: xi: oprobit promote lnarea ties gdpgrowth lngdppc lnpop revgrowth age age2 eduyear i.year i.provid if year>=2004 & ps==0
esttab using table7.csv, b(%12.3fc) se ar2 nogap star(* 0.10 ** 0.05 *** 0.01) replace label order(princeling discount lnarea ties gdpgrowth) drop(_Iyear_* _Iprovid_* lngdppc lnpop age age2 eduyear _cons) 


