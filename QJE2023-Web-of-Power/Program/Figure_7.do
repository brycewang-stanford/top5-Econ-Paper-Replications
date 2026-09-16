
************************************************************************************************
************* Figure 7: National-level Power Distribution and the Contribution of Elite Networks
************************************************************************************************


use Data/EG_Index.dta, clear


**** Gen Hunan dummy 
gen hunan=(provcd==11)
 
 
**** Gen number of offices net of the effect of connections*Hunan 
gen alloff_NoConn=alloff
replace alloff_NoConn=alloff_NoConn-estimate*Zeng_all0_invdist if hunan==1

sort provcd year 
collapse (sum) alloff alloff_NoConn labor, by(provcd year)


sort year
by year: egen tot_labor=sum(labor)
gen x=labor/tot_labor 
 
gen x2=x^2
sort year
by year: egen sigmax2=sum(x2)




local vars "alloff  alloff_NoConn"

foreach y of local vars {

sort year
by year: egen t`y'=sum(`y')
gen s`y'=`y'/t`y'

gen H`y'=1/t`y'

gen sminusx`y'=(s`y'-x)

gen sminusx2`y'=(s`y'-x)^2
sort year
by year: egen G`y'=sum(sminusx2`y')

gen gama`y'=(G`y'-(1-sigmax2)*H`y')/((1-sigmax2)*(1-H`y'))
}



****************** ****************** ****************** ****************** 

keep if provcd==10


keep year gamaalloff  gamaalloff_NoConn 

gen hXconnRole=gamaalloff-gamaalloff_NoConn
label var hXconnRole "The role of Hunan*connections"


label var gamaalloff "EG Index"
label var gamaalloff_NoConn "EG Index excluding the Hunan*connected officials"


****


*************************** Figure 7. National-level Power Distribution and the Contribution of Elite Networks


scatter  gamaalloff  year, ylabel(0(0.02)0.06)   xlabel(1820(30)1910)  ms(O) mc(gs4) msize(medium) || scatter gamaalloff_NoConn   year, ylabel(0(0.02)0.06) xlabel(1820(30)1910) ms(Oh) mc(blue) msize(medium) mlwidth(medthick) xtitle(Year) ytitle(EG index) title(A. EG index)  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) legend(order(1 "Real" 2 "Counterfactual: Net the effect of Hunan*connections") region(color(none)))  saving(Results/ProvEG.gph, replace)  xsize(4.5) ysize(4.5)

****

scatter hXconnRole  year,  legend(on) xlabel(1820(30)1910) ylabel(0(0.01)0.03)   ms(Oh) mc(gs1) mlwidth(medthick) msize(medium)  xtitle(Year) ytitle(Difference in the two indices) title(B. The role of Hunan*connections) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) legend(order(1 "The role of Hunan*connections") region(color(none)))  saving(Results/Role_hXconn.gph, replace)   xsize(4.5) ysize(4.5) 

graph combine Results/ProvEG.gph Results/Role_hXconn.gph,  row(1)  xsize(9) ysize(4.5) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))

graph export Results/Figure_7.png, replace 

