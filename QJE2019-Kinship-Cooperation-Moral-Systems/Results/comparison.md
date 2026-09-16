# Comparison: paper vs original Stata code vs StatsPAI

Enke (2019), *Kinship, Cooperation, and the Evolution of Moral Systems*, QJE 134(2): 953–1019.

* **Paper** = published QJE tables (Materials/ PDF). **Stata** = the author's unmodified do-files run by
  `Program/run_original.do` (Stata 18 MP), coefficients dumped at 6 decimals by `Program/run_precise.do`.
  **StatsPAI** = `Program/statspai/replicate_statspai.py` (statspai 1.28.0, `sp.feols` / `sp.bootstrap`).
* Match rule: value rounded to the decimals printed in the paper must equal the printed value; N identical.
* ✅ match at reported precision · ⚠️ small difference, explained · ❌ failure.
* Bootstrap columns (Table III cols 4–11, Table IV cols 1, 2, 6, 7): 500 cluster-bootstrap reps, and the author
  sets no seed, so SEs are Monte-Carlo draws. Our Stata run uses `set seed 20190001`; StatsPAI uses its own RNG.
  If the coefficient matches exactly and such an SE is within 10% of the printed value it is marked ⚠️
  (rule: |SE − printed| ≤ 0.005 rounding half-width + 10% of printed value; the bootstrap Monte-Carlo s.d. of an SE with B=500 is ~3%), not ❌.

## Summary

| Table | Coefficients compared | ✅ | ⚠️ | ❌ |
|---|---|---|---|---|
| III | 20 | 17 | 3 | 0 |
| IV | 17 | 13 | 4 | 0 |
| V | 7 | 7 | 0 | 0 |
| VI | 8 | 8 | 0 | 0 |
| VII | 14 | 14 | 0 | 0 |
| VIII | 8 | 8 | 0 | 0 |
| IX | 8 | 8 | 0 | 0 |
| X | 3 | 3 | 0 | 0 |
| XI | 9 | 9 | 0 | 0 |

