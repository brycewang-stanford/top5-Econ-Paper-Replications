
********************************************************************************
***** Table B.6. II. The Battle of Three Rivers vs. Other Battles in 1858
***** Sample: Hunan counties, 1858
********************************************************************************
 

use Data/ThreeRivers.dta,clear


foreach x of varlist martyrs_battle martyrs_battle_sanhe martyrs_battle_nosanhe {
gen ln`x'1=ln(1+`x')
}



********************************************************************************



sum  martyrs_battle martyrs_battle_sanhe martyrs_battle_nosanhe if year==1858

sum  martyrs_battle martyrs_battle_sanhe martyrs_battle_nosanhe if year==1858



********************************************************************************
****************************** Appendix Table B.6.II San He 



egen  prefidXyear=group(prefid year)


 reghdfe    lnmartyrs_battle1 Zeng_all0_invdist ///
 capital    lnjinshi   lnquotas ///
  route1    dist_nanjing ///
lnurbanpop dist2canal lnrice lnwheat     mainriv lnhh lnarea   if year==1858 , absorb(prefid)  cluster(  cntyid)
outreg2 using Results/Appendix_Table_B6_II.doc, keep(Zeng_all0_invdist)  se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  replace


 reghdfe    lnmartyrs_battle_sanhe1 Zeng_all0_invdist ///
 capital    lnjinshi   lnquotas ///
  route1    dist_nanjing ///
lnurbanpop  dist2canal lnrice lnwheat     mainriv lnhh lnarea if year==1858 , absorb(prefid)   cluster(  cntyid)
outreg2 using Results/Appendix_Table_B6_II.doc, keep(Zeng_all0_invdist)  se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  append


 reghdfe    lnmartyrs_battle_nosanhe1 Zeng_all0_invdist ///
 capital    lnjinshi   lnquotas ///
  route1    dist_nanjing ///
lnurbanpop  dist2canal lnrice lnwheat     mainriv lnhh lnarea  if year==1858 , absorb(prefid)   cluster(  cntyid)
outreg2 using Results/Appendix_Table_B6_II.doc, keep(Zeng_all0_invdist)  se  bdec(3) rdec(3) nocons addtext(Observations, `e(N_full)') noobs  append



