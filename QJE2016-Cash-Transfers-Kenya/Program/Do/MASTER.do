// This is the master do-file for producing updated tables for Haushofer & Shapiro (QJE 2016).

version 13.1
clear all
clear matrix
clear mata
cap log close
set matsize 5000
set maxvar 20000
set more off
set seed 479316908

********************************************************************************
******************************* SET PATHS **************************************
********************************************************************************

cd ..

global root "`c(pwd)'"
global ado_dir "$root/Ado"
* [REPLICATION EDIT] project layout: Program/{Do,Ado}, Data/, Results/{Tables,Figures}
global data_dir "$root/../Data"
global output_dir "$root/../Results/Tables"
global figs_dir "$root/../Results/Figures"
global do_dir "$root/Do"

********************************************************************************
******************************* WHICH ANALYSES? ********************************
********************************************************************************

*** MAIN PAPER ***
global maketable1_flag = 1 // Baseline Balance for Index Variables
global maketable2_flag = 1 // Treatment Effects for Index Variables
global maketable3_flag = 1 // Spillover Effects for Index Variables
global maketable4_flag = 1 // Detailed Treatment Effects for Psych Wellbeing
global maketable5_flag = 1 // Detailed Treatment Effects for Consumption
global maketable6_flag = 1 // Detailed Treatment Effects for Assets and Enterprise
global maketableA1_flag = 1 // Ex post minimum detectable effect sizes

*** ONLINE APPENDIX ***
//Section 5: Description of Censusing and Recruitment
global OASection5_3_flag = 1 //Section 5.3: Unmatched Households

//Section 6: Village Summary Statistics
//Section 6.1: Village Summary Statistics Section
//Section 6.2: Comparision of Thatched and Metal Roof Households
global OASection6_flag = 1

//Section 7: Baseline Balance
global OASection7_1_flag = 1 // Section 7.1: Baseline Balance on Covariates

//Section 8: Attrition Analysis
global OASection8_1_flag = 1 // Section 8.1: Evaluating Attrition Level
global OASection8_2_flag = 1 // Section 8.2: Lee bounds on attrition at endline

//Section 9: Detailed Timing Analysis
global OASection9_1_flag = 1 // Section 9.1: Transfer and Survey Timeline
global OASection9_2_flag = 1 // Section 9.2: Timing Summary Statistics
global OASection9_3_flag = 1 // Section 9.3: Transfer and Survey Timing by Treament Status
global OASection9_4_flag = 1 // Section 9.4: Correlation of Timing with Baseline Characteristics
global OASection9_5_flag = 1 // Section 9.5: Controlling for Timing in Treament Effect Calculations
global OASection9_6_flag = 1 // Section 9.6: Controlling for Timing in Treament Arm Calculations
global OASection9_7_flag = 1 // Section 9.7: Temporal Evolution of Treatment Effects

//Section 10: Ex-post Power Calculations
global OASection10_1_flag = 1 // Section 10.1: Ex-post Power Calculations

//Section 12: Evaluating Metal Roof Household Characteristics
global OASection12_1_flag = 1 // Section 12.1: Baseline Balance on Immutable Characteristics
global OASection12_2_flag = 1 // Section 12.2: Determinants of Metal Roof Upgrade

//Section 13: Within-village Spillovers
global OASection13_1_flag = 1 // Section 13.1: Within Village Spillovers

//Section 14: Distributional Effects
global OASection14_1_flag = 1 // Section 14.1: Quantile Regressions

//Section 15: List Randomization for Alcohol and Tobacco Consumption
global OASection15_1_flag = 1 // Section 15.1: List Method

//Section 16: Assessing the Validity of Measures of Psychological Wellbeing
global OASection16_1_flag = 1 // Section 16.1: Predictors of Psychological well-being and Cortisol
global OASection16_2_flag = 1 // Section 16.2: Cronbach's Alpha for Psychological Scales

//Section 17: M-Pesa Use
global OASection17_1_flag = 1 // Section 17.1: Remittances and Savings with M-Pesa

//Section 18: Detailed Findings
global primary_effects_flag = 1 // Primary Treatment Effects
global baselinecontrols_flag = 1 // Primary Treatment Effects with baseline controls
global spillover_effects_flag = 1 // Spillover Effects
global acrossvillage_flag = 1 // Across village treatment effects
global femalerec_flag = 1 // Detailed effects by recipient gender
global monthly_flag = 1 // Detailed effects by monthly vs. lump sum
global large_flag = 1 // Detailed effects by large vs. small transfer
global respondent_flag = 1 // Detailed effects by respondent gender

