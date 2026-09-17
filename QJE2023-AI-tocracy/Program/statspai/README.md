# StatsPAI re-implementation

Python 3.13 + `statspai` 1.28.0 (pyfixest backend for `sp.feols`). Run from the project root:

```bash
# 1) once: build the regression-ready panels (runs a hooked copy of the author's Analysis.do, ~25 min)
Program/statspai/run_export.sh "10 11 12 8 9 2 14"
# 2) everything (tables, figures, extensions, Results/comparison.md)
/usr/local/bin/python3.13 Program/statspai/replicate_statspai.py            # add --skip-ext / --skip-lasso to shorten
```

| Script | Exhibit | StatsPAI estimator | Match to Stata |
|---|---|---|---|
| `make_export_do.py`, `run_export.sh` | — | generates `export_analysis_data.do` = `Analysis.do` + `save` hooks right before each estimation command (30 hooks); LASSO IV calls replaced by a trivial `regress` to save hours | — |
| `common.py` | — | `hdfe()` wrapper around `sp.feols` that reproduces Stata's `reghdfe`/`ivreghdfe ..., small` finite-sample factors (singletons, FE nested in cluster, reghdfe constant); `stata_keep_order()` mimics Stata's sequential collinearity omission | — |
| `t2_t3_unrest_to_procurement.py` | Tables II–III | Panel A/C OLS: `sp.feols` HDFE + CRV1; Panel B/D cross-fit PO-LASSO-IV: **approximation** (`sp.demean` FWL + `sp.lasso_iv(penalty="cv", cluster=...)`; `sp.rlasso_iv` shown as diagnostic) | OLS exact; LASSO IV approximate |
| `t4_t5_ai_and_unrest.py` | Tables IV–V | first stage + second stage `sp.feols`; whole variable construction (conducive-weather prediction, demeaning, standardisation, imputation) rebuilt in Python from pre-first-stage panels | exact (4 dp) |
| `t6_t7_firm_eventstudy.py` | Tables VI–VII, Figure V/VI profiles | `sp.feols` HDFE event study with explicit Stata-order dummies; author's `addQuarterInter` (b sum, variance sum without covariance) | exact (3 dp) |
| `t8_exports.py` | Table VIII | `sp.feols` WLS (aweights) + HC with ivreghdfe small factor | exact |
| `t9_spillovers.py` | Table IX | Panel A: xtevent 1.0.0 design (continuous policy, endpoint bins) built in Python + `sp.feols`, areg-style CRV1; Panels B/C `sp.feols` | exact |
| `figures.py` | Figure II (A.12, A.13), Figure V | `sp.feols` | exact |
| `extensions_modern.py` | extensions E1–E5 | flow-vs-stock check, `sp.callaway_santanna`, `sp.did_imputation`, `sp.sun_abraham`, `sp.honest_did`, `sp.pretrends_power`, `sp.wild_cluster_bootstrap`, `sp.anderson_rubin_ci` + cluster-robust AR by test inversion | extensions (not replication) |
| `build_comparison.py` | `Results/comparison.md` | paper vs Stata re-run vs StatsPAI + cell-by-cell diff of every shipped `.tex` | — |

Outputs: `Results/statspai/*.csv|png`. StatsPAI bugs / friction found here are documented (with minimal repros) in `Materials/论文模型解读与StatsPAI复现分析.md`.
