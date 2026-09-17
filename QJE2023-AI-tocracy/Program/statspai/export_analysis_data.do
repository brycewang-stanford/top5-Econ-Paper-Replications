/* ===========================================================================================
// Analysis for "AI-tocracy"
// Updated: 01/29/2022
=========================================================================================== */ 


* set directories 
clear all
set maxvar  30000
set matsize 11000 
set more off
cap log close

**** MODIFY THE LINE BELOW WITH YOUR PATH TO THE REPLICATION FOLDER
global dir = "~/Dropbox/Polecon_AI/Analysis/Replication"
* [REPLICATION EDIT 1] allow the wrapper (Program/run_original.do) to set the root folder
if "$AITOC_ROOT" != "" global dir = "$AITOC_ROOT"


cd "$dir"

global raw = "$dir/Data"
global analysis = "$dir/Data"
global rawdata = "$dir/Data"
global Tab_Fig = "$dir/Output"

adopath + "${dir}/Analysis"

****** modify the local variable `output' to construct the desired tables/figures
local output = "all"
* [EXPORT] sections restricted below
* [REPLICATION EDIT 2] allow the section number to be passed as an argument: do Analysis.do 8
if "`1'" != "" local output = "`1'"
* output guide:
* "all": produce all tables and figures
* 1: Figure 1 and A.5, maps
* 2: Figure 2, A.12, and A.13, AI/camera procurement event study
* 3: Figure 3 and Table A.3, different estimators
* 4: Figure 4, impact of AI on unrest
* 5: Figure 5, total effect of politically motivated contract
* 6: Figure 6, Fig A.11, Fig A.14,  differential effect of politically motivated contract
* 7: Table 1, summary table
* 8: Table 2, effect of unrest on AI
* 9: Table 3, effect of unrest on cam/AI
* 10: Table 4, 5, A.5, A.6, and A.7 effect of AI on unrest
* 11: Table 6, A.8, A.9, and A.10 effect of AI contracts on software
* 12: Table 7, A.11, A.12, and A.13 effect of AI contracts on software
* 13: Table 8, export AI
* 14: Table 9, Figure A.16 spillovers
* 15: Figure A.4, contracts data
* 16: Figure A.6, firm capital and software
* 17: Figure A.10, LASSO seed
* 18: Figure A.15, politically motivated vs. neutral
* 19: Table A.2, different types of unrest on AI
* 20: Table A.4, police hires
* 21: Table A.14, A.15, software robustness





* [EXPORT] stub for the cross-fit LASSO IV: posts a dummy coefficient so est sto/estout still work
cap program drop xpoivregress
program define xpoivregress, eclass
    tempname b V
    matrix `b' = (0)
    matrix colnames `b' = blank
    matrix `V' = (1)
    matrix colnames `V' = blank
    matrix rownames `V' = blank
    ereturn post `b' `V'
end
cap program drop lassocoef
program define lassocoef
    di "[EXPORT] lassocoef skipped"
end
cap mkdir "Data/Intermediate/statspai"

**************** HELPER FUNCTIONS ******************

/*===========================================================================
* Regression to Coef Dataset
===========================================================================*/
* syntax: none
* usage: after running a regression, takes the first coefficients and turns it 
* into a dataset with coef/SEs -- note usage keeps quarters -3 to 2
cap program drop regToCoefDataset
program regToCoefDataset
syntax anything

* graph 
cap drop beta1
mat b = e(b)'
svmat double b, n(beta) // convert matrix b into variable beta1 
mat V = e(V) 
// loca n = `e(rankxx)' 
loca n = rowsof(V)
mat se=J(`n',1,-9999) 
forval i=1/`n' {
	mat se[`i',1] = sqrt(V[`i',`i']) 
}   
svmat double se, n(se) 

// diff between coeff label and actual event time
local offset = 3

gen top =  beta1 + 1.645 * se1
gen bottom = beta1 - 1.645 * se1
gen id = _n 
replace id = id - `offset'
keep if inrange(id,-2,3)
keep beta1 top bottom id se1

end

* same as regToCoefDataset, but quarters -8 to 8
cap program drop regToCoefDataset90
program regToCoefDataset90
syntax anything

* graph 
mat b = e(b)'
svmat double b, n(beta) // convert matrix b into variable beta1 
mat V = e(V) 
loca n = `e(rank)' 
mat se=J(`n',1,-9999) 
forval i=1/`n' {
	mat se[`i',1] = sqrt(V[`i',`i']) 
}   
svmat double se, n(se) 

* when we don't have enough prior semiyears to fill to -12
local offset = 24
while beta[`offset'] != 0 {
local offset = `offset' - 1
}

*list beta1 se1 if beta1<. ,clean
gen top =  beta1 + 1.65 * se1
gen bottom = beta1 - 1.65 * se1
gen id = _n 
replace id = id - `offset' - 1
keep if inrange(id,-8,16)
keep beta1 top bottom id se1

end


***** program addQuarterInter ******
* adds the year and interaction effect
capture program drop addQuarterInter
program define addQuarterInter, eclass
    matrix A = e(b)
	mat V2 = e(V) 
	forv i = 13/48 {
	local inter`i' = colnumb(A,"`i'.semi_to_f_x_ca_x_with_c")
	local s`i' = colnumb(A,"`i'.quarter_to_first")
    matrix A[1,`inter`i''] = A[1,`inter`i''] +  A[1,`s`i'']   // add coeffs
	matrix V2[`inter`i'',`inter`i''] = V2[`inter`i'',`inter`i''] + V2[`s`i'',`s`i'']  // add variances
	}
    ereturn repost b=A
	ereturn repost V=V2
end

***** program addQuarter24 ******
* adds the quarter 24 effect
capture program drop addQuarter24
program define addQuarter24, eclass
    matrix A = e(b)
	mat V2 = e(V) 
	local inter24 = colnumb(A,"semi25_to_f_x_ca_x_with_c")
	forv i = 13/49 {
	local inter`i' = colnumb(A,"semi`i'_to_f_x_ca_x_with_c")
    cap matrix A[1,`inter`i''] = A[1,`inter`i''] -  A[1,`inter24']   // add coeffs
	matrix V2[`inter`i'',`inter`i''] = V2[`inter`i'',`inter`i''] + V2[`inter24',`inter24']  // add variances
	}
    ereturn repost b=A
	ereturn repost V=V2
end


**************** MAIN CODE ******************


/* 1: Figure 1 and A.5, maps --- construct data
* note: run make_map.R afterwards to construct map data
*/
if "`output'" == "1" | "`output'" == "all" {
	

use "Data/GDELT_China_072920.dta", clear

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
keep if actor1geo_type > 1 & actor2geo_type > 1

gen unrest = protest
replace unrest = 0 if missing(unrest)

collapse (sum) unrest (sum) pop (lastnm) prov_eng pref_eng, by(province merge_pref)

replace prov_eng = "Xizang" if province == "西藏自治区"
replace pref_eng = "Chamdo" if merge_pref == "成都市"
replace pref_eng = "Lhasa" if merge_pref == "拉萨市"
replace pref_eng = "Nyingtri" if merge_pref == "海西蒙古族藏族自治州"
replace prov_eng = "Nei Mongol" if province == "内蒙古自治区"
replace pref_eng = "Ulaan Chab" if merge_pref == "乌兰察布市"
replace pref_eng = "Wuhai" if merge_pref == "乌海市"
replace pref_eng = "Xing'an" if merge_pref == "兴安盟"
replace pref_eng = "Baotou" if merge_pref == "包头市"
replace pref_eng = "Hulunbuir" if merge_pref == "呼伦贝尔市"
replace pref_eng = "Hohhot" if merge_pref == "呼和浩特市"
replace pref_eng = "Chifeng" if merge_pref == "赤峰市"
replace pref_eng = "Tongliao" if merge_pref == "通辽市"
replace pref_eng = "Ordos" if merge_pref == "鄂尔多斯市"
replace pref_eng = "Xilin Gol" if merge_pref == "锡林郭勒盟"
replace prov_eng = "Xinjiang Uygur" if province == "新疆维吾尔自治区"
replace pref_eng = "Alxa" if merge_pref == "阿拉善盟"
replace pref_eng = "Kashgar" if merge_pref == "喀什地区"
replace pref_eng = "Tacheng" if merge_pref == "塔城地区"

export delim "Data/Intermediate/China_map_unrest.csv", replace



use "Data/contracts_gdp_pop_admin-unit.dta", clear 

gen qofd = qofd(mdy(month,1,year))

* merge unrest data
merge n:1 prov city qofd using "Data/unrest_data.dta", keep(1 3) nogen

* impute 0s for cities with no data
bys city: egen protest_count = count(event)
replace event = 0 if protest_count == 0
replace event = 0 if missing(event)

su event, d
gen unrest = (event > r(p50)) if !missing(event)

keep if police == 1

collapse (mean) unrest (sum) event (count) police, by(prov city)

* crosswalk to english
ren (prov city) (province merge_pref)
merge 1:1 province merge_pref using "Data/cn_eng_pref_crosswalk", keep(1 3) nogen

replace prov_eng = "Xizang" if province == "西藏自治区"
replace pref_eng = "Chamdo" if merge_pref == "成都市"
replace pref_eng = "Lhasa" if merge_pref == "拉萨市"
replace pref_eng = "Nyingtri" if merge_pref == "海西蒙古族藏族自治州"
replace prov_eng = "Nei Mongol" if province == "内蒙古自治区"
replace pref_eng = "Ulaan Chab" if merge_pref == "乌兰察布市"
replace pref_eng = "Wuhai" if merge_pref == "乌海市"
replace pref_eng = "Xing'an" if merge_pref == "兴安盟"
replace pref_eng = "Baotou" if merge_pref == "包头市"
replace pref_eng = "Hulunbuir" if merge_pref == "呼伦贝尔市"
replace pref_eng = "Hohhot" if merge_pref == "呼和浩特市"
replace pref_eng = "Chifeng" if merge_pref == "赤峰市"
replace pref_eng = "Tongliao" if merge_pref == "通辽市"
replace pref_eng = "Ordos" if merge_pref == "鄂尔多斯市"
replace pref_eng = "Xilin Gol" if merge_pref == "锡林郭勒盟"
replace prov_eng = "Xinjiang Uygur" if province == "新疆维吾尔自治区"
replace pref_eng = "Alxa" if merge_pref == "阿拉善盟"
replace pref_eng = "Kashgar" if merge_pref == "喀什地区"
replace pref_eng = "Tacheng" if merge_pref == "塔城地区"

export delim "Data/Intermediate/China_map_data", replace

bys province: egen nn = count(police)
gen xadd = nn * police if merge_pref == ""

collapse (mean) unrest xadd (sum) police, by(prov_eng)
replace xadd = 0 if missing(xadd)

replace police = police + xadd

export delim "Data/Intermediate/China_map_data_prov.csv", replace
	
	
}

/* 2: Figure 2, A.12, and A.13, AI/camera procurement event study
*/
if "`output'" == "2" | "`output'" == "all" {
	
local time = "qofd"
local event = "event"
local outcomes = "lead_police_pc lead_camera_time_city_pc aiXcam"


foreach outcome in `outcomes' {
local allinstr = ""

	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
* lag = 0, default 1 year lead
* else lag is number of quarters to lead AI
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)
gen nonpolice = contracts - lead_police

ren city merge_pref

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen lead_nonpolice_pc = nonpolice/prefecture_city_population


drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 

* collapse to daily level
collapse (sum) protest demand threat (mean) lead_police_pc lead_nonpolice_pc camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue, ///
 by(pref_eng prov_eng year month day station)
 
 gen lead_camera_time_city_pc = camera_time_city_pc
 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_nonpolice_pc lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv timeX = `smin'/`smax' {
	qui count if time == `timeX'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `timeX', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `timeX'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng , by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
replace rain = 1 - rain
replace prcp = -prcp



gen blank = .
replace blank = `event'

local itype = "rtw"

if "`itype'" == "rtw" {
local instrument "w__rain w__gust w__thunder"
gen w__rain = rain
gen w__gust = gust
gen w__thunder = thunder
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`itype'" == "lasso" {
local instrument "w_`lagO'_thunder_hail361I w_`lagO'_hail_gust14I w_`lagO'_max5_hail50I w_`lagO'_thunder_gust360I w_`lagO'_min4_hail96I w_`lagO'_min4_hail96 w_`lagO'_mxspd_gust124I"
local instruments = "`instrument'"

	gen w_`lagO'_thunder_hail361I = thunder * hail * event_elsewhere
	gen w_`lagO'_hail_gust14I = hail * gust * event_elsewhere
	gen w_`lagO'_max5_hail50I = max5 * hail * event_elsewhere
	gen w_`lagO'_thunder_gust360I = thunder * gust * event_elsewhere
	gen w_`lagO'_min4_hail96I = min4 * hail * event_elsewhere
	gen w_`lagO'_min4_hail96 = min4 * hail 
	gen w_`lagO'_mxspd_gust124I = mxspd * gust * event_elsewhere	
}
else {
foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}	
}

if "`outcome'" == "aiXcam" {
	gen aiXcam = lead_police_pc * lead_camera_time_city_pc
}


collapse (sum) blank `instruments' (mean) `outcome' prefecture_city_population prefecture_gdp prefecture_fiscal_revenue prov_fe year, by(place `time')

su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)
su blank
replace blank = (blank - r(mean))/r(sd)

tempfile master
save `master'

forv lag = -2/3 {

local lagO = `lag' + 2

use `master', clear

** to get time variation in the instruments now:
preserve
drop `outcome'
replace `time' = `time' - `lagO'

tempfile t`lagO'
save `t`lagO''
restore

drop blank `instruments'
local new_instruments = ""

merge 1:1 place `time' using `t`lagO'', nogen keep(1 3)

ren w__* w_`lagO'_*

if "`itype'" == "lasso" {
local allinstr = "`allinstr' w_`lagO'_thunder_hail361I w_`lagO'_hail_gust14I w_`lagO'_max5_hail50I w_`lagO'_thunder_gust360I w_`lagO'_min4_hail96I w_`lagO'_min4_hail96 w_`lagO'_mxspd_gust124I"
}
else if "`itype'" == "rtw" {
local allinstr = "`allinstr' w_`lagO'_rain w_`lagO'_rainI w_`lagO'_gust w_`lagO'_gustI w_`lagO'_thunder w_`lagO'_thunderI "	
}
gen lag = `lagO'
ren blank blank_`lagO'

tempfile l`lagO'
save `l`lagO''
di "save `lagO'"
	
}

gen blank = .
* merge datasets
forv lag = 0/5 {
if `lag' != 5 {
append using `l`lag''	
}
}
forv lag = 0/5 {
replace blank = blank_`lag' if lag == `lag'
replace blank_`lag' = 0 if missing(blank_`lag')
}


* replace instruments
foreach instr in `allinstr' {
bys place `time': egen `instr'M = mean(`instr')
replace `instr' = `instr'M	
}


drop blank_*

reshape wide blank prefecture_city_population prefecture_gdp prefecture_fiscal_revenue, i(place `time') j(lag)	

ren blank* blank_*

* orthogonalize events
forv period = 0/5 {
if `period' !=2{
*** Residualized events
qui reg blank_2 blank_`period', r
qui predict res_blank_`period', r

replace blank_`period' = blank_`period' - res_blank_`period'
}
}

cap drop res_*

gen logpop = log(prefecture_city_population0)

egen prov_by_year = group(prov_fe year)

** run main regression
tsset place `time'
qui save "Data/Intermediate/statspai/s2_`outcome'.dta", replace  // [EXPORT HOOK]
ivreghdfe `outcome' blank_* c.prefecture_gdp0#qofd c.logpop#qofd c.prefecture_fiscal_revenue0#qofd prefecture_gdp0 logpop prefecture_fiscal_revenue0, absorb(place qofd) cl(place) 
	
** save data	
regToCoefDataset xx

if "`outcome'" == "lead_police_pc" {
	save "Data/Intermediate/statspai/_fig_Fig2.dta", replace
}
else if "`outcome'" == "lead_camera_time_city_pc" {
	save "Data/Intermediate/statspai/_fig_FigA12.dta", replace
}
else if "`outcome'" == "aiXcam" {
	save "Data/Intermediate/statspai/_fig_FigA13.dta", replace
}


