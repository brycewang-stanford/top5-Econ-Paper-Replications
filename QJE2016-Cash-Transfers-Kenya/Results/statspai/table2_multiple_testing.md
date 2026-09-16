# Table II: multiple-testing adjustments

| arm     | outcome              |   p_naive |   p_bonferroni |   p_holm |   p_bh |   p_fwer_author_stepdown_port |
|:--------|:---------------------|----------:|---------------:|---------:|-------:|------------------------------:|
| treat   | asset_total_ppp1     |    0      |         0      |   0      | 0      |                        0      |
| treat   | cons_nondurable_ppp1 |    0      |         0      |   0      | 0      |                        0      |
| treat   | ent_total_rev_ppp1   |    0.0061 |         0.049  |   0.0245 | 0.0098 |                        0.0231 |
| treat   | fs_hhfoodindexnew1   |    0      |         0.0003 |   0.0002 | 0.0001 |                        0.0001 |
| treat   | med_hh_healthindex1  |    0.5789 |         1      |   1      | 0.6616 |                        0.8209 |
| treat   | ed_index1            |    0.1719 |         1      |   0.5157 | 0.2292 |                        0.4312 |
| treat   | psy_index_z1         |    0      |         0      |   0      | 0      |                        0      |
| treat   | ih_overall_index_z1  |    0.882  |         1      |   1      | 0.882  |                        0.8809 |
| female  | asset_total_ppp1     |    0.1151 |         0.9209 |   0.6907 | 0.307  |                        0.4932 |
| female  | cons_nondurable_ppp1 |    0.8457 |         1      |   1      | 0.8457 |                        0.9192 |
| female  | ent_total_rev_ppp1   |    0.6102 |         1      |   1      | 0.6974 |                        0.9192 |
| female  | fs_hhfoodindexnew1   |    0.5088 |         1      |   1      | 0.6785 |                        0.9192 |
| female  | med_hh_healthindex1  |    0.2317 |         1      |   1      | 0.4634 |                        0.701  |
| female  | ed_index1            |    0.4786 |         1      |   1      | 0.6785 |                        0.9192 |
| female  | psy_index_z1         |    0.0697 |         0.5572 |   0.5572 | 0.307  |                        0.4324 |
| female  | ih_overall_index_z1  |    0.0962 |         0.7697 |   0.6735 | 0.307  |                        0.4932 |
| monthly | asset_total_ppp1     |    0.0458 |         0.3661 |   0.3203 | 0.183  |                        0.2715 |
| monthly | cons_nondurable_ppp1 |    0.6947 |         1      |   1      | 0.9009 |                        0.993  |
| monthly | ent_total_rev_ppp1   |    0.1407 |         1      |   0.8441 | 0.3752 |                        0.5871 |
| monthly | fs_hhfoodindexnew1   |    0.017  |         0.1364 |   0.1364 | 0.1364 |                        0.1129 |
| monthly | med_hh_healthindex1  |    0.9009 |         1      |   1      | 0.9009 |                        0.993  |
| monthly | ed_index1            |    0.6332 |         1      |   1      | 0.9009 |                        0.993  |
| monthly | psy_index_z1         |    0.8638 |         1      |   1      | 0.9009 |                        0.993  |
| monthly | ih_overall_index_z1  |    0.649  |         1      |   1      | 0.9009 |                        0.993  |
| large   | asset_total_ppp1     |    0      |         0      |   0      | 0      |                        0      |
| large   | cons_nondurable_ppp1 |    0.043  |         0.344  |   0.2458 | 0.086  |                        0.2107 |
| large   | ent_total_rev_ppp1   |    0.783  |         1      |   1      | 0.783  |                        0.8277 |
| large   | fs_hhfoodindexnew1   |    0.0687 |         0.5496 |   0.2748 | 0.1099 |                        0.2438 |
| large   | med_hh_healthindex1  |    0.3343 |         1      |   1      | 0.4457 |                        0.6888 |
| large   | ed_index1            |    0.5962 |         1      |   1      | 0.6814 |                        0.8277 |
| large   | psy_index_z1         |    0.0007 |         0.0055 |   0.0048 | 0.0027 |                        0.0029 |
| large   | ih_overall_index_z1  |    0.041  |         0.3277 |   0.2458 | 0.086  |                        0.2107 |

Bonferroni/Holm/BH via sp.bonferroni/sp.holm/sp.benjamini_hochberg on the naive p-values; last column = port of the authors' permutation stepdown (Westfall-Young style).

## sp.romano_wolf (extension, common sample)

| outcome              |     coef |      se |       t |   p_value |   p_rw |   p_bonf |   p_holm |   p_bh | note                                                                                                            |
|:---------------------|---------:|--------:|--------:|----------:|-------:|---------:|---------:|-------:|:----------------------------------------------------------------------------------------------------------------|
| asset_total_ppp1     | 310.352  | 28.0205 | 11.0759 |    0      | 0      |   0      |   0      | 0      | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
| cons_nondurable_ppp1 |  38.6654 |  5.9776 |  6.4683 |    0      | 0      |   0      |   0      | 0      | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
| ent_total_rev_ppp1   |  17.3243 |  6.0848 |  2.8471 |    0.0045 | 0.001  |   0.0271 |   0.0136 | 0.0068 | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
| fs_hhfoodindexnew1   |   0.3175 |  0.0591 |  5.3707 |    0      | 0      |   0      |   0      | 0      | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
| med_hh_healthindex1  |   0.061  |  0.0524 |  1.1658 |    0.244  | 0.2255 |   1      |   0.4485 | 0.244  | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
| ed_index1            |   0.0701 |  0.0577 |  1.2162 |    0.2243 | 0.2255 |   1      |   0.4485 | 0.244  | sp.romano_wolf, complete cases N=823, village-demeaned, common baseline controls, cluster bootstrap 2000 (210s) |