## Table III

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `s_malariaindex` | 0.12 (0.01) | 0.1234 (0.0149) | 0.1234 (0.0149) | 4.1e-07 / 1.9e-07 | 1,226 / 1,226 / 1,226 | ✅  |
| 2 | `s_malariaindex` | 0.098 (0.01) | 0.0981 (0.0120) | 0.0981 (0.0119) | 4.6e-07 / 2.1e-08 | 1,225 / 1,225 / 1,225 | ✅  |
| 3 | `s_malariaindex` | 0.033 (0.01) | 0.0327 (0.0131) | 0.0327 (0.0131) | 4.5e-07 / 1.7e-07 | 1,216 / 1,216 / 1,216 | ✅  |
| 4 | `s_malariaindex` | 0.031 (0.02) | 0.0311 (0.0138) | 0.0311 (0.0150) | 3.0e-07 / 1.2e-03 | 504 / 504 / 504 | ⚠️ bootstrap SE noise |
| 5 | `s_malariaindex` | 0.030 (0.01) | 0.0298 (0.0123) | 0.0298 (0.0121) | 1.2e-07 / 2.0e-04 | 504 / 504 / 504 | ✅  |
| 10 | `s_malariaindex` | 0.025 (0.01) | 0.0255 (0.0122) | 0.0255 (0.0122) | 3.1e-07 / 4.2e-05 | 500 / 500 / 500 | ✅  |
| 2 | `small_scale` | -0.35 (0.09) | -0.3502 (0.0863) | -0.3502 (0.0863) | 3.0e-07 / 3.5e-07 | 1,225 / 1,225 / 1,225 | ✅  |
| 3 | `small_scale` | -0.17 (0.10) | -0.1729 (0.0967) | -0.1729 (0.0967) | 3.7e-07 / 3.9e-07 | 1,216 / 1,216 / 1,216 | ✅  |
| 5 | `small_scale` | -0.42 (0.19) | -0.4217 (0.1847) | -0.4217 (0.1905) | 3.4e-07 / 5.8e-03 | 504 / 504 / 504 | ⚠️ bootstrap SE noise |
| 7 | `small_scale` | -0.39 (0.16) | -0.3895 (0.1552) | -0.3895 (0.1626) | 4.2e-07 / 7.4e-03 | 501 / 501 / 501 | ✅  |
| 9 | `small_scale` | -0.41 (0.18) | -0.4101 (0.1846) | -0.4101 (0.1806) | 4.1e-07 / 4.0e-03 | 500 / 500 / 500 | ✅  |
| 10 | `small_scale` | -0.41 (0.16) | -0.4081 (0.1462) | -0.4081 (0.1541) | 3.7e-07 / 7.9e-03 | 500 / 500 / 500 | ⚠️ bootstrap SE noise |
| 11 | `small_scale` | -0.37 (0.15) | -0.3660 (0.1467) | -0.3660 (0.1458) | 3.0e-07 / 8.6e-04 | 497 / 497 / 497 | ✅  |
| 6 | `s_distance_mutation` | -0.058 (0.02) | -0.0576 (0.0246) | -0.0576 (0.0249) | 3.4e-07 / 3.7e-04 | 501 / 501 / 501 | ✅  |
| 7 | `s_distance_mutation` | -0.053 (0.02) | -0.0531 (0.0167) | -0.0531 (0.0164) | 2.8e-07 / 2.7e-04 | 501 / 501 / 501 | ✅  |
| 11 | `s_distance_mutation` | -0.041 (0.02) | -0.0413 (0.0173) | -0.0413 (0.0181) | 3.8e-08 / 8.6e-04 | 497 / 497 / 497 | ✅  |
| 8 | `s_tsi` | 0.035 (0.01) | 0.0350 (0.0080) | 0.0350 (0.0076) | 1.6e-07 / 3.4e-04 | 500 / 500 / 500 | ✅  |
| 9 | `s_tsi` | 0.041 (0.01) | 0.0410 (0.0076) | 0.0410 (0.0068) | 2.5e-07 / 7.7e-04 | 500 / 500 / 500 | ✅  |
| 10 | `s_tsi` | 0.038 (0.01) | 0.0380 (0.0097) | 0.0380 (0.0082) | 2.4e-07 / 1.5e-03 | 500 / 500 / 500 | ✅  |
| 11 | `s_tsi` | 0.019 (0.01) | 0.0192 (0.0090) | 0.0192 (0.0093) | 5.2e-08 / 3.2e-04 | 497 / 497 / 497 | ✅  |