** graphing
if "`outcome'" == "lead_police_pc"   {
local minY = -.05
local yInc = .05
local maxY = .15	
local ytitle = "Public security AI investments"
use "Data/Intermediate/statspai/_fig_Fig2.dta", clear
local outpath = "Output/Figure2_eventstudy.png"
}
else if "`outcome'" == "lead_camera_time_city_pc" {
local minY = -.02
local yInc = .01
local maxY = .04	
local ytitle = "Surveillance cameras per capita"
use "Data/Intermediate/statspai/_fig_FigA12.dta", clear
local outpath = "Output/FigureA12_eventstudy.png"
}
else if  "`outcome'" == "aiXcam" {
local minY = -.05
local yInc = .05
local maxY = .15	
local ytitle = "Public security AI X surveillance cam"
use "Data/Intermediate/statspai/_fig_FigA13.dta", clear
local outpath = "Output/FigureA13_eventstudy.png"
}


replace id = -id

replace top = beta1 + invttail(4814,.05) * se1
replace bottom = beta1 - invttail(4814,.05) * se1
twoway (scatter beta id if inrange(id,-3,2),color(black))  /// 
			(rcap top bottom id if inrange(id,-3,2),color(black)) ///
			, ytitle(`ytitle') xtitle(" ") ///
					xlabel(-3 "2 Q before" -2 "1 Q before" -1 "Q of unrest" 0 "1 Q after" 1 "2 Q after" 2 "3 Q after", alternate)   yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) /// 
					legend(label(1 "Coefficient") label(2 "90% CI")) ///
					ylabel(`minY'(`yInc')`maxY')
					
	graph export "`outpath'", replace
	

}	

}

/* 3: Figure 3 and Table A.3, different estimators
*/
if "`output'" == "3" | "`output'" == "all" {


local cltext = "place"

****** LASSO *******
* niv: no iv
* "" : IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {

	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)


gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc"

* droptype is instruments
* lassoinf: lasso inference, gen all keep all
local droptypes = "lassoinf"

local events = "event"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {

gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}



collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)



*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
log using "Output/TableA3_xpoivregress.log", replace
** different FEs, differetn outcomes
xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1) verbose

est sto xpoiv
lassocoef (xpoiv, for(blank) xfold(1)) (xpoiv, for(blank) xfold(2)) (xpoiv, for(blank) xfold(3)) (xpoiv, for(blank) xfold(4)) (xpoiv, for(blank) xfold(5)) (xpoiv, for(blank) xfold(6)) (xpoiv, for(blank) xfold(7)) (xpoiv, for(blank) xfold(8)) (xpoiv, for(blank) xfold(9)) (xpoiv, for(blank) xfold(10)), sort(coef, standardized) display(coef)
log close
est sto a`j'
}
local j = `j' + 1

local b1 = _b[blank]
local s1 = _se[blank]
local p1 = e(p)

}

}	
}
}
}


cd "$dir"
****** Parsimonious *******

* niv: no iv
* "" : IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear
*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)


collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max1 max2 max3 max4 max5 min1 min2 min3 min4 min5 mxspd prcp rain sndp snow stp temp1 temp2 temp3 temp4 temp5 thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" // ai lead_police_pc  lead_camera_time_city_pc aiXcam lead_nonpolice_pc
* droptype is instruments
* z: rain thunder gust
local droptypes = "z"

local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {


gen blank = .
replace blank = `event'

if "`droptype'" == "z" {
local instrument "rain gust thunder"
}


* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}
	

collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)
drop if missing(prefecture_city_population)

egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)


*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_gdp##`time' (blank = `instruments'), absorb(place) cl(`cltext') savefirst savefprefix(f`j') ffirst
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1

local b2 = _b[blank]
local s2 = _se[blank]

}


}
}
}
}	


****** LIML & JIVE *******

* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
* lag = 0, default 1 year lead
* else lag is number of quarters to lead AI
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear
*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)


gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc"
* droptype is instruments
* lassoinf: lasso inference, gen all keep all
local droptypes = "lassoinf"

local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}



collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_fiscal_revenue = log(1+prefecture_fiscal_revenue)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)


*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes

ivreghdfe lead_police_pc c.prefecture_gdp##`time' (blank = c.(w1-w18)##c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), absorb(qofd place) cl(place) liml
est sto a`j'
}
local j = `j' + 1

local b3 = _b[blank]
local s3 = _se[blank]

est clear

forv wi1=1/18 {
	forv wi2 = 1/18 {
		gen ww_`wi1'_`wi2' = w`wi1' * w`wi2'
		gen wwI_`wi1'_`wi2' = wI`wi1' * wI`wi2'
	}
}

tab qofd, gen(qofd_)
tab place, gen(place_)

*** Col 2: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
jive lead_police_pc gdp_* qofd_* place_* (blank = ww*), ujive1 robust
est sto a`j'
}
local j = `j' + 1

local b4 = _b[blank]
local s4 = _se[blank]



}

}	

if "`niv'" == "" {
	// local stats = `"stats( N, fmt(3 3 0) label( "N"))"'
	local stats = ""
}




}


}
}




****** LASSO 7 days *******

* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
* lag = 0, default 1 year lead
* else lag is number of quarters to lead AI
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear
*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)


gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference, gen all keep all
local droptypes = "lassoinf"

** timeframe to roll event elsewhere
local windows "7"

local events = "event"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
foreach window in `windows' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}


* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
sort place date

gen event_elsewhere_roll = event_elsewhere
forv ww = 1/`window' {
	by place: replace event_elsewhere_roll = event_elsewhere_roll + event_elsewhere[_n-`ww']
}
replace event_elsewhere = (event_elsewhere_roll > 0) if !missing(event_elsewhere_roll)

local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}


collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)



*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

local b5 = _b[blank]
local s5 = _se[blank]

restore	

}

}	





}
}


}
}



************ OLS ***************

* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max1 max2 max3 max4 max5 min1 min2 min3 min4 min5 mxspd prcp rain sndp snow stp temp1 temp2 temp3 temp4 temp5 thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* z: rain thunder gust
local droptypes = "z"

local events = "event"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
preserve


gen blank = .
replace blank = `event'

if "`droptype'" == "z" {
local instrument "rain gust thunder"
}


* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"


foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}
	

local outcome_text = ""


collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)
drop if missing(prefecture_city_population)


egen prov_by_year = group(prov_fe `time')
su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)



*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_gdp##`time' (blank = `instruments'), absorb(place) cl(`cltext') savefirst savefprefix(f`j') ffirst
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1

local b6 = _b[blank]
local s6 = _se[blank]

restore	

}

}	



}


}
}



gen b = .
gen s = .

forv i = 1/6 {
	replace b = `b`i'' if _n == `i'
	replace s = `s`i'' if _n == `i'
}

save "Data/Intermediate/statspai/_fig_Fig3.dta", replace


** actually make graph
use "Data/Intermediate/statspai/_fig_Fig3.dta", clear
keep b s 

keep if _n <= 6

gen p = ttail(8424,b/s)

gen hicap = b + s*1.64
gen lowcap = b - s*1.64

gen nn = _n * 2

* switch 7 day and JIVE
replace nn = 14 if nn == 4
replace nn = 4 if nn == 10
replace nn = 10 if nn == 14
* switch 7 day and parsimonious
replace nn = 14 if nn == 4
replace nn = 4 if nn == 6
replace nn = 6 if nn == 14
* shift up to make room for OLS
replace nn = nn + 2
replace nn = 2 if nn == 14


twoway  (bar b nn if nn == 2) ///
       (bar b nn if nn == 4 ) ///
       (bar b nn if nn ==6 ) ///
       (bar b nn if nn == 8) ///
	   (bar b nn if nn == 10) ///
	   (bar b nn if nn == 12) ///
       (rcap hicap lowcap nn, color(black)), ///
       legend(order(1 "OLS" 2 "LASSO IV" 3 "Parsimonious IV" 4 "LASSO IV, 7 day window" 5 "LIML" 6 "JIVE" 7 "90% CI") ) ///
       xlabel( 1 " ", noticks) ///
       xtitle("Different estimators") ytitle("Public security AI procurement") ///
	   graphregion(fcolor(white) ilcolor(white) lcolor(white))
gr export "Output/Figure3_altestimator.png", replace	  
	  

	


	
}

/* 4: Figure 4, impact of AI on unrest
*/
if "`output'" == "4" | "`output'" == "all" {
	

use "Data/GDELT_China_contemp_distance_111820.dta", clear

keep if place == place_lag


gen event_lag = protest_lag + demand_lag + threat_lag
gen event = protest + demand + threat

* standard data cleaning
local outcomes "protest demand threat event"

replace distance_centroid = distance_centroid/1000000 // in 1000 KM

gen circle_1000k = (distance_centroid <= 1)
gen sample = 1 if !missing(prefecture_gdp)

drop _m

* LASSO selected instruments
local i3 "c.fog#c.visib  c.frshtt#c.visib  c.rainXEE##c.stpXEE c.snowXEE##c.stpXEE c.stpXEE#c.stpXEE c.stpXEE#c.visibXEE c.fogXEE#c.minXEE c.frshttXEE#c.stpXEE stpXEE"

gen dewXEE = dewp * event_elsewhere
gen fogXEE = fog * event_elsewhere
gen min2XEE = min2 * event_elsewhere
gen temp5XEE = temp5 * event_elsewhere
gen min3XEE = min3 * event_elsewhere
gen stpXEE = stp * event_elsewhere
gen rainXEE = rain * event_elsewhere
gen snowXEE = snow * event_elsewhere
gen visibXEE = visib * event_elsewhere
gen frshttXEE = frshtt * event_elsewhere
gen max1XEE = max1 * event_elsewhere
gen min4XEE = min4 * event_elsewhere
gen max2XEE = max2 * event_elsewhere
gen sndpXEE = sndp * event_elsewhere
gen minXEE = min * event_elsewhere


ivreghdfe event event_elsewhere `i3', absorb(qofd place)
predict event_hat
ivreghdfe protest event_elsewhere `i3', absorb(qofd place)
predict protest_hat
ivreghdfe demand event_elsewhere `i3', absorb(qofd place)
predict demand_hat
ivreghdfe threat event_elsewhere `i3', absorb(qofd place)
predict threat_hat

gen blank_hat = .
gen blank_pol = .


***** demean
su police
replace police = police - r(mean)

su event_hat
replace event_hat = event_hat - r(mean)

replace blank_hat = event_hat
replace blank_pol = blank_hat * police


su event
replace event = (event - r(mean))/r(sd)
su blank_hat
replace blank_hat = (blank_hat - r(mean))/r(sd)

gen pol2 = .
gen blank_pol2 = .



bys prov_eng: egen prov_pg = mean(prefecture_gdp)
replace prefecture_gdp = prov_pg if missing(prefecture_gdp)
replace prefecture_city_population = log(prefecture_city_population)
bys prov_eng: egen prov_pcp = mean(prefecture_city_population)
replace prefecture_city_population = prov_pcp if missing(prefecture_city_population)
gen epop = exp(prefecture_city_population)
bys prov_eng: egen prov_pfr = mean(prefecture_fiscal_revenue)
replace prefecture_fiscal_revenue = prov_pfr if missing(prefecture_fiscal_revenue)

gen year = yofd(dofq(qofd))
egen pref_by_time = group(prov_eng qofd)
egen pref_by_year = group(prov_eng year)

******* short regression

est clear
gen pol = police_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol


ivreghdfe event c.pol##c.blank_hat prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(place) 	

*** data at 2 sd below and above
count
local nn = r(N) + 10
set obs `nn'

forv i = 1/10 {
replace blank_hat = 0.2775 - 0.0365*`i' if _n == _N - `i' + 1
replace qofd = 230 if _n == _N - `i' + 1
replace place = 1 if _n == _N - `i' + 1
replace prefecture_gdp = 252 if _n == _N - `i' + 1
replace pol = 2 if _n == _N - `i' + 1
}

count
local nn = r(N) + 10
set obs `nn'

forv i = 1/10 {
replace blank_hat = 0.2775 - 0.0365*`i' if _n == _N - `i' + 1
replace qofd = 230 if _n == _N - `i' + 1
replace place = 1 if _n == _N - `i' + 1
replace prefecture_gdp = 252 if _n == _N - `i' + 1
replace pol = -2 if _n == _N - `i' + 1
}


cap drop new_y new_sd top bot

predict new_y, xb
predict new_sd, stdp

*** plot
gen top = new_y + 1.646 * new_sd
gen bot = new_y - 1.646 * new_sd

twoway (line new_y blank_hat if pol == 2, color(blue)) ///
	(rcap top bot blank_hat if pol == 2, color(blue%40)) ///
	(line new_y blank_hat if pol == -2, color(red)) ///
	(rcap top bot blank_hat if pol == -2, color(red%40)), ///
	graphregion(fcolor(white) ilcolor(white) lcolor(white)) ytitle("Predicted unrest events, standardized") ///
	legend(order(1 "AI 2 SD above mean" 3 "AI 2 SD below mean")) ///
	xtitle("Conducive weather, standardized")
gr export "Output/Figure4_weatherunrest.png", replace
	



}

/* 5: Figure 5, total effect of politically motivated contract
*/
if "`output'" == "5" | "`output'" == "all" {

set sortseed 2

local pres = "event event_hat_lasso"  

foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

local i = 0
foreach t in   `"GOVERNMENT"' `"BUSINESS"' `"ALL"' { 
	
	local ip = "software"
	dis "`t'"
	
	
	** beta 1 + 2
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe) cl(place)
	addQuarterInter	
		
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_Fig5_`pre'_`t'.dta", replace
	
	restore 
	
	
	** beta 1 + 2
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place scale capital_usd_m, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen scale_`jj' = scale if year == `jj'
		replace scale_`jj' = 0 if missing(scale_`jj')
		gen capital_usd_m_`jj' = capital_usd_m if year == `jj'
		replace capital_usd_m_`jj' = 0 if missing(capital_usd_m_`jj')
	}
	
	* inverse covariance matrix
	gen wgt = 1
	gen stdgroup = 1
	local vlist = ""
	foreach var of varlist scale_* capital_usd_m_* {
	local vlist = "`vlist' `var'"	
	}
	di "`vlist'"
	make_index_gr firm wgt stdgroup  `vlist'
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data index_firm, absorb(sub_fe) cl(place)
	addQuarterInter	
		
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_Fig5_`pre'_`t'_b1.dta", replace
	
	restore 
	
	
	
	
	local i = `i' + 1
}
	
}

local pre = "event"
foreach t in `"GOVERNMENT"' `"BUSINESS"' `"ALL"' {
	use "Data/Intermediate/statspai/_fig_Fig5_`pre'_`t'.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .3
	ren (beta top bottom) (beta_niv_b12 top_niv_b12 bottom_niv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig5_`pre'_hat_lasso_`t'.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b12 top_iv_b12 bottom_iv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig5_`pre'_`t'_b1.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_niv_b1 top_niv_b1 bottom_niv_b1)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig5_`pre'_hat_lasso_`t'_b1.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .3 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b1 top_iv_b1 bottom_iv_b1)
	
	drop if id > 8.5
	
	twoway (scatter beta_niv_b12 id if inrange(id,-8.5,34.5),color(black%25))  /// 
			(rcap top_niv_b12 bottom_niv_b12 id if inrange(id,-8.5,34.5),color(black%25)) /// 
			(scatter beta_iv_b12 id if inrange(id,-8.5,34.5),color(black))  /// 
			(rcap top_iv_b12 bottom_iv_b12 id if inrange(id,-8.5,34.5),color(black)) ///
			(scatter beta_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25))  /// 
			(rcap top_niv_b1 bottom_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25)) /// 
			(scatter beta_iv_b1 id if inrange(id,-8.5,34.5),color(blue))  /// 
			(rcap top_iv_b1 bottom_iv_b1 id if inrange(id,-8.5,34.5),color(blue)) ///
			, legend(order(1 "OLS" 3 "IV" 5 "OLS, controls" 7 "IV, controls")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white))  
					
	if "`t'" == "ALL" {
		graph export "Output/Figure5_PanelA_all.png", replace
	}
	else if "`t'" == "GOVERNMENT" {
		graph export "Output/Figure5_PanelB_gov.png", replace
	}
	else if "`t'" == "BUSINESS" {
		graph export "Output/Figure5_PanelC_com.png", replace
	}
	
}

	
}	

