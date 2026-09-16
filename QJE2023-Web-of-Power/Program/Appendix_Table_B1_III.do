
***************************************************************************************
************************** Appendix Table B.1.III. arbitray clustering standard errors
****************************************************************************************

use Data/HunanCntyYr.dta,clear

********************************************************************************
********************** gen Zeng Guofan period dummies

gen Post=0 if year<1854
replace Post=1 if year>=1854&year<=1864


foreach y of varlist Zeng_all0_invdist_pc Zeng_all0_pc Zenghu_all Zenghu_all_invdist  Zeng_all0 Zeng_all0_invdist  Zeng_exam0_invdist  Zeng_BMF_invdist Zeng_Juren_invdist lnarea capital lnurbanpop  lnpop  dist_nanjing lnjinshi lnquotas mainriv route1 dist2canal lnwheat lnrice {
gen `y'_Post=`y'*Post

}


********************************************************************************
********************** regression




************* 50 KM
reg2hdfespatial lnmartyr1     Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace


reg2hdfespatial lnmartyr1  lnurbanpop_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


*************

reg2hdfespatial lnmartyr1    Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 


*** *** *** 
reg2hdfespatial  lnmartyr1     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

 
*** *** *** 
reg2hdfespatial  lnmartyr1   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

*** *** *** 

reg2hdfespatial lnmartyr1  Zeng_all0_pc_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

 
reg2hdfespatial  lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_pc_Post  , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(50) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_50KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append





********************* 100 KM

reg2hdfespatial lnmartyr1     Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace


reg2hdfespatial lnmartyr1  lnurbanpop_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


*************

reg2hdfespatial lnmartyr1    Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 






*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** 
*** *** *** 
reg2hdfespatial  lnmartyr1     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

 
*** *** *** 
reg2hdfespatial  lnmartyr1   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

*** *** *** 

reg2hdfespatial lnmartyr1  Zeng_all0_pc_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

 
reg2hdfespatial  lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_pc_Post  , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(100) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_100KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append





********************* 200 KM

reg2hdfespatial lnmartyr1     Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons replace


reg2hdfespatial lnmartyr1  lnurbanpop_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_Post)  se  bdec(3) rdec(3) nocons append 



*************

reg2hdfespatial lnmartyr1    Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 


reg2hdfespatial lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post  Zeng_all0_invdist_pc_Post, timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_invdist_pc_Post)  se  bdec(3) rdec(3) nocons append 




*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** 
*** *** *** 
reg2hdfespatial  lnmartyr1     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

 
*** *** *** 
reg2hdfespatial  lnmartyr1   capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post  lnwheat_Post lnrice_Post lnpop_Post lnarea_Post     Zeng_all0_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_Post)  se  bdec(3) rdec(3) nocons append

*** *** *** 

reg2hdfespatial lnmartyr1  Zeng_all0_pc_Post , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append

 
reg2hdfespatial  lnmartyr1  capital_Post lnurbanpop_Post  lnjinshi_Post  lnquotas_Post route1_Post  dist_nanjing_Post mainriv_Post dist2canal_Post   lnwheat_Post lnrice_Post lnpop_Post lnarea_Post   Zeng_all0_pc_Post  , timevar(year) panelvar(cntyid)    lat(y_coord) lon(x_coord) distcutoff(200) lagcutoff(20) 
outreg2 using Results/Appendix_Table_B1_III_200KM.doc, keep(Zeng_all0_pc_Post )  se  bdec(3) rdec(3) nocons append