## Table IV

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 1.27 (0.47) | 1.2667 (0.4617) | 1.2667 (0.4766) | 4.6e-07 / 1.5e-02 | 61 / 61 / 61 | ⚠️ bootstrap SE noise |
| 2 | `kinship_score` | 1.13 (0.46) | 1.1261 (0.4651) | 1.1261 (0.4808) | 1.4e-07 / 1.6e-02 | 61 / 61 / 61 | ⚠️ bootstrap SE noise |
| 3 | `kinship_score` | -0.77 (0.19) | -0.7746 (0.1909) | -0.7746 (0.1909) | 2.5e-07 / 4.7e-07 | 776 / 776 / 776 | ✅  |
| 4 | `kinship_score` | -0.50 (0.13) | -0.5036 (0.1310) | -0.5036 (0.1310) | 2.1e-07 / 1.7e-07 | 770 / 770 / 770 | ✅  |
| 5 | `kinship_score` | -0.41 (0.15) | -0.4123 (0.1484) | -0.4123 (0.1484) | 1.5e-09 / 2.7e-07 | 770 / 770 / 770 | ✅  |
| 6 | `kinship_score` | 1.16 (0.33) | 1.1604 (0.3188) | 1.1604 (0.3063) | 1.4e-07 / 1.3e-02 | 83 / 83 / 83 | ⚠️ bootstrap SE noise |
| 7 | `kinship_score` | 1.14 (0.32) | 1.1405 (0.3202) | 1.1405 (0.2989) | 1.1e-07 / 2.1e-02 | 83 / 83 / 83 | ⚠️ bootstrap SE noise |
| 8 | `kinship_score` | 0.83 (0.20) | 0.8325 (0.1951) | 0.8325 (0.1951) | 2.1e-07 / 2.0e-07 | 371 / 371 / 371 | ✅  |
| 9 | `kinship_score` | 0.46 (0.19) | 0.4581 (0.1924) | 0.4581 (0.1924) | 1.5e-07 / 3.1e-07 | 371 / 371 / 371 | ✅  |
| 10 | `kinship_score` | -0.39 (0.20) | -0.3884 (0.1977) | -0.3884 (0.1977) | 6.2e-09 / 5.1e-08 | 1,156 / 1,156 / 1,156 | ✅  |
| 11 | `kinship_score` | -0.37 (0.12) | -0.3678 (0.1216) | -0.3678 (0.1216) | 3.3e-07 / 4.3e-07 | 1,146 / 1,146 / 1,146 | ✅  |
| 12 | `kinship_score` | -0.26 (0.14) | -0.2576 (0.1364) | -0.2576 (0.1364) | 2.0e-07 / 2.6e-07 | 1,146 / 1,146 / 1,146 | ✅  |
| 13 | `kinship_score` | 0.83 (0.12) | 0.8328 (0.1239) | 0.8328 (0.1239) | 3.8e-07 / 8.2e-08 | 1,151 / 1,151 / 1,151 | ✅  |
| 14 | `kinship_score` | 0.87 (0.12) | 0.8734 (0.1206) | 0.8734 (0.1206) | 2.2e-07 / 2.5e-07 | 1,141 / 1,141 / 1,141 | ✅  |
| 15 | `kinship_score` | 0.76 (0.15) | 0.7640 (0.1496) | 0.7640 (0.1496) | 2.6e-07 / 4.3e-07 | 1,141 / 1,141 / 1,141 | ✅  |
| 4 | `s_have_god` | 0.30 (0.05) | 0.2964 (0.0460) | 0.2964 (0.0460) | 4.4e-07 / 3.0e-07 | 770 / 770 / 770 | ✅  |
| 5 | `s_have_god` | 0.23 (0.05) | 0.2250 (0.0491) | 0.2250 (0.0491) | 6.2e-08 / 3.1e-07 | 770 / 770 / 770 | ✅  |

## Table V

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | -0.34 (0.13) | -0.3415 (0.1299) | -0.3415 (0.1299) | 4.6e-07 / 2.0e-07 | 2,468 / 2,468 / 2,468 | ✅  |
| 2 | `kinship_score` | -0.38 (0.12) | -0.3801 (0.1238) | -0.3801 (0.1238) | 2.1e-07 / 2.6e-07 | 2,465 / 2,465 / 2,465 | ✅  |
| 3 | `kinship_score` | -0.0066 (0.09) | -0.0066 (0.0900) | -0.0066 (0.0900) | 4.3e-07 / 3.2e-07 | 7,582 / 7,582 / 7,582 | ✅  |
| 4 | `kinship_score` | -0.028 (0.08) | -0.0281 (0.0828) | -0.0281 (0.0828) | 2.5e-07 / 1.8e-07 | 7,573 / 7,573 / 7,573 | ✅  |
| 5 | `kinship_score` | 0.64 (0.20) | 0.6393 (0.1967) | 0.6393 (0.1967) | 1.5e-07 / 4.1e-07 | 7,601 / 7,601 / 7,601 | ✅  |
| 6 | `kinship_score` | 0.65 (0.19) | 0.6535 (0.1941) | 0.6535 (0.1941) | 8.2e-08 / 2.0e-07 | 7,592 / 7,592 / 7,592 | ✅  |
| 2 | `s_have_god` | 0.12 (0.04) | 0.1213 (0.0355) | 0.1213 (0.0355) | 3.7e-08 / 4.3e-07 | 2,465 / 2,465 / 2,465 | ✅  |