/* 6: Figure 6, Fig A.11, Fig A.14, differential effect of politically motivated contract
*/
if "`output'" == "6" | "`output'" == "all" {

set sortseed 2

local pres = "event event_hat_lasso"

foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

local i = 0
foreach t in   `"GOVERNMENT"' `"BUSINESS"' `"ALL"' { 
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""  // count number of software  
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_Fig6_`pre'_`t'.dta", replace
	
	restore 
	local i = `i' + 1
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""  // count number of software  
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place capital_usd_m scale, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
		gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen scale_`jj' = scale if year == `jj'
		replace scale_`jj' = 0 if missing(scale_`jj')
		gen capital_usd_m_`jj' = capital_usd_m if year == `jj'
		replace capital_usd_m_`jj' = 0 if missing(capital_usd_m_`jj')
	}
	
	* inverse covariance matrix
	gen wgt = 1
	gen stdgroup = 1
	local vlist = ""
	foreach var of varlist scale_* capital_usd_m_* {
	local vlist = "`vlist' `var'"	
	}
	di "`vlist'"
	make_index_gr firm wgt stdgroup  `vlist'
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data index_firm, absorb(sub_fe qofd) cl(place)
		
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_Fig6_`pre'_`t'_b1.dta", replace
	
	restore 
	local i = `i' + 1
}
	
}



local pre = "event"
foreach t in `"GOVERNMENT"' `"BUSINESS"' `"ALL"' {
	use "Data/Intermediate/statspai/_fig_Fig6_`pre'_`t'.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .3
	ren (beta top bottom) (beta_niv_b12 top_niv_b12 bottom_niv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig6_`pre'_hat_lasso_`t'.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b12 top_iv_b12 bottom_iv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig6_`pre'_`t'_b1.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_niv_b1 top_niv_b1 bottom_niv_b1)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_Fig6_`pre'_hat_lasso_`t'_b1.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .3 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b1 top_iv_b1 bottom_iv_b1)
	
	drop if id > 8.5
	
	twoway (scatter beta_niv_b12 id if inrange(id,-8.5,34.5),color(black%25))  /// 
			(rcap top_niv_b12 bottom_niv_b12 id if inrange(id,-8.5,34.5),color(black%25)) /// 
			(scatter beta_iv_b12 id if inrange(id,-8.5,34.5),color(black))  /// 
			(rcap top_iv_b12 bottom_iv_b12 id if inrange(id,-8.5,34.5),color(black)) ///
			(scatter beta_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25))  /// 
			(rcap top_niv_b1 bottom_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25)) /// 
			(scatter beta_iv_b1 id if inrange(id,-8.5,34.5),color(blue))  /// 
			(rcap top_iv_b1 bottom_iv_b1 id if inrange(id,-8.5,34.5),color(blue)) ///
			, legend(order(1 "OLS" 3 "IV" 5 "OLS, controls" 7 "IV, controls")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) 
	
	if "`t'" == "ALL" {
		graph export "Output/Figure6_PanelA_all.png", replace
	}
	else if "`t'" == "GOVERNMENT" {
		graph export "Output/Figure6_PanelB_gov.png", replace
	}
	else if "`t'" == "BUSINESS" {
		graph export "Output/Figure6_PanelC_com.png", replace
	}
}




local pres = "event event_hat_lasso" // protest demand threat event protest protest_sum demand_sum threat_sum event_sum protest_hat demand_hat threat_hat  protest_hat_sum demand_hat_sum threat_hat_sum event_hat_sum

foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

local i = 0
foreach t in  `"GOVSURVEILLANCE"' `"AI-COMPLEMENTARY"'  { 
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""  // count number of software  
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	addQuarterInter	
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_FigA11_`pre'_`t'_dd.dta", replace
	
	restore 
	local i = `i' + 1
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""  // count number of software  
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place capital_usd_m scale, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
		gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen scale_`jj' = scale if year == `jj'
		replace scale_`jj' = 0 if missing(scale_`jj')
		gen capital_usd_m_`jj' = capital_usd_m if year == `jj'
		replace capital_usd_m_`jj' = 0 if missing(capital_usd_m_`jj')
	}
	
	* inverse covariance matrix
	gen wgt = 1
	gen stdgroup = 1
	local vlist = ""
	foreach var of varlist scale_* capital_usd_m_* {
	local vlist = "`vlist' `var'"	
	}
	di "`vlist'"
	make_index_gr firm wgt stdgroup  `vlist'
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first  ///
		i.with_contract_dummy qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data index_firm, absorb(sub_fe qofd) cl(place)
	
	addQuarterInter
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_FigA11_`pre'_`t'_b1_dd.dta", replace
	
	restore 
	local i = `i' + 1
}
	
}

local pre = "event"
foreach t in  `"AI-COMPLEMENTARY"'  `"GOVSURVEILLANCE"' {
	use "Data/Intermediate/statspai/_fig_FigA11_`pre'_`t'_dd.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .3
	ren (beta top bottom) (beta_niv_b12 top_niv_b12 bottom_niv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA11_`pre'_hat_lasso_`t'_dd.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b12 top_iv_b12 bottom_iv_b12)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA11_`pre'_`t'_b1_dd.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .1 if !missing(beta1)
	ren (beta1 top bottom) (beta_niv_b1 top_niv_b1 bottom_niv_b1)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA11_`pre'_hat_lasso_`t'_b1_dd.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .3 if !missing(beta1)
	ren (beta1 top bottom) (beta_iv_b1 top_iv_b1 bottom_iv_b1)
	
	drop if id > 8.5
	
	twoway (scatter beta_niv_b12 id if inrange(id,-8.5,34.5),color(black%25))  /// 
			(rcap top_niv_b12 bottom_niv_b12 id if inrange(id,-8.5,34.5),color(black%25)) /// 
			(scatter beta_iv_b12 id if inrange(id,-8.5,34.5),color(black))  /// 
			(rcap top_iv_b12 bottom_iv_b12 id if inrange(id,-8.5,34.5),color(black)) ///
			(scatter beta_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25))  /// 
			(rcap top_niv_b1 bottom_niv_b1 id if inrange(id,-8.5,34.5),color(blue%25)) /// 
			(scatter beta_iv_b1 id if inrange(id,-8.5,34.5),color(blue))  /// 
			(rcap top_iv_b1 bottom_iv_b1 id if inrange(id,-8.5,34.5),color(blue)) ///
			, legend(order(1 "OLS" 3 "IV" 5 "OLS, controls" 7 "IV, controls")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) 
					
	if "`t'" == "GOVSURVEILLANCE" {
		graph export "Output/FigureA11_govsurveillance.png", replace
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
		graph export "Output/FigureA14_datacomplementary.png", replace
	}
	
}
	
}	

/* 7: Table 1, summary table
*/
if "`output'" == "7" | "`output'" == "all" {

	
*** Panel A: unrest data

use "Data/GDELT_China_072920.dta", clear

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 

gen qofd = qofd(mdy(month,1,year))

* collapse to year-prefecture level
collapse (sum) protest demand threat, by(pref_eng prov_eng qofd)
gen event = protest + demand + threat


* write file with summary stats

tempname fh 
file open `fh' using "Output/Table1_PanelA_unrest.tex", write text replace


su event, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "All events (per prefecture-quarter) & `m1' & `s1' \\" _newline

su protest, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Protests & `m1' & `s1'  \\" _newline

su demand, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Demands & `m1' & `s1'  \\" _newline

su threat, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Threats & `m1' & `s1'  \\" _newline

file close `fh'
 
 
*** Panel B: contracts
use "Data/baseline_data_04292020", clear

collapse (count) sub_fe, by(url)

replace sub_fe = (!missing(sub_fe))
tempfile firsts
save `firsts'

use "Data/contracts_gdp_pop_admin-unit.dta", clear

merge 1:1 url using `firsts', keep(1 3) nogen

gen first_public = (police == 1 & sub_fe == 1)

gen qofd = qofd(mdy(month,1,year))

drop if city == ""

collapse (count) contracts=police (sum) police first_public, by(prov city qofd)

egen place = group(prov city)
tsset place qofd
tsfill 

replace contracts = 0 if missing(contracts)
replace police = 0 if missing(police)
replace first_public = 0 if missing(first_public)

tempname fh 
file open `fh' using "Output/Table1_PanelB_contracts.tex", write text replace


* all contracts
su contracts, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "All AI contracts (per prefecture-quarter) & `m1' & `s1'  \\" _newline

* non-public security contracts
gen np = contracts - police
su np, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Non-public security contracts & `m1' & `s1'  \\" _newline

* public security contracts
su police, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Public security contracts & `m1' & `s1'  \\" _newline

* first public security contracts
su first_public, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad First public security contracts & `m1' & `s1'  \\" _newline


use "Data/Hardware_Capacities_20201020", clear

gen qofd = qofd(mdy(month,1,year))

gen cam_lag = camera_time_city[_n+1] if city == city[_n+1]
replace cam_lag = 0 if missing(cam_lag)
replace camera_time_city = camera_time_city - cam_lag

collapse (sum) camera_time_city, by(prov city qofd)

su camera_time_city, d

local m1 = string(r(mean),"%9.0fc")
local s1 = string(r(sd),"%9.0fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "Surveillance cameras (per prefecture-quarter) & `m1' & `s1'  \\" _newline

use "Data/police_new_recruit.dta", clear


su job_count, d

local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "Police hires (per prefecture-year) & `m1' & `s1'  \\" _newline


file close `fh'
 


*** Panel C: software
use "Data/pd_meta_screening_by_keywords.dta", clear

gen surveillance_dummy = (surveillance >= 1)

ren mergeid mergeID

tempfile surveillance
save `surveillance'

use "Data/baseline_data_04292020", clear

keep if software_ID != ""
merge m:1 mergeID using `surveillance', keep(1 3) nogen

gen gov_soft = (Customers_pred == "GOVERNMENT")
gen bus_soft = (Customers_pred == "BUSINESS")
gen data_soft = (Functions_pred == "AI-COMPLEMENTARY")

gen qofd = qofd(mdy(month,1,year))

collapse (count) software=gov_soft (sum) surveillance_dummy gov_soft bus_soft data_soft (mean) quarters_to_first, by(qofd sub_fe)


tempname fh 
file open `fh' using "Output/Table1_PanelC_software.tex", write text replace


su software, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "All software (per firm-quarter) & `m1' & `s1' \\" _newline

su gov_soft, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Government software & `m1' & `s1'  \\" _newline

su bus_soft, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Commercial software & `m1' & `s1'  \\" _newline


file close `fh'

**** cumulative pre-contract software
drop if quarters_to_first > 0 // keeps firms with no contract
collapse (sum) software surveillance_dummy gov_soft bus_soft data_soft, by(sub_fe)


tempname fh 
file open `fh' using "Output/Table1_PanelD_softwareprecontract.tex", write text replace


su software, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "All software (per firm) & `m1' & `s1' \\" _newline

su gov_soft, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Government software & `m1' & `s1'  \\" _newline

su bus_soft, d
local m1 = string(r(mean),"%9.3fc")
local s1 = string(r(sd),"%9.3fc")
local p10 = string(r(p10),"%9.3fc")
local p90 = string(r(p90),"%9.3fc")
file write `fh' "\qquad Commercial software & `m1' & `s1'  \\" _newline

file close `fh'



}

/* 8: Table 2, effect of unrest on AI
*/
if "`output'" == "8" | "`output'" == "all" {


local cltext = "place"


****** OLS *******
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"

forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop  contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max1 max2 max3 max4 max5 min1 min2 min3 min4 min5 mxspd prcp rain sndp snow stp temp1 temp2 temp3 temp4 temp5 thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* z: rain thunder gust
local droptypes = "z"

local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
preserve


gen blank = .
replace blank = `event'

if "`droptype'" == "z" {
local instrument "rain gust thunder"
}


* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}

local outcome_text = ""

collapse (sum) blank `instruments' (mean) `outcome'  prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)
drop if missing(prefecture_city_population)


egen prov_by_year = group(prov_fe `time')


sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)



qui save "Data/Intermediate/statspai/s8_ols_`outcome'.dta", replace  // [EXPORT HOOK]
*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_gdp##`time' (blank = `instruments'), absorb(place) cl(`cltext') savefirst savefprefix(f`j') ffirst
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_city_population##`time' (blank = `instruments'), absorb(place) cl(`cltext') savefirst savefprefix(f`j') ffirst
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_fiscal_revenue##`time' (blank = `instruments'), absorb(place) cl(`cltext') savefirst savefprefix(f`j') ffirst
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1


*** Col 4: AI stock t-2 ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2, absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `instruments'), absorb(place `time') cl(`cltext') 
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' AI_stock_t2, absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
ivreghdfe `outcome' c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `instruments'), absorb(place `time') cl(`cltext') 
est sto a`j'
estadd local ivF = string(e(widstat),"%9.3fc")
mat first = e(first)
estadd scalar apf = round(first[rownumb(first,"APF"),colnumb(first,"blank")],.1)
su `outcome' if e(sample)
estadd local dvmean = string(r(mean),"%9.3fc")
estadd local dvsd = string(r(sd),"%9.3fc")
}
local j = `j' + 1

restore	

}

}	

if "`niv'" == "" {
	local stats = `""'
}

estout a* using "Output/Table2_PanelA_ols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest  $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'


}


}
}


****** LASSO *******


* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear


*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)


gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp

local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc"
* droptype is instruments
* lassoinf: lasso inference, gen all keep all
local droptypes = "lassoinf"

local events = "event"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
preserve


gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}


collapse (sum) blank `instruments' (mean) `outcome' `o2' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')


su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)


qui save "Data/Intermediate/statspai/s8_lasso_`outcome'.dta", replace  // [EXPORT HOOK]
*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) 
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) 
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) 
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18)#
est sto a`j'
}
local j = `j' + 1


*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress lead_police_pc  AI_stock_t2 (blank = c.(w1-w18)
est sto a`j'
}
local j = `j' + 1

restore	

}

}	

if "`niv'" == "" {
	local stats = ""
}

estout a* using "Output/Table2_PanelB_iv.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'


}


}
}



	
}

/* 9: Table 3, effect of unrest on cam/AI
*/
if "`output'" == "9" | "`output'" == "all" {

local cltext = "place"

****** OLS *******
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
* lag = 0, default 1 year lead
* else lag is number of quarters to lead AI
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_camera_time_city_pc aiXcam" 
* droptype is instruments
* z: rain thunder gust
* lassoinf: lasso gen all keep all
local droptypes = "z" // lassoinf

local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
preserve

if "`outcome'" == "lead_camera_time_city_pc" {
	local outcome_text = ""
}
else if "`outcome'" == "aiXcam" {
	local outcome_text = "aiXcam"	
	gen aiXcam = lead_police_pc * lead_camera_time_city_pc
}


gen blank = .
replace blank = `event'

if "`droptype'" == "z" {
local instrument "rain gust thunder"
}
else if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}
else {
foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}
}

