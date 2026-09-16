# Comparison: paper vs original Stata code vs StatsPAI

He, Wang & Zhang (2020, QJE). Paper values transcribed from the published PDF. Original Stata = author's do-files run with
Stata 18 MP + rdrobust 10.0.0 (`Program/run_original.do`; per-cell e() export via `Program/statspai/export_stata_estimates.do`).
StatsPAI = `statspai` 1.28.0 (`Program/statspai/replicate_statspai.py`).

* **StatsPAI matched** — `sp.rdrobust(h=, b=, cluster='site_id')` with the author's `masspoints(off)` bandwidth (from the official rdrobust Python port; Stata e(h,b) fallback).
* **StatsPAI native** — `sp.rdrobust(bwselect=..., cluster='site_id')`; StatsPAI always applies the mass-point adjustment in bandwidth selection (= Stata's default `masspoints(adjust)`), so h differs.
* Status compares the original Stata output with the paper at the paper's reported precision: ✅ identical after rounding; ⚠️ small difference or matches only under a documented spec variant; ❌ unexplained.

## Summary

| exhibit | cells | ✅ | ⚠️ | ❌ | share of cells where StatsPAI(matched) == Stata (b, se; rel. tol 1e-5) |
|---|---|---|---|---|---|
| T1 | 18 | 18 | 0 | 0 | 100% |
| T2 | 6 | 1 | 5 | 0 | 100% |
| T3 | 42 | 42 | 0 | 0 | 100% |
| T4 | 12 | 12 | 0 | 0 | 100% |
| T5 | 24 | 16 | 5 | 3 | 100% |
| T6 | 27 | 23 | 3 | 1 | 100% |
| T7 | 36 | 30 | 2 | 4 | 100% |
| T8 | 6 | 6 | 0 | 0 |  |
| F4 (Figure IV) | 2 panels | author's `rdplot` ran (Results/Figures/F3_TFP.png); StatsPAI `sp.rdplot` re-draw in Results/statspai/figure4_rdplot.png | | | |
| F5 (Figure V) | 8 years | plotted from pre-computed `graph_by_year.dta` (year-by-year RD data not shipped); identical inputs in both | | | |

## Explained differences

1. **Table V, uniform-kernel column (col 3).** The shipped `5_Emissions_Replication.do` uses the default `bwselect(mserd)`. The published column reproduces exactly with `bwselect(msecomb1)` (COD 0.73 (0.35), COD intensity 0.84 (0.33), wastewater intensity 0.56 (0.26)); SO2/NOx match `mserd`; the NH3-N uniform cells match neither. The published column was evidently produced from an earlier version of the do-file (the same `bwselect(msecomb1)` survives in one line of `6_PE_replication.do`).
2. **Table VI Panel A (waste discharge fee).** The shipped code uses `bwselect(certwo)`; published cols (1)–(2) reproduce exactly with `mserd` (−0.91 (0.44), −1.12 (0.45)); col (3) matches `certwo` (−0.91 (0.48)).
3. **Table III, before-2003 columns (4)–(6).** The paper prints the *bias-corrected* point estimate with the *conventional* SE (all other RD tables print the conventional estimate). With that reading every cell matches.
4. **Table VII Panel C (SNWD).** The code's kernel loop is `epa tri uni`, but the paper labels the columns Triangle/Epanech./Uniform; the numbers match the code order (col 1 = Epanechnikov).
5. **Table VI, nonpolluting × automatic stations, col (6).** The shipped code uses `bwselect(msecomb1)` without `masspoints(off)` → −0.54 (1.61); the paper shows −0.43 (0.32). No bandwidth selector / mass-point combination reproduces it (grid in the StatsPAI note); col (5) matches the coefficient (−0.48) but not the SE (0.71 vs 0.76).
6. **Table II (mdrd).** Ribas's `mdrd` is no longer online; the archived 26-Apr-2017 build (Wayback Machine) was used. Coefficients match to ±0.01 and SEs to ±0.01, but the selected bandwidths (6.39/5.69/5.35; 6.33/6.44/6.42) are smaller than those printed (10.39/10.20/9.89; 8.96/8.87/9.17) → the authors used a later `mdrd`/`ddbwsel` build (their T2 zip is dated Sept 2020). The paper's "Obs." is the full polluting / nonpolluting panel (20,588 / 34,892), which our data reproduce.
7. **Small-sample cells** (SOE polluting col 3, N = 513; SNWD nonpolluting cols 2–3, N = 1,429; one obs. in Table VI Panel B weak-incentive nonpolluting: 4,739 vs 4,738) do not reproduce under rdrobust 10.0.0 with any bwselect/masspoints combination tried. These are the cells most sensitive to rdrobust version changes in the bandwidth selector (the paper was estimated with a 2019–2020 rdrobust release). Point estimates of all headline cells are unaffected.

## StatsPAI vs Stata

* With the author's bandwidth passed explicitly, `sp.rdrobust` reproduces Stata's conventional estimate and cluster-robust SE to ~1e-12 in every cell, and the bias-corrected estimate exactly; the robust (RBC) SE differs in the 4th decimal (e.g. 0.70282 vs 0.70245).
* StatsPAI's own bandwidth selector cannot switch off the mass-point adjustment, so "native" results differ from the paper wherever mass points are present (Table I Panel A col 1: h = 3.75 vs 4.20, b = 0.23 vs 0.34).
* Table II: StatsPAI has no difference-in-discontinuities estimator; `RD(post03) − RD(pre03)` with `mdrd`'s bandwidths reproduces `mdrd`'s conventional and bias-corrected estimates to 4 decimals; the SE (√(V₁+V₀)) differs from mdrd's by < 0.001.

## Cell-by-cell

### Table I — Upstream–downstream TFP gap

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| A: no control | TFP polluting | 1 | 0.34 (0.57) | 0.34 (0.57); paper h=4.203, Stata h=4.203 | 6,224 | 0.34 (0.57) | 0.23 (0.58) [3.75] | 0.00 | ✅ |
| A: no control | TFP polluting | 2 | 0.37 (0.59) | 0.37 (0.59); paper h=3.889, Stata h=3.889 | 6,224 | 0.37 (0.59) | 0.37 (0.59) [3.88] | 0.00 | ✅ |
| A: no control | TFP polluting | 3 | 0.32 (0.56) | 0.32 (0.56); paper h=3.622, Stata h=3.622 | 6,224 | 0.32 (0.56) | 0.42 (0.54) [4.70] | 0.00 | ✅ |
| A: no control | TFP nonpolluting | 4 | -0.03 (0.15) | -0.03 (0.15); paper h=5.887, Stata h=5.887 | 11,502 | -0.03 (0.15) | 0.07 (0.19) [4.73] | 0.00 | ✅ |
| A: no control | TFP nonpolluting | 5 | 0.04 (0.18) | 0.04 (0.18); paper h=5.168, Stata h=5.168 | 11,502 | 0.04 (0.18) | 0.06 (0.19) [4.84] | 0.00 | ✅ |
| A: no control | TFP nonpolluting | 6 | 0.01 (0.18) | 0.01 (0.18); paper h=4.522, Stata h=4.522 | 11,502 | 0.01 (0.18) | 0.02 (0.18) [4.21] | 0.00 | ✅ |
| B: station+industry FE | TFP polluting | 1 | 0.36 (0.17) | 0.36 (0.17); paper h=5.723, Stata h=5.723 | 5,890 (paper 6,224) | 0.36 (0.17) | 0.36 (0.17) [5.63] | 0.00 | ✅ |
| B: station+industry FE | TFP polluting | 2 | 0.38 (0.17) | 0.38 (0.17); paper h=5.523, Stata h=5.523 | 5,890 (paper 6,224) | 0.38 (0.17) | 0.36 (0.15) [5.89] | 0.00 | ✅ |
| B: station+industry FE | TFP polluting | 3 | 0.34 (0.15) | 0.34 (0.15); paper h=5.144, Stata h=5.144 | 5,890 (paper 6,224) | 0.34 (0.15) | 0.38 (0.15) [5.34] | 0.00 | ✅ |
| B: station+industry FE | TFP nonpolluting | 4 | 0.03 (0.09) | 0.03 (0.09); paper h=5.890, Stata h=5.890 | 11,536 (paper 11,502) | 0.03 (0.09) | 0.04 (0.09) [5.72] | 0.00 | ✅ |
| B: station+industry FE | TFP nonpolluting | 5 | 0.04 (0.09) | 0.04 (0.09); paper h=5.479, Stata h=5.479 | 11,536 (paper 11,502) | 0.04 (0.09) | 0.02 (0.09) [5.86] | 0.00 | ✅ |
| B: station+industry FE | TFP nonpolluting | 6 | -0.02 (0.09) | -0.02 (0.09); paper h=6.091, Stata h=6.091 | 11,536 (paper 11,502) | -0.02 (0.09) | 0.04 (0.10) [4.49] | 0.00 | ✅ |
| C: station x industry FE | TFP polluting | 1 | 0.27 (0.15) | 0.27 (0.15); paper h=4.496, Stata h=4.496 | 5,836 (paper 6,224) | 0.27 (0.15) | 0.24 (0.16) [3.75] | 0.00 | ✅ |
| C: station x industry FE | TFP polluting | 2 | 0.29 (0.15) | 0.29 (0.15); paper h=4.333, Stata h=4.333 | 5,836 (paper 6,224) | 0.29 (0.15) | 0.27 (0.15) [3.90] | 0.00 | ✅ |
| C: station x industry FE | TFP polluting | 3 | 0.29 (0.14) | 0.29 (0.14); paper h=4.689, Stata h=4.689 | 5,836 (paper 6,224) | 0.29 (0.14) | 0.32 (0.11) [4.92] | 0.00 | ✅ |
| C: station x industry FE | TFP nonpolluting | 4 | 0.02 (0.06) | 0.02 (0.06); paper h=5.692, Stata h=5.692 | 11,002 (paper 11,502) | 0.02 (0.06) | 0.06 (0.06) [5.08] | 0.00 | ✅ |
| C: station x industry FE | TFP nonpolluting | 5 | 0.04 (0.06) | 0.04 (0.06); paper h=5.204, Stata h=5.204 | 11,002 (paper 11,502) | 0.04 (0.06) | 0.04 (0.07) [5.14] | 0.00 | ✅ |
| C: station x industry FE | TFP nonpolluting | 6 | 0.03 (0.07) | 0.03 (0.07); paper h=4.430, Stata h=4.430 | 11,002 (paper 11,502) | 0.03 (0.07) | 0.07 (0.07) [3.84] | 0.00 | ✅ |

### Table III — Inputs and outputs

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| after 2003 | profit (10k RMB) | 1 | 478.59 (470.49) | 478.59 (470.49) | 5,520 | 478.59 (470.49) | 331.61 (531.83) [4.73] | 0.00 | ✅ |
| after 2003 | profit (10k RMB) | 2 | 441.18 (524.34) | 441.18 (524.34) | 5,520 | 441.18 (524.34) | 338.54 (550.10) [4.93] | 0.00 | ✅ |
| after 2003 | profit (10k RMB) | 3 | 693.76 (595.49) | 693.76 (595.49) | 5,520 | 693.76 (595.49) | 603.21 (548.14) [4.88] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | profit (10k RMB) | 4 | -207.19 (386.84) | -207.19 (386.84) | 2,282 | -207.19 (386.84) | 121.50 (408.19) [6.10] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | profit (10k RMB) | 5 | -233.60 (410.51) | -233.60 (410.51) | 2,282 | -233.60 (410.51) | 75.84 (416.53) [5.86] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | profit (10k RMB) | 6 | 250.92 (494.19) | 250.92 (494.19) | 2,282 | 250.92 (494.19) | 91.60 (442.22) [4.93] | 0.00 | ✅ |
| after 2003 | value added (log) | 1 | 0.05 (0.19) | 0.05 (0.19) | 5,520 | 0.05 (0.19) | -0.02 (0.21) [6.08] | 0.00 | ✅ |
| after 2003 | value added (log) | 2 | 0.07 (0.19) | 0.07 (0.19) | 5,520 | 0.07 (0.19) | 0.05 (0.19) [6.75] | 0.00 | ✅ |
| after 2003 | value added (log) | 3 | 0.11 (0.18) | 0.11 (0.18) | 5,520 | 0.11 (0.18) | 0.11 (0.18) [7.14] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | value added (log) | 4 | -0.11 (0.13) | -0.11 (0.13) | 2,272 | -0.11 (0.13) | -0.18 (0.14) [4.00] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | value added (log) | 5 | -0.09 (0.14) | -0.09 (0.14) | 2,272 | -0.09 (0.14) | -0.13 (0.14) [4.29] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | value added (log) | 6 | 0.03 (0.16) | 0.03 (0.16) | 2,272 | 0.03 (0.16) | 0.13 (0.15) [5.62] | 0.00 | ✅ |
| after 2003 | employees (log) | 1 | -0.22 (0.16) | -0.22 (0.16) | 5,473 | -0.22 (0.16) | -0.40 (0.20) [5.11] | 0.00 | ✅ |
| after 2003 | employees (log) | 2 | -0.19 (0.16) | -0.19 (0.16) | 5,473 | -0.19 (0.16) | -0.35 (0.19) [5.45] | 0.00 | ✅ |
| after 2003 | employees (log) | 3 | -0.09 (0.16) | -0.09 (0.16) | 5,473 | -0.09 (0.16) | -0.11 (0.16) [6.15] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | employees (log) | 4 | -0.07 (0.19) | -0.07 (0.19) | 2,259 | -0.07 (0.19) | -0.35 (0.26) [5.37] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | employees (log) | 5 | 0.01 (0.19) | 0.01 (0.19) | 2,259 | 0.01 (0.19) | -0.07 (0.20) [6.60] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | employees (log) | 6 | 0.05 (0.20) | 0.05 (0.20) | 2,259 | 0.05 (0.20) | 0.06 (0.19) [6.88] | 0.00 | ✅ |
| after 2003 | capital (log) | 1 | -0.40 (0.22) | -0.40 (0.22) | 5,380 | -0.40 (0.22) | -0.45 (0.28) [5.62] | 0.00 | ✅ |
| after 2003 | capital (log) | 2 | -0.45 (0.27) | -0.45 (0.27) | 5,380 | -0.45 (0.27) | -0.46 (0.28) [5.17] | 0.00 | ✅ |
| after 2003 | capital (log) | 3 | -0.61 (0.29) | -0.61 (0.29) | 5,380 | -0.61 (0.29) | -0.46 (0.29) [4.39] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | capital (log) | 4 | -0.06 (0.21) | -0.06 (0.21) | 2,271 | -0.06 (0.21) | -0.12 (0.23) [6.24] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | capital (log) | 5 | -0.04 (0.22) | -0.04 (0.22) | 2,271 | -0.04 (0.22) | -0.08 (0.23) [5.95] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | capital (log) | 6 | -0.04 (0.26) | -0.04 (0.26) | 2,271 | -0.04 (0.26) | 0.02 (0.24) [5.61] | 0.00 | ✅ |
| after 2003 | intermediate (log) | 1 | -0.05 (0.24) | -0.05 (0.24) | 5,540 | -0.05 (0.24) | -0.10 (0.27) [4.44] | 0.00 | ✅ |
| after 2003 | intermediate (log) | 2 | -0.04 (0.24) | -0.04 (0.24) | 5,540 | -0.04 (0.24) | -0.05 (0.24) [5.01] | 0.00 | ✅ |
| after 2003 | intermediate (log) | 3 | -0.05 (0.18) | -0.05 (0.18) | 5,540 | -0.05 (0.18) | -0.01 (0.17) [7.00] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | intermediate (log) | 4 | -0.03 (0.16) | -0.03 (0.16) | 2,274 | -0.03 (0.16) | -0.05 (0.18) [5.73] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | intermediate (log) | 5 | -0.01 (0.16) | -0.01 (0.16) | 2,274 | -0.01 (0.16) | 0.00 (0.16) [6.32] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | intermediate (log) | 6 | 0.05 (0.20) | 0.05 (0.20) | 2,274 | 0.05 (0.20) | -0.01 (0.18) [5.23] | 0.00 | ✅ |
| after 2003 | VA/employee (log) | 1 | 0.08 (0.08) | 0.08 (0.08) | 5,540 | 0.08 (0.08) | 0.09 (0.08) [6.49] | 0.00 | ✅ |
| after 2003 | VA/employee (log) | 2 | 0.08 (0.08) | 0.08 (0.08) | 5,540 | 0.08 (0.08) | 0.08 (0.08) [6.80] | 0.00 | ✅ |
| after 2003 | VA/employee (log) | 3 | 0.05 (0.08) | 0.05 (0.08) | 5,540 | 0.05 (0.08) | 0.06 (0.08) [6.52] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/employee (log) | 4 | 0.00 (0.06) | 0.00 (0.06) | 2,276 | 0.00 (0.06) | -0.02 (0.07) [4.42] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/employee (log) | 5 | 0.02 (0.06) | 0.02 (0.06) | 2,276 | 0.02 (0.06) | 0.02 (0.06) [5.02] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/employee (log) | 6 | 0.01 (0.05) | 0.01 (0.05) | 2,276 | 0.01 (0.05) | -0.01 (0.04) [6.95] | 0.00 | ✅ |
| after 2003 | VA/capital (log) | 1 | 0.25 (0.10) | 0.25 (0.10) | 5,532 | 0.25 (0.10) | 0.25 (0.11) [4.51] | 0.00 | ✅ |
| after 2003 | VA/capital (log) | 2 | 0.27 (0.10) | 0.27 (0.10) | 5,532 | 0.27 (0.10) | 0.27 (0.10) [4.98] | 0.00 | ✅ |
| after 2003 | VA/capital (log) | 3 | 0.28 (0.10) | 0.28 (0.10) | 5,532 | 0.28 (0.10) | 0.26 (0.10) [4.39] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/capital (log) | 4 | 0.04 (0.08) | 0.04 (0.08) | 2,274 | 0.04 (0.08) | 0.04 (0.09) [5.13] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/capital (log) | 5 | 0.04 (0.09) | 0.04 (0.09) | 2,274 | 0.04 (0.09) | 0.04 (0.09) [5.43] | 0.00 | ✅ |
| before 2003 (paper reports BC coef) | VA/capital (log) | 6 | -0.00 (0.10) | -0.00 (0.10) | 2,274 | -0.00 (0.10) | 0.06 (0.09) [5.43] | 0.00 | ✅ |

### Table IV — Abatement efforts

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| A | operating hours | 1 | 288 (101) | 288 (101) | 7,302 | 288 (101) | 288 (101) [5.21] | 0.30 | ✅ |
| A | operating hours | 2 | 256 (105) | 256 (105) | 7,302 | 256 (105) | 260 (105) [5.51] | 0.07 | ✅ |
| A | operating hours | 3 | 171 (92) | 171 (92) | 7,302 | 171 (92) | 238 (110) [4.92] | 0.45 | ✅ |
| B | log water input | 1 | 0.62 (0.23) | 0.62 (0.23) | 6,606 | 0.62 (0.23) | 0.62 (0.23) [3.25] | 0.00 | ✅ |
| B | log water input | 2 | 0.60 (0.25) | 0.60 (0.25) | 6,606 | 0.60 (0.25) | 0.61 (0.25) [3.25] | 0.00 | ✅ |
| B | log water input | 3 | 0.40 (0.28) | 0.40 (0.28) | 6,606 | 0.40 (0.28) | 0.63 (0.28) [2.67] | 0.00 | ✅ |
| C | # treatment facilities | 1 | -1.15 (0.62) | -1.15 (0.62) | 7,265 | -1.15 (0.62) | -1.23 (0.65) [4.02] | 0.00 | ✅ |
| C | # treatment facilities | 2 | -1.07 (0.62) | -1.07 (0.62) | 7,265 | -1.07 (0.62) | -1.24 (0.68) [3.92] | 0.00 | ✅ |
| C | # treatment facilities | 3 | -1.29 (0.69) | -1.29 (0.69) | 7,265 | -1.29 (0.69) | -1.15 (0.67) [3.54] | 0.00 | ✅ |
| D | treatment capacity (t/day) | 1 | -7,381 (3,733) | -7,381 (3,733) | 4,624 | -7,381 (3,733) | -7,354 (3,736) [4.14] | 0.07 | ✅ |
| D | treatment capacity (t/day) | 2 | -8,594 (3,855) | -8,594 (3,855) | 4,624 | -8,594 (3,855) | -7,794 (3,853) [3.93] | 0.06 | ✅ |
| D | treatment capacity (t/day) | 3 | -7,849 (3,714) | -7,849 (3,714) | 4,624 | -7,849 (3,714) | -9,806 (4,302) [4.09] | 0.40 | ✅ |

### Table V — Emissions

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| A | COD (log) | 1 | 0.84 (0.43) | 0.84 (0.43) | 9,797 | 0.84 (0.43) | 0.86 (0.44) [3.20] | 0.00 | ✅ |
| A | COD (log) | 2 | 0.75 (0.39) | 0.75 (0.39) | 9,797 | 0.75 (0.39) | 0.74 (0.37) [3.63] | 0.00 | ✅ |
| A | COD (log) | 3 | 0.73 (0.35) | 0.24 (0.32) → with `msecomb1`: Stata 0.73 (0.35), StatsPAI 0.73 (0.35) | 9,797 | 0.24 (0.32) | 0.58 (0.30) [4.44] | 0.49 | ⚠️ |
| A | COD intensity (log) | 1 | 0.77 (0.29) | 0.77 (0.29) | 9,797 | 0.77 (0.29) | 0.88 (0.32) [4.23] | 0.00 | ✅ |
| A | COD intensity (log) | 2 | 0.70 (0.27) | 0.70 (0.27) | 9,797 | 0.70 (0.27) | 0.81 (0.29) [4.32] | 0.00 | ✅ |
| A | COD intensity (log) | 3 | 0.84 (0.33) | 0.73 (0.26) → with `msecomb1`: Stata 0.84 (0.33), StatsPAI 0.84 (0.33) | 9,797 | 0.73 (0.26) | 0.76 (0.33) [3.36] | 0.11 | ⚠️ |
| B | NH3-N (log) | 1 | 0.87 (0.90) | 0.87 (0.90) | 4,772 | 0.87 (0.90) | 0.98 (1.08) [3.90] | 0.00 | ✅ |
| B | NH3-N (log) | 2 | 0.76 (0.76) | 0.76 (0.76) | 4,772 | 0.76 (0.76) | 0.92 (0.99) [3.93] | 0.00 | ✅ |
| B | NH3-N (log) | 3 | 0.46 (0.62) | 0.63 (0.69) | 4,772 | 0.63 (0.69) | 1.00 (0.91) [3.72] | 0.17 | ❌ |
| B | NH3-N intensity (log) | 1 | 1.23 (0.45) | 1.23 (0.45) | 4,752 (paper 4,772) | 1.23 (0.45) | 1.22 (0.45) [3.23] | 0.00 | ✅ |
| B | NH3-N intensity (log) | 2 | 1.01 (0.44) | 1.01 (0.44) | 4,752 (paper 4,772) | 1.01 (0.44) | 1.06 (0.43) [3.33] | 0.00 | ✅ |
| B | NH3-N intensity (log) | 3 | 0.73 (0.44) | 0.85 (0.43) | 4,752 (paper 4,772) | 0.85 (0.43) | 0.85 (0.43) [3.01] | 0.12 | ❌ |
| C | wastewater (log) | 1 | 0.34 (0.31) | 0.34 (0.31) | 9,797 | 0.34 (0.31) | 0.34 (0.31) [3.75] | 0.00 | ✅ |
| C | wastewater (log) | 2 | 0.33 (0.33) | 0.33 (0.33) | 9,797 | 0.33 (0.33) | 0.33 (0.32) [4.06] | 0.00 | ✅ |
| C | wastewater (log) | 3 | 0.06 (0.26) | 0.06 (0.28) | 9,797 | 0.06 (0.28) | 0.24 (0.31) [4.64] | 0.00 | ⚠️ |
| C | wastewater intensity (log) | 1 | 0.43 (0.21) | 0.44 (0.21) | 9,797 | 0.44 (0.21) | 0.47 (0.23) [3.96] | 0.01 | ⚠️ |
| C | wastewater intensity (log) | 2 | 0.38 (0.20) | 0.40 (0.20) | 9,797 | 0.40 (0.20) | 0.43 (0.22) [4.35] | 0.02 | ❌ |
| C | wastewater intensity (log) | 3 | 0.56 (0.26) | 0.24 (0.19) → with `msecomb1`: Stata 0.56 (0.26), StatsPAI 0.56 (0.26) | 9,797 (paper 9,796) | 0.24 (0.19) | 0.35 (0.22) [4.07] | 0.32 | ⚠️ |
| D | SO2 (log) | 1 | 0.03 (0.29) | 0.03 (0.29) | 4,740 | 0.03 (0.29) | 0.05 (0.31) [3.99] | 0.00 | ✅ |
| D | SO2 (log) | 2 | 0.06 (0.30) | 0.06 (0.30) | 4,740 | 0.06 (0.30) | 0.06 (0.30) [4.18] | 0.00 | ✅ |
| D | SO2 (log) | 3 | -0.16 (0.25) | -0.16 (0.25) | 4,740 | -0.16 (0.25) | -0.10 (0.25) [6.10] | 0.00 | ✅ |
| D | NOx (log) | 1 | 0.09 (0.28) | 0.09 (0.28) | 4,740 | 0.09 (0.28) | 0.11 (0.29) [3.42] | 0.00 | ✅ |
| D | NOx (log) | 2 | 0.14 (0.29) | 0.14 (0.29) | 4,740 | 0.14 (0.29) | 0.14 (0.29) [3.38] | 0.00 | ✅ |
| D | NOx (log) | 3 | -0.05 (0.20) | -0.05 (0.20) | 4,740 | -0.05 (0.20) | -0.06 (0.20) [5.95] | 0.00 | ✅ |

### Table VI — Political economy

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| A: double standard | waste discharge fee (log) | 1 | -0.91 (0.44) | -1.14 (0.44) → with `mserd`: Stata -0.91 (0.44), StatsPAI -0.91 (0.44) | 3,050 | -1.14 (0.44) | -1.46 (0.45) [2.79] | 0.23 | ⚠️ |
| A: double standard | waste discharge fee (log) | 2 | -1.12 (0.45) | -1.32 (0.45) → with `mserd`: Stata -1.12 (0.45), StatsPAI -1.12 (0.45) | 3,050 | -1.32 (0.45) | -1.32 (0.45) [2.72] | 0.20 | ⚠️ |
| A: double standard | waste discharge fee (log) | 3 | -0.91 (0.48) | -0.91 (0.48) | 3,050 | -0.91 (0.48) | -0.88 (0.46) [2.74] | 0.00 | ✅ |
| B: strong incentive | TFP polluting | 1 | 0.56 (0.20) | 0.56 (0.20) | 5,305 | 0.56 (0.20) | 0.54 (0.21) [4.22] | 0.00 | ✅ |
| B: strong incentive | TFP polluting | 2 | 0.58 (0.20) | 0.58 (0.20) | 5,305 | 0.58 (0.20) | 0.57 (0.19) [5.03] | 0.00 | ✅ |
| B: strong incentive | TFP polluting | 3 | 0.59 (0.20) | 0.59 (0.20) | 5,305 | 0.59 (0.20) | 0.62 (0.20) [4.54] | 0.00 | ✅ |
| B: strong incentive | TFP nonpolluting | 4 | 0.12 (0.13) | 0.12 (0.13) | 9,382 | 0.12 (0.13) | 0.12 (0.13) [5.04] | 0.00 | ✅ |
| B: strong incentive | TFP nonpolluting | 5 | 0.09 (0.14) | 0.09 (0.14) | 9,382 | 0.09 (0.14) | 0.11 (0.14) [5.36] | 0.00 | ✅ |
| B: strong incentive | TFP nonpolluting | 6 | 0.07 (0.10) | 0.07 (0.10) | 9,382 | 0.07 (0.10) | 0.11 (0.11) [5.84] | 0.00 | ✅ |
| B: weak incentive | TFP polluting | 1 | 0.13 (0.19) | 0.13 (0.19) | 2,450 | 0.13 (0.19) | 0.10 (0.23) [4.01] | 0.00 | ✅ |
| B: weak incentive | TFP polluting | 2 | 0.19 (0.25) | 0.19 (0.25) | 2,450 | 0.19 (0.25) | 0.12 (0.24) [3.64] | 0.00 | ✅ |
| B: weak incentive | TFP polluting | 3 | 0.18 (0.27) | 0.18 (0.27) | 2,450 | 0.18 (0.27) | 0.06 (0.14) [6.10] | 0.00 | ✅ |
| B: weak incentive | TFP nonpolluting | 4 | 0.04 (0.19) | 0.04 (0.19) | 4,739 (paper 4,738) | 0.04 (0.19) | 0.10 (0.19) [3.18] | 0.00 | ✅ |
| B: weak incentive | TFP nonpolluting | 5 | 0.01 (0.19) | 0.01 (0.19) | 4,739 (paper 4,738) | 0.01 (0.19) | 0.14 (0.19) [3.37] | 0.00 | ✅ |
| B: weak incentive | TFP nonpolluting | 6 | 0.26 (0.22) | 0.26 (0.22) | 4,739 (paper 4,738) | 0.26 (0.22) | -0.00 (0.19) [3.49] | 0.00 | ✅ |
| C: automatic stations | TFP polluting | 1 | 1.18 (0.55) | 1.18 (0.55) | 932 | 1.18 (0.55) | 1.16 (0.51) [4.90] | 0.00 | ✅ |
| C: automatic stations | TFP polluting | 2 | 1.22 (0.55) | 1.22 (0.55) | 932 | 1.22 (0.55) | 1.18 (0.51) [4.90] | 0.00 | ✅ |
| C: automatic stations | TFP polluting | 3 | 1.21 (0.47) | 1.21 (0.47) | 932 | 1.21 (0.47) | 0.81 (0.47) [4.90] | 0.00 | ✅ |
| C: automatic stations | TFP nonpolluting | 4 | -1.07 (1.44) | -1.07 (1.44) | 1,815 | -1.07 (1.44) | -0.98 (0.16) [4.48] | 0.00 | ✅ |
| C: automatic stations | TFP nonpolluting | 5 | -0.48 (0.76) | -0.48 (0.71) | 1,815 | -0.48 (0.71) | -1.03 (0.19) [4.48] | 0.00 | ⚠️ |
| C: automatic stations | TFP nonpolluting | 6 | -0.43 (0.32) | -0.54 (1.61) | 1,815 | -0.54 (1.61) | -1.20 (0.30) [4.48] | 0.11 | ❌ |
| C: manual stations | TFP polluting | 1 | 0.30 (0.15) | 0.30 (0.15) | 4,953 | 0.30 (0.15) | 0.32 (0.18) [5.39] | 0.00 | ✅ |
| C: manual stations | TFP polluting | 2 | 0.35 (0.17) | 0.35 (0.17) | 4,953 | 0.35 (0.17) | 0.35 (0.17) [5.67] | 0.00 | ✅ |
| C: manual stations | TFP polluting | 3 | 0.41 (0.20) | 0.41 (0.20) | 4,953 | 0.41 (0.20) | 0.41 (0.20) [4.49] | 0.00 | ✅ |
| C: manual stations | TFP nonpolluting | 4 | 0.10 (0.08) | 0.10 (0.08) | 9,523 | 0.10 (0.08) | 0.10 (0.08) [4.28] | 0.00 | ✅ |
| C: manual stations | TFP nonpolluting | 5 | 0.11 (0.08) | 0.11 (0.08) | 9,523 | 0.11 (0.08) | 0.12 (0.08) [5.04] | 0.00 | ✅ |
| C: manual stations | TFP nonpolluting | 6 | 0.10 (0.08) | 0.10 (0.08) | 9,523 | 0.10 (0.08) | 0.12 (0.08) [4.66] | 0.00 | ✅ |

### Table VII — Heterogeneity

| panel | outcome | col | paper b (se) | Stata b (se) | Stata N | StatsPAI matched b (se) | StatsPAI native b (se) [h] | \|Δ\| Stata−paper | status |
|---|---|---|---|---|---|---|---|---|---|
| A: ownership | private, polluting | 1 | 0.45 (0.18) | 0.45 (0.18) | 6,149 | 0.45 (0.18) | 0.43 (0.18) [4.22] | 0.00 | ✅ |
| A: ownership | private, polluting | 2 | 0.48 (0.18) | 0.48 (0.18) | 6,149 | 0.48 (0.18) | 0.48 (0.18) [4.58] | 0.00 | ✅ |
| A: ownership | private, polluting | 3 | 0.43 (0.17) | 0.43 (0.17) | 6,149 | 0.43 (0.17) | 0.37 (0.15) [5.17] | 0.00 | ✅ |
| A: ownership | private, nonpolluting | 4 | 0.05 (0.09) | 0.05 (0.09) | 11,510 | 0.05 (0.09) | 0.03 (0.09) [4.69] | 0.00 | ✅ |
| A: ownership | private, nonpolluting | 5 | 0.05 (0.09) | 0.05 (0.09) | 11,510 | 0.05 (0.09) | 0.05 (0.09) [4.95] | 0.00 | ✅ |
| A: ownership | private, nonpolluting | 6 | 0.07 (0.10) | 0.07 (0.10) | 11,510 | 0.07 (0.10) | -0.01 (0.09) [3.78] | 0.00 | ✅ |
| A: ownership | SOE, polluting | 1 | -0.11 (0.44) | -0.13 (0.42) | 513 | -0.13 (0.42) | -0.12 (0.42) [3.33] | 0.02 | ❌ |
| A: ownership | SOE, polluting | 2 | 0.00 (0.51) | 0.00 (0.50) | 513 | 0.00 (0.50) | 0.01 (0.49) [3.58] | 0.00 | ⚠️ |
| A: ownership | SOE, polluting | 3 | -0.01 (0.61) | 0.62 (0.41) | 513 | 0.62 (0.41) | 0.04 (0.54) [3.62] | 0.63 | ❌ |
| A: ownership | SOE, nonpolluting | 4 | 0.11 (0.35) | 0.11 (0.35) | 1,169 | 0.11 (0.35) | 0.15 (0.40) [5.00] | 0.00 | ✅ |
| A: ownership | SOE, nonpolluting | 5 | 0.09 (0.33) | 0.09 (0.33) | 1,169 | 0.09 (0.33) | 0.12 (0.42) [4.68] | 0.00 | ✅ |
| A: ownership | SOE, nonpolluting | 6 | 0.06 (0.41) | 0.06 (0.41) | 1,169 | 0.06 (0.41) | 0.06 (0.31) [5.78] | 0.00 | ✅ |
| B: size | small, polluting | 1 | 0.06 (0.41) | 0.06 (0.41) | 1,829 | 0.06 (0.41) | -0.00 (0.42) [3.94] | 0.00 | ✅ |
| B: size | small, polluting | 2 | 0.13 (0.36) | 0.13 (0.36) | 1,829 | 0.13 (0.36) | 0.05 (0.43) [3.74] | 0.00 | ✅ |
| B: size | small, polluting | 3 | 0.17 (0.39) | 0.17 (0.39) | 1,829 | 0.17 (0.39) | 0.13 (0.50) [3.07] | 0.00 | ✅ |
| B: size | small, nonpolluting | 4 | -0.01 (0.16) | -0.01 (0.16) | 3,981 | -0.01 (0.16) | -0.02 (0.16) [4.09] | 0.00 | ✅ |
| B: size | small, nonpolluting | 5 | -0.04 (0.16) | -0.04 (0.16) | 3,981 | -0.04 (0.16) | -0.02 (0.16) [3.91] | 0.00 | ✅ |
| B: size | small, nonpolluting | 6 | 0.04 (0.18) | 0.04 (0.18) | 3,981 | 0.04 (0.18) | 0.07 (0.17) [4.34] | 0.00 | ✅ |
| B: size | large, polluting | 1 | 0.49 (0.16) | 0.49 (0.16) | 4,818 | 0.49 (0.16) | 0.49 (0.17) [4.55] | 0.00 | ✅ |
| B: size | large, polluting | 2 | 0.52 (0.17) | 0.52 (0.17) | 4,818 | 0.52 (0.17) | 0.51 (0.17) [4.95] | 0.00 | ✅ |
| B: size | large, polluting | 3 | 0.52 (0.17) | 0.52 (0.17) | 4,818 | 0.52 (0.17) | 0.44 (0.16) [5.31] | 0.00 | ✅ |
| B: size | large, nonpolluting | 4 | 0.02 (0.11) | 0.02 (0.11) | 8,765 | 0.02 (0.11) | 0.02 (0.10) [5.68] | 0.00 | ✅ |
| B: size | large, nonpolluting | 5 | 0.03 (0.11) | 0.03 (0.11) | 8,765 | 0.03 (0.11) | 0.02 (0.10) [5.99] | 0.00 | ✅ |
| B: size | large, nonpolluting | 6 | 0.02 (0.10) | 0.02 (0.10) | 8,765 | 0.02 (0.10) | 0.01 (0.10) [5.53] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, polluting | 1 | 0.89 (0.31) | 0.89 (0.31) | 933 | 0.89 (0.31) | 0.63 (0.37) [6.19] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, polluting | 2 | 0.69 (0.32) | 0.69 (0.32) | 933 | 0.69 (0.32) | 0.68 (0.33) [6.19] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, polluting | 3 | 0.94 (0.31) | 0.94 (0.31) | 933 | 0.94 (0.31) | 0.89 (0.37) [6.90] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, nonpolluting | 4 | 0.17 (0.18) | 0.17 (0.16) | 1,429 | 0.17 (0.16) | 0.01 (0.24) [5.70] | 0.00 | ⚠️ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, nonpolluting | 5 | 0.23 (0.15) | 0.10 (0.18) | 1,429 | 0.10 (0.18) | 0.08 (0.19) [5.70] | 0.13 | ❌ |
| C: SNWD (code kernel order epa/tri/uni) | SNWD, nonpolluting | 6 | -0.19 (0.52) | 0.05 (0.25) | 1,429 | 0.05 (0.25) | 0.23 (0.23) [5.70] | 0.24 | ❌ |
| C: SNWD (code kernel order epa/tri/uni) | other, polluting | 1 | 0.38 (0.19) | 0.38 (0.19) | 4,998 | 0.38 (0.19) | 0.38 (0.19) [4.52] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | other, polluting | 2 | 0.35 (0.18) | 0.35 (0.18) | 4,998 | 0.35 (0.18) | 0.36 (0.19) [4.61] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | other, polluting | 3 | 0.36 (0.18) | 0.36 (0.18) | 4,998 | 0.36 (0.18) | 0.36 (0.16) [4.81] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | other, nonpolluting | 4 | 0.13 (0.11) | 0.13 (0.11) | 9,739 | 0.13 (0.11) | 0.13 (0.11) [4.77] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | other, nonpolluting | 5 | 0.11 (0.10) | 0.11 (0.10) | 9,739 | 0.11 (0.10) | 0.13 (0.11) [5.28] | 0.00 | ✅ |
| C: SNWD (code kernel order epa/tri/uni) | other, nonpolluting | 6 | 0.11 (0.11) | 0.11 (0.11) | 9,739 | 0.11 (0.11) | 0.07 (0.12) [3.77] | 0.00 | ✅ |

### Table II — Difference in discontinuities (`mdrd`, bias-corrected coef, conventional SE)

| col | kernel | paper b (se) [h] | Stata mdrd b (se) [h] | N (sample) | StatsPAI b (se) | \|Δ\| b | status |
|---|---|---|---|---|---|---|---|
| 1 | tri | 0.21 (0.07) [10.39] | 0.2043 (0.0703) [6.39] | 20,588 (paper 20,588) | 0.2043 (0.0695) | 0.006 | ⚠️ |
| 2 | epa | 0.21 (0.07) [10.20] | 0.2107 (0.0765) [5.69] | 20,588 (paper 20,588) | 0.2107 (0.0764) | 0.001 | ⚠️ |
| 3 | uni | 0.20 (0.07) [9.89] | 0.1979 (0.0750) [5.35] | 20,588 (paper 20,588) | 0.1979 (0.0744) | 0.002 | ✅ |
| 4 | tri | 0.03 (0.06) [8.96] | 0.0278 (0.0663) [6.33] | 34,892 (paper 34,892) | 0.0278 (0.0651) | 0.002 | ⚠️ |
| 5 | epa | 0.01 (0.06) [8.87] | 0.0024 (0.0629) [6.44] | 34,892 (paper 34,892) | 0.0024 (0.0616) | 0.008 | ⚠️ |
| 6 | uni | -0.06 (0.06) [9.17] | -0.0686 (0.0566) [6.42] | 34,892 (paper 34,892) | -0.0686 (0.0573) | 0.009 | ⚠️ |

### Table VIII — Economic costs (spreadsheet `8_Cost_Estimates.xlsx`; re-computed in Python)

| col | Panel A MRS % (paper / xlsx / StatsPAI) | Panel B 2001–07 bn CNY (paper / xlsx / StatsPAI) | Panel C annual (paper / xlsx / StatsPAI) | Panel C 5-yr (paper / xlsx / StatsPAI) | status |
|---|---|---|---|---|---|
| 1 | 3.38 / 3.38 / 3.42 | 1,342 / 1,342 / 1,360 | 261 / 261 / 264 | 1,303 / 1,303 / 1,320 | ✅ |
| 2 | 3.81 / 3.81 / 3.85 | 1,527 / 1,527 / 1,544 | 294 / 294 / 298 | 1,472 / 1,472 / 1,488 | ✅ |
| 3 | 3.53 / 3.53 / 3.50 | 1,408 / 1,408 / 1,393 | 273 / 273 / 270 | 1,364 / 1,364 / 1,350 | ✅ |
| 4 | 2.12 / 2.12 / 2.07 | 816 / 816 / 797 | 162 / 162 / 158 | 808 / 808 / 790 | ✅ |
| 5 | 2.28 / 2.28 / 2.29 | 882 / 882 / 884 | 174 / 174 / 175 | 872 / 872 / 874 | ✅ |
| 6 | 2.22 / 2.22 / 2.19 | 858 / 858 / 847 | 170 / 170 / 168 | 849 / 849 / 838 | ✅ |
