************************************
************************************
************************************ This dofile could generate key tables and figures in the paper
************************************ in the order which they are cited in the text
************************************
************************************

clear


*********
********* Change directory to Replication/
*********
cd D:/Dropbox/Xiangjun/FinalFiles/Replication/




log using "Results/All_in_One.log", replace 

********************************************************************************

******** Table 1: Summary Statistics 


do Programs/Table_1.do


******** Table A3: Elite Connections and Other Characteristics cross Counties


do Programs/Appendix_Table_A3.do


******** Figure 3. Motivational Evidence on Elite Networks and Soldier Deaths: Raw Data


do Programs/Figure_3.do


******** Figure A.5. II. Number of National-level Offices and Officials Over Time


do Programs/Appendix_Figure_A5.do


******** Table 2. The Impact of Elite Connections on Soldier Deaths: DD Estimates


do Programs/Table_2.do


******* Table B.1. I. The Impact of Elite Connections on Soldier Deaths: Checking Outliers


do Programs/Appendix_Table_B1_I.do


******* Table B.1. II. The Impact of Elite Connections on Soldier Deaths


do Programs/Appendix_Table_B1_II.do


******* Table B.1. III. The Impact of Elite Connections on Soldier Deaths: Spatial Clustering S.E.


do Programs/Appendix_Table_B1_III.do


******* Table B.1. IV. The Impact of Elite Connections on Soldier Deaths: Controls X Year FE


do Programs/Appendix_Table_B1_IV.do


******* Table B.2. Yearly Effects of Elite Connections


do Programs/Appendix_Table_B2.do


******* Table 3. The Impact of Elite Connections on Soldier Deaths: Types of Links


do Programs/Table_3.do


******* Table 4. The Impact of Elite Connections on Soldier Deaths: Placebo Networks


do Programs/Table_4.do


******* Figure 4. The Impact of Elite Connections on Soldier Deaths: Year-by-Year Estimates


do Programs/Figure_4.do


******* Table B.4. The Impact of Elite Connections on Soldier Deaths: Controlling for Physical Distance to Zeng


do Programs/Appendix_Table_B4.do


******* Table B.5. I. Elite Networks and Data Missing


do Programs/Appendix_Table_B5_I.do


******* Table B.5. II. The Impact of Elite Connections on Soldier Deaths: Degree-Holders vs. Commoners


do Programs/Appendix_Table_B5_II.do


******* Table B.6. I. What Does the Number of Soldier Deaths Measure?


do Programs/Appendix_Table_B6_I.do


******* Table B.6. II. The Battle of Three Rivers vs. Other Battles in 1858


do Programs/Appendix_Table_B6_II.do


******** Table 5. The Impact of Elite Connections on Elite Power: DD and DDD Estimates


do Programs/Table_5.do


******** Figure 5. Motivational Evidence for the Power Effect: National-level Offices by Connection-Province


do Programs/Figure_5.do


******** Table 6. The Power Effect: the Role of Soldier Deaths


do Programs/Table_6.do


******** Figure 6. The Dynamics Impacts of Elite Network on National-level Offices


do Programs/Figure_6.do


******** Figure C.1. Understanding the Fluctuation of the Power Impact


do Programs/Appendix_Figure_C1.do


******** Table C.2. The Impact of Elite Networks on Elite Power: Inside and Outside the Network


do Programs/Appendix_Table_C2.do


******** Table C.3. The Impact of Elite Networks on Exam Quotas and Numbers of Jinshi


do Programs/Appendix_Table_C3.do



******** Figure 7. National-level Power Distribution and the Contribution of Elite Networks


do Programs/Figure_7.do


******** Table C.4. The Impact of Elite Networks on Elite Power
******** Observation of Zeros in Our Data on National-level Offices


do Programs/Appendix_Table_C4.do


******** Table C.5. The Impact of Elite Networks and Elite Power: Varying Comparison Provinces


do Programs/Appendix_Table_C5.do


******** Table C.6. The Impact of Elite Networks and Elite Power: Controlling for Placebo Networks


do Programs/Appendix_Table_C6.do



*********Table C.7. The Changes in Power Distribution by Decade


do Programs/Appendix_Table_C7.do


******** Figure 8. The Share of Provincial Officials from Connected Counties in Hunan


do Programs/Figure_8.do



clear 
log close