//Section 19: Village Level Regressions
global OASection19_1_flag = 1 // Section 19.1: Village-level effects

* [REPLICATION EDIT] let Program/run_original.do run one step at a time (timing/rc per step)
if `"$UCT_ONLYSTEP"' != "" {
	foreach f in maketable1 maketable2 maketable3 maketable4 maketable5 maketable6 maketableA1 OASection5_3 OASection6 OASection7_1 OASection8_1 OASection8_2 OASection9_1 OASection9_2 OASection9_3 OASection9_4 OASection9_5 OASection9_6 OASection9_7 OASection10_1 OASection12_1 OASection12_2 OASection13_1 OASection14_1 OASection15_1 OASection16_1 OASection16_2 OASection17_1 primary_effects baselinecontrols spillover_effects acrossvillage femalerec monthly large respondent OASection19_1 {
		global `f'_flag = ("`f'" == "$UCT_ONLYSTEP")
	}
}

// Set iterations for FWER p-values
global stepdowniternow = 10000

// Set PPP Rate
global ppprate = 0.01601537

********************************************************************************
******************************* DEFINE OUTCOMES ********************************
********************************************************************************
global regvars ""

*** MAIN PAPER OUTCOMES  ***
//Indexes: Main Paper Tables 1, 2 and 3
global indices_ppp "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"
global indices_weighted "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"

//Psychological Wellbeing - Main Paper Table 4
global psyvars "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"
global psyvars_weighted "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"
global psyvars_weighted2 "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"

//Consumption - Main Paper Table 5
global cons_final "cons_allfood_ppp_m cons_cereals_ppp_m cons_meatfish_ppp_m cons_alcohol_ppp_m cons_tobacco_ppp_m cons_social_ppp_m cons_med_total_ppp_m  cons_ed_ppp_m cons_nondurable_ppp"

//Combined Assets and Enterprise - Main Paper Table 6
global assets_short "asset_total_ppp asset_livestock_ppp asset_durable_ppp asset_savings_ppp asset_land_owned_total asset_niceroof"
global ent_short "ent_wagelabor ent_ownfarm ent_nonagbusiness ent_total_rev_ppp ent_total_cost_ppp ent_total_profit_ppp"

*** APPENDIX OUTCOMES ***
// Indexes in Logs
global indicesln "asset_lntotal_ppp cons_lnnondurable_ppp ent_lntotal_rev_ppp"

// households only
global indices_ppphh "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index"

// Detailed Consumption: 1) Levels; 2) Logs
global consvarsnew_ppp_m "cons_allfood_ppp_m cons_ownfood_ppp_m cons_boughtfood_ppp_m cons_cereals_ppp_m cons_meatfish_ppp_m cons_fruitveg_ppp_m cons_dairy_ppp_m cons_fats_ppp_m cons_sugars_ppp_m cons_otherfood_ppp_m cons_alcohol_ppp_m cons_tobacco_ppp_m cons_med_total_ppp_m cons_med_children_ppp_m cons_ed_ppp_m cons_social_ppp_m cons_other_ppp cons_nondurable_ppp"
global consvarsln_ppp_m "cons_lnallfood_ppp_m cons_lnownfood_ppp_m cons_lnboughtfood_ppp_m cons_lncereals_ppp_m cons_lnmeatfish_ppp_m cons_lnfruitveg_ppp_m cons_lndairy_ppp_m cons_lnfats_ppp_m cons_lnsugars_ppp_m cons_lnotherfood_ppp_m cons_lnalcohol_ppp_m cons_lntobacco_ppp_m cons_lnmed_total_ppp_m cons_lnmed_children_ppp_m cons_lned_ppp_m cons_lnsocial_ppp_m cons_lnother_ppp cons_lnnondurable_ppp"

