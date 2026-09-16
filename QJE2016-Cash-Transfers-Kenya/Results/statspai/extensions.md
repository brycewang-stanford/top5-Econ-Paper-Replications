# Modern-methods extensions (NOT replication)

## 1. Randomization inference, Table II col (2) (2000 permutations)

`p_ri_within_village`: households re-randomised to treatment within village (the actual design), statistic = areg coefficient with baseline-outcome controls. `sp.ri_test` can only permute the whole vector (no strata), so its diff-in-means p is shown for contrast.

| outcome              | label                          |   coef_areg |   p_ri_within_village |   sp_ri_test_diffmeans_unstratified_p |   sp_ri_test_observed_diffmeans |
|:---------------------|:-------------------------------|------------:|----------------------:|--------------------------------------:|--------------------------------:|
| asset_total_ppp1     | Value of non-land assets (USD) |    301.507  |                0      |                                0      |                        296.121  |
| cons_nondurable_ppp1 | Non-durable expenditure (USD)  |     35.6574 |                0      |                                0      |                         33.596  |
| ent_total_rev_ppp1   | Total revenue, monthly (USD)   |     16.1525 |                0.003  |                                0.0315 |                         13.0467 |
| fs_hhfoodindexnew1   | Food security index            |      0.2554 |                0      |                                0      |                          0.2478 |
| med_hh_healthindex1  | Health index                   |     -0.0341 |                0.5815 |                                0.6745 |                         -0.0264 |
| ed_index1            | Education index                |      0.0802 |                0.1685 |                                0.696  |                          0.0254 |
| psy_index_z1         | Psychological well-being index |      0.2559 |                0      |                                0      |                          0.2449 |
| ih_overall_index_z1  | Female empowerment index       |     -0.0104 |                0.8875 |                                0.845  |                         -0.0145 |

## 2. Table III col (1): village-clustered SE, wild cluster bootstrap, village-level RI

| outcome              | label                          |    beta |   se_cluster_village |   p_cluster |   p_wild_rademacher |   ci_wild_lo |   ci_wild_hi |   p_ri_village_level |   n_villages |
|:---------------------|:-------------------------------|--------:|---------------------:|------------:|--------------------:|-------------:|-------------:|---------------------:|-------------:|
| asset_total_ppp1     | Value of non-land assets (USD) |  0.9999 |              21.4367 |      0.9629 |              0.964  |     -41.5969 |      42.3104 |               0.9655 |          123 |
| cons_nondurable_ppp1 | Non-durable expenditure (USD)  | -7.7681 |               7.1998 |      0.2827 |              0.2731 |     -22.2315 |       5.8259 |               0.2825 |          123 |
| ent_total_rev_ppp1   | Total revenue, monthly (USD)   | -3.6768 |               6.1792 |      0.5529 |              0.5393 |     -16.1076 |       8.3894 |               0.5555 |          123 |
| fs_hhfoodindexnew1   | Food security index            |  0.0553 |               0.0932 |      0.5541 |              0.5783 |      -0.1349 |       0.2463 |               0.5595 |          123 |
| med_hh_healthindex1  | Health index                   | -0.0582 |               0.0775 |      0.4539 |              0.4542 |      -0.2113 |       0.0986 |               0.4455 |          123 |
| ed_index1            | Education index                |  0.0129 |               0.0715 |      0.8576 |              0.8619 |      -0.1282 |       0.1499 |               0.8645 |          122 |
| psy_index_z1         | Psychological well-being index |  0.0323 |               0.0731 |      0.659  |              0.6648 |      -0.1181 |       0.1731 |               0.6555 |          123 |
| ih_overall_index_z1  | Female empowerment index       |  0.2146 |               0.0862 |      0.0141 |              0.0215 |       0.0392 |       0.3858 |               0.014  |          122 |

## 3. Causal forest CATEs (sp.causal_forest, 1000 trees)

| outcome              | label                          |    N |   forest_ate |   cate_mean |   cate_sd |   cate_baseline_asset_Q1 |   cate_baseline_asset_Q2 |   cate_baseline_asset_Q3 |   cate_baseline_asset_Q4 |
|:---------------------|:-------------------------------|-----:|-------------:|------------:|----------:|-------------------------:|-------------------------:|-------------------------:|-------------------------:|
| asset_total_ppp1     | Value of non-land assets (USD) |  939 |      333.469 |     333.469 |    32.322 |                  331.119 |                  325.512 |                  329.318 |                  347.908 |
| cons_nondurable_ppp1 | Non-durable expenditure (USD)  |  939 |       32.142 |      32.142 |     9.833 |                   23.473 |                   32.728 |                   37.506 |                   34.885 |
| fs_hhfoodindexnew1   | Food security index            |  939 |        0.267 |       0.267 |     0.144 |                    0.183 |                    0.259 |                    0.332 |                    0.294 |
| psy_index_z1         | Psychological well-being index | 1473 |        0.19  |       0.19  |     0.12  |                    0.104 |                    0.177 |                    0.236 |                    0.245 |