if "`outcome'" != "lead_police_pc" {
	local o2 = "lead_police_pc"
}
else {
	local o2 = ""
}


collapse (sum) blank `instruments' (mean) `outcome' `o2' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

qui save "Data/Intermediate/statspai/s9_ols_`outcome'.dta", replace  // [EXPORT HOOK]
*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome'  AI_stock_t2 (blank = c.(w1-w18) c.(w
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' AI_stock_t2 (blank = c.(w1-w18) c.(wI
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`outcome'" == "lead_camera_time_city_pc" {
estout a* using "Output/Table3_PanelA.1_olscam.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
else if "`outcome'" == "aiXcam" {
estout a* using "Output/Table3_PanelB.1_olsaicam.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
est clear


}	



}


}
}


****** LASSO *******
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
* lag = 0, default 1 year lead
* else lag is number of quarters to lead AI
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_camera_time_city_pc aiXcam" 
* droptype is instruments
* z: rain thunder gust
* lassoinf: lasso gen all keep all
local droptypes = "lassoinf" // lassoinf

local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
preserve

if "`outcome'" == "lead_camera_time_city_pc" {
	local outcome_text = ""
}
else if "`outcome'" == "aiXcam" {
	local outcome_text = "aiXcam"	
	gen aiXcam = lead_police_pc * lead_camera_time_city_pc
}


gen blank = .
replace blank = `event'

if "`droptype'" == "z" {
local instrument "rain gust thunder"
}
else if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}
else {
foreach x in `instrument' {
gen `x'I = `x' * event_elsewhere
local instruments = "`instruments' `x'I"
}
}

if "`outcome'" != "lead_police_pc" {
	local o2 = "lead_police_pc"
}
else {
	local o2 = ""
}


collapse (sum) blank `instruments' (mean) `outcome' `o2' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

qui save "Data/Intermediate/statspai/s9_lasso_`outcome'.dta", replace  // [EXPORT HOOK]
*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' (blank = c.(w1-w18) c.(wI1-wI18)), co
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome'  AI_stock_t2 (blank = c.(w1-w18) c.(w
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
qui regress blank  // [EXPORT] replaces: xpoivregress `outcome' AI_stock_t2 (blank = c.(w1-w18) c.(wI
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`outcome'" == "lead_camera_time_city_pc" {
estout a* using "Output/Table3_PanelA.2_ivcam.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
else if "`outcome'" == "aiXcam" {
estout a* using "Output/Table3_PanelB.2_ivaicam.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
est clear


}	



}


}
}

	
	
	
}