## Table VI

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 1.46 (0.33) | 1.4611 (0.3311) | 1.4611 (0.3311) | 1.5e-08 / 1.9e-07 | 72 / 72 / 72 | ✅  |
| 2 | `kinship_score` | 1.44 (0.36) | 1.4415 (0.3557) | 1.4415 (0.3557) | 4.3e-07 / 2.0e-07 | 70 / 70 / 70 | ✅  |
| 3 | `kinship_score` | 1.03 (0.35) | 1.0313 (0.3513) | 1.0313 (0.3513) | 4.3e-07 / 2.3e-07 | 72 / 72 / 72 | ✅  |
| 4 | `kinship_score` | 1.24 (0.46) | 1.2358 (0.4603) | 1.2358 (0.4603) | 3.2e-08 / 1.7e-07 | 70 / 70 / 70 | ✅  |
| 5 | `kinship_score` | 0.40 (0.06) | 0.4002 (0.0612) | 0.4002 (0.0612) | 4.8e-07 / 1.5e-08 | 21,813 / 21,813 / 21,813 | ✅  |
| 6 | `kinship_score` | 0.35 (0.07) | 0.3536 (0.0740) | 0.3536 (0.0740) | 4.8e-07 / 4.5e-07 | 21,758 / 21,758 / 21,758 | ✅  |
| 7 | `kinship_score` | 0.17 (0.04) | 0.1709 (0.0374) | 0.1709 (0.0374) | 2.5e-07 / 5.7e-07 | 21,813 / 21,813 / 21,813 | ✅  |
| 8 | `kinship_score` | 0.21 (0.06) | 0.2095 (0.0599) | 0.2095 (0.0599) | 1.9e-07 / 4.1e-07 | 21,758 / 21,758 / 21,758 | ✅  |

## Table VII

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 1.16 (0.35) | 1.1597 (0.3454) | 1.1597 (0.3454) | 1.0e-07 / 2.7e-07 | 79 / 79 / 79 | ✅  |
| 2 | `kinship_score` | 0.87 (0.24) | 0.8745 (0.2357) | 0.8745 (0.2357) | 4.8e-07 / 4.2e-07 | 79 / 79 / 79 | ✅  |
| 3 | `kinship_score` | 0.88 (0.25) | 0.8805 (0.2450) | 0.8805 (0.2450) | 3.4e-07 / 1.9e-07 | 78 / 78 / 78 | ✅  |
| 4 | `kinship_score` | 0.47 (0.24) | 0.4734 (0.2359) | 0.4734 (0.2359) | 1.1e-07 / 7.9e-08 | 78 / 78 / 78 | ✅  |
| 5 | `kinship_score` | 0.26 (0.04) | 0.2583 (0.0362) | 0.2583 (0.0362) | 2.2e-07 / 3.4e-07 | 26,220 / 26,220 / 26,220 | ✅  |
| 6 | `kinship_score` | 0.18 (0.02) | 0.1753 (0.0246) | 0.1753 (0.0246) | 5.0e-08 / 2.7e-08 | 25,752 / 25,752 / 25,752 | ✅  |
| 7 | `kinship_score` | 0.17 (0.03) | 0.1741 (0.0252) | 0.1741 (0.0252) | 2.4e-07 / 3.8e-07 | 25,722 / 25,722 / 25,722 | ✅  |
| 8 | `kinship_score` | 0.20 (0.04) | 0.2030 (0.0433) | 0.2030 (0.0433) | 1.7e-07 / 2.2e-07 | 23,891 / 23,891 / 23,891 | ✅  |
| 2 | `s_religion_god` | 0.67 (0.11) | 0.6704 (0.1064) | 0.6704 (0.1064) | 1.5e-07 / 1.4e-07 | 79 / 79 / 79 | ✅  |
| 3 | `s_religion_god` | 0.69 (0.11) | 0.6873 (0.1145) | 0.6873 (0.1145) | 1.5e-07 / 1.3e-07 | 78 / 78 / 78 | ✅  |
| 4 | `s_religion_god` | 0.70 (0.09) | 0.7002 (0.0876) | 0.7002 (0.0876) | 1.8e-07 / 8.1e-08 | 78 / 78 / 78 | ✅  |
| 6 | `s_religion_god` | 0.30 (0.04) | 0.3047 (0.0419) | 0.3047 (0.0419) | 4.0e-07 / 1.8e-08 | 25,752 / 25,752 / 25,752 | ✅  |
| 7 | `s_religion_god` | 0.30 (0.04) | 0.2984 (0.0405) | 0.2984 (0.0405) | 2.3e-07 / 1.1e-07 | 25,722 / 25,722 / 25,722 | ✅  |
| 8 | `s_religion_god` | 0.34 (0.03) | 0.3359 (0.0321) | 0.3359 (0.0321) | 2.6e-07 / 8.9e-08 | 23,891 / 23,891 / 23,891 | ✅  |

