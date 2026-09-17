# Comparison: paper vs original Stata code vs StatsPAI

Paper = published QJE PDF (Materials/AI-tocracy (QJE 2023).pdf). Original Stata = our re-run of the author's `Analysis.do` (Stata 18 MP, reghdfe 6.13.1, ivreghdfe 1.1.4, xtevent 1.0.0; `Results/Tables/*.tex`). StatsPAI = `Program/statspai/*.py` (statspai 1.28.0; `Results/statspai/*.csv`).
Marks: Stata column vs paper; StatsPAI column vs our Stata run (vs paper if Stata missing). ✅ equal at reported precision · ⚠️ small difference, explained below / approximation · ❌ material difference, explained below.


## Table II

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table II A (OLS) unrest_{t-1} | 1 | 0.199 (0.043) | 0.199 (0.043) | 0.199 (0.043) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table II A (OLS) unrest_{t-1} | 2 | 0.196 (0.046) | 0.196 (0.046) | 0.196 (0.046) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table II A (OLS) unrest_{t-1} | 3 | 0.199 (0.044) | 0.199 (0.044) | 0.199 (0.044) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table II A (OLS) unrest_{t-1} | 4 | 0.204 (0.046) | 0.204 (0.046) | 0.204 (0.046) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table II A (OLS) unrest_{t-1} | 5 | 0.205 (0.044) | 0.205 (0.044) | 0.205 (0.044) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table II B (LASSO IV) unrest_{t-1} | 1 | 0.377 (0.084) | 0.377 (0.084) | 0.248 (0.026) | 0.000 / 0.000 | 0.129 / 0.058 | ✅ | ⚠️ (approx.) |
| Table II B (LASSO IV) unrest_{t-1} | 2 | 0.377 (0.084) | 0.377 (0.084) | 0.245 (0.030) | 0.000 / 0.000 | 0.132 / 0.054 | ✅ | ⚠️ (approx.) |
| Table II B (LASSO IV) unrest_{t-1} | 3 | 0.377 (0.084) | 0.377 (0.084) | 0.248 (0.027) | 0.000 / 0.000 | 0.129 / 0.057 | ✅ | ⚠️ (approx.) |
| Table II B (LASSO IV) unrest_{t-1} | 4 | 0.349 (0.080) | 0.349 (0.080) | 0.264 (0.026) | 0.000 / 0.000 | 0.085 / 0.054 | ✅ | ⚠️ (approx.) |
| Table II B (LASSO IV) unrest_{t-1} | 5 | 0.348 (0.080) | 0.348 (0.080) | 0.261 (0.028) | 0.000 / 0.000 | 0.087 / 0.052 | ✅ | ⚠️ (approx.) |

## Table III

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table III A (OLS, cameras) | 1 | 0.436 (0.084) | 0.436 (0.084) | 0.436 (0.084) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III A (OLS, cameras) | 2 | 0.420 (0.083) | 0.420 (0.083) | 0.420 (0.083) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III A (OLS, cameras) | 3 | 0.436 (0.085) | 0.436 (0.085) | 0.436 (0.085) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III A (OLS, cameras) | 4 | 0.425 (0.080) | 0.425 (0.080) | 0.425 (0.080) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III A (OLS, cameras) | 5 | 0.425 (0.080) | 0.425 (0.080) | 0.425 (0.080) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III B (LASSO IV, cameras) | 1 | 0.593 (0.175) | 0.593 (0.175) | 0.737 (0.214) | 0.000 / 0.000 | 0.144 / 0.039 | ✅ | ⚠️ (approx.) |
| Table III B (LASSO IV, cameras) | 2 | 0.599 (0.174) | 0.599 (0.174) | 0.695 (0.172) | 0.000 / 0.000 | 0.096 / 0.002 | ✅ | ⚠️ (approx.) |
| Table III B (LASSO IV, cameras) | 3 | 0.593 (0.175) | 0.593 (0.175) | 0.721 (0.194) | 0.000 / 0.000 | 0.128 / 0.019 | ✅ | ⚠️ (approx.) |
| Table III B (LASSO IV, cameras) | 4 | 0.559 (0.167) | 0.559 (0.167) | 0.737 (0.209) | 0.000 / 0.000 | 0.178 / 0.042 | ✅ | ⚠️ (approx.) |
| Table III B (LASSO IV, cameras) | 5 | 0.559 (0.167) | 0.559 (0.167) | 0.724 (0.205) | 0.000 / 0.000 | 0.165 / 0.038 | ✅ | ⚠️ (approx.) |
| Table III C (OLS, AI x cameras) | 1 | 0.681 (0.154) | 0.681 (0.154) | 0.681 (0.154) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III C (OLS, AI x cameras) | 2 | 0.669 (0.157) | 0.669 (0.157) | 0.669 (0.157) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III C (OLS, AI x cameras) | 3 | 0.680 (0.155) | 0.680 (0.155) | 0.680 (0.155) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III C (OLS, AI x cameras) | 4 | 0.671 (0.148) | 0.671 (0.148) | 0.671 (0.148) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III C (OLS, AI x cameras) | 5 | 0.671 (0.148) | 0.671 (0.148) | 0.671 (0.148) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table III D (LASSO IV, AI x cameras) | 1 | 1.054 (0.374) | 1.054 (0.374) | 0.898 (0.076) | 0.000 / 0.000 | 0.156 / 0.298 | ✅ | ⚠️ (approx.) |
| Table III D (LASSO IV, AI x cameras) | 2 | 1.070 (0.376) | 1.070 (0.376) | 0.872 (0.049) | 0.000 / 0.000 | 0.198 / 0.327 | ✅ | ⚠️ (approx.) |
| Table III D (LASSO IV, AI x cameras) | 3 | 1.054 (0.374) | 1.054 (0.374) | 0.888 (0.065) | 0.000 / 0.000 | 0.166 / 0.309 | ✅ | ⚠️ (approx.) |
| Table III D (LASSO IV, AI x cameras) | 4 | 0.967 (0.334) | 0.967 (0.334) | 0.904 (0.081) | 0.000 / 0.000 | 0.063 / 0.253 | ✅ | ⚠️ (approx.) |
| Table III D (LASSO IV, AI x cameras) | 5 | 0.966 (0.334) | 0.966 (0.334) | 0.896 (0.099) | 0.000 / 0.000 | 0.070 / 0.235 | ✅ | ⚠️ (approx.) |

