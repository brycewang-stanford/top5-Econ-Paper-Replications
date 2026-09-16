
***************************************************************************************
************************** Table A3： Elite Connections and Other Characteristics cross Counties
************************** Sample: Hunan counties, 1850--1864
****************************************************************************************

use Data/NationalCntyYr.dta,clear

*********************************************************************************


reg     Zeng_all0_invdist   lncntyarea lncntypop    lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1 if year==1855&hunan==1,  cluster(  samcntyid)  
outreg2 using Results/Appendix_Table_A3.doc,  keep(lncntyarea lncntypop    lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1 ) sortvar(lncntyarea lncntypop     lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1) se  bdec(3) rdec(3) nocons  replace


reg     Zeng_all0_invdist   lncntyarea lncntypop    lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1 if year==1855,  cluster(samcntyid)  
outreg2 using Results/Appendix_Table_A3.doc,  keep(lncntyarea lncntypop   lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1 ) sortvar(lncntyarea lncntypop     lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1) se  bdec(3) rdec(3) nocons   append


