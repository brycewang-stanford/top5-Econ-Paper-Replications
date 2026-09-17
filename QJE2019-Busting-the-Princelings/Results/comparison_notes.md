## Notes on differences and implementation choices

**Original Stata code.** All 13 steps of `Tables&Figures.do` ran with rc = 0 under Stata 18 MP, reghdfe 6.13.1 and current estout. Every regression cell in Tables V, VI and VIII–XII matches the published table at 3 decimals. The N and adjusted R² reported in the tables also match. One edit was needed: Table 11's `esttab … drop(_cons)` aborts with r(111) because all 12 models are `oprobit`, so the wrapper removes that token (see README). Figures IV–VII are reproduced as graphs. The paper prints no coefficients for Figures V and VI, so the StatsPAI event studies are compared with the Stata log instead.

**StatsPAI — linear models (Tables V, VI, X, XI; Figures V, VI).** Every cell is exact.
- `sp.feols(..., vcov={"CRV1": "provid + firmid"})` reproduces reghdfe's two-way clustering (CGM), its nested-FE degrees of freedom and `keepsingletons`.
- Table XI (11.5M obs) uses `sp.hdfe_ols(..., cluster=["provid", "firmid"], drop_singletons=False)`, because `sp.feols` needs more than 12 GB already at 5.7M obs.

**StatsPAI — ordered probits (Tables VIII, IX, XII).**
- `sp.oprobit` needs the substantive regressors standardized (and back-transformed); otherwise its BFGS stops early.
- The ⚠️ cells in Table VIII are SEs that differ by ≤ 0.001, a consequence of the finite-difference Hessian.
- The prefecture-level models (about 300 dummies) take 20–50 minutes each in `sp.oprobit`, and hours on a loaded machine.
- `Program/statspai/oprobit_fast.py`, an analytic-score Newton ordered probit **that is not StatsPAI**, cross-checks all three tables in under 1 second per model. Its tallies are below.

**Do-file quirks that must be reproduced to match the paper.**
1. Table XII columns 10 and 12 (ALP × central inspection) enter `post2012`, not `inspection`, as the main effect.
2. Table XII column 11 omits `ties`.
3. Table XI's `xi` is Stata's abbreviation of `xi_assign`.
4. Promotion SEs are the default OIM SEs, although the table notes say "robust".
5. Table IX uses prefecture FE, although the table says "Province FE".
6. Table VI includes no industry FE, although the notes list one.
7. Figure V/VI regressions omit the princeling main effect and the controls; their base period is 2004–05.
