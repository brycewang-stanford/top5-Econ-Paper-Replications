
*********************************************************************************************************
**********  Figure 8. The Share of Provincial Officials from Connected Counties in Hunan 
*********************************************************************************************************


use Data/ProvGovernors.dta, clear 

***** Gen the ratio from Hunan*counnected counties 

gen RatioWar2053=mobbased2053/num2053
gen RatioWar5464=mobbased5464/num5464
gen RatioWar6599=mobbased6599/num6599 



*************************** Figure 8. The Share of Provincial Officials from Connected Counties in Hunan 


*Share of top-4 officials from Hunan*connected area
scatter RatioWar5464 RatioWar2053 if  provinceid!=6,  xlabel(0(0.1)0.3) ylabel(0(0.1)0.3, tposition(inside)) xtitle("From Hunan*connected counties, 1820-53", size(medium)) ytitle("From Hunan*connected counties, 1854-64", size(medium) margin(right)) ms(Oh) mc(blue) mlwidth(medthick) mlabel(prov_en)   mlabcolor(black) mlabposition(1) xsize(6) ysize(6)  title(A. 1820-53 (Pre-war)  vs. 1854-64 (In-war), size(medium))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving(Results/ProvChief1_HXConn.gph, replace)



**********************************************************
 
scatter RatioWar6599  RatioWar5464 if  provinceid!=6 ,  xlabel(0(0.1)0.3) ylabel(0(0.1)0.3, tposition(inside)) xtitle("From Hunan*connected counties, 1854-64", size(medium)) ytitle("From Hunan*connected counties, 1865-99", size(medium) margin(right))   ms(Oh) mcolor(blue) mlwidth(medthick) mlabel(prov_en)  mlabcolor(black) mlabposition(1) legend(off) xsize(6) ysize(6)  title(B. 1854-64 (In-war) vs. 1865-99 (Post-war), size(medium))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving(Results/ProvChief2_HXConn.gph, replace)



**********************************************************

twoway lfitci  Yangtze RatioWar5464 if  provinceid!=6  , ciplot(rline) lp(solid) lcolor(black) || scatter Yangtze RatioWar5464 , ms(Oh) mc(blue)  mlwidth(medthick) legend(off) xtitle("From Hunan*connected counties, 1854-64", size(medium) margin(right))   ylabel(0(1)2, tposition(inside))  ytitle("Disobeying the imperial edict", size(medium))  xsize(6) ysize(6)  title(C. Prob. of disobeying the state, size(medium))  graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white)) saving(Results/ProvChief3_HXConn.gph, replace)



graph combine Results/ProvChief1_HXConn.gph Results/ProvChief2_HXConn.gph Results/ProvChief3_HXConn.gph, row(1) xsize(18) ysize(6) graphregion(color(white) ifcolor(white) ilcolor(white) fcolor(white))

graph export Results/Figure_8.png, replace width(3600) height(1200)