## Table IV

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table IV A: conducive weather | 1 | 0.9176 (0.1609) | 0.9176 (0.1609) | 0.9176 (0.1609) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: conducive weather | 2 | 0.9523 (0.1597) | 0.9523 (0.1597) | 0.9523 (0.1597) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: conducive weather | 3 | 0.9183 (0.1613) | 0.9183 (0.1613) | 0.9183 (0.1613) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: conducive weather | 4 | 0.9511 (0.1543) | 0.9511 (0.1542) | 0.9511 (0.1542) | 0.0000 / 0.0001 | 0.0000 / 0.0000 | ⚠️ | ✅ |
| Table IV A: stock_{t-1} | 1 | -0.0080 (0.0039) | -0.0080 (0.0039) | -0.0080 (0.0039) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: stock_{t-1} | 2 | -0.0032 (0.0050) | -0.0032 (0.0050) | -0.0032 (0.0050) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: stock_{t-1} | 3 | -0.0079 (0.0038) | -0.0079 (0.0038) | -0.0079 (0.0038) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: stock_{t-1} | 4 | -0.0020 (0.0050) | -0.0020 (0.0050) | -0.0020 (0.0050) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: weather x stock_{t-1} | 1 | -0.2265 (0.1153) | -0.2265 (0.1153) | -0.2265 (0.1153) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: weather x stock_{t-1} | 2 | -0.2729 (0.1306) | -0.2729 (0.1306) | -0.2729 (0.1306) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: weather x stock_{t-1} | 3 | -0.2260 (0.1156) | -0.2260 (0.1156) | -0.2260 (0.1156) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV A: weather x stock_{t-1} | 4 | -0.2662 (0.1250) | -0.2662 (0.1250) | -0.2662 (0.1250) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: conducive weather | 1 | 0.9113 (0.1585) | 0.9113 (0.1584) | 0.9113 (0.1584) | 0.0000 / 0.0001 | 0.0000 / 0.0000 | ⚠️ | ✅ |
| Table IV B: conducive weather | 2 | 0.9446 (0.1560) | 0.9446 (0.1560) | 0.9446 (0.1560) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: conducive weather | 3 | 0.9118 (0.1587) | 0.9118 (0.1587) | 0.9118 (0.1587) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: conducive weather | 4 | 0.9449 (0.1517) | 0.9449 (0.1516) | 0.9449 (0.1516) | 0.0000 / 0.0001 | 0.0000 / 0.0000 | ⚠️ | ✅ |
| Table IV B: stock_{t-1} | 1 | 0.2462 (0.1074) | 0.2462 (0.1074) | 0.2462 (0.1074) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: stock_{t-1} | 2 | 0.2734 (0.0997) | 0.2734 (0.0997) | 0.2734 (0.0997) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: stock_{t-1} | 3 | 0.2455 (0.1073) | 0.2455 (0.1073) | 0.2455 (0.1073) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: stock_{t-1} | 4 | 0.2638 (0.0945) | 0.2638 (0.0945) | 0.2638 (0.0945) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: weather x stock_{t-1} | 1 | -0.5688 (0.2281) | -0.5688 (0.2281) | -0.5688 (0.2281) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: weather x stock_{t-1} | 2 | -0.6598 (0.2401) | -0.6598 (0.2401) | -0.6598 (0.2401) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: weather x stock_{t-1} | 3 | -0.5735 (0.2304) | -0.5735 (0.2304) | -0.5735 (0.2304) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table IV B: weather x stock_{t-1} | 4 | -0.6403 (0.2229) | -0.6403 (0.2229) | -0.6403 (0.2229) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |

## Table V

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table V A: conducive weather | 1 | 0.9378 (0.1678) | 0.9378 (0.1678) | 0.9378 (0.1678) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: conducive weather | 2 | 0.9768 (0.1666) | 0.9768 (0.1666) | 0.9768 (0.1666) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: conducive weather | 3 | 0.9385 (0.1682) | 0.9385 (0.1682) | 0.9385 (0.1682) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: conducive weather | 4 | 0.9747 (0.1608) | 0.9747 (0.1608) | 0.9747 (0.1608) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: stock_{t-1} | 1 | -0.0021 (0.0012) | -0.0021 (0.0012) | -0.0021 (0.0012) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: stock_{t-1} | 2 | -0.0022 (0.0014) | -0.0022 (0.0014) | -0.0022 (0.0014) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: stock_{t-1} | 3 | -0.0021 (0.0012) | -0.0021 (0.0012) | -0.0021 (0.0012) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: stock_{t-1} | 4 | -0.0019 (0.0012) | -0.0019 (0.0012) | -0.0019 (0.0012) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: weather x stock_{t-1} | 1 | -0.0441 (0.0299) | -0.0441 (0.0299) | -0.0441 (0.0299) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: weather x stock_{t-1} | 2 | -0.0513 (0.0338) | -0.0513 (0.0338) | -0.0513 (0.0338) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: weather x stock_{t-1} | 3 | -0.0444 (0.0305) | -0.0444 (0.0305) | -0.0444 (0.0305) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V A: weather x stock_{t-1} | 4 | -0.0473 (0.0301) | -0.0473 (0.0301) | -0.0473 (0.0301) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: conducive weather | 1 | 0.9770 (0.1660) | 0.9770 (0.1660) | 0.9770 (0.1660) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: conducive weather | 2 | 0.9813 (0.1711) | 0.9813 (0.1711) | 0.9813 (0.1711) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: conducive weather | 3 | 0.9777 (0.1664) | 0.9777 (0.1664) | 0.9777 (0.1664) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: conducive weather | 4 | 0.9798 (0.1656) | 0.9798 (0.1656) | 0.9798 (0.1656) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: stock_{t-1} | 1 | 0.0002 (0.0672) | 0.0002 (0.0671) | 0.0002 (0.0671) | 0.0000 / 0.0001 | 0.0000 / 0.0000 | ⚠️ | ✅ |
| Table V B: stock_{t-1} | 2 | -0.0006 (0.0706) | -0.0006 (0.0706) | -0.0006 (0.0706) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: stock_{t-1} | 3 | 0.0038 (0.0684) | 0.0038 (0.0684) | 0.0038 (0.0684) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: stock_{t-1} | 4 | 0.0013 (0.0664) | 0.0013 (0.0664) | 0.0013 (0.0664) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: weather x stock_{t-1} | 1 | -0.0110 (0.0187) | -0.0110 (0.0187) | -0.0110 (0.0187) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: weather x stock_{t-1} | 2 | -0.0114 (0.0195) | -0.0114 (0.0195) | -0.0114 (0.0195) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |
| Table V B: weather x stock_{t-1} | 3 | -0.0120 (0.0189) | -0.0120 (0.0188) | -0.0120 (0.0188) | 0.0000 / 0.0001 | 0.0000 / 0.0000 | ⚠️ | ✅ |
| Table V B: weather x stock_{t-1} | 4 | -0.0114 (0.0186) | -0.0114 (0.0186) | -0.0114 (0.0186) | 0.0000 / 0.0000 | 0.0000 / 0.0000 | ✅ | ✅ |

## Table VI

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table VI A (total) 8q after | 1 | 10.671 (3.664) | 10.783 (3.888) | 10.783 (3.888) | 0.112 / 0.224 | 0.000 / 0.000 | ❌ | ✅ |
| Table VI A (total) 8q after | 2 | 11.153 (3.103) | 11.275 (3.315) | 11.275 (3.315) | 0.122 / 0.212 | 0.000 / 0.000 | ❌ | ✅ |
| Table VI A (total) 8q after | 3 | 13.111 (2.957) | 13.123 (3.051) | 13.123 (3.051) | 0.012 / 0.094 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI A (total) 8q after | 4 | 9.287 (2.127) | 9.238 (2.076) | 9.238 (2.076) | 0.049 / 0.051 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI A (total) 8q after | 5 | 9.711 (2.119) | 9.673 (2.071) | 9.673 (2.071) | 0.038 / 0.048 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI A (total) 8q after | 6 | 11.124 (1.948) | 11.105 (1.926) | 11.105 (1.926) | 0.019 / 0.022 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 1 | 3.465 (1.543) | 3.481 (1.495) | 3.481 (1.495) | 0.016 / 0.048 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 2 | 3.566 (1.415) | 3.592 (1.381) | 3.592 (1.381) | 0.026 / 0.034 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 3 | 4.198 (1.375) | 4.196 (1.360) | 4.196 (1.360) | 0.002 / 0.015 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 4 | 3.099 (0.920) | 3.105 (0.913) | 3.105 (0.913) | 0.006 / 0.007 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 5 | 3.170 (0.916) | 3.174 (0.909) | 3.174 (0.909) | 0.004 / 0.007 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI B (government) 8q after | 6 | 3.745 (0.952) | 3.753 (0.946) | 3.753 (0.946) | 0.008 / 0.006 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI C (commercial) 8q after | 1 | 5.098 (2.409) | 5.071 (2.282) | 5.071 (2.282) | 0.027 / 0.127 | 0.000 / 0.000 | ❌ | ✅ |
| Table VI C (commercial) 8q after | 2 | 5.310 (1.956) | 5.314 (1.924) | 5.314 (1.924) | 0.004 / 0.032 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI C (commercial) 8q after | 3 | 6.009 (1.856) | 5.964 (1.791) | 5.964 (1.791) | 0.045 / 0.065 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI C (commercial) 8q after | 4 | 3.718 (1.146) | 3.760 (1.140) | 3.760 (1.140) | 0.042 / 0.006 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI C (commercial) 8q after | 5 | 3.898 (1.157) | 3.897 (1.149) | 3.897 (1.149) | 0.001 / 0.008 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VI C (commercial) 8q after | 6 | 4.373 (0.945) | 4.397 (0.964) | 4.397 (0.964) | 0.024 / 0.019 | 0.000 / 0.000 | ⚠️ | ✅ |