/* 10: Table 4, 5, A.5, A.6, and A.7 effect of AI on unrest
*/
if "`output'" == "10" | "`output'" == "all" {

local cltext = "place"

*** Table 4A, 5A, Table A.5
forv lag = 1/1 {
	
use "Data/GDELT_China_contemp_distance_111820.dta", clear

keep if place == place_lag


gen event_lag = protest_lag + demand_lag + threat_lag
gen event = protest + demand + threat

* standard data cleaning
local outcomes "protest demand threat event"

replace distance_centroid = distance_centroid/1000000 // in 1000 KM

gen circle_1000k = (distance_centroid <= 1)
gen sample = 1 if !missing(prefecture_gdp)

drop _m

local i3 "c.fog#c.visib  c.frshtt#c.visib  c.rainXEE##c.stpXEE c.snowXEE##c.stpXEE c.stpXEE#c.stpXEE c.stpXEE#c.visibXEE c.fogXEE#c.minXEE c.frshttXEE#c.stpXEE stpXEE"

gen dewXEE = dewp * event_elsewhere
gen fogXEE = fog * event_elsewhere
gen min2XEE = min2 * event_elsewhere
gen temp5XEE = temp5 * event_elsewhere
gen min3XEE = min3 * event_elsewhere
gen stpXEE = stp * event_elsewhere
gen rainXEE = rain * event_elsewhere
gen snowXEE = snow * event_elsewhere
gen visibXEE = visib * event_elsewhere
gen frshttXEE = frshtt * event_elsewhere
gen max1XEE = max1 * event_elsewhere
gen min4XEE = min4 * event_elsewhere
gen max2XEE = max2 * event_elsewhere
gen sndpXEE = sndp * event_elsewhere
gen minXEE = min * event_elsewhere

qui save "Data/Intermediate/statspai/s10_raw_b1.dta", replace  // [EXPORT HOOK]
ivreghdfe event event_elsewhere `i3', absorb(qofd place)
predict event_hat
ivreghdfe protest event_elsewhere `i3', absorb(qofd place)
predict protest_hat
ivreghdfe demand event_elsewhere `i3', absorb(qofd place)
predict demand_hat
ivreghdfe threat event_elsewhere `i3', absorb(qofd place)
predict threat_hat


gen blank_hat = .
gen blank_pol = .


***** demean


su police
replace police = police - r(mean)

su event_hat
replace event_hat = event_hat - r(mean)
su protest_hat
replace protest_hat = protest_hat - r(mean)
su demand_hat
replace demand_hat = demand_hat - r(mean)
su threat_hat
replace threat_hat = threat_hat - r(mean)

replace blank_hat = event_hat
replace blank_pol = blank_hat * police

su event
replace event = (event - r(mean))/r(sd)
su blank_hat
replace blank_hat = (blank_hat - r(mean))/r(sd)


** IHS version
gen asinh_nonpol_pc = asinh(lead_nonpolice_pc)

gen pol = .
gen pol2 = .
gen blank_pol2 = .



bys prov_eng: egen prov_pg = mean(prefecture_gdp)
replace prefecture_gdp = prov_pg if missing(prefecture_gdp)
replace prefecture_city_population = log(prefecture_city_population)
bys prov_eng: egen prov_pcp = mean(prefecture_city_population)
replace prefecture_city_population = prov_pcp if missing(prefecture_city_population)
gen epop = exp(prefecture_city_population)
bys prov_eng: egen prov_pfr = mean(prefecture_fiscal_revenue)
replace prefecture_fiscal_revenue = prov_pfr if missing(prefecture_fiscal_revenue)

gen year = yofd(dofq(qofd))
egen pref_by_time = group(prov_eng qofd)
egen pref_by_year = group(prov_eng year)

******* short

est clear
replace pol = police_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol


ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_Table4_PanelA_ai.dta", replace  // [EXPORT HOOK]
estout a* using "Output/Table4_PanelA_ai.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

replace pol2 = lead_nonpolice_pc
su pol2
replace pol2 = (pol2 - r(mean))/r(sd)
replace blank_pol2 = blank_hat * pol2

ivreghdfe event pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a2

ivreghdfe event pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe event pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe event pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a5

qui save "Data/Intermediate/statspai/s10_Table5_PanelA_nonpublic.dta", replace  // [EXPORT HOOK]
estout a* using "Output/Table5_PanelA_nonpublic.tex", ///
replace style(tex) keep(blank_hat pol2 blank_pol2) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label


*** protest
su protest
replace protest = (protest - r(mean))/r(sd)
est clear
replace pol = police_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe protest pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe protest pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe protest pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe protest pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_TableA5_PanelA.1_aiprotest.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelA.1_aiprotest.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

est clear

replace pol2 = lead_nonpolice_pc
su pol2
replace pol2 = (pol2 - r(mean))/r(sd)
replace blank_pol2 = blank_hat * pol2

ivreghdfe protest pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a7

ivreghdfe protest pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a8

ivreghdfe protest pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a9

ivreghdfe protest pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a10

qui save "Data/Intermediate/statspai/s10_TableA5_PanelB.1_nonpublicprotest.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelB.1_nonpublicprotest.tex", ///
replace style(tex) keep( blank_hat pol2 blank_pol2) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

*** demand
su demand
replace demand = (demand - r(mean))/r(sd)
est clear
replace pol = police_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe demand pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe demand pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe demand pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe demand pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_TableA5_PanelA.2_aidemand.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelA.2_aidemand.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

est clear

replace pol2 = lead_nonpolice_pc
su pol2
replace pol2 = (pol2 - r(mean))/r(sd)
replace blank_pol2 = blank_hat * pol2

ivreghdfe demand pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a7

ivreghdfe demand pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a8

ivreghdfe demand pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a9

ivreghdfe demand pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a10

qui save "Data/Intermediate/statspai/s10_TableA5_PanelB.2_nonpublicdemand.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelB.2_nonpublicdemand.tex", ///
replace style(tex) keep( blank_hat pol2 blank_pol2) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label


*** threat
su threat
replace threat = (threat - r(mean))/r(sd)
est clear
replace pol = police_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe threat pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe threat pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe threat pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe threat pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_TableA5_PanelA.3_aithreat.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelA.3_aithreat.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

est clear

replace pol2 = lead_nonpolice_pc
su pol2
replace pol2 = (pol2 - r(mean))/r(sd)
replace blank_pol2 = blank_hat * pol2

ivreghdfe threat pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a7

ivreghdfe threat pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a8

ivreghdfe threat pol2 blank_hat blank_pol2 prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a9

ivreghdfe threat pol2 blank_hat blank_pol2 prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a10

qui save "Data/Intermediate/statspai/s10_TableA5_PanelB.3_nonpublicprotest.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA5_PanelB.3_nonpublicprotest.tex", ///
replace style(tex) keep(blank_hat pol2 blank_pol2) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{AI}_{t-1}$" pol "Public security procurement stock $ \text{AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

	
}

*** Table 4B, A.6
forv lag = 1/1 {
	
use "Data/GDELT_China_contemp_distance_111820.dta", clear

keep if place == place_lag


gen event_lag = protest_lag + demand_lag + threat_lag
gen event = protest + demand + threat

* standard data cleaning
local outcomes "protest demand threat event"

replace distance_centroid = distance_centroid/1000000 // in 1000 KM

gen circle_1000k = (distance_centroid <= 1)
gen sample = 1 if !missing(prefecture_gdp)

drop _m

local i3 "c.fog#c.visib  c.frshtt#c.visib  c.rainXEE##c.stpXEE c.snowXEE##c.stpXEE c.stpXEE#c.stpXEE c.stpXEE#c.visibXEE c.fogXEE#c.minXEE c.frshttXEE#c.stpXEE stpXEE"

gen dewXEE = dewp * event_elsewhere
gen fogXEE = fog * event_elsewhere
gen min2XEE = min2 * event_elsewhere
gen temp5XEE = temp5 * event_elsewhere
gen min3XEE = min3 * event_elsewhere
gen stpXEE = stp * event_elsewhere
gen rainXEE = rain * event_elsewhere
gen snowXEE = snow * event_elsewhere
gen visibXEE = visib * event_elsewhere
gen frshttXEE = frshtt * event_elsewhere
gen max1XEE = max1 * event_elsewhere
gen min4XEE = min4 * event_elsewhere
gen max2XEE = max2 * event_elsewhere
gen minXEE = min * event_elsewhere


qui save "Data/Intermediate/statspai/s10_raw_b2.dta", replace  // [EXPORT HOOK]
ivreghdfe event `i3' event_elsewhere, absorb(qofd place)
predict event_hat
ivreghdfe protest event_elsewhere `i3', absorb(qofd place)
predict protest_hat
ivreghdfe demand event_elsewhere `i3', absorb(qofd place)
predict demand_hat
ivreghdfe threat event_elsewhere `i3', absorb(qofd place)
predict threat_hat


gen blank_hat = .
gen blank_pol = .


***** demean


su police
replace police = police - r(mean)
su lead_camera_time_city_pc
replace lead_camera_time_city_pc = (lead_camera_time_city_pc - r(mean))/r(sd)

su event_hat
replace event_hat = event_hat - r(mean)
su protest_hat
replace protest_hat = protest_hat - r(mean)
su demand_hat
replace demand_hat = demand_hat - r(mean)
su threat_hat
replace threat_hat = threat_hat - r(mean)


replace blank_hat = event_hat
replace blank_pol = blank_hat * police

su event
replace event = (event - r(mean))/r(sd)
su blank_hat
replace blank_hat = (blank_hat - r(mean))/r(sd)


gen pol = .
gen pol2 = .
gen blank_pol2 = .



bys prov_eng: egen prov_pg = mean(prefecture_gdp)
replace prefecture_gdp = prov_pg if missing(prefecture_gdp)
replace prefecture_city_population = log(prefecture_city_population)
bys prov_eng: egen prov_pcp = mean(prefecture_city_population)
replace prefecture_city_population = prov_pcp if missing(prefecture_city_population)
gen epop = exp(prefecture_city_population)
bys prov_eng: egen prov_pfr = mean(prefecture_fiscal_revenue)
replace prefecture_fiscal_revenue = prov_pfr if missing(prefecture_fiscal_revenue)

gen year = yofd(dofq(qofd))
egen pref_by_time = group(prov_eng qofd)
egen pref_by_year = group(prov_eng year)

******* short

est clear
replace pol = police_pc * lead_camera_time_city_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol


ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_Table4_PanelB_aicam.dta", replace  // [EXPORT HOOK]
estout a* using "Output/Table4_PanelB_aicam.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ public security $ \text{cam. and AI}_{t-1}$" pol "Public security procurement stock $ \text{cam. and AI}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label



********** cameras
est clear
replace pol = lead_camera_time_city_pc
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a2

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a3

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext')
est sto a4

ivreghdfe event pol blank_hat blank_pol prefecture_gdp epop c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(`cltext') 
est sto a5

qui save "Data/Intermediate/statspai/s10_TableA6_cam.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA6_cam.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ surveillance $ \text{cam}_{t-1}$" pol "Surveillance camera procurement stock $ \text{cam}_{t-1}$" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label




}

*** Table 5B
forv lag = 1/1 {
use "Data/GDELT_China_contemp_distance_111820.dta", clear

keep if place == place_lag


gen event_lag = protest_lag + demand_lag + threat_lag
gen event = protest + demand + threat

* standard data cleaning
local outcomes "protest demand threat event"

replace distance_centroid = distance_centroid/1000000 // in 1000 KM

gen circle_1000k = (distance_centroid <= 1)

local i3 "c.fog#c.visib c.frshtt#c.visib c.dewXEE#c.fogXEE c.min2XEE#c.temp5XEE c.min3XEE##c.stpXEE c.rainXEE##c.stpXEE c.snowXEE##c.stpXEE c.stpXEE#c.stpXEE c.stpXEE#c.visibXEE c.frshttXEE#c.stpXEE c.max1XEE#c.min4XEE c.max2XEE#c.stpXEE c.stpXEE"

gen dewXEE = dewp * event_elsewhere
gen fogXEE = fog * event_elsewhere
gen min2XEE = min2 * event_elsewhere
gen temp5XEE = temp5 * event_elsewhere
gen min3XEE = min3 * event_elsewhere
gen stpXEE = stp * event_elsewhere
gen rainXEE = rain * event_elsewhere
gen snowXEE = snow * event_elsewhere
gen visibXEE = visib * event_elsewhere
gen frshttXEE = frshtt * event_elsewhere
gen max1XEE = max1 * event_elsewhere
gen min4XEE = min4 * event_elsewhere
gen max2XEE = max2 * event_elsewhere

qui save "Data/Intermediate/statspai/s10_raw_b3.dta", replace  // [EXPORT HOOK]
ivreghdfe event event_elsewhere `i3', absorb(qofd place)
predict event_hat
ivreghdfe protest event_elsewhere `i3', absorb(qofd place)
predict protest_hat
ivreghdfe demand event_elsewhere `i3', absorb(qofd place)
predict demand_hat
ivreghdfe threat event_elsewhere `i3', absorb(qofd place)
predict threat_hat


gen blank_hat = .
gen blank_pol = .

***** demean


su police
replace police = police - r(mean)

su event_hat
replace event_hat = event_hat - r(mean)
su protest_hat
replace protest_hat = protest_hat - r(mean)
su demand_hat
replace demand_hat = demand_hat - r(mean)
su threat_hat
replace threat_hat = threat_hat - r(mean)

replace blank_hat = event_hat
replace blank_pol = blank_hat * police

********* regression
est clear
su event
replace event = (event - r(mean))/r(sd)
su blank_hat
replace blank_hat = (blank_hat - r(mean))/r(sd)

gen year = year(dofq(qofd))

* lagged unrest
gen pol = protest_t1 + demand_t1 + threat_t1
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a1

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a2

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a3

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a4

qui save "Data/Intermediate/statspai/s10_Table5_PanelB_pastunrest.dta", replace  // [EXPORT HOOK]
estout a* using "Output/Table5_PanelB_pastunrest.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol) ///
 varlabels(blank_pol "Conducive weather $\times$ $ \text{unrest}_{t-1}$" pol "$ \text{Unrest}_{t-1}$" blank_hat "Conducive weather")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label




}

*** Table A.7
forv lag = 1/1 {

use "Data/GDELT_China_contemp_distance_111820.dta", clear

keep if place == place_lag

gen year = yofd(dofq(qofd))

merge n:1 year merge_pref using "Data/cityPS_history_allcities_by2015_finalrestat_temp.dta",keep(1 3) nogen

gen event_lag = protest_lag + demand_lag + threat_lag
gen event = protest + demand + threat

* standard data cleaning
local outcomes "protest demand threat event"

replace distance_centroid = distance_centroid/1000000 // in 1000 KM

gen circle_1000k = (distance_centroid <= 1)

drop _m


local i3 "c.fog#c.visib c.frshtt#c.visib c.dewXEE#c.fogXEE c.min2XEE#c.temp5XEE c.min3XEE#c.stpXEE c.rainXEE##c.stpXEE c.snowXEE#c.stpXEE c.stpXEE#c.stpXEE c.stpXEE#c.visibXEE c.frshttXEE#c.stpXEE c.max1XEE#c.min4XEE c.max2XEE#c.stpXEE c.stpXEE"

gen dewXEE = dewp * event_elsewhere
gen fogXEE = fog * event_elsewhere
gen min2XEE = min2 * event_elsewhere
gen temp5XEE = temp5 * event_elsewhere
gen min3XEE = min3 * event_elsewhere
gen stpXEE = stp * event_elsewhere
gen rainXEE = rain * event_elsewhere
gen snowXEE = snow * event_elsewhere
gen visibXEE = visib * event_elsewhere
gen frshttXEE = frshtt * event_elsewhere
gen max1XEE = max1 * event_elsewhere
gen min4XEE = min4 * event_elsewhere
gen max2XEE = max2 * event_elsewhere

qui save "Data/Intermediate/statspai/s10_raw_b4.dta", replace  // [EXPORT HOOK]
ivreghdfe event event_elsewhere `i3', absorb(qofd place)
predict event_hat
ivreghdfe protest event_elsewhere `i3', absorb(qofd place)
predict protest_hat
ivreghdfe demand event_elsewhere `i3', absorb(qofd place)
predict demand_hat
ivreghdfe threat event_elsewhere `i3', absorb(qofd place)
predict threat_hat

gen blank_hat = .
gen blank_pol = .

***** demean


su police
replace police = police - r(mean)

su event_hat
replace event_hat = event_hat - r(mean)
su protest_hat
replace protest_hat = protest_hat - r(mean)
su demand_hat
replace demand_hat = demand_hat - r(mean)
su threat_hat
replace threat_hat = threat_hat - r(mean)

replace blank_hat = event_hat
replace blank_pol = blank_hat * police

su event
replace event = (event - r(mean))/r(sd)
su blank_hat
replace blank_hat = (blank_hat - r(mean))/r(sd)

gen pol = .
gen pol2 = .
gen blank_pol2 = .

******* nonIHS, bw 6
replace pol = prt_hat1
su pol
replace pol = (pol - r(mean))/r(sd)
replace blank_pol = blank_hat * pol

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a1

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_city_population##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a2

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a3

ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.prefecture_gdp##qofd c.prefecture_city_population##qofd c.prefecture_fiscal_revenue##qofd  if circle_1000k == 1, absorb(qofd place) cl(place)
est sto a4


qui save "Data/Intermediate/statspai/s10_TableA7_incentive.dta", replace  // [EXPORT HOOK]
estout a* using "Output/TableA7_incentive.tex", ///
replace style(tex) keep(pol blank_hat blank_pol) ///
order(blank_hat pol blank_pol pol2 blank_pol2) ///
 varlabels(blank_pol "Conducive weather $\times$ politician incentive" pol "Politician incentive" blank_hat "Conducive weather" blank_pol2 "Conducive weather $\times$ non-public security $ \text{AI}_{t-1}$" pol2 "Non-public security procurement stock $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.4f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label



}


}

/* 11: Table 6, A.8, A.9, and A.10 total effect of AI contracts on software
*/
if "`output'" == "11" | "`output'" == "all" {


set sortseed 2


local pres = "event event_hat_lasso"

foreach t in  `"AI-COMPLEMENTARY"' `"GOVERNMENT"' `"BUSINESS"' `"SURVEILLANCE"' `"GOVSURVEILLANCE"' `"BUSSURVEILLANCE"' `"ALL"' { 

local i = 0	
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	


	
	local ip = "software"
	dis "`t'"
	
	
	** beta 1 + 2
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
qui save "Data/Intermediate/statspai/s11_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe) cl(place)
	addQuarterInter	
	
	est sto a`i'
	local i = `i' + 1
	restore 
	
	
	** beta 1 + 2
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place scale capital_usd_m, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* make firm characteristic X year variables
	gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen scale_`jj' = scale if year == `jj'
		replace scale_`jj' = 0 if missing(scale_`jj')
		gen capital_usd_m_`jj' = capital_usd_m if year == `jj'
		replace capital_usd_m_`jj' = 0 if missing(capital_usd_m_`jj')
	}
	
	* inverse covariance matrix
	gen wgt = 1
	gen stdgroup = 1
	local vlist = ""
	foreach var of varlist scale_* capital_usd_m_* {
	local vlist = "`vlist' `var'"	
	}
	di "`vlist'"
	make_index_gr firm wgt stdgroup  `vlist'
	
	* col 1 and 2
qui save "Data/Intermediate/statspai/s11_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data index_firm, absorb(sub_fe) cl(place)
	addQuarterInter	
		
	est sto a`i'
	local i = `i' + 1
	restore 
	
	
	** beta 1 + 2
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	gen weight = 10 if with_contract_dummy == 0
	replace weight = 1 if with_contract_dummy == 1
	
	* col 1 and 2
qui save "Data/Intermediate/statspai/s11_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data [aweight = weight], absorb(sub_fe) cl(place)
	addQuarterInter	
	
	est sto a`i'
	local i = `i' + 1
	restore 
	
	
	
}


if "`t'" == "ALL"  {

estout a* using "Output/Table6_PanelA_total.tex", ///
replace style(tex) keep( 32.semi_to_f_x_ca_x_with_c) ///
order( 32.semi_to_f_x_ca_x_with_c) ///
varlabels(32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout a* using "Output/TableA8_total.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract"  18.semi_to_f_x_ca_x_with_c "6 quarters before contract" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
		
	
}
else if "`t'" == "GOVERNMENT"  {
estout a* using "Output/Table6_PanelB_gov.tex", ///
replace style(tex) keep( 32.semi_to_f_x_ca_x_with_c) ///
order( 32.semi_to_f_x_ca_x_with_c) ///
varlabels(32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout a* using "Output/TableA9_gov.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract"  18.semi_to_f_x_ca_x_with_c "6 quarters before contract" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
else if "`t'" == "BUSINESS"  {
estout a* using "Output/Table6_PanelC_commercial.tex", ///
replace style(tex) keep( 32.semi_to_f_x_ca_x_with_c) ///
order( 32.semi_to_f_x_ca_x_with_c) ///
varlabels(32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout a* using "Output/TableA10_commercial.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract"  18.semi_to_f_x_ca_x_with_c "6 quarters before contract" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label		
}


	
}
	



}

/* 12: Table 7, A.11, A.12, and A.13 differential effect of AI contracts on software
*/
if "`output'" == "12" | "`output'" == "all" {

set sortseed 1


local pres = "event event_hat_lasso" // protest_hat demand_hat threat_hat protest demand threat

foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"'  {
local i = 0
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no unrest
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))


	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (mean) year (lastnm) place prov scale  capital_usd_m, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* odd cols
qui save "Data/Intermediate/statspai/s12_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	local i = `i' + 1
	
	
	replace year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen scale_`jj' = scale if qofd == `jj'
		replace scale_`jj' = 0 if missing(scale_`jj')
		gen capital_usd_m_`jj' = capital_usd_m if qofd == `jj'
		replace capital_usd_m_`jj' = 0 if missing(capital_usd_m_`jj')
	}
	
	* odd cols
qui save "Data/Intermediate/statspai/s12_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data scale* capital_usd_m*, absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	local i = `i' + 1


	gen weight = 1000 if with_contract_dummy == 0
	replace weight = 1 if with_contract_dummy == 1
	
	* even cols
qui save "Data/Intermediate/statspai/s12_`t'_`pre'_`i'.dta", replace  // [EXPORT HOOK]
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data [aweight = weight], absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	local i = `i' + 1
	
	
	
	restore 
}


if "`t'" == "ALL"  {
	
estout reg_`task'* using "Output/Table7_PanelA_total.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 18.quarter_to_first 20.quarter_to_first 22.quarter_to_first 24.quarter_to_first 26.quarter_to_first  28.quarter_to_first 30.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract"  32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout reg_`task'* using "Output/TableA11_total.tex", ///
replace style(tex) keep(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 23.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 17.quarter_to_first "7 quarters before contract"  18.quarter_to_first "6 quarters before contract" 19.quarter_to_first "5 quarters before contract" 20.quarter_to_first "4 quarters before contract" 21.quarter_to_first "3 quarters before contract" 22.quarter_to_first "2 quarters before contract" 23.quarter_to_first "1 quarter before contract" 24.quarter_to_first "Receiving 1st contract" 25.quarter_to_first "1 quarter after contract" 26.quarter_to_first "2 quarters after contract" 27.quarter_to_first "3 quarters after contract" 28.quarter_to_first "4 quarters after contract" 29.quarter_to_first "5 quarters after contract" 30.quarter_to_first "6 quarters after contract" 31.quarter_to_first "7 quarters after contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract $\times$ public security" 18.semi_to_f_x_ca_x_with_c "6 quarters before contract $\times$ public security" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract $\times$ public security" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract $\times$ public security" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract $\times$ public security" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract $\times$ public security" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract $\times$ public security" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract $\times$ public security" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract $\times$ public security" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract $\times$ public security" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract $\times$ public security" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract $\times$ public security" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract $\times$ public security" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract $\times$ public security" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract $\times$ public security"  32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


}
else if "`t'" == "GOVERNMENT"  {
	
estout reg_`task'* using "Output/Table7_PanelB_gov.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 18.quarter_to_first 20.quarter_to_first 22.quarter_to_first 24.quarter_to_first 26.quarter_to_first  28.quarter_to_first 30.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract"  32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout reg_`task'* using "Output/TableA12_gov.tex", ///
replace style(tex) keep(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 23.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 17.quarter_to_first "7 quarters before contract"  18.quarter_to_first "6 quarters before contract" 19.quarter_to_first "5 quarters before contract" 20.quarter_to_first "4 quarters before contract" 21.quarter_to_first "3 quarters before contract" 22.quarter_to_first "2 quarters before contract" 23.quarter_to_first "1 quarter before contract" 24.quarter_to_first "Receiving 1st contract" 25.quarter_to_first "1 quarter after contract" 26.quarter_to_first "2 quarters after contract" 27.quarter_to_first "3 quarters after contract" 28.quarter_to_first "4 quarters after contract" 29.quarter_to_first "5 quarters after contract" 30.quarter_to_first "6 quarters after contract" 31.quarter_to_first "7 quarters after contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract $\times$ public security" 18.semi_to_f_x_ca_x_with_c "6 quarters before contract $\times$ public security" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract $\times$ public security" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract $\times$ public security" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract $\times$ public security" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract $\times$ public security" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract $\times$ public security" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract $\times$ public security" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract $\times$ public security" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract $\times$ public security" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract $\times$ public security" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract $\times$ public security" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract $\times$ public security" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract $\times$ public security" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract $\times$ public security"  32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


}
else if "`t'" == "BUSINESS"  {
	
estout reg_`task'* using "Output/Table7_PanelC_commercial.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 18.quarter_to_first 20.quarter_to_first 22.quarter_to_first 24.quarter_to_first 26.quarter_to_first  28.quarter_to_first 30.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract"  32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

estout reg_`task'* using "Output/TableA13_commercial.tex", ///
replace style(tex) keep(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 17.quarter_to_first 18.quarter_to_first 19.quarter_to_first 20.quarter_to_first 21.quarter_to_first 22.quarter_to_first 23.quarter_to_first 24.quarter_to_first 25.quarter_to_first 26.quarter_to_first 27.quarter_to_first 28.quarter_to_first 29.quarter_to_first 30.quarter_to_first 31.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 17.semi_to_f_x_ca_x_with_c 18.semi_to_f_x_ca_x_with_c 19.semi_to_f_x_ca_x_with_c 20.semi_to_f_x_ca_x_with_c 21.semi_to_f_x_ca_x_with_c 22.semi_to_f_x_ca_x_with_c 23.semi_to_f_x_ca_x_with_c 24.semi_to_f_x_ca_x_with_c 25.semi_to_f_x_ca_x_with_c 26.semi_to_f_x_ca_x_with_c 27.semi_to_f_x_ca_x_with_c 28.semi_to_f_x_ca_x_with_c 29.semi_to_f_x_ca_x_with_c 30.semi_to_f_x_ca_x_with_c 31.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 17.quarter_to_first "7 quarters before contract"  18.quarter_to_first "6 quarters before contract" 19.quarter_to_first "5 quarters before contract" 20.quarter_to_first "4 quarters before contract" 21.quarter_to_first "3 quarters before contract" 22.quarter_to_first "2 quarters before contract" 23.quarter_to_first "1 quarter before contract" 24.quarter_to_first "Receiving 1st contract" 25.quarter_to_first "1 quarter after contract" 26.quarter_to_first "2 quarters after contract" 27.quarter_to_first "3 quarters after contract" 28.quarter_to_first "4 quarters after contract" 29.quarter_to_first "5 quarters after contract" 30.quarter_to_first "6 quarters after contract" 31.quarter_to_first "7 quarters after contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 17.semi_to_f_x_ca_x_with_c "7 quarters before contract $\times$ public security" 18.semi_to_f_x_ca_x_with_c "6 quarters before contract $\times$ public security" 19.semi_to_f_x_ca_x_with_c "5 quarters before contract $\times$ public security" 20.semi_to_f_x_ca_x_with_c "4 quarters before contract $\times$ public security" 21.semi_to_f_x_ca_x_with_c "3 quarters before contract $\times$ public security" 22.semi_to_f_x_ca_x_with_c "2 quarters before contract $\times$ public security" 23.semi_to_f_x_ca_x_with_c "1 quarter before contract $\times$ public security" 24.semi_to_f_x_ca_x_with_c "Receiving 1st contract $\times$ public security" 25.semi_to_f_x_ca_x_with_c "1 quarter after contract $\times$ public security" 26.semi_to_f_x_ca_x_with_c "2 quarters after contract $\times$ public security" 27.semi_to_f_x_ca_x_with_c "3 quarters after contract $\times$ public security" 28.semi_to_f_x_ca_x_with_c "4 quarters after contract $\times$ public security" 29.semi_to_f_x_ca_x_with_c "5 quarters after contract $\times$ public security" 30.semi_to_f_x_ca_x_with_c "6 quarters after contract $\times$ public security" 31.semi_to_f_x_ca_x_with_c "7 quarters after contract $\times$ public security"  32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


}


}




	
}	

/* 13: Table 8, export AI
*/
if "`output'" == "13" | "`output'" == "all" {

use "Data/export_regression.dta", clear
	

ivreghdfe export_diff police_data scale if ever_contract == 1 [aweight = sub_weight], robust
est sto a1

ivreghdfe export_diff police_data scale if ever_contract == 1 [aweight = sub_weight], robust absorb(contract_ym place)
est sto a2

ivreghdfe export_diff police_data scale software if ever_contract == 1 [aweight = sub_weight], robust absorb(contract_ym place)
est sto a3

ivreghdfe export_diff police_data scale software year_founded if ever_contract == 1 [aweight = sub_weight], robust absorb(contract_ym place)
est sto a4

 estout a* using "Output/Table8_export.tex", ///
    replace style(tex) keep(police_data) ///
    order(police_data) ///
     varlabels(police_data "Public security" )  ///
     ml(, none) collabels(, none) ///
    cells(b(star fmt(%9.3f)) se(par)) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) label   		
	


	
}

/* 14: Table 9, Figure A.16 spillovers 
*/
if "`output'" == "14" | "`output'" == "all" {
	
****** Panel A ******	
forv lag = 1/1 {

set sortseed 2

** get number of contracts
use "Data/contracts_gdp_pop_admin-unit.dta", clear

collapse (count) year, by(company)

ren year n_contracts

tempfile n_contracts
save `n_contracts'


use "Data/firms_matched_prefecture.dta", clear

collapse (lastnm) firm_prov=province firm_pref=merge_pref, by(company)

tempfile a
save `a'
 

*** crosswalk, events to events 
use "Data/unrest_data.dta", clear

ren (prov city) (firm_prov firm_pref)
collapse (mean) event event_hat_lasso, by(firm_prov firm_pref qofd)
replace event = 0 if missing(event)
replace event_hat_lasso = 0 if missing(event_hat_lasso)
tempfile unrest
save `unrest'

local pres = "event" 
local j = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear
	
* merge in hq
merge n:1 company using `a', keep(1 3) nogen

drop event event_hat_lasso

merge n:1 firm_prov firm_pref qofd using `unrest', keep(1 3) nogen
	
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui collapse (count) n_`ip' (mean) `pre' , ///
		by(company qofd firm_prov firm_pref sub_fe)
		
	merge n:1 company using `n_contracts', keep(1 3) nogen
	replace n_contracts = 0 if missing(n_contracts)
		
	egen place = group(firm_prov firm_pref)	
	xtset sub_fe qofd
	
	sort sub_fe qofd
	by sub_fe: gen n_`ip'_cum = n_`ip' + n_`ip'[_n-1]
		
qui save "Data/Intermediate/statspai/s14_A_`t'.dta", replace  // [EXPORT HOOK]
	xtevent n_`ip'_cum if n_contracts == 0, policyvar(`pre') panelvar(sub_fe) timevar(qofd) plot w(-8 8) cl(place)
	est sto nc_reg_`j'
	xteventplot, nosupt levels(95) noprepval nopostpval ///
		graphregion(fcolor(white) ilcolor(white) lcolor(white)) /// 
		ytitle("Software releases") xtitle(" ") ///
				legend(label(1 "95% CI") label(2 "Coefficient")) 

	
	** store coefficients/SEs for graphing
	gen beta1 = .
	gen se1 = .
	forv i = 1/7 {
		local ii = 9 - `i'
		replace beta1 = _b[_k_eq_m`ii'] if _n == `i'
		replace se1 = _se[_k_eq_m`ii'] if _n == `i'
	}
	replace beta1 = 0 if _n == 8
	replace se1 = 0 if _n == 8
	forv i = 0/8 {
		local ip9 = `i' + 9
		replace beta1 = _b[_k_eq_p`i'] if _n == `ip9'
		replace se1 = _se[_k_eq_p`i'] if _n == `ip9'
	}
	
	*list beta1 se1 if beta1<. ,clean
	gen top =  beta1 + 1.96 * se1
	gen bottom = beta1 - 1.96 * se1
	gen id = _n 
	replace id = id - 8 - 1
	keep if inrange(id,-8,16)
	keep beta1 top bottom id se1

	save "Data/Intermediate/statspai/_fig_FigA16_PanelA_`t'.dta", replace
	
	restore 
	local j = `j' + 1
}
	
}

estout nc_reg_* using "Output/Table9_PanelA_unrestlocality.tex", ///
replace style(tex) keep(_k_eq_p8) ///
order( _k_eq_p8) ///
varlabels(  _k_eq_p8 "8 quarters after unrest" ) ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label





** total and commercial
local pre = "event"

	
	use "Data/Intermediate/statspai/_fig_FigA16_PanelA_ALL.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_a top_a bottom_a)
	

	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelA_GOVERNMENT.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .01 if !missing(beta1)
	ren (beta1 top bottom) (beta_g top_g bottom_g)

	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelA_BUSINESS.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_b top_b bottom_b)
	
	
	
	
	drop if id > 8.5
	
					
	twoway (scatter beta_a id if inrange(id,-8.5,40.5),color(black))  /// 
			(rcap top_a bottom_a id if inrange(id,-8.5,40.5),color(black)) /// 
			(scatter beta_g id if inrange(id,-8.5,40.5),color(blue) msymbol(D))  /// 
			(rcap top_g bottom_g id if inrange(id,-8.5,40.5),color(blue)) /// 
			(scatter beta_b id if inrange(id,-8.5,40.5),color(red) msymbol(T))  /// 
			(rcap top_b bottom_b id if inrange(id,-8.5,40.5),color(red)) /// 
			, legend(order(1 "Total software OLS" 3 "Government OLS" 5 "Commercial OLS")) /// 
			ytitle("# of Software") xtitle("Quarters to Unrest") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white))  
	graph export "Output/FigureA16_PanelA_unrestlocality.png", replace 
	
}	

****** Panel B ******		
forv lag = 1/1 {

set sortseed 2

** get number of contracts
use "Data/contracts_gdp_pop_admin-unit.dta", clear

collapse (count) year, by(company)

ren year n_contracts

tempfile n_contracts
save `n_contracts'


** get firm prefecture
use "Data/firms_matched_prefecture.dta", clear
drop if missing(prov_eng)
tempfile firmbase
save `firmbase'


local ip = "software"
local pres = "event" 

local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"'  { 
foreach pre in `pres' {
	
*** build firm-quarter software data with location data	
use "Data/firm_data.dta", clear

if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	qui collapse (count) n_`ip' , ///
		by(company qofd)
merge n:1 company using `firmbase', keep(1 3) nogen

drop if missing(prov_eng) | missing(company)
drop prov_eng pref_eng
ren (province merge_pref) (firm_prov firm_pref)

tempfile fqs
save `fqs'		

*** build contract level data	
use "Data/firm_data.dta", clear

* impute 0s for cities with no unrest
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))

* keep only public security contracts
keep if police_data == 1 & quarter_to_first == 0

** go to contract level
collapse (lastnm) qofd company, by(url)

merge n:1 company using `firmbase', keep(1 3) nogen

drop if missing(prov_eng)
drop prov_eng pref_eng
ren (province merge_pref company qofd) (firm_prov firm_pref company_contract qofd_contract)


** join across contracts by all firms
joinby firm_prov firm_pref using `fqs'

drop if company == company_contract

merge n:1 company using `n_contracts', keep(1 3) nogen
replace n_contracts = 0 if missing(n_contracts)

gen quarter_to_first = qofd - qofd_contract
gen contract_date = (quarter_to_first == 0)

egen firm_contract = group(company url)
egen place = group(firm_prov firm_pref)

** duplicates
bys firm_contract qofd: drop if _n > 1

xtset firm_contract qofd

keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	
qui save "Data/Intermediate/statspai/s14_B_`t'.dta", replace  // [EXPORT HOOK]
	reghdfe n_software b(23).quarter_to_first ///
		 if n_contracts == 0, absorb(firm_contract qofd) cl(place)
	est sto nc_reg_`task'_`i'
	
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_FigA16_PanelB_`t'.dta", replace

	
local i = `i' +1

}



}



estout nc_reg_`task'* using "Output/Table9_PanelB_contractHQ.tex", ///
replace style(tex) keep( 32.quarter_to_first) ///
order(32.quarter_to_first ) ///
varlabels(32.quarter_to_first "8 quarters after contract" ) ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


** make figure
local pre = "event"

	
	use "Data/Intermediate/statspai/_fig_FigA16_PanelB_ALL.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_a top_a bottom_a)
	

	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelB_GOVERNMENT.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .01 if !missing(beta1)
	ren (beta1 top bottom) (beta_g top_g bottom_g)

	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelB_BUSINESS.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_b top_b bottom_b)
	
	
	
	
	drop if id > 8.5
	
					
	twoway (scatter beta_a id if inrange(id,-8.5,40.5),color(black))  /// 
			(rcap top_a bottom_a id if inrange(id,-8.5,40.5),color(black)) /// 
			(scatter beta_g id if inrange(id,-8.5,40.5),color(blue) msymbol(D))  /// 
			(rcap top_g bottom_g id if inrange(id,-8.5,40.5),color(blue)) /// 
			(scatter beta_b id if inrange(id,-8.5,40.5),color(red) msymbol(T))  /// 
			(rcap top_b bottom_b id if inrange(id,-8.5,40.5),color(red)) /// 
			, legend(order(1 "Total software OLS" 3 "Government OLS" 5 "Commercial OLS")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) 
	graph export "Output/FigureA16_Panel_B_contractHQ.png", replace
	

	
}	

****** Panel C ******		
forv lag = 1/1 {

set sortseed 2


** get number of contracts
use "Data/contracts_gdp_pop_admin-unit.dta", clear

collapse (count) year, by(company)

ren year n_contracts

tempfile n_contracts
save `n_contracts'

** get firm prefecture
use "Data/firms_matched_prefecture.dta", clear
drop if missing(prov_eng)
tempfile firmbase
save `firmbase'


local ip = "software"
local pres = "event" 

local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' { 
foreach pre in `pres' {
	
*** build firm-quarter software data with location data	
use "Data/firm_data.dta", clear

if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	
	qui collapse (count) n_`ip' (lastnm) mother_name, ///
		by(company qofd)

drop if missing(mother_name) | missing(company)

tempfile fqs
save `fqs'		

*** build contract level data	
use "Data/firm_data.dta", clear

* impute 0s for cities with no unrest
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))

* keep only public security contracts
keep if police_data == 1 & quarter_to_first == 0

** go to contract level
collapse (lastnm) qofd company mother_name place, by(url)

drop if missing(mother_name)


ren (company qofd) (company_contract qofd_contract)


** join across mother firm by all subsidiaries
joinby mother_name using `fqs'

drop if company == company_contract

gen quarter_to_first = qofd - qofd_contract
gen contract_date = (quarter_to_first == 0)

egen firm_contract = group(company url)

merge n:1 company using `n_contracts', keep(1 3) nogen
replace n_contracts = 0 if missing(n_contracts)

** duplicates
bys firm_contract qofd: drop if _n > 1

xtset firm_contract qofd

keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	
qui save "Data/Intermediate/statspai/s14_C_`t'.dta", replace  // [EXPORT HOOK]
	reghdfe n_software b(23).quarter_to_first ///
		if n_contracts == 0 , absorb(firm_contract qofd) cl(place)
	est sto nc_reg_`task'_`i'
	
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_FigA16_PanelC_`t'.dta", replace


local i = `i' +1

}



}


