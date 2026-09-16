
*********************************************************************************************************
**********  Table C.7. The Changes in Power Distribution by Decade
*********************************************************************************************************


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

label var gamaalloff "EG Index"
label var gamaalloff_NoConn "EG Index excluding the Hunan*connected officials"

****



*************************** Table C.7. The Changes in Power Distribution by Decade 

gen dec=int(year/10)
table dec
table dec, c(mean gamaalloff   mean gamaalloff_NoConn)