## Table VII

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table VII A (total) 8q before | 1 | 5.239 (3.427) | 4.779 (3.056) | 4.779 (3.056) | 0.460 / 0.371 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before | 2 | 4.170 (2.805) | 3.383 (2.072) | 3.383 (2.072) | 0.787 / 0.733 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before | 3 | 0.646 (1.318) | 0.326 (1.114) | 0.326 (1.114) | 0.320 / 0.204 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before | 4 | 1.509 (1.539) | 1.529 (1.541) | 1.529 (1.541) | 0.020 / 0.002 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q before | 5 | 0.564 (1.519) | 0.576 (1.524) | 0.576 (1.524) | 0.012 / 0.005 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q before | 6 | -1.043 (0.926) | -1.058 (0.925) | -1.058 (0.925) | 0.015 / 0.001 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after | 1 | 0.823 (1.644) | 1.014 (1.551) | 1.014 (1.551) | 0.191 / 0.093 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q after | 2 | 4.625 (1.946) | 4.521 (1.888) | 4.521 (1.888) | 0.104 / 0.058 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after | 3 | 6.330 (1.696) | 6.311 (1.692) | 6.311 (1.692) | 0.019 / 0.004 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after | 4 | 1.893 (1.029) | 1.810 (1.017) | 1.810 (1.017) | 0.083 / 0.012 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after | 5 | 4.041 (1.322) | 3.964 (1.313) | 3.964 (1.313) | 0.077 / 0.009 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after | 6 | 5.452 (1.285) | 5.474 (1.290) | 5.474 (1.290) | 0.022 / 0.005 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q before x PS | 1 | -1.897 (1.239) | -1.485 (1.041) | -1.485 (1.041) | 0.412 / 0.198 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before x PS | 2 | -2.221 (1.665) | -1.557 (1.440) | -1.557 (1.440) | 0.664 / 0.225 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before x PS | 3 | -1.941 (1.221) | -1.604 (1.059) | -1.604 (1.059) | 0.337 / 0.162 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before x PS | 4 | 0.246 (1.250) | 0.228 (1.266) | 0.228 (1.266) | 0.018 / 0.016 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before x PS | 5 | 0.464 (1.453) | 0.434 (1.472) | 0.434 (1.472) | 0.030 / 0.019 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII A (total) 8q before x PS | 6 | -0.055 (1.286) | -0.057 (1.310) | -0.057 (1.310) | 0.002 / 0.024 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 1 | 9.825 (3.368) | 9.751 (3.290) | 9.751 (3.290) | 0.074 / 0.078 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 2 | 4.024 (3.829) | 4.052 (3.690) | 4.052 (3.690) | 0.028 / 0.139 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 3 | 7.896 (2.439) | 7.963 (2.450) | 7.963 (2.450) | 0.067 / 0.011 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 4 | 7.460 (1.863) | 7.445 (1.824) | 7.445 (1.824) | 0.015 / 0.039 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 5 | 4.071 (1.670) | 4.054 (1.689) | 4.054 (1.689) | 0.017 / 0.019 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII A (total) 8q after x PS | 6 | 6.385 (1.560) | 6.314 (1.542) | 6.314 (1.542) | 0.071 / 0.018 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q before | 1 | 1.697 (1.067) | 1.628 (1.005) | 1.628 (1.005) | 0.069 / 0.062 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before | 2 | 0.951 (0.706) | 0.860 (0.635) | 0.860 (0.635) | 0.091 / 0.071 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before | 3 | 0.065 (0.514) | 0.043 (0.498) | 0.043 (0.498) | 0.022 / 0.016 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before | 4 | 0.230 (0.491) | 0.359 (0.562) | 0.359 (0.562) | 0.129 / 0.071 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before | 5 | -0.259 (0.631) | -0.048 (0.736) | -0.048 (0.736) | 0.211 / 0.105 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before | 6 | -0.712 (0.508) | -0.595 (0.534) | -0.595 (0.534) | 0.117 / 0.026 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q after | 1 | 1.278 (0.778) | 1.258 (0.801) | 1.258 (0.801) | 0.020 / 0.023 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after | 2 | 3.196 (1.054) | 3.146 (1.052) | 3.146 (1.052) | 0.050 / 0.002 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after | 3 | 3.205 (0.885) | 3.210 (0.872) | 3.210 (0.872) | 0.005 / 0.013 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after | 4 | 0.700 (0.490) | 0.718 (0.487) | 0.718 (0.487) | 0.018 / 0.003 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after | 5 | 1.465 (0.702) | 1.489 (0.709) | 1.489 (0.709) | 0.024 / 0.007 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after | 6 | 2.048 (0.639) | 2.055 (0.643) | 2.055 (0.643) | 0.007 / 0.004 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q before x PS | 1 | -0.158 (0.463) | -0.118 (0.452) | -0.118 (0.452) | 0.040 / 0.011 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before x PS | 2 | 0.154 (0.602) | 0.231 (0.596) | 0.231 (0.596) | 0.077 / 0.006 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before x PS | 3 | -0.222 (0.457) | -0.199 (0.452) | -0.199 (0.452) | 0.023 / 0.005 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before x PS | 4 | 0.429 (0.498) | 0.380 (0.577) | 0.380 (0.577) | 0.049 / 0.079 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before x PS | 5 | 0.883 (0.643) | 0.796 (0.788) | 0.796 (0.788) | 0.087 / 0.145 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q before x PS | 6 | 0.250 (0.477) | 0.212 (0.558) | 0.212 (0.558) | 0.038 / 0.081 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q after x PS | 1 | 2.180 (1.284) | 2.230 (1.330) | 2.230 (1.330) | 0.050 / 0.046 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after x PS | 2 | -0.128 (1.455) | -0.057 (1.429) | -0.057 (1.429) | 0.071 / 0.026 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII B (government) 8q after x PS | 3 | 1.360 (1.079) | 1.373 (1.093) | 1.373 (1.093) | 0.013 / 0.014 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after x PS | 4 | 2.408 (0.771) | 2.381 (0.766) | 2.381 (0.766) | 0.027 / 0.005 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after x PS | 5 | 1.453 (0.906) | 1.412 (0.918) | 1.412 (0.918) | 0.041 / 0.012 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII B (government) 8q after x PS | 6 | 1.963 (0.756) | 1.937 (0.759) | 1.937 (0.759) | 0.026 / 0.003 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q before | 1 | 2.267 (1.510) | 2.212 (1.444) | 2.212 (1.444) | 0.055 / 0.066 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q before | 2 | 1.694 (1.015) | 1.682 (1.012) | 1.682 (1.012) | 0.012 / 0.003 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q before | 3 | 0.304 (0.490) | 0.269 (0.452) | 0.269 (0.452) | 0.035 / 0.038 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before | 4 | 0.689 (0.742) | 0.591 (0.656) | 0.591 (0.656) | 0.098 / 0.086 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before | 5 | 0.285 (0.555) | 0.137 (0.434) | 0.137 (0.434) | 0.148 / 0.121 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before | 6 | -0.263 (0.276) | -0.345 (0.226) | -0.345 (0.226) | 0.082 / 0.050 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after | 1 | -0.420 (0.821) | -0.463 (0.894) | -0.463 (0.894) | 0.043 / 0.073 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after | 2 | 0.759 (0.637) | 0.813 (0.613) | 0.813 (0.613) | 0.054 / 0.024 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after | 3 | 1.883 (0.703) | 1.867 (0.666) | 1.867 (0.666) | 0.016 / 0.037 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after | 4 | 0.476 (0.551) | 0.515 (0.521) | 0.515 (0.521) | 0.039 / 0.030 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after | 5 | 1.174 (0.410) | 1.176 (0.412) | 1.176 (0.412) | 0.002 / 0.002 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after | 6 | 1.820 (0.456) | 1.814 (0.453) | 1.814 (0.453) | 0.006 / 0.003 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q before x PS | 1 | -0.754 (0.511) | -0.657 (0.438) | -0.657 (0.438) | 0.097 / 0.073 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before x PS | 2 | -0.937 (0.550) | -0.933 (0.548) | -0.933 (0.548) | 0.004 / 0.002 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q before x PS | 3 | -0.823 (0.563) | -0.768 (0.522) | -0.768 (0.522) | 0.055 / 0.041 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before x PS | 4 | -0.171 (0.360) | -0.014 (0.294) | -0.014 (0.294) | 0.157 / 0.066 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before x PS | 5 | -0.169 (0.393) | 0.051 (0.366) | 0.051 (0.366) | 0.220 / 0.027 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q before x PS | 6 | -0.274 (0.415) | -0.134 (0.355) | -0.134 (0.355) | 0.140 / 0.060 | 0.000 / 0.000 | ❌ | ✅ |
| Table VII C (commercial) 8q after x PS | 1 | 5.482 (2.168) | 5.552 (2.230) | 5.552 (2.230) | 0.070 / 0.062 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after x PS | 2 | 1.979 (1.616) | 1.949 (1.607) | 1.949 (1.607) | 0.030 / 0.009 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after x PS | 3 | 4.521 (1.522) | 4.566 (1.557) | 4.566 (1.557) | 0.045 / 0.035 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after x PS | 4 | 3.225 (1.037) | 3.221 (1.041) | 3.221 (1.041) | 0.004 / 0.004 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after x PS | 5 | 1.552 (0.636) | 1.564 (0.625) | 1.564 (0.625) | 0.012 / 0.011 | 0.000 / 0.000 | ⚠️ | ✅ |
| Table VII C (commercial) 8q after x PS | 6 | 2.805 (0.803) | 2.823 (0.823) | 2.823 (0.823) | 0.018 / 0.020 | 0.000 / 0.000 | ⚠️ | ✅ |