## Table VIII

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `corigin_kinship_score` | 0.11 (0.04) | 0.1105 (0.0428) | 0.1105 (0.0428) | 9.4e-08 / 4.9e-07 | 27,994 / 27,994 / 27,994 | ✅  |
| 2 | `corigin_kinship_score` | -0.23 (0.13) | -0.2262 (0.1350) | -0.2262 (0.1350) | 2.4e-07 / 1.1e-07 | 27,994 / 27,994 / 27,994 | ✅  |
| 3 | `corigin_kinship_score` | 0.37 (0.13) | 0.3689 (0.1258) | 0.3689 (0.1258) | 7.2e-08 / 1.0e-07 | 28,432 / 28,432 / 28,432 | ✅  |
| 4 | `corigin_kinship_score` | 0.29 (0.12) | 0.2916 (0.1238) | 0.2916 (0.1238) | 6.8e-10 / 4.9e-07 | 27,994 / 27,994 / 27,994 | ✅  |
| 5 | `corigin_kinship_score` | 0.36 (0.04) | 0.3573 (0.0442) | 0.3573 (0.0442) | 3.2e-07 / 5.1e-08 | 28,432 / 28,432 / 28,432 | ✅  |
| 6 | `corigin_kinship_score` | 0.39 (0.05) | 0.3929 (0.0518) | 0.3929 (0.0518) | 2.2e-07 / 6.1e-08 | 27,994 / 27,994 / 27,994 | ✅  |
| 7 | `corigin_kinship_score` | 0.41 (0.05) | 0.4120 (0.0460) | 0.4120 (0.0460) | 4.8e-07 / 4.7e-07 | 28,432 / 28,432 / 28,432 | ✅  |
| 8 | `corigin_kinship_score` | 0.41 (0.04) | 0.4068 (0.0442) | 0.4068 (0.0442) | 1.3e-07 / 3.3e-07 | 27,994 / 27,994 / 27,994 | ✅  |

## Table IX

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 0.30 (0.17) | 0.3039 (0.1724) | 0.3038 (0.1724) | 3.5e-07 / 4.8e-07 | 2,570 / 2,570 / 2,570 | ✅  |
| 2 | `kinship_score` | 0.32 (0.17) | 0.3230 (0.1710) | 0.3230 (0.1710) | 4.7e-07 / 3.6e-07 | 2,567 / 2,567 / 2,567 | ✅  |
| 3 | `kinship_score` | 0.31 (0.17) | 0.3110 (0.1715) | 0.3110 (0.1715) | 4.4e-08 / 3.5e-07 | 2,490 / 2,490 / 2,490 | ✅  |
| 4 | `kinship_score` | 0.27 (0.14) | 0.2724 (0.1355) | 0.2724 (0.1355) | 3.0e-07 / 1.6e-07 | 2,626 / 2,626 / 2,626 | ✅  |
| 5 | `kinship_score` | 0.27 (0.13) | 0.2728 (0.1261) | 0.2728 (0.1261) | 2.5e-07 / 1.1e-07 | 2,623 / 2,623 / 2,623 | ✅  |
| 6 | `kinship_score` | 0.20 (0.17) | 0.1974 (0.1672) | 0.1974 (0.1672) | 3.9e-07 / 3.1e-07 | 2,545 / 2,545 / 2,545 | ✅  |
| 7 | `kinship_score` | 0.79 (0.35) | 0.7857 (0.3542) | 0.7857 (0.3542) | 1.3e-07 / 4.3e-07 | 72 / 72 / 72 | ✅  |
| 8 | `kinship_score` | 0.88 (0.35) | 0.8757 (0.3512) | 0.8757 (0.3512) | 9.7e-08 / 2.0e-07 | 71 / 71 / 71 | ✅  |