// Detailed Assets: 1) Levels; 2) Logs; (3) Levels with no metal roof variable
global assetvarsshort_ppp "asset_total_noroof_ppp asset_livestock_ppp asset_cows_ppp asset_smalllivestock_ppp asset_birds_ppp  asset_durable_ppp asset_furniture_ppp asset_ag_ppp asset_radiotv_ppp asset_trans_ppp asset_appliance_ppp asset_phone_ppp asset_savings_ppp asset_land_owned_total asset_niceroof"
global assetvarsln_ppp "asset_lntotal_noroof_ppp asset_lnlivestock_ppp asset_lncows_ppp asset_lnsmallstock_ppp asset_lnbirds_ppp asset_lndurable_ppp asset_lnfurniture_ppp asset_lnag_ppp asset_lnradiotv_ppp asset_lntrans_ppp asset_lnappliance_ppp asset_lnphone_ppp asset_lnsavings_ppp"
global assetvarsnoroof_ppp "asset_total_noroof_ppp asset_livestock_ppp asset_cows_ppp asset_smalllivestock_ppp asset_birds_ppp  asset_durable_ppp asset_furniture_ppp asset_ag_ppp asset_radiotv_ppp asset_trans_ppp asset_appliance_ppp asset_phone_ppp asset_savings_ppp asset_land_owned_total"

// Detailed Enterprise: 1) Levels; 2) Logs; 3) Conditional on Business Ownership
global entvars_ppp "ent_wagelabor ent_ownfarm ent_business ent_nonagbusiness ent_employees ent_nonag_revenue_ppp ent_nonag_flowcost_ppp ent_nonag_profit_ppp ent_nonag_profit_self_ppp ent_nonag_durables_ppp ent_farmrevenue_ppp ent_farmexpenses_ppp ent_farmprofit_ppp ent_animalflowrev_ppp ent_animalflowcost_ppp ent_animalflowprofit_ppp ent_animalstockrev_ppp ent_total_rev_ppp ent_total_cost_ppp ent_total_profit_ppp"
global entvarsln_ppp "ent_lnnonag_revenue_ppp ent_lnnonag_flowcost_ppp ent_lnnonag_profit_ppp ent_lnnonag_pro_slf_ppp ent_lnnonag_durables_ppp ent_lnfarmrevenue_ppp ent_lnfarmexpenses_ppp ent_lnfarmprofit_ppp ent_lnanimalflowrev_ppp ent_lnanimalflowcost_ppp ent_lnanimalflowprofit_ppp ent_lnanimalstockrev_ppp ent_lntotal_rev_ppp ent_lntotal_cost_ppp ent_lntotal_profit_ppp"
global entvars_cond_ppp "ent_nonag_revenue_ppp ent_nonag_flowcost_ppp ent_nonag_profit_ppp ent_nonag_profit_self_ppp ent_nonag_durables_ppp"

// Food Security
global fsvars "fs_adskipm_often fs_adwholed_often fs_chskipm_often fs_chwholed_often fs_hhcheapf_often fs_hhfriendf_often fs_foodcred_often fs_wildf_often fs_hhbeg_often fs_2meals fs_eatcont fs_meat fs_enoughtom fs_sleephun fs_selfprotein fs_hhfracprotein fs_childfracprotein  fs_childfoodindexnew fs_hhfoodindexnew"

// Health
global medvars_ppp "med_expenses_hh_ppp_ep med_expenses_sp_ppp_ep med_expenses_child_ppp_ep med_portion_sickinjured med_port_sick_child med_afford_port med_sickdays_hhave med_healthconsult med_vacc_newborns med_child_check med_u5_deaths bmitoage_HH_z heighttoage_HH_z weighttoage_HH_z armcirctoage_HH_z med_child_healthindex med_hh_healthindex"

// Education
global edvars_ppp "ed_expenses_ppp ed_expenses_perkid_ppp ed_schoolattend ed_sch_missedpc ed_work_act_pc ed_index"

// Household Finances
global finvars_ppp "fin_loansout_ppp fin_loan_norepay fin_remittances_sent_ppp fin_remittances_rec_ppp fin_remittances_net_ppp"

// Labor Variables
global laborvars "hh_propsalaried hh_propcasual hh_workactivities labor_primary wage_expenditures"

// Durable and Nondurable Investment
global investvars "durable_investment nondurable_investment"

*** CONTROL VARIABLES ***
// Main Effect Controls
global baselinecontrols "b_age b_married b_edu b_children b_hhsize asset_total_ppp0 cons_total_ppp0 ent_wagelabor0 ent_ownfarm0 ent_business0 ent_nonagbusiness0"

// Controls for Spillover analysis
global spillovercontrols "b_age b_married b_children b_hhsize b_edu"

// Controls for Unmatched HH analysis
global unmatched_vars "b_age b_married b_edu b_children b_hhsize ent_wagelabor0 ent_ownfarm0 ent_nonagbusiness0"