Variable importance:

|                    |   asset_total_ppp1 |   cons_nondurable_ppp1 |   fs_hhfoodindexnew1 |   psy_index_z1 |
|:-------------------|-------------------:|-----------------------:|---------------------:|---------------:|
| b_age              |              0.202 |                  0.255 |                0.18  |          0.176 |
| b_married          |              0.169 |                  0.222 |                0.155 |          0.171 |
| b_edu              |              0.15  |                  0.118 |                0.146 |          0.129 |
| b_children         |              0.111 |                  0.116 |                0.141 |          0.122 |
| b_hhsize           |              0.077 |                  0.092 |                0.108 |          0.116 |
| asset_total_ppp0   |              0.068 |                  0.075 |                0.092 |          0.075 |
| cons_total_ppp0    |              0.066 |                  0.048 |                0.056 |          0.065 |
| ent_wagelabor0     |              0.057 |                  0.035 |                0.047 |          0.054 |
| ent_ownfarm0       |              0.054 |                  0.02  |                0.047 |          0.044 |
| ent_nonagbusiness0 |              0.045 |                  0.019 |                0.029 |          0.028 |
| femaleres          |              0     |                  0     |                0     |          0.02  |

## 4. Quantile treatment effects (sp.qreg) -> fig_oa_quantile_effects.png

| label                          |   0.1 |    0.2 |    0.3 |    0.4 |    0.5 |    0.6 |    0.7 |    0.8 |    0.9 |
|:-------------------------------|------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|
| Education index                | -0    |   0.06 |   0.05 |   0.04 |   0.06 |   0.02 |   0.01 |   0.04 |   0.04 |
| Female empowerment index       |  0.04 |   0.03 |   0.07 |   0.08 |   0.02 |  -0.05 |  -0.02 |  -0.02 |  -0    |
| Food security index            |  0.22 |   0.28 |   0.27 |   0.24 |   0.23 |   0.18 |   0.2  |   0.29 |   0.3  |
| Health index                   |  0.05 |   0.1  |   0.04 |  -0    |   0.02 |   0.02 |  -0.12 |  -0.1  |  -0.03 |
| Non-durable expenditure (USD)  | 16.04 |  16.69 |  16.45 |  23.17 |  29.88 |  41.23 |  41.27 |  50.84 |  68.86 |
| Psychological well-being index |  0.27 |   0.28 |   0.31 |   0.27 |   0.22 |   0.24 |   0.23 |   0.19 |   0.15 |
| Total revenue, monthly (USD)   |  1.72 |   2.11 |   2.4  |   3.73 |   6.91 |  11.37 |  12.68 |  26.73 |  57.39 |
| Value of non-land assets (USD) | 77.08 | 116.84 | 190.76 | 252.07 | 377.43 | 501.79 | 518.66 | 374.43 | 352.34 |

## 5. Baseline balance (sp.balance_diagnostics, treat vs spillover, female-respondent rows)

| variable           |   mean_treat |   mean_control |   weighted_mean_treat |   weighted_mean_control |   smd_raw |   smd_weighted |   variance_ratio_weighted |   ks_stat_weighted | balanced   |
|:-------------------|-------------:|---------------:|----------------------:|------------------------:|----------:|---------------:|--------------------------:|-------------------:|:-----------|
| b_age              |       34.17  |         35.351 |                34.762 |                  34.76  |    -0.085 |          0     |                     1.047 |              0.029 | True       |
| b_married          |        0.783 |          0.784 |                 0.783 |                   0.783 |    -0.003 |         -0     |                     1     |              0     | True       |
| b_edu              |        8.823 |          8.535 |                 8.68  |                   8.678 |     0.1   |          0.001 |                     0.999 |              0.029 | True       |
| b_children         |        2.926 |          2.881 |                 2.906 |                   2.904 |     0.024 |          0.001 |                     0.9   |              0.036 | True       |
| b_hhsize           |        4.97  |          4.945 |                 4.957 |                   4.956 |     0.012 |          0.001 |                     0.977 |              0.019 | True       |
| asset_total_ppp0   |      380.712 |        383.361 |               381.411 |                 381.631 |    -0.007 |         -0.001 |                     1.156 |              0.044 | True       |
| cons_total_ppp0    |      179.6   |        184.818 |               182.772 |                 182.536 |    -0.039 |          0.002 |                     1.371 |              0.065 | True       |
| ent_wagelabor0     |        0.265 |          0.246 |                 0.256 |                   0.256 |     0.044 |         -0     |                     1     |              0     | True       |
| ent_ownfarm0       |        0.353 |          0.366 |                 0.359 |                   0.359 |    -0.029 |         -0     |                     1     |              0     | True       |
| ent_business0      |        0.145 |          0.16  |                 0.153 |                   0.154 |    -0.042 |         -0     |                     1     |              0     | True       |
| ent_nonagbusiness0 |        0.378 |          0.36  |                 0.37  |                   0.37  |     0.037 |          0     |                     1     |              0     | True       |