## Table VIII

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table VIII public security | 1 | 0.032 (0.018) | 0.032 (0.018) | 0.032 (0.018) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table VIII public security | 2 | 0.036 (0.017) | 0.036 (0.017) | 0.036 (0.017) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table VIII public security | 3 | 0.039 (0.019) | 0.039 (0.019) | 0.039 (0.019) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table VIII public security | 4 | 0.036 (0.018) | 0.036 (0.018) | 0.036 (0.018) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |

## Table IX

| Coefficient | Col | Paper b (se) | Stata b (se) | StatsPAI b (se) | abs diff paper–Stata b / se | abs diff Stata–StatsPAI b / se | Stata | StatsPAI |
|---|---|---|---|---|---|---|---|---|
| Table IX A (unrest locality) 8q after | 1 | 23.968 (10.122) | 23.968 (10.122) | 23.968 (10.122) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table IX A (unrest locality) 8q after | 2 | 1.372 (1.102) | 1.372 (1.102) | 1.372 (1.102) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table IX A (unrest locality) 8q after | 3 | 9.812 (4.709) | 9.812 (4.709) | 9.812 (4.709) | 0.000 / 0.000 | 0.000 / 0.000 | ✅ | ✅ |
| Table IX B (contract HQ) 8q after | 1 | 0.003 (0.071) | 0.056 (0.076) | 0.056 (0.076) | 0.053 / 0.005 | 0.000 / 0.000 | ❌ | ✅ |
| Table IX B (contract HQ) 8q after | 2 | 0.028 (0.033) | 0.015 (0.034) | 0.015 (0.034) | 0.013 / 0.001 | 0.000 / 0.000 | ❌ | ✅ |
| Table IX B (contract HQ) 8q after | 3 | 0.047 (0.046) | 0.030 (0.042) | 0.030 (0.042) | 0.017 / 0.004 | 0.000 / 0.000 | ❌ | ✅ |
| Table IX C (mother firm) 8q after | 1 | -0.498 (0.381) | 0.810 (0.391) | 0.810 (0.391) | 1.308 / 0.010 | 0.000 / 0.000 | ❌ | ✅ |
| Table IX C (mother firm) 8q after | 2 | -0.102 (0.391) | -0.228 (0.172) | -0.228 (0.172) | 0.126 / 0.219 | 0.000 / 0.000 | ❌ | ✅ |
| Table IX C (mother firm) 8q after | 3 | 1.365 (0.310) | 0.070 (0.197) | 0.070 (0.197) | 1.295 / 0.113 | 0.000 / 0.000 | ❌ | ✅ |