// Timing Controls
global timecontrols "endline_timing"

// MPESA ANALYSIS
global mpesavars "given_mpesa amount_given_mpesa received_mpesa amount_received_mpesa net_mpesa saved_mpesa amount_saved_mpesa"

********************************************************************************
********************************* CHECK DATA ***********************************
********************************************************************************

use "$data_dir/UCT_FINAL_CLEAN.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_MetalRoofHHs.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_UNMATCHED.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_Village_Collapsed.dta", clear
datasignature confirm, strict

********************************************************************************
******************************* WHICH DOFILES? *********************************
********************************************************************************


*** MAIN PAPER TABLES ***
// Baseline Balance
if $maketable1_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Baseline_Balance.do"
}

// Main Treatment Effects
if $maketable2_flag == 1 {
	global thesecontrol ""
	global controllabel ""
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Endline_Regs_Main.do"
}

// Spillover Effects
if $maketable3_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Endline_Regs_Spillover.do"
}

// Psychological Wellbeing
if $maketable4_flag == 1 {
	global thesecontrol ""
	global regvars ""psyvars""
	global controllabel ""
	do "$do_dir/UCT_Endline_Regs_Main.do"
}

// Consumption
if $maketable5_flag == 1 {
	global regvars ""cons_final""
	global thesecontrol ""
	global controllabel ""
	do "$do_dir/UCT_Endline_Regs_Main.do"
}

// Assets and Enterprise
if $maketable6_flag == 1 {
	global thesecontrol ""
	global regvars ""assets_ent_final""
	global controllabel ""
	do "$do_dir/UCT_Endline_Regs_Ent+Assets_Main.do"
}

// Ex post minimum detectable effect sizes
if $maketableA1_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_PowerCalcs.do"
}

*** APPENDIX TABLES ***

// Detailed Findings: Main Treatment Arms
if $primary_effects_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "finvars_ppp" "laborvars" "investvars""
	global thesecontrol ""
	global controllabel ""
	do "$do_dir/UCT_Endline_Regs_Main.do"
}

// Detailed Findings: Main Treatment Arms with Baseline Controls
if $baselinecontrols_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars""
	global thesecontrol "$baselinecontrols"
	global controllabel "_baseline_controls"
	do "$do_dir/UCT_Endline_Regs_Main.do"
	global thesecontrol ""
	global controllabel ""
}

// Detailed Findings: Spillover Effects
if $spillover_effects_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsnoroof_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars"" // Note that we can't include the indicator for metal roofs as an outcome in some of these analyses
	do "$do_dir/UCT_Endline_Regs_Spillover.do"
}

// Detailed Findings: Across Village Comparisions
if $acrossvillage_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsnoroof_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars""
	do "$do_dir/UCT_Endline_Regs_AcrossVillage.do"
}

// Detailed Findings: Recipient Gender
if $femalerec_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsnoroof_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars""
	do "$do_dir/UCT_Endline_Regs_RecGender.do"
}

// Detailed Findings: Monthly vs. Lump
if $monthly_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsnoroof_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars""
	do "$do_dir/UCT_Endline_Regs_Monthly.do"
}

// Detailed Findings: Large vs. Small
if $large_flag == 1 {
	global regvars ""indices_ppp" "indices_weighted" "indicesln" "consvarsnew_ppp_m" "consvarsln_ppp_m" "assetvarsshort_ppp" "assetvarsnoroof_ppp" "assetvarsln_ppp" "entvars_ppp" "entvarsln_ppp" "entvars_cond_ppp" "fsvars" "medvars_ppp" "psyvars" "psyvars_weighted" "psyvars_weighted2" "edvars_ppp" "laborvars" "investvars""
	do "$do_dir/UCT_Endline_Regs_LargeSmall.do"
}

// Detailed Findings: Respondent Gender
if $respondent_flag == 1 {
	global regvars ""psyvars"" // Only individual-level measures
	do "$do_dir/UCT_Endline_Regs_RespondentGender.do"
}

//Section 5: Description of Censusing and Recruitment
//Section 5.3: Unmatched Households
if $OASection5_3_flag == 1 {
	global regvars ""baselinecontrols" "indices_ppp""
	do "$do_dir/UCT_UnmatchedHH_Balance.do" // Balance of these households on baseline characteristics
}