estout nc_reg_`task'* using "Output/Table9_PanelC_motherfirm.tex", ///
replace style(tex) keep(32.quarter_to_first) ///
order(32.quarter_to_first) ///
varlabels( 32.quarter_to_first "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	




** make figure
local pre = "event"

	
	use "Data/Intermediate/statspai/_fig_FigA16_PanelC_ALL.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_a top_a bottom_a)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelC_GOVERNMENT.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .01 if !missing(beta1)
	ren (beta1 top bottom) (beta_g top_g bottom_g)
	
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA16_PanelC_BUSINESS.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .2 if !missing(beta1)
	ren (beta1 top bottom) (beta_b top_b bottom_b)
	

	drop if id > 8.5
	
					
	twoway (scatter beta_a id if inrange(id,-8.5,40.5),color(black))  /// 
			(rcap top_a bottom_a id if inrange(id,-8.5,40.5),color(black)) /// 
			(scatter beta_g id if inrange(id,-8.5,40.5),color(blue) msymbol(D))  /// 
			(rcap top_g bottom_g id if inrange(id,-8.5,40.5),color(blue)) /// 
			(scatter beta_b id if inrange(id,-8.5,40.5),color(red) msymbol(T))  /// 
			(rcap top_b bottom_b id if inrange(id,-8.5,40.5),color(red)) /// 
			, legend(order(1 "Total software OLS" 3 "Government OLS" 5 "Commercial OLS")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) 
	graph export "Output/FigureA16_PanelC_motherfirm.png", replace
	

	
}	
	

	
}

/* 15: Figure A.4, contracts data
*/
if "`output'" == "15" | "`output'" == "all" {
use "Data/time_series_contracts.dta", clear

twoway (line N_police ym,color(red)) /// 
	(line N_nonpolice ym , color(black)), ytitle("# of Contracts")  ///
	legend(label(1 "Public security") ///
		   label(2 "Non-public security") ) graphregion(fcolor(white) ilcolor(white) lcolor(white))
graph export "Output/FigureA4_PanelB_flow.png",width(1000) replace 

cap drop N_nonpolice_cum
gen N_nonpolice_cum = N_nonpolice
replace N_nonpolice_cum =   N_nonpolice_cum[_n-1] +  N_nonpolice_cum[_n] if _n >= 2


cap drop N_police_cum
gen N_police_cum = N_police
replace N_police_cum =   N_police_cum[_n-1] +  N_police_cum[_n] if _n >= 2



twoway (line N_police_cum ym,color(red)) /// 
	(line N_nonpolice_cum ym , color(black)), ytitle("# of Contracts (cumulative)")  ///
	legend(label(1 "Public security") ///
		   label(2 "Non-public security") ) graphregion(fcolor(white) ilcolor(white) lcolor(white))
graph export "Output/FigureA4_PanelA_stock.png",width(1000) replace 
}

/* 16: Figure A.6, firm capital and software
*/
if "`output'" == "16" | "`output'" == "all" {
use "Data/firm_data.dta", clear	
	
keep if software_ID != "" 
 
collapse (count) id (mean) capital_usd_m, by(sub_fe)

replace capital_usd_m = log(capital_usd_m)
corr capital_usd_m id
local crr = round(r(rho),.001)
binscatter capital_usd_m id, savegraph("Output/FigureA6_capitalsoftware.png") ///
	ytitle("log(Capitalization)") xtitle("Software") replace ///
	note("Correlation: `crr'")	

}

/* 17: Figure A.10, LASSO seed
*/
if "`output'" == "17" | "`output'" == "all" {


local cltext = "place"

* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc"
* droptype is instruments
* lassoinf: lasso inference, gen all keep all
local droptypes = "lassoinf"


local events = "event"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach outcome in `outcomes' {
foreach event in `events' {
// preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}



* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}


collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')


replace prefecture_city_population = log(1+prefecture_city_population)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)


tempname fh 
file open `fh' using "Data/Intermediate/statspai/_fig_FigA10_seeds.csv", write text replace

forv i = 1/100 {
// di `i'	

*** interactions ***
cap xpoivregress lead_police_pc (blank = c.(w1-w18)##c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(`i')
if _rc != 481 {

local b = _b[blank]

file write `fh' "`i',`b'" _newline
	
}


		
}

