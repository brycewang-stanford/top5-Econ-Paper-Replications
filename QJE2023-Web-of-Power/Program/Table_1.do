
***************************************************************************************
************************** Table 1: Summary Statistics 
****************************************************************************************

************************** PanelA: Hunan

use Data/HunanCntyYr.dta,clear

********************************************************************************


sum martyr martyrs_tot_hn Zeng_all0_invdist  Zeng_all0_invdist_pc lnarea lnpop   lnrice lnwheat mainriv  dist2canal lnurbanpop capital  lnjinshi  lnquotas dist_nanjing route1


********************************************************************************
********************************************************************************

************************** PanelB: All counties

use Data/NationalCntyYr.dta,clear


********************************************************************************

sum  martyrs_tot_post Zeng_all0_invdist  alloff  lncntyarea lncntypop  lnrice lnwheat mainriv dist2canal   lnurbanpop  prefcap       lnjinshi  lncntyquota0   dist_nanjing   Taiping_route1

   
	
		