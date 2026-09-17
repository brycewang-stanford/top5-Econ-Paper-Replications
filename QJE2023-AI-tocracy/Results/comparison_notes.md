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