file close `fh'


}

}	


}


}
}


	
	
import delim "Data/Intermediate/statspai/_fig_FigA10_seeds.csv", clear	

ren (v1 v2) (nn b)	

sort b
drop nn
gen nn = _n


local max5 = _N - 5	
su b if nn == 5
local b5 = string(r(mean),"%9.3f")
su b if nn == 50
local b50 = string(r(mean),"%9.3f")
su b if nn == `max5'
local b95 = string(r(mean),"%9.3f")
graph twoway (scatter b nn ,color(black)) ///
	, ytitle("") xtitle(" ") xline(5 50 `max5') yline(1.889, lcolor(grey)) ///
					graphregion(fcolor(white) ilcolor(white) lcolor(white)) /// 
					legend(label(1 "Coefficient")) ///
					title("Cross-partial out IV LASSO by seed") ///
					note("5%: `b5', 50%: `b50' , 95%: `b95', rank of main coefficient (0.375) = 87th ")
					
	graph export "Output/FigureA10_seeds.png", replace

}

/* 18: Figure A.15, politically motivated vs. neutral
*/
if "`output'" == "18" | "`output'" == "all" {

set seed 2

local pres = "event event_hat_lasso" 

foreach pre in `pres' {

use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

* generate capacity for panel, continuous
su `pre', d
gen capacity_panel_dummy = (`pre' > r(p50))


local i = 0
foreach t in `"BUSINESS"'  {
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (median) capacity_panel_dummy (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe)
		
	* gen cumulative number of software
	sort company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= 0
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 
	replace capacity_panel_dummy = round(capacity_panel_dummy)
	tab quarter_to_first, gen(sytf)
	forv j = 1/49 {
	gen semi`j'_to_f_x_ca_x_with_c = sytf`j' * capacity_panel_dummy * with_contract_dummy
	gen semi`j'_to_f_x_ca = sytf`j' * capacity_panel_dummy	
	}
	gen ca_x_with_c =  capacity_panel_dummy * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum semi*_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi*_to_f_x_ca ///
		capacity_panel_dummy , absorb(sub_fe qofd) cl(place)
		
	addQuarter24	
	regToCoefDataset90 blank 
	save "Data/Intermediate/statspai/_fig_FigA15_`pre'_`t'.dta", replace


	restore 
}


}

local t = "BUSINESS"
local pre = "event"
	use "Data/Intermediate/statspai/_fig_FigA15_`pre'_`t'.dta", clear
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id - .1
	ren (beta top bottom) (beta_niv top_niv bottom_niv)
	
	merge 1:1 id using "Data/Intermediate/statspai/_fig_FigA15_`pre'_hat_lasso_`t'.dta", nogen
	replace top = . if id == -1
	replace bottom = . if id == -1
	replace id = id + .1
	
	drop if id > 8.5
	
	twoway (scatter beta_niv id if inrange(id,-8.5,40.5),color(black%25))  /// 
			(rcap top_niv bottom_niv id if inrange(id,-8.5,40.5),color(black%25)) /// 
			(scatter beta1 id if inrange(id,-8.5,40.5),color(black))  /// 
			(rcap top bottom id if inrange(id,-8.5,40.5),color(black)) /// 
			, legend(order(1 "OLS" 3 "IV")) /// 
			ytitle("# of Software") xtitle("Quarters to the First Contract") ///
					xlabel(-8(2)8)   xline(-1) yline(0) graphregion(fcolor(white) ilcolor(white) lcolor(white)) 
	graph export "Output/FigureA15_politicalvsneutral.png", replace
	

	
	
}	

/* 19: Table A.2, different types of unrest on AI
*/
if "`output'" == "19" | "`output'" == "all" {

local cltext = "place"


******** PROTEST, OLS ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"

forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "protest"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}



collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"

*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_gdp##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_city_population##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_fiscal_revenue##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_gdp##`time'  (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelA.2_protestiv.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelA.1_protestols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}


est clear
}	




}


}
}


******** PROTEST, IV ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""

forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "protest"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}



collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"

*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_gdp##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_city_population##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_fiscal_revenue##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_gdp##`time'  (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelA.2_protestiv.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelA.1_protestols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}


est clear
}	




}


}
}



******** DEMAND, OLS ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"

forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "demand"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}


collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"

*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelB.2_demandiv.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelB.1_demandols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}

est clear
}	




}


}
}


******** DEMAND, IV ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""

forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen

tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)
replace prefecture_city_population = 0 if missing(prefecture_city_population) & !missing(prefecture_gdp)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "demand"

foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}


collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}



egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"

*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelB.2_demandiv.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelB.1_demandols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}

est clear
}	




}


}
}



******** THREAT, OLS ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = "niv"


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "threat"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}

collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"


*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_gdp##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_city_population##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_fiscal_revenue##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock  ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelC.2_threativ.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelC.1_threatols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}

est clear
}	




}


}
}


******** THREAT, IV ********
* niv: no iv
* "" : regular IV
* "niv" : no iv
local niv = ""


forv lag = 1/1 {


	
* prep data for shapefile merge	
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}

* get police vars
if `lag' != 0 {
drop contracts
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

*** bhe
merge 1:1 url using "Data/nonpolice_def.dta", keep(1 3) nogen
drop if missing(nonpolice_bank) | (nonpolice_bank == 0 & nonpolice_hospital == 0 & nonpolice_edu == 0 & police == 0)

collapse (sum) police (count) contracts=police (mean) pop gdp, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (lead_police contracts)

ren city merge_pref

local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

gen lead_police_pc = lead_police/prefecture_city_population
gen nonpolice = contracts - lead_police
gen lead_nonpolice_pc = nonpolice/prefecture_city_population
}

drop if actiongeo_type <= 1

replace pref_eng = subinstr(pref_eng, " ", "", .)
replace pref_eng = lower(pref_eng)
	
* merge to keep shapefile data
merge m:1 pref_eng prov_eng  using "Data/prefectureDist.dta", keep(2 3) nogen

* merge in weather station transition
merge m:1 pref_eng prov_eng using "Data/prefec_station.dta", keep(3) nogen


tostring sqldate, replace
gen day = substr(sqldate,7,8)
destring day, force replace

ren station_id station

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 
gen ease = nongov_ease_poli + nongov_ease_econ + nongov_ease_mil

* collapse to daily level
collapse (sum) protest demand threat ease (mean) lead_police_pc lead_camera_time_city_pc prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, ///
 by(pref_eng prov_eng year month day station)

 
egen place = group(pref_eng prov_eng) 
drop if missing(place)
gen date = mdy(month, day, year)
su date
replace date = r(min) if missing(date)  // for the prefectures with no event data

* time series
tsset place date
tsfill, full


* refill missings
replace year = yofd(date)
replace month = month(date)
replace day = day(date)
set type double
bys place: egen m_station = max(station)
replace station = m_station
drop m_station
carryforward lead_police lead_camera_time_city prefecture_city_population prefecture_gdp prefecture_fiscal_revenue lead_nonpolice_pc, replace 
replace lead_police = 0 if missing(lead_police)
replace lead_camera_time_city = 0 if missing(lead_camera_time_city)
replace lead_nonpolice_pc = 0 if missing(lead_nonpolice_pc)

gen time = ym(year, month)

gen panel_capacity_dummy = .
qui su time, d
local smin = r(min)
local smax = r(max)
forv time = `smin'/`smax' {
	qui count if time == `time'
	if r(N) > 0 {
		qui su lead_camera_time_city if time == `time', d
		qui replace panel_capacity_dummy = (lead_camera_time_city > r(p50)) if !missing(lead_camera_time_city) & time == `time'
	}
}

gen ai = panel_capacity_dummy * lead_police
* weather panel data
merge m:1 year month day station using "Data/china_weather_panel.dta", keep(1 3) nogen


* get province FE
preserve
collapse (lastnm) prov_eng, by(place)
ren prov_eng province
tempfile provs
save `provs'
restore
merge m:1 place using `provs', keep(1 3) nogen

egen prov_fe = group(province)


replace protest = 0 if missing(protest)
replace demand = 0 if missing(demand)
replace threat = 0 if missing(threat)
replace ease = 0 if missing(ease)

gen wofd = wofd(date)
gen mofd = mofd(date)
gen qofd = qofd(date)
gen hofd = hofd(date)

gen event = protest + demand + threat



* gen vars for lasso
gen temp1 = (temp < 32)
gen temp2 = (temp >= 32 & temp < 48)
gen temp3 = (temp >= 48 & temp < 64)
gen temp4 = (temp >= 64 & temp < 95)
gen temp5 = (temp > 95) if !missing(temp)
gen max1 = (max < 32)
gen max2 = (max >= 32 & max < 48)
gen max3 = (max >= 48 & max < 64)
gen max4 = (max >= 64 & max < 95)
gen max5 = (max > 95) if !missing(max)
gen min1 = (min < 32)
gen min2 = (min >= 32 & min < 48)
gen min3 = (min >= 48 & min < 64)
gen min4 = (min >= 64 & min < 95)
gen min5 = (min > 95) if !missing(min)

gen temp_dummy = (temp >= 32 & temp <= 95) // >= 0 and <= 35 celsius
gen temp_dummy2 = (temp >= 0 & temp <= 97) // >= 0 and <= 97 celsius
replace rain = 1 - rain
replace prcp = -prcp


local weathervars = "dewp fog frshtt gust hail max min mxspd prcp rain sndp snow stp temp thunder tornado visib wdsp"

local times = "qofd"

local outcomes = "lead_police_pc" 
* droptype is instruments
* lassoinf: lasso inference
local droptypes = "lassoinf"

local events = "threat"


foreach time in `times' {
foreach droptype in `droptypes' {
local j = 1
foreach event in `events' {
foreach outcome in `outcomes' {
preserve



gen blank = .
replace blank = `event'

if "`droptype'" == "lassoinf" {
local instrument = ""
local i = 1	

foreach w in `weathervars' {
	gen w`i' = `w'
	local instrument "`instrument' w`i'"
	local i = `i' + 1
}	
}

* first stage interaction between good weather and event elsewhere
bys date: egen all_event = sum(blank)
gen event_elsewhere = (all_event > 0)
local instruments = "`instrument'"

if "`droptype'" == "lassoinf" {
local i = 1
foreach w in `instrument' {
gen wI`i' = `w' * event_elsewhere
local instruments = "`instruments' wI`i'"
local i = `i' + 1
}
}

collapse (sum) blank `instruments' (mean) `outcome' prov_fe prefecture_city_population prefecture_gdp prefecture_fiscal_revenue year,by(place `time')

replace prefecture_city_population = log(1+prefecture_city_population)

sort place qofd
by place: gen AI_stock = sum(lead_police_pc)
gen AI_stock_t2 = AI_stock - lead_police_pc - lead_police_pc[_n-1] if place == place[_n-1]
replace AI_stock_t2 = 0 if missing(AI_stock_t2) // initial period


forv q = 216/241 {
	gen gdp_`q' = prefecture_gdp if qofd == `q'
	replace gdp_`q' = 0 if missing(gdp_`q')
	gen pcp_`q' = prefecture_city_population if qofd == `q'
	replace pcp_`q' = 0 if missing(pcp_`q')
	gen pfr_`q' = prefecture_fiscal_revenue if qofd == `q'
	replace pfr_`q' = 0 if missing(pfr_`q')
}


egen prov_by_year = group(prov_fe `time')

su blank
replace blank = (blank - r(mean))/r(sd)
su `outcome'
replace `outcome' = (`outcome' - r(mean))/r(sd)

local ev_i "c.w2#c.w29 c.w3#c.w29 c.wI1#c.wI2 c.wI12#c.wI26 c.wI13##c.wI21 c.wI18##c.wI21 c.wI20#c.wI21 c.wI21#c.wI21 c.wI21#c.wI29 c.wI3#c.wI21 c.wI6#c.wI14 c.wI7#c.wI21 wI21"


*** Col 1: GDP control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_gdp##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_gdp##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 2: Population control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_city_population##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_city_population pcp_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_city_population##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 3: Gov revenue control ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc c.prefecture_fiscal_revenue##qofd (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1


*** Col 4: AI stock  ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

*** Col 5: All controls ***
if "`niv'" == "niv" {
ivreghdfe `outcome' blank AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time', absorb(place `time') cl(`cltext')
est sto a`j'
}   
else {
** different FEs, differetn outcomes
cap xpoivregress lead_police_pc AI_stock_t2 (blank = c.(w1-w18) c.(wI1-wI18)), control((i.qofd i.place) prefecture_gdp gdp_* prefecture_city_population pcp_* prefecture_fiscal_revenue pfr_*) vce(cl place) rseed(1)
if _rc == 481 {
di "use same instrument as main event"
ivreghdfe lead_police_pc AI_stock_t2 c.prefecture_city_population##`time' c.prefecture_gdp##`time' c.prefecture_fiscal_revenue##`time' (blank = `ev_i'), absorb(place qofd) cl(place)
}
est sto a`j'
}
local j = `j' + 1

restore	

}

if "`niv'" == "" {
	local stats = ""
	estout a* using "Output/TableA2_PanelC.2_threativ.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label `stats'
}
else {
	estout a* using "Output/TableA2_PanelC.1_threatols.tex", ///
replace style(tex) keep(blank) ///
order(blank) ///
 varlabels(blank "Unrest $ \text{events}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) label 
}

est clear
}	




}


}
}





}

/* 20: Table A.4, police hires
*/
if "`output'" == "20" | "`output'" == "all" {

***** # HIRES *****

* get police (contract) data at the annual-prefecture level
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lag = 4
local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}
** END MERGE NEW CAMERA DATA

sort province merge_pref year month
by province merge_pref: carryforward camera_time_city, replace

replace camera_time_city = 0 if missing(camera_time_city)

** police data
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

collapse (sum) police (count) contracts=police (mean) pop, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (police contracts)

ren city merge_pref
keep police merge_pref year month

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen


drop if missing(province) | missing(merge_pref)
ren (province merge_pref year) (prov city year_founded)

merge n:1 prov year_founded using "Data/province_fiscal_revenue.dta", keep(1 3) nogen
merge n:1 prov year_founded using "Data/province_fiscal_expenditure.dta", keep(1 3) nogen

ren year_founded year

replace prefecture_fiscal_expenditure = province_fiscal_expenditure if prov == "上海市" | prov == "北京市" | prov == "天津市" | prov == "重庆市"
replace prefecture_fiscal_revenue = province_fiscal_revenue if prov == "上海市" | prov == "北京市" | prov == "天津市" | prov == "重庆市"

bys prov: egen m_prefecture_city_population = mean(prefecture_city_population)
replace prefecture_city_population = m_prefecture_city_population if missing(prefecture_city_population)

gen protest = nongov_protest_poli + nongov_protest_econ + nongov_protest_other + nongov_protest_force
gen demand = nongov_demand_poli + nongov_demand_econ + nongov_demand_mil + nongov_demand_other
gen threat = nongov_threat_poli + nongov_threat_econ + nongov_threat_mil + nongov_threat_other 

collapse (mean) police camera_time_city_pc prefecture_fiscal_revenue prefecture_city_population (sum) protest demand threat, by(prov city year month)

gen mofd = mofd(mdy(month,1,year))
replace police = 0 if missing(police)

collapse (sum) police protest demand threat (mean) camera_time_city prefecture_fiscal_revenue prefecture_city_population, by(prov city year)

* merge in job data
replace year = year + 1
merge n:1 prov city year using "Data/police_new_recruit.dta", keep(1 3) nogen
ren job_count lead_job_count
replace year = year - 1	

merge n:1 prov city year using "Data/police_new_recruit.dta", keep(1 3) nogen

egen place = group(prov city)

gen police_raw = police

su lead_job_count
gen lead_job_std = (lead_job_count - r(mean))/r(sd)

tsset place year

* topcode at 95%
su police_raw, d
gen police_t95 = r(p95) if police_raw > r(p95)
replace police_t95 = police_raw if missing(police_t95)
su police_t95
replace police_t95 = (police_t95 - r(mean))/r(sd)

