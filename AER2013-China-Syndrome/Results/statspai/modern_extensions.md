# Modern-methods extensions (NOT part of the replication)

Headline spec: Table 3, cols 1 and 6. StatsPAI values vs external references.

| block | spec | statistic | StatsPAI / Python | reference | abs diff | reference source | note |
|---|---|---|---|---|---|---|---|
| weak_IV | c1 | F_eff (Olea-Pflueger) via sp.feols first stage t^2 | 97.539 | 97.539 | 1.0889e-06 | Stata weakivtest |  |
| weak_IV | c1 | F_eff via sp.effective_f_test (sqrt-w transform, extra intercept) | 97.504 | 97.539 | 0.03433 | Stata weakivtest | no weights= argument in sp.effective_f_test |
| weak_IV | c1 | AR 95% CI lower, Wald form (sp.feols reduced-form t^2, unrestricted residuals) | -0.89 |  |  |  | differs from weakiv by construction (variance at unrestricted residuals) |
| weak_IV | c1 | AR 95% CI upper, Wald form | -0.617 |  |  |  |  |
| weak_IV | c1 | AR 95% CI lower, score form (null-imposed cluster variance) | -0.9005 | -0.9005 | 0 | Stata weakiv (same grid) |  |
| weak_IV | c1 | AR 95% CI upper, score form (null-imposed cluster variance) | -0.599 | -0.599 | 0 | Stata weakiv (same grid) |  |
| weak_IV | c1 | AR set is a single bounded interval (1=yes) | 1 |  |  |  |  |
| weak_IV | c1 | sp.anderson_rubin_ci lower (UNWEIGHTED, homoskedastic) | -0.69645 |  |  |  | gap: no weights/cluster |
| weak_IV | c1 | sp.anderson_rubin_ci upper (UNWEIGHTED, homoskedastic) | -0.55008 |  |  |  | gap: no weights/cluster |
| weak_IV | c1 | sp.iv_diag effective F (sqrt-w transform) | 97.504 | 97.539 | 0.03433 | Stata weakivtest |  |
| weak_IV | c6 | F_eff (Olea-Pflueger) via sp.feols first stage t^2 | 47.643 | 47.643 | 6.1813e-08 | Stata weakivtest |  |
| weak_IV | c6 | F_eff via sp.effective_f_test (sqrt-w transform, extra intercept) | 47.879 | 47.643 | 0.23647 | Stata weakivtest | no weights= argument in sp.effective_f_test |
| weak_IV | c6 | AR 95% CI lower, Wald form (sp.feols reduced-form t^2, unrestricted residuals) | -0.854 |  |  |  | differs from weakiv by construction (variance at unrestricted residuals) |
| weak_IV | c6 | AR 95% CI upper, Wald form | -0.434 |  |  |  |  |
| weak_IV | c6 | AR 95% CI lower, score form (null-imposed cluster variance) | -0.827 | -0.827 | 0 | Stata weakiv (same grid) |  |
| weak_IV | c6 | AR 95% CI upper, score form (null-imposed cluster variance) | -0.3875 | -0.3875 | 0 | Stata weakiv (same grid) |  |
| weak_IV | c6 | AR set is a single bounded interval (1=yes) | 1 |  |  |  |  |
| weak_IV | c6 | sp.anderson_rubin_ci lower (UNWEIGHTED, homoskedastic) | -0.38177 |  |  |  | gap: no weights/cluster |
| weak_IV | c6 | sp.anderson_rubin_ci upper (UNWEIGHTED, homoskedastic) | -0.22709 |  |  |  | gap: no weights/cluster |
| weak_IV | c6 | sp.iv_diag effective F (sqrt-w transform) | 47.879 | 47.643 | 0.23647 | Stata weakivtest |  |
| wild_bootstrap | c1 | WRE 95% CI lower (sp.ivreg vce='wild', 9999 Rademacher) | -0.90726 | -0.87293 | 0.034331 | Stata boottest (9999 reps) |  |
| wild_bootstrap | c1 | WRE 95% CI upper | -0.56778 | -0.59386 | 0.026077 | Stata boottest (9999 reps) |  |
| wild_bootstrap | c1 | WRE p-value (H0: beta=0) | 0 | 0 | 0 | Stata boottest |  |
| wild_bootstrap | c6 | WRE 95% CI lower (sp.ivreg vce='wild', 9999 Rademacher) | -0.86086 | -0.7958 | 0.06506 | Stata boottest (9999 reps) |  |
| wild_bootstrap | c6 | WRE 95% CI upper | -0.351 | -0.32603 | 0.024965 | Stata boottest (9999 reps) |  |
| wild_bootstrap | c6 | WRE p-value (H0: beta=0) | 0 | 0 | 0 | Stata boottest |  |
| wild_bootstrap | c6u | UNWEIGHTED WRE 95% CI lower (sp.ivreg vce='wild') | -0.49553 | -0.5801 | 0.084563 | Stata boottest (unweighted) | sp CI = null-imposed bootstrap-t percentiles around beta_hat, boottest inverts the test |
| wild_bootstrap | c6u | UNWEIGHTED WRE 95% CI upper | -0.078041 | -0.11162 | 0.033582 | Stata boottest (unweighted) |  |
| wild_bootstrap | c6u | UNWEIGHTED WRE p-value | 0.0027003 | 0.0020002 | 0.00070007 | Stata boottest (unweighted) |  |
| shift_share | data | max |S g - ADH instrument| (BHJ shares x shocks) | 5.8595e-06 | 0 | 5.8595e-06 | ADH workfile |  |
| shift_share_AKM | BHJshares_weighted_sic3 | beta (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.59636 | -0.59636 | 8.0069e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_sic3 | se_ehw (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.095216 | 0.095216 | 2.6229e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_sic3 | se_akm (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.12649 | 0.12649 | 1.0103e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_sic3 | akm0_lo (Python port of ShiftShareSE, shares from sp-ready matrix) | -1.0181 | -1.0181 | 1.8015e-08 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_sic3 | akm0_hi (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.36182 | -0.36182 | 2.6457e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_sic3 | se_akm vs BHJ (2022) Table C2 col 1 | 0.12649 | 0.12649 | 1.0103e-09 | BHJ replication output |  |
| shift_share_AKM | BHJshares_weighted_sic3 | akm0_lo vs BHJ (2022) Table C2 col 1 | -1.0181 | -1.0181 | 1.8015e-08 | BHJ replication output |  |
| shift_share_AKM | BHJshares_weighted_sic3 | akm0_hi vs BHJ (2022) Table C2 col 1 | -0.36182 | -0.36182 | 2.6457e-09 | BHJ replication output |  |
| shift_share_AKM | BHJshares_weighted_nocluster | beta (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.59636 | -0.59636 | 8.0069e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_nocluster | se_ehw (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.095216 | 0.095216 | 2.6229e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_nocluster | se_akm (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.10942 | 0.10942 | 1.734e-10 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_nocluster | akm0_lo (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.89202 | -0.89202 | 1.4248e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_weighted_nocluster | akm0_hi (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.39188 | -0.39188 | 3.122e-09 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_unweighted_nocluster | beta (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.30283 | -0.30283 | 5.5189e-12 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_unweighted_nocluster | se_ehw (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.090163 | 0.090163 | 4.9372e-10 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_unweighted_nocluster | se_akm (Python port of ShiftShareSE, shares from sp-ready matrix) | 0.11033 | 0.11033 | 4.4129e-10 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_unweighted_nocluster | akm0_lo (Python port of ShiftShareSE, shares from sp-ready matrix) | -1.499 | -1.499 | 1.2375e-08 | R ShiftShareSE 1.1.0 |  |
| shift_share_AKM | BHJshares_unweighted_nocluster | akm0_hi (Python port of ShiftShareSE, shares from sp-ready matrix) | -0.16626 | -0.16626 | 7.242e-10 | R ShiftShareSE 1.1.0 |  |
| shift_share_statspai | unweighted | sp.BartikIV beta | -0.30283 | -0.30283 | 1.1582e-09 | R ShiftShareSE |  |
| shift_share_statspai | unweighted | sp.BartikIV HC1 SE | 0.090699 | 0.090163 | 0.00053547 | R ShiftShareSE EHW (no dof adj.) |  |
| shift_share_statspai | unweighted | sp.shift_share_se AKM SE | 0.007608 | 0.11033 | 0.10272 | R ShiftShareSE | BUG: uses fitted values as instrument |
| shift_share_statspai | unweighted | sp.ssaggregate beta | -0.30283 | -0.30283 | 1.1582e-09 | R ShiftShareSE |  |
| shift_share_statspai | unweighted | sp.ssaggregate AKM SE | 0.018206 | 0.11033 | 0.092122 | R ShiftShareSE | BUG: omits shock-level projection of the instrument |
| BHJ_shock_level | c1 | beta (industry-level IV, weights s_n) | -0.59636 | -0.596 | 0.00036008 | BHJ (2022) Table 4 |  |
| BHJ_shock_level | c1 | SE clustered by SIC3 | 0.11403 | 0.114 | 3.2568e-05 | BHJ (2022) Table 4 |  |
| BHJ_shock_level | c1 | shock-level first-stage F ((b/se)^2 of x on z instrumented by g) | 185.59 | 185.59 | 3.275e-05 | BHJ (2022) Table 4 |  |
| BHJ_shock_level | c3 | beta (industry-level IV, weights s_n) | -0.26668 | -0.267 | 0.00032133 | BHJ (2022) Table 4 |  |
| BHJ_shock_level | c3 | SE clustered by SIC3 | 0.099223 | 0.099 | 0.00022302 | BHJ (2022) Table 4 |  |
| BHJ_shock_level | c3 | shock-level first-stage F ((b/se)^2 of x on z instrumented by g) | 123.64 | 123.64 | 0.000405 | BHJ (2022) Table 4 |  |
| rotemberg | c6_weighted | sum of negative alpha_k (industry-collapsed) | -0.066903 | -0.067 | 9.7325e-05 | GPSS (2020) Table (ADH) panel A |  |
| rotemberg | c6_weighted | sum of positive alpha_k (industry-collapsed) | 1.0669 | 1.067 | 9.7325e-05 | GPSS (2020) Table (ADH) panel A |  |
| rotemberg | c6_weighted | sum of negative alpha_k (industry x period) | -0.12789 |  |  |  | GPSS panel A uses industry-collapsed weights |
| rotemberg | c6_weighted | sum alpha_k, 1990 shocks | 0.016892 | 0.017 | 0.00010818 | GPSS panel C |  |
| rotemberg | c6_weighted | sum alpha_k, 2000 shocks | 0.98311 | 0.983 | 0.00010818 | GPSS panel C |  |
| rotemberg | c6_weighted | alpha-weighted sum of beta_k = 2SLS beta | -0.59636 | -0.59636 | 1.8012e-08 | Table 3 col 6 |  |
| rotemberg | c6_weighted | alpha (summed over periods), SIC 3571 | 0.1826 | 0.183 | 0.00039953 | GPSS panel D |  |
| rotemberg | c6_weighted | alpha (summed over periods), SIC 3944 | 0.13756 | 0.138 | 0.00044424 | GPSS panel D |  |
| rotemberg | c6_weighted | alpha (summed over periods), SIC 3651 | 0.08539 | 0.085 | 0.00039006 | GPSS panel D |  |
| rotemberg | c6_weighted | alpha (summed over periods), SIC 3661 | 0.066248 | 0.066 | 0.00024757 | GPSS panel D |  |
| rotemberg | c6_weighted | alpha (summed over periods), SIC 3577 | 0.06019 | 0.06 | 0.0001904 | GPSS panel D |  |
| rotemberg | c6_unweighted | max |sp.BartikIV.rotemberg_weights - manual| (unweighted) | 3.7192e-15 | 0 | 3.7192e-15 | manual formula |  |
| rotemberg | c6_unweighted | sp.BartikIV top industry alpha (SIC 3944, unweighted) | 0.47154 |  |  |  | gap: no weights -> different ranking from GPSS |

Top-10 Rotemberg-weight industries (weighted, full controls):

|   sic87dd |   alpha | description                                                     |
|----------:|--------:|:----------------------------------------------------------------|
|      3571 |   0.183 | Electronic Computers                                            |
|      3944 |   0.138 | Games, Toys, and Children's Vehicles, Except Dolls and Bicycles |
|      3651 |   0.085 | Household Audio and Video Equipment                             |
|      3661 |   0.066 | Telephone and Telegraph Apparatus                               |
|      3577 |   0.060 | Computer Peripheral Equipment, Not Elsewhere Classified         |
|      3679 |   0.053 | Electronic Components, Not Elsewhere Classified                 |
|      3674 |   0.053 | Semiconductors and Related Devices                              |
|      2599 |   0.048 | Furniture and Fixtures, Not Elsewhere Classified                |
|      3555 |   0.039 | Printing Trades Machinery and Equipment                         |
|      3663 |   0.027 | Radio and Television Broadcasting and Communications Equipment  |

Runtime 256s