## Tally (coefficient rows)

- Original Stata vs paper: ✅ 80 · ⚠️ 57 · ❌ 44 · not run 0
- StatsPAI vs Stata: ✅ 166 · ⚠️ 15 · ❌ 0 · not available 0


## All tabular exhibits: re-run vs the author's shipped `Output/*.tex`

Cell-by-cell comparison of every number in each estout/file-write fragment (the shipped files are the authors' own January 2023 outputs, i.e. the online-appendix numbers).

| File | cells | identical | max abs diff | status |
|---|---|---|---|---|
| Table1_PanelA_unrest.tex | 8 | 8 | 0 | ✅ identical |
| Table1_PanelB_contracts.tex | 12 | 12 | 0 | ✅ identical |
| Table1_PanelC_software.tex | 6 | 6 | 0 | ✅ identical |
| Table1_PanelD_softwareprecontract.tex | 6 | 6 | 0 | ✅ identical |
| Table2_PanelA_ols.tex | 11 | 11 | 0 | ✅ identical |
| Table2_PanelB_iv.tex | 11 | 11 | 0 | ✅ identical |
| Table3_PanelA.1_olscam.tex | 11 | 11 | 0 | ✅ identical |
| Table3_PanelA.2_ivcam.tex | 11 | 11 | 0 | ✅ identical |
| Table3_PanelB.1_olsaicam.tex | 11 | 11 | 0 | ✅ identical |
| Table3_PanelB.2_ivaicam.tex | 11 | 11 | 0 | ✅ identical |
| Table4_PanelA_ai.tex | 26 | 25 | 0.0001 | ⚠️ last-digit |
| Table4_PanelB_aicam.tex | 26 | 24 | 0.0001 | ⚠️ last-digit |
| Table5_PanelA_nonpublic.tex | 26 | 26 | 0 | ✅ identical |
| Table5_PanelB_pastunrest.tex | 26 | 24 | 0.0001 | ⚠️ last-digit |
| Table6_PanelA_total.tex | 13 | 1 | 0.224 | ❌ differs |
| Table6_PanelB_gov.tex | 13 | 1 | 0.048 | ❌ differs |
| Table6_PanelC_commercial.tex | 13 | 1 | 0.127 | ❌ differs |
| Table7_PanelA_total.tex | 52 | 4 | 0.787 | ❌ differs |
| Table7_PanelB_gov.tex | 52 | 4 | 0.211 | ❌ differs |
| Table7_PanelC_commercial.tex | 52 | 4 | 0.22 | ❌ differs |
| Table8_export.tex | 8 | 8 | 0 | ✅ identical |
| Table9_PanelA_unrestlocality.tex | 7 | 7 | 0 | ✅ identical |
| Table9_PanelB_contractHQ.tex | 7 | 1 | 0.053 | ❌ differs |
| Table9_PanelC_motherfirm.tex | 7 | 1 | 1.308 | ❌ differs |
| TableA10_commercial.tex | 208 | 18 | 0.927 | ❌ differs |
| TableA11_total.tex | 416 | 37 | 0.787 | ❌ differs |
| TableA12_gov.tex | 416 | 37 | 0.211 | ❌ differs |
| TableA13_commercial.tex | 416 | 43 | 0.22 | ❌ differs |
| TableA14_PanelA.1_baseline.tex | | | | not produced (see notes) |
| TableA14_PanelA.2_age.tex | 26 | 2 | 0.422 | ❌ differs |
| TableA14_PanelA.3_precontract.tex | 26 | 2 | 0.233 | ❌ differs |
| TableA14_PanelB_major.tex | 26 | 2 | 0.204 | ❌ differs |
| TableA14_PanelC_video.tex | 26 | 3 | 0.057 | ❌ differs |
| TableA14_PanelD_ambiguous.tex | 26 | 2 | 0.198 | ❌ differs |
| TableA14_PanelE.1_timestep.tex | 26 | 2 | 0.157 | ❌ differs |
| TableA14_PanelE.2_embedding.tex | 26 | 4 | 0.123 | ❌ differs |
| TableA14_PanelE.3_node.tex | 26 | 3 | 0.411 | ❌ differs |
| TableA14_PanelF.1_balanced.tex | 26 | 2 | 0.169 | ❌ differs |
| TableA14_PanelF.2_extended.tex | 26 | 2 | 1.212 | ❌ differs |
| TableA14_PanelG.1_Beijing.tex | 26 | 3 | 0.21 | ❌ differs |
| TableA14_PanelG.2_Xinjiang.tex | 26 | 2 | 1.105 | ❌ differs |
| TableA14_PanelG.3_prefecture.tex | 26 | 3 | 0.224 | ❌ differs |
| TableA14_PanelG.4_province.tex | 26 | 3 | 0.224 | ❌ differs |
| TableA14_PanelH_provqofd.tex | 26 | 2 | 0.255 | ❌ differs |
| TableA15_PanelA.1_baseline.tex | | | | not produced (see notes) |
| TableA15_PanelA.2_age.tex | 52 | 5 | 0.394 | ❌ differs |
| TableA15_PanelA.3_precontract.tex | 52 | 4 | 0.241 | ❌ differs |
| TableA15_PanelB_major.tex | 52 | 4 | 0.195 | ❌ differs |
| TableA15_PanelC_video.tex | 52 | 6 | 0.082 | ❌ differs |
| TableA15_PanelD_ambiguous.tex | 52 | 4 | 0.19 | ❌ differs |
| TableA15_PanelE.1_timestep.tex | 52 | 5 | 0.146 | ❌ differs |
| TableA15_PanelE.2_embedding.tex | 52 | 6 | 0.158 | ❌ differs |
| TableA15_PanelE.3_node.tex | 52 | 4 | 0.379 | ❌ differs |
| TableA15_PanelF.1_balanced.tex | 52 | 4 | 0.163 | ❌ differs |
| TableA15_PanelF.2_extended.tex | 52 | 5 | 1.128 | ❌ differs |
| TableA15_PanelG.1_Beijing.tex | 52 | 6 | 0.129 | ❌ differs |
| TableA15_PanelG.2_Xinjiang.tex | 52 | 4 | 1.152 | ❌ differs |
| TableA15_PanelG.3_prefecture.tex | 52 | 5 | 0.313 | ❌ differs |
| TableA15_PanelG.4_province.tex | 52 | 4 | 0.313 | ❌ differs |
| TableA15_PanelH_provqofd.tex | 52 | 4 | 0.2 | ❌ differs |
| TableA2_PanelA.1_protestols.tex | 11 | 11 | 0 | ✅ identical |
| TableA2_PanelA.2_protestiv.tex | 11 | 11 | 0 | ✅ identical |
| TableA2_PanelB.1_demandols.tex | 11 | 11 | 0 | ✅ identical |
| TableA2_PanelB.2_demandiv.tex | 11 | 11 | 0 | ✅ identical |
| TableA2_PanelC.1_threatols.tex | 11 | 11 | 0 | ✅ identical |
| TableA2_PanelC.2_threativ.tex | 11 | 11 | 0 | ✅ identical |
| TableA4_PanelA_hires.tex | 5 | 5 | 0 | ✅ identical |
| TableA4_PanelB_office.tex | 5 | 5 | 0 | ✅ identical |
| TableA5_PanelA.1_aiprotest.tex | 26 | 25 | 0.0001 | ⚠️ last-digit |
| TableA5_PanelA.2_aidemand.tex | 26 | 24 | 0.0001 | ⚠️ last-digit |
| TableA5_PanelA.3_aithreat.tex | 26 | 26 | 0 | ✅ identical |
| TableA5_PanelB.1_nonpublicprotest.tex | 26 | 26 | 0 | ✅ identical |
| TableA5_PanelB.2_nonpublicdemand.tex | 26 | 25 | 0.0001 | ⚠️ last-digit |
| TableA5_PanelB.3_nonpublicprotest.tex | 26 | 26 | 0 | ✅ identical |
| TableA6_cam.tex | 26 | 26 | 0 | ✅ identical |
| TableA7_incentive.tex | 24 | 24 | 0 | ✅ identical |
| TableA8_total.tex | 208 | 16 | 0.995 | ❌ differs |
| TableA9_gov.tex | 208 | 19 | 0.154 | ❌ differs |

## Notes on every mismatch

**N1 — Tables IV, V, A.5 (⚠️ last digit of a SE).** Coefficients are identical to the paper; 1–2 SEs per panel differ by 0.0001 (e.g. Table IV A col 4: 0.1542 vs 0.1543). The regressions include ~70 collinear `X × quarter` terms that `ivreghdfe` partials out; the difference is a floating-point / version effect (ivreghdfe 1.1.4 and reghdfe 6.13.1 here vs the 2021–22 versions used by the authors). StatsPAI reproduces our Stata re-run to all digits.

**N2 — Tables VI, VII, A.8–A.15, IX B/C, Figures V/VI/A.11/A.14–A.16 (⚠️/❌ random tie-breaking).** The firm panels are built with `collapse … (lastnm) place` after `bys city:` / `bys sub_fe:` sorts. In `firm_data.dta` 425 collapse cells contain several contract locations, so `lastnm place` depends on the random order Stata uses to break ties (`set sortseed` fixes the seed but not the sort algorithm or the random numbers consumed earlier in the section). `place` is both the cluster variable and a sample filter (`keep if place != 0`); Table IX B/C additionally use `bys firm_contract qofd: drop if _n > 1`. Evidence: the same code gives 10.783 (3.888) with Stata's default sort method, 10.663 (3.667) with `set sortmethod qsort`, 10.671 (3.664) in the paper and 10.746 (3.917) in the October 2022 working paper (Table VI A col 1). All Table VI–VII differences are well within one standard error and leave every conclusion unchanged, except Table IX C (mother-firm spillovers: paper −0.498 / −0.102 / 1.365***, re-run 0.810** / −0.228 / 0.070). The authors' own file time stamps show Table IX C was produced separately, 26 hours after Panels A–B, so we cannot tell whether the gap is randomness or a later code change. StatsPAI starts from the exported panels of our run and matches our Stata numbers exactly.

**N3 — Table IX A (✅ only with xtevent 1.0.0).** With the current SSC `xtevent` (3.1.0) and with GitHub tags 2.1.1/2.2.0 the same command returns −8.678 (23.771) / 3.961 (19.363) / −5.343 (9.448). With tag 1.0.0 (Aug 2021) it reproduces the paper exactly. The versions differ in how the endpoint bins are built for a non-binary policy variable (v1.0.0 uses `1 − F8.z` and `L9.z`). `Program/ado/` pins 1.0.0.

**N4 — Tables II B, III B/D (LASSO IV).** Stata: our re-run of `xpoivregress … rseed(1)` reproduces all 15 cells exactly (Table II B took 3.1 h for 5 calls, Table III 1.5 h for 10 calls on a shared 8-core machine; Table A.2's 15 LASSO calls 3.3 h; Table A.3 lasso-coefficient log identical up to label wrapping). StatsPAI has no cross-fit partialing-out LASSO IV; the StatsPAI column is an approximation (FE and controls partialled out with `sp.demean`, then `sp.lasso_iv(penalty="cv", cluster="place")`), systematically below the paper for Table II (≈0.25 vs 0.35–0.38) and above it for Table III B. `sp.rlasso_iv` (plug-in rigorous LASSO) selects no instrument at all on these data.

**N5 — Figure A.10 (100 seeds).** Not run: 100 cross-fit LASSO IV estimations at ≈30 min each (> 50 hours).

**N6 — `TableA14_PanelA.1_baseline.tex`, `TableA15_PanelA.1_baseline.tex`.** Shipped by the authors but no `estout` command in `Analysis.do` writes these files (they duplicate Tables VI/VII column 1), so they cannot be regenerated from the package.

**N7 — Section 3 (Figure III, Table A.3).** The first run stopped with r(199) because `jive` (Poi 2006, Stata Journal st0108) is used but not listed in the package README; after installing it into `Program/ado/` the section was re-run (rc 0, 1.5 h). Figure III bar values (`Data/Intermediate/Fig3.dta`, first 6 rows) vs the authors' shipped file:

| Bar | Authors b (se) | Stata re-run b (se) | StatsPAI b (se) |
|---|---|---|---|
| LASSO IV | 0.3774 (0.0837) | 0.3774 (0.0837) ✅ | — (not available) |
| Parsimonious IV | 0.3131 (0.1598) | 0.3131 (0.1598) ✅ | 0.3131 (0.1598) ✅ |
| LIML | 0.2894 (0.1327) | 0.2936 (0.1309) ❌ | 0.2667 (0.0222) ❌ |
| JIVE (UJIVE1) | 0.3007 (0.0779) | 0.3005 (0.0778) ⚠️ | — (not available) |
| LASSO IV, 7-day window | 0.3790 (0.0837) | 0.3790 (0.0837) ✅ | — |
| OLS | 0.1995 (0.0434) | 0.1995 (0.0434) ✅ | 0.1995 (0.0434) ✅ |

**N8 — Figure III LIML/JIVE are numerically unstable.** Both use ~340 products of quarterly weather sums (magnitudes up to 1e13) as instruments. Re-running the authors' exact `ivreghdfe … liml` on the same data with each instrument standardized first (a linear reparametrisation that cannot change the estimator) moves 2SLS from 0.2956 to 0.2488 and LIML from 0.2936 to 0.2678; a numpy k-class implementation and `sp.liml` on standardized instruments give 0.2479 / 0.2667. The authors' 0.2894, our 0.2936 and the stable 0.267 therefore differ because of floating-point error in Stata's cross-product inversion, not because of the data.
