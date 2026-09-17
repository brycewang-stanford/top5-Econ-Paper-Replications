# StatsPAI re-implementation

Python re-implementation of Bai, Jia & Yang (2023, QJE) with **StatsPAI 1.28.0** (`import statspai as sp`),
starting from the same `Data/*.dta` files the Stata code reads. Variable construction (`*_Post`, `*Xperiod`,
`prefidXyear`, surname sub-sample, year-dummy interactions) is transcribed from the author do-files.

| Script | What | Runtime* |
|---|---|---:|
| `common.py` | data prep, `ols()` (reghdfe replica), `iv()` (ivreghdfe replica), outreg2-text parser, comparison helpers | – |
| `replicate_tables.py` | Tables 1–6, all columns → `Results/statspai/table*.csv`, `main_tables_long.csv`, `statspai_hdfe_ols_issue.csv` | ~1.5 min |
| `replicate_figures.py` | Figures 3–8 (package numbering; QJE numbering = +1) → `figure*.png`, estimate CSVs, `figures_check.csv`, `tableC7_eg_by_decade.csv` | ~1 min |
| `extensions.py` | modern-methods extensions E1–E6 (NOT replication) → `ext_E*.csv/json` | ~5 min |

\* 8-core Mac, Python 3.13.

```bash
cd Program/statspai
/usr/local/bin/python3.13 replicate_tables.py
/usr/local/bin/python3.13 replicate_figures.py   # E6 in extensions.py can reuse figure6_estimates.csv
/usr/local/bin/python3.13 extensions.py          # or: extensions.py e3 e4   (run selected parts)
```

## Estimator mapping

| Stata (author) | StatsPAI used here | SE matching |
|---|---|---|
| `reghdfe y x, absorb(fe...) cluster(c)` (one-way) | `sp.feols("y ~ x | fe", vcov={"CRV1": c}, ssc=pf.ssc(adj=False, cluster_adj=False))` on the singleton-free sample, × `sqrt(G/(G-1)·(N-1)/(N-K-1-df_a))` | exact (df_a = rank of FE dummies not nested in the cluster − 1) |
| `reghdfe ..., cluster(c1 c2)` | `sp.hdfe_ols("y ~ x | fe", cluster=[c1, c2])` | exact |
| `ivreghdfe y (d = z) x, absorb(fe) cluster(c)` | `sp.feols("y ~ x | fe | d ~ z", ...)` × `sqrt(G/(G-1)·(N-1)/(N-K-df_a))` | exact vs. current ivreghdfe; the authors' older ivreghdfe counted one extra absorbed dof (3rd-decimal SE differences) |
| `parmest` + `twoway rcap` | coefficient table + matplotlib | CIs use t(G−1) like parmest |
| `reg2hdfespatial` (Conley) | `sp.conley(sp.regress(...demeaned...), time=, lag_cutoff=, unit=, kernel="bartlett")` | extension E1 (see comparison.md) |

Why not `sp.hdfe_ols` everywhere: `sp.hdfe_ols` 1.28.0 (i) does not detect regressors made collinear by the absorbed FEs —
in the Huai columns of Table 4, `lncntypop_Post`/`lncntyarea_Post` are (up to float32 noise) spanned by prefecture×year FEs;
Stata and pyfixest drop them, `hdfe_ols` keeps them (coefficients ±4.8e5) and the coefficients of interest move
(0.0196 vs 0.0214); with exact collinearity it raises `LinAlgError` — and (ii) over-counts absorbed dof when `year` is
nested in `prefidXyear` (SEs ≈0.8% too large).
See `Results/statspai/statspai_hdfe_ols_issue.csv` and the Chinese analysis note, §StatsPAI bugs.