reghdfe lead_job_std police_t95 prefecture_fiscal_revenue, absorb(year place) vce(robust)
est sto a1

reghdfe lead_job_std police_t95 prefecture_fiscal_revenue prefecture_city_population, absorb(year place) vce(robust)
est sto a2
		
estout a* using "Output/TableA4_PanelA_hires.tex", ///
replace style(tex) keep(police_t95) ///
order(police_t95) ///
 varlabels(police_t95 "Public security $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label




***** % OFFICE *****

* get police (contract) data at the annual-prefecture level
use "Data/GDELT_China_072920.dta", clear

** MERGE NEW CAMERA DATA

preserve

use "Data/Hardware_Capacities_20201020.dta", clear

ren (prov city) (province merge_pref)

local lag = 4
local lagnum = `lag'*3
replace month = month + `lagnum'
replace year = year + 1 if month > 12
replace month = month - 12 if month > 12

tempfile a
save `a'

restore

replace year = year - 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year + 1

label var camera_count_city "Camera X-Section (Event lead, Camera lag)"
label var camera_time_city "Camera Panel (Event lead, Camera lag)"

ren (camera_count_city camera_time_city) (lag_camera_count_city lag_camera_time_city)

replace year = year + 1

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

replace year = year - 1

label var camera_count_city "Camera X-Section (Event lag, Camera lead)"
label var camera_time_city "Camera Panel (Event lag, Camera lead)"

ren (camera_count_city camera_time_city) (lead_camera_count_city lead_camera_time_city)

merge n:1 province merge_pref year month using `a', keep(1 3) nogen

label var camera_count_city "Camera X-Section"
label var camera_time_city "Camera Panel"

local aivars = "lag_camera_count_city lag_camera_time_city lead_camera_count_city lead_camera_time_city camera_count_city camera_time_city"
foreach var in `aivars' {
gen `var'_pc = `var'/prefecture_city_population
}
** END MERGE NEW CAMERA DATA

sort province merge_pref year month
by province merge_pref: carryforward camera_time_city, replace

replace camera_time_city = 0 if missing(camera_time_city)

** police data
preserve

use "Data/contracts_gdp_pop_admin-unit.dta", clear

collapse (sum) police (count) contracts=police (mean) pop, by(year month city)

sort city year month
by city: gen police2 = sum(police)
by city: gen contracts2 = sum(contracts)
drop police contracts
ren (police2 contracts2) (police contracts)

ren city merge_pref
keep police merge_pref year month

tempfile a
save `a'

restore
merge n:1 merge_pref year month using `a', keep(1 3) nogen

drop if missing(province) | missing(merge_pref)
ren (province merge_pref year) (prov city year_founded)

merge n:1 prov year_founded using "Data/province_fiscal_revenue.dta", keep(1 3) nogen
merge n:1 prov year_founded using "Data/province_fiscal_expenditure.dta", keep(1 3) nogen

ren year_founded year

replace prefecture_fiscal_expenditure = province_fiscal_expenditure if prov == "上海市" | prov == "北京市" | prov == "天津市" | prov == "重庆市"
replace prefecture_fiscal_revenue = province_fiscal_revenue if prov == "上海市" | prov == "北京市" | prov == "天津市" | prov == "重庆市"

collapse (mean) camera_time_city_pc police prefecture_fiscal_revenue prefecture_city_population, by(prov city year month)

collapse (sum) police (mean) prefecture_fiscal_revenue prefecture_city_population camera_time_city_pc, by(prov city year)

* merge in job data
replace year = year + 1
merge n:1 prov city year using "Data/police_office_share.dta", keep(1 3) nogen
ren (jobs field office unknown) (lead_jobs lead_field lead_office lead_unknown)
replace year = year - 1	

merge n:1 prov city year using "Data/police_office_share.dta", keep(1 3) nogen

gen police_raw = police

egen place = group(prov city)
gen lead_share_office = lead_office/lead_jobs


* topcode at 95%
su police_raw, d
gen police_t95 = r(p95) if police_raw > r(p95)
replace police_t95 = police_raw if missing(police_t95)
su police_t95
replace police_t95 = (police_t95 - r(mean))/r(sd)


reghdfe lead_share_office police_t95 prefecture_fiscal_revenue, absorb(year place) vce(robust)
est sto a1

reghdfe lead_share_office police_t95 prefecture_fiscal_revenue prefecture_city_pop, absorb(year place) vce(robust)
est sto a2
		
estout a* using "Output/TableA4_PanelB_office.tex", ///
replace style(tex) keep(police_t95) ///
order(police_t95) ///
 varlabels(police_t95 "Public security $ \text{AI}_{t-1}$")  ///
 ml(, none) collabels(, none)  ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label



}

/* 21: Table A.14, A.15, software robustness
*/
if "`output'" == "21" | "`output'" == "all" {
	
*** Panel A.1 ***	
* see Tables A.8-A.13

*** Panel A.2 ***	
forv lag = 1/1 {

set sortseed 2

use "Data/firm_characteristics.dta", clear

keep company year_founded

tempfile age
save `age'




local pres = "event event_hat_lasso" 

local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {

use "Data/firm_data.dta", clear

merge n:1 company using `age', keep(1 3) nogen

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (mean) year_founded (lastnm) place , ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen year_founded_`jj' = year_founded if year == `jj'
		replace year_founded_`jj' = 0 if missing(year_founded_`jj')
	}
		
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data year_founded*, absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'
	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelA.2_age.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelA.2_age.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label


	
}	

*** Panel A.3 ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 

local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))

* flag for pre-contract software
gen flag = ((quarter_to_first < 0) | with_contract_dummy == 0) & software_ID != ""
bys sub_fe: egen pre_soft = sum(flag)
	

	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (mean) pre_soft (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy


	gen year = yofd(dofq(qofd))
	forv jj = 2013/2019 {
		gen pre_soft_`jj' = pre_soft if qofd == `jj'
		replace pre_soft_`jj' = 0 if missing(pre_soft_`jj')
	}
		
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data pre_soft*, absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelA.3_precontract.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelA.3_precontract.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label


	
}	

*** Panel B ***
forv lag = 1/1 {

set sortseed 2


local pres = "event event_hat_lasso" 

local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
* ambiguous data
merge n:1 mergeID using "Data/software_version_X.0.dta", keep(1 3) nogen
	

	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" & new_version == 1 // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" & new_version == 1 // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 & new_version == 1 // count number of software 
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelB_major.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelB_major.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label
	

	
}	

*** Panel C ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 

local i = 0

foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"'   { 
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	


	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	keep if Functions_pred == `"AI-VIDEO"' | Functions_pred == ""
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "GOVSURVEILLANCE" {
	keep if Customers_pred == "GOVERNMENT" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "BUSSURVEILLANCE" {
	keep if Customers_pred == "BUSINESS" | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""  // count number of software  
	}
		
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place , ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd 
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
}


estout reg_`task'* using "Output/TableA15_PanelC_video.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelC_video.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label
	

	
}	

*** Panel D ***
forv lag = 1/1 {

set sortseed 2


local pres = "event event_hat_lasso" 


local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
	
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))

* merge in ambiguous data
merge m:1 company using "Data/ambiguous_public_security_agencies_firm_list.dta", keep(1 3)

gen ambiguous = (_m == 3)
drop _m
drop if ambiguous == 1
	

	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelD_ambiguous.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelD_ambiguous.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
	

	
}	

*** Panel E (E.1, E.2, E.3) ***
forv lag = 1/1 {

set sortseed 2


local models "10_32_32 20_16_32 20_32_16"

foreach model in `models' {


local pres = "event event_hat_lasso" 

local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))



****** CUSTOMERS ******

* merge in prediction data
drop Customers_pred
merge n:1 mergeID using "Data/predict_customer_`model'.dta", nogen keep(1 3)

	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}



	

}


if "`model'" == "10_32_32" {
estout reg_`task'* using "Output/TableA15_PanelE.1_timestep.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelE.1_timestep.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
else if "`model'" == "20_16_32" {
estout reg_`task'* using "Output/TableA15_PanelE.2_embedding.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelE.2_embedding.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}
else if "`model'" == "20_32_16" {
estout reg_`task'* using "Output/TableA15_PanelE.3_node.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelE.3_node.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
}

	

}



	
}	

*** Panel F.1 ***
forv lag = 1/1 {



set sortseed 2

local pres = "event event_hat_lasso" 
local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	gen in1632 = (quarter_to_first >= 16 & quarter_to_first <= 32)
	bys company: egen sum1632 = sum(in1632)
	keep if sum1632 >= 17
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'
	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelF.1_balanced.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	


estout dd_`task'* using "Output/TableA14_PanelF.1_balanced.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	
	

	
}	

*** Panel F.2 ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 
local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}
	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place , ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelF.2_extended.tex", ///
replace style(tex) keep(15.quarter_to_first 42.quarter_to_first 15.semi_to_f_x_ca_x_with_c 42.semi_to_f_x_ca_x_with_c) ///
order(15.quarter_to_first 42.quarter_to_first 15.semi_to_f_x_ca_x_with_c 42.semi_to_f_x_ca_x_with_c) ///
varlabels(15.quarter_to_first "9 quarters before contract" 42.quarter_to_first "18 quarters after contract" 15.semi_to_f_x_ca_x_with_c "9 quarters before contract $\times$ public security" 42.semi_to_f_x_ca_x_with_c "18 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelF.2_extended.tex", ///
replace style(tex) keep(15.semi_to_f_x_ca_x_with_c 42.semi_to_f_x_ca_x_with_c) ///
order( 15.semi_to_f_x_ca_x_with_c 42.semi_to_f_x_ca_x_with_c) ///
varlabels(15.semi_to_f_x_ca_x_with_c "8 quarters before contract" 42.semi_to_f_x_ca_x_with_c "18 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

	
}	

*** Panel G.1 ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 

local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
gen shanghai = (prov == "上海市")
gen beijing = (prov == "北京市")
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (mean) shanghai beijing (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	
	gen year = yofd(dofq(qofd))
	
	replace shanghai = round(shanghai)
	replace beijing = round(beijing)
	forv jj = 2013/2019 {
		gen beijing_`jj' = beijing if year == `jj'
		replace beijing_`jj' = 0 if missing(beijing_`jj')
		gen shanghai_`jj' = shanghai if year == `jj'
		replace shanghai_`jj' = 0 if missing(shanghai_`jj')
	}
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data shanghai* beijing*, absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
}	


estout reg_`task'* using "Output/TableA15_PanelG.1_Beijing.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelG.1_Beijing.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

	
}	

*** Panel G.2 ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 

local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
drop if prov == "新疆维吾尔自治区"
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(24).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
}	


estout reg_`task'* using "Output/TableA15_PanelG.2_Xinjiang.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelG.2_Xinjiang.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label
	

	
}	

*** Panel G.3 ***
forv lag = 1/1 {


set sortseed 2

use "Data/firm_data.dta", clear

bys mother_firm_fe: gen city2 = cityid if _n == 1
collapse (last) city2, by(company)

rename city city_firm_base

tempfile a
save `a'
 

local pres = "event event_hat_lasso" 
local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
* mergeg and only keep data where prefecture different from home
merge n:1 company using `a', keep(1 3) nogen
keep if city != city_firm_base
	
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelG.3_prefecture.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelG.3_prefecture.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label
	
}	

*** Panel G.4 ***
forv lag = 1/1 {

set sortseed 2

use "Data/firm_data.dta", clear

bys mother_firm_fe: gen prov2 = provid if _n == 1

collapse (last) prov2, by(company)

rename prov prov_firm_base

tempfile a
save `a'
 

local pres = "event event_hat_lasso" 
local i = 0
foreach t in `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	
* mergeg and only keep data where prefecture different from home
merge n:1 company using `a', keep(1 3) nogen
keep if prov != prov_firm_base
	
	
	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelG.4_province.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelG.4_province.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label

	
}	

*** Panel H ***
forv lag = 1/1 {

set sortseed 2

local pres = "event event_hat_lasso" 

local geos "prov"
local times "qofd"
	
foreach geo in `geos' {
foreach time in `times' {
local i = 0
foreach t in  `"ALL"' `"GOVERNMENT"' `"BUSINESS"' {
foreach pre in `pres' {
use "Data/firm_data.dta", clear

* impute 0s for cities with no data
bys city: egen protest_count = count(`pre')
replace `pre' = 0 if protest_count == 0
replace `pre' = 0 if missing(`pre')

gen t0_`pre' = `pre' if quarter_to_first == 0 | missing(quarter_to_first)
bys sub_fe: egen mt0_`pre' = mean(t0_`pre')

* keep high unrest contracts
su mt0_`pre', d
keep if (mt0_`pre' > r(p50))
	

	local ip = "software"
	dis "`t'"
	
	
	** cleaning
	preserve 
	
	if "`t'" == "BUSINESS" | "`t'" == "GOVERNMENT" {
	keep if Customers_pred == `"`t'"' | Customers_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "AI-COMPLEMENTARY" {
	keep if Functions_pred == `"`t'"' | Functions_pred == ""
	gen n_`ip' = _n if `ip'_ID ~= "" // count number of software 
	}
	else if "`t'" == "SURVEILLANCE" {
	gen n_`ip' = _n if `ip'_ID ~= "" &  surveillance_dummy == 1 // count number of software  
	}
	else if "`t'" == "ALL" {
	gen n_`ip' = _n if `ip'_ID ~= ""
	}

	
	
	qui replace quarter_to_first = 0 if quarter_to_first == .
	qui collapse (count) n_`ip' (lastnm) place prov city, ///
		by(company mother_name mother_firm_fe quarter_to_first qtf qofd year with_contract_dummy sub_fe police_data)
		
	* gen cumulative number of software
	sort police_data company qofd qtf
	cap drop n_`ip'_cum
	gen n_`ip'_cum = n_`ip'
	replace n_`ip'_cum = n_`ip'_cum[_n-1] + n_`ip'_cum[_n] if company[_n] == company[_n-1] & with_contract_dummy == 1 & quarter_to_first >= -1
	keep if inrange(quarter_to_first,-24,24) & place != 0 // balance the number of periods before and after, not missing place
	replace quarter_to_first = quarter_to_first + 24
	
	* gen interaction term 

	gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
	gen semi_to_f_x_ca = quarter_to_first * police_data
	gen ca_x_with_c =  police_data * with_contract_dummy
	gen semi_to_f_x_with_c = quarter_to_first  * with_contract_dummy
	
	egen fe = group(`geo' `time')
	
	* col 1 and 2
	reghdfe n_`ip'_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
		i.with_contract_dummy ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca ///
		police_data , absorb(sub_fe fe qofd) cl(place)
		
	est sto reg_`task'_`i'
	
	addQuarterInter
	est sto dd_`task'_`i'

	
	restore 
	local i = `i' + 1
}
	
}

estout reg_`task'* using "Output/TableA15_PanelH_provqofd.tex", ///
replace style(tex) keep(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order(16.quarter_to_first 32.quarter_to_first 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.quarter_to_first "8 quarters before contract" 32.quarter_to_first "8 quarters after contract" 16.semi_to_f_x_ca_x_with_c "8 quarters before contract $\times$ public security" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract $\times$ public security") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label	

estout dd_`task'* using "Output/TableA14_PanelH_provqofd.tex", ///
replace style(tex) keep(16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
order( 16.semi_to_f_x_ca_x_with_c 32.semi_to_f_x_ca_x_with_c) ///
varlabels(16.semi_to_f_x_ca_x_with_c "8 quarters before contract" 32.semi_to_f_x_ca_x_with_c "8 quarters after contract") ///
 ml(, none) collabels(, none) ///
cells(b(star fmt(%9.3f)) se(par)) stats() ///
starlevels(* 0.10 ** 0.05 *** 0.01) label
	
}
}
	
}	


	
}	








	