//Section 6: Village Summary Statistics
if $OASection6_flag == 1 {
	do "$do_dir/UCT_Population_Analysis.do" // Total population, % sample, % treated
	//Section 6.2: Comparision of Thatched and Metal Roof Households
	do "$do_dir/UCT_MetalRoof_Analysis.do" // Compare baseline consumption with metal roof
}

//Section 7: Baseline Balance
//Section 7.1: Baseline Balance on Covariates
if $OASection7_1_flag == 1 {
	global regvars ""baselinecontrols""
	do "$do_dir/UCT_Baseline_Balance.do"
}

//Section 8: Attrition Analysis
//Section 8.1: Evaluating Attrition Level
if $OASection8_1_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Attrition_Analysis.do"
}
//Section 8.2: Lee bounds on attrition at endline
if $OASection8_2_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_LeeBounds.do"
}

//Section 9: Detailed Timing Analysis
//Section 9.1: Transfer and Survey Timeline
if $OASection9_1_flag == 1 do "$do_dir/UCT_Timing_Graph.do"

//Section 9.2: Timing Summary Statistics
if $OASection9_2_flag == 1 do "$do_dir/UCT_Timing_Summary_Stats.do"

//Section 9.3: Transfer and Survey Timing by Treament Status
if $OASection9_3_flag == 1 do "$do_dir/UCT_Timing_TreatmentStatus.do"

//Section 9.4: Correlation of Timing with Baseline Characteristics
if $OASection9_4_flag == 1 do "$do_dir/UCT_Timing_BaselineVars.do"

//Section 9.5: Controlling for Timing in Treament Effect Calculations
if $OASection9_5_flag == 1 {
	global regvars ""indices_ppp""
	global thesecontrol "$timecontrols"
	global controllabel "_timing_controls"
	do "$do_dir/UCT_Endline_Regs_Main.do"
}
//Section 9.6: Controlling for Timing in Treament Arm Calculations
if $OASection9_6_flag == 1 do "$do_dir/UCT_Timing_TreatmentArm.do"

//Section 9.7: Temporal Evolution of Treatment Effects
if $OASection9_7_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Temporal_Evolution_Table.do"
	do "$do_dir/UCT_Temporal_Evolution_Figure.do"
}

//Section 10: Ex-post Power Calculations
if $OASection10_1_flag == 1 { // Section 10.1: Ex-post Power Calculations
	global regvars ""indices_ppp" "psyvars" "consvarsnew_ppp_m" "assetvarsshort_ppp" "entvars_ppp""
	do "$do_dir/UCT_PowerCalcs.do"
}

//Section 12: Evaluating Metal Roof Household Characteristics
//Section 12.1: Baseline Balance on Immutable Characteristics
if $OASection12_1_flag == 1 {
	global immutable_baseline "b_age b_married b_children b_hhsize b_edu" // set immutable characteristics to test
	do "$do_dir/UCT_PC_Baseline.do"
}
//Section 12.2: Determinants of Metal Roof Upgrade
if $OASection12_2_flag == 1 do "$do_dir/UCT_RoofUpgrade_Predictors.do"

//Section 13: Within-village Spillovers
//Section 13.1: Within Village Spillovers
if $OASection13_1_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_InVillage_Spillover.do"
}

//Section 14: Distributional Effects
//Section 14.1: Quantile Regressions
if $OASection14_1_flag == 1 {
	global regvars ""indices_ppp""
	do "$do_dir/UCT_Quantile_Regs.do"
}

//Section 15: List Randomization for Alcohol and Tobacco Consumption
//Section 15.1: List Method
if $OASection15_1_flag == 1 do "$do_dir/UCT_Endline_ListMethod.do"

//Section 16: Assessing the Validity of Measures of Psychological Wellbeing
//Section 16.1: Predictors of Psychological well-being and Cortisol
if $OASection16_1_flag == 1 do "$do_dir/UCT_Psych_Correlations.do"
//Section 16.2: Cronbach's Alpha for Psychological Scales
if $OASection16_2_flag == 1 do "$do_dir/UCT_Psych_Alpha.do"

//Section 17: M-Pesa Use
//Section 17.1: Remittances and Savings with M-Pesa
if $OASection17_1_flag == 1 do "$do_dir/UCT_MPESA_Use.do"

//Section 19: Village Level Regressions
//Section 19.1: Village-level effects
if $OASection19_1_flag == 1 {
	do "$do_dir/UCT_Village_Analysis.do"

}