## Table X

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 1.20 (0.36) | 1.2032 (0.3615) | 1.2032 (0.3615) | 2.9e-07 / 8.8e-08 | 74 / 74 / 74 | ✅  |
| 2 | `kinship_score` | 1.19 (0.39) | 1.1881 (0.3909) | 1.1881 (0.3909) | 3.2e-07 / 3.1e-09 | 74 / 74 / 74 | ✅  |
| 3 | `kinship_score` | 0.83 (0.49) | 0.8310 (0.4904) | 0.8310 (0.4904) | 1.2e-07 / 1.1e-07 | 74 / 74 / 74 | ✅  |

## Table XI

| Col | Term | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff b / se (StatsPAI−Stata) | N paper / Stata / StatsPAI | Status |
|---|---|---|---|---|---|---|---|
| 1 | `kinship_score` | 0.60 (0.30) | 0.6009 (0.2976) | 0.6009 (0.2976) | 3.9e-07 / 4.7e-07 | 1,172 / 1,172 / 1,172 | ✅  |
| 2 | `kinship_score` | -0.26 (0.17) | -0.2620 (0.1747) | -0.2620 (0.1747) | 5.0e-07 / 4.8e-07 | 1,171 / 1,171 / 1,171 | ✅  |
| 3 | `kinship_score` | 0.94 (0.26) | 0.9434 (0.2592) | 0.9434 (0.2592) | 6.4e-08 / 3.3e-07 | 1,186 / 1,186 / 1,186 | ✅  |
| 4 | `kinship_score` | 0.24 (0.15) | 0.2410 (0.1463) | 0.2410 (0.1463) | 4.7e-07 / 3.6e-08 | 1,176 / 1,176 / 1,176 | ✅  |
| 5 | `kinship_score` | 0.25 (0.35) | 0.2550 (0.3509) | 0.2550 (0.3509) | 1.7e-07 / 1.1e-07 | 613 / 613 / 613 | ✅  |
| 6 | `kinship_score` | -0.21 (0.16) | -0.2124 (0.1572) | -0.2124 (0.1572) | 1.9e-07 / 1.0e-07 | 607 / 607 / 607 | ✅  |
| 2 | `small_scale` | -1.41 (0.20) | -1.4111 (0.2030) | -1.4111 (0.2030) | 2.9e-07 / 7.0e-08 | 1,171 / 1,171 / 1,171 | ✅  |
| 4 | `small_scale` | -2.51 (0.20) | -2.5073 (0.1979) | -2.5073 (0.1979) | 7.5e-08 / 1.0e-07 | 1,176 / 1,176 / 1,176 | ✅  |
| 6 | `small_scale` | -2.06 (0.23) | -2.0572 (0.2330) | -2.0572 (0.2330) | 1.3e-07 / 6.4e-08 | 607 / 607 / 607 | ✅  |

## Figures

The paper prints no numbers for its figures, so the check is: does the author's code run, does StatsPAI reproduce the same underlying statistics, and do the sample sizes and patterns match what the text says.

