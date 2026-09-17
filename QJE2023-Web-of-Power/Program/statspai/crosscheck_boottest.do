* Cross-check of the StatsPAI wild-cluster-bootstrap extension (E2) with Stata boottest (Roodman et al. 2019).
* boottest does not run after reghdfe with 2 absorbed FEs, so areg + i.year is used (same point estimates).
* Run from anywhere: stata-mp -b do Program/statspai/crosscheck_boottest.do
capture which boottest
if _rc ssc install boottest
cd "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/QJE2023-Web-of-Power"
log using Results/statspai/crosscheck_boottest.log, replace text
use Data/HunanCntyYr.dta, clear
gen Post=year>=1854
foreach y in Zeng_all0_invdist capital lnurbanpop lnjinshi lnquotas route1 dist_nanjing mainriv dist2canal lnwheat lnrice lnpop lnarea {
 gen `y'_Post=`y'*Post
}
areg lnmartyr1 Zeng_all0_invdist_Post i.year, absorb(cntyid) cluster(prefid)
boottest Zeng_all0_invdist_Post, reps(9999) seed(20230501) weight(rademacher) nograph
boottest Zeng_all0_invdist_Post, reps(9999) seed(20230501) weight(webb) nograph
areg lnmartyr1 capital_Post lnurbanpop_Post lnjinshi_Post lnquotas_Post route1_Post dist_nanjing_Post mainriv_Post dist2canal_Post lnwheat_Post lnrice_Post lnpop_Post lnarea_Post Zeng_all0_invdist_Post i.year, absorb(cntyid) cluster(prefid)
boottest Zeng_all0_invdist_Post, reps(9999) seed(20230501) weight(webb) nograph
use Data/NationalCntyYr.dta, clear
keep if year>=1820 & hunan==1
gen Zeng_all0_invdistXperiod=Zeng_all0_invdist*period
areg alloff Zeng_all0_invdistXperiod i.year, absorb(samcntyid) cluster(prefid)
boottest Zeng_all0_invdistXperiod, reps(9999) seed(20230501) weight(webb) nograph
log close