| Figure | Content | Original Stata (`Results/Figures/`) | StatsPAI (`Results/statspai/`) | Check against paper | Status |
|---|---|---|---|---|---|
| I | Histogram of kinship tightness | no code in package | `Figure_1_kinship_histogram.png` | 1,246 EA societies, index 0–1 in steps of 1/8 | ✅ (StatsPAI only) |
| II | Binscatter: kinship vs hunting-gathering | `Hunter_kinship.pdf` rc 0 | `Figures_2_3_binscatter.png`; slope −0.45 | negative, as in text | ✅ |
| III | Binscatter: kinship vs sickle-cell distance (15 bins) | `Sickle_kinship.pdf` rc 0 | same png; slope −0.058 = Table III col 6 | ✅ |
| IV | EA moral systems, tight (≥ .25) vs loose | `Overview_ea.pdf` rc 0 | `Figure_4_overview_ea.png`, `Figure_4_means.csv` | tight: more in-group favoritism, loyalty, purity, village institutions; loose: moralizing gods, higher-level hierarchy | ✅ (bootstrap SEs for 2 bars are MC draws) |
| V | Contemporary moral systems by tight/loose | `Overview_country.pdf` rc 0 | `Figure_5_overview_country.png`, `Figure_5_means.csv` | same sign pattern on all 6 outcomes | ✅ |
| VI | Country scatter: trust out-in vs kinship | `Trust_kinship.pdf` rc 0 | slope 1.461, N = 72 = Table VI col 1 | ✅ |
| VII | US migrants: disgust by country of origin (≥ 20 resp.) | `Disgust_kinship.pdf` rc 0 | slope 0.388, 88 origin countries | text: 13,723 US migrants; data has 13,751 US respondents (all with origin kinship) | ⚠️ 28-person gap between text and posted data; figure itself unaffected |
| VIII | Morality kernel (PCA of 5 moral variables) | `Kernel_kinship.pdf` rc 0 | slope 3.83, N = 33 complete-case countries | ✅ |
| IX | Kinship coefficient on log pop. density / urbanization, 1500–1950 | `Pd.pdf`, `Urbfrac.pdf` rc 0 | `Figure_9_development.png`, `Figure_9_coefs.csv` | N = 123 countries (text: 123); coefficients ≈ 0 before 1700 and increasingly negative after 1800 | ✅ |

## Exhibits that cannot be replicated

| Exhibit | Reason |
|---|---|
| Table X, cols 4–6 (GPS migrants) | Individual GPS data with country of birth are restricted under the Gallup World Poll license; the author's code comments these regressions out. Published: 0.31 (0.11), 0.29 (0.11), 0.28 (0.10); N = 2,289 / 2,279 / 2,266. |
| Tables I, II | Conceptual tables (overview of hypotheses; prisoner's-dilemma payoffs): no data. |
| Online Appendix tables/figures | Not in the replication package. |
| Kinship index construction | `Kinship_index/Generate_kinship_index.do` needs the raw Ethnographic Atlas (v8, v11, v15, v43), which is not included; its output `kinship_score` is shipped in every dataset. We re-derived it from the shipped components: see `Materials/论文模型解读与StatsPAI复现分析.md`. |

## Extensions (not replication) — headline numbers

Full output: `Results/statspai/ext_E*.csv`. Details in `Materials/论文模型解读与StatsPAI复现分析.md` §5.

* **E1 Conley spatial SEs (Table IV).** Language-subfamily clustered SEs are close to Conley SEs with a 500 km cut-off; at 2000 km they grow up to ~2.5× (village institutions col 13: 0.12 → 0.31). Still, every non-bootstrap column except col 10 (hierarchy above local, clustered p ≈ .05) keeps |t| > 2 at both 1000 km and 2000 km.
* **E2 Oster δ\*** (R²max = 1.3·R²): village institutions 21.8, trust out-in 13.5 (robust); revenge punishment 1.30; sex taboo 0.55 and belief in hell 0.24 (fragile, |δ\*| < 1). For moralizing god and trust in family the coefficient moves *away* from zero when controls are added (δ\* < 0).
* **E3 sensemakr robustness value RV_q**: 0.13–0.42; the partial R² needed to push the estimate to insignificance (RV_q,α) is 0 for belief in hell and revenge punishment (already p > .05 with continent FE).
* **E5 specification curves** (8 control sets; EA outcomes × {cluster, HC1} SEs): moralizing god, village institutions, sex taboo, trust out-in and revenge punishment keep their sign in every specification. Hierarchy above local is positive only without the hunting-gathering control. Belief in hell turns negative (insignificant) only in the richest set (log GDP + Catholic/Muslim shares + continent FE, N = 75); communal-vs-universal values turns negative whenever log GDP is added (N = 61) and is never significant at 5% in this common sample.
* **E6 Romano–Wolf**: EA family (4 outcomes, N = 293 common sample) — all adjusted p < .01 except hierarchy above local (0.07). The country family collapses to N = 15 because `sp.romano_wolf` drops rows missing *any* outcome — not informative (see StatsPAI friction log).

