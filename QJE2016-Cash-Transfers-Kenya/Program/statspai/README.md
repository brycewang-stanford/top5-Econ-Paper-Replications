# StatsPAI re-implementation

Python 3.13 + `statspai` 1.28.0 (with `pyreadstat`, `pyfixest` as used internally by `sp.feols`).
All scripts read the author's final file `Data/UCT_FINAL_CLEAN.dta` and write to `Results/statspai/`.

| Script | Replicates | Runtime (8-core Mac, shared) |
|---|---|---|
| `uct_common.py` | helpers: sample flags, `areg`→`sp.feols(... \| village, vcov={"CRV1": "surveyid"})`, suest-equivalent Wald test, port of `stepdown.ado` | – |
| `replicate_main_tables.py [--iters 10000]` | Tables I, II (with FWER p), IV, V, VI, A.1 + `sp.bonferroni/holm/benjamini_hochberg` and `sp.romano_wolf` on Table II + coefficient plot | ~5 min |
| `replicate_spillover_lee.py` | Table III (cols 1–10), pre-erratum weighted psych row, OA §8.2 Lee bounds (exact `leebounds.ado` port + `sp.lee_bounds`) | ~15 s |
| `extensions_modern.py` | extensions: within-village randomization inference, `sp.ri_test`, `sp.wild_cluster_bootstrap`, `sp.causal_forest`, `sp.qreg` quantile effects (OA §14 figure), `sp.balance_diagnostics` | ~9 min |
| `build_comparison.py` | `Results/comparison.md` (paper vs Stata vs StatsPAI, every cell) + PDF verification | ~5 s |

Run everything from the project root:

```bash
cd Program/statspai
/usr/local/bin/python3.13 replicate_main_tables.py --iters 10000
/usr/local/bin/python3.13 replicate_spillover_lee.py
/usr/local/bin/python3.13 extensions_modern.py
/usr/local/bin/python3.13 build_comparison.py     # needs Results/Tables from the Stata run
```

## Specification mapping

| Stata (author) | StatsPAI / Python |
|---|---|
| `areg y x controls, absorb(village) cluster(surveyid)` | `sp.feols("y ~ x + controls \| village", vcov={"CRV1": "surveyid"})` — identical b, SE (same small-sample factor), p |
| `reg y spillover [controls], cluster(village)` | `sp.feols(..., vcov={"CRV1": "village"})` |
| `reg y spillover, r` | `sp.regress(..., robust="hc1")` |
| `suest m1 … mK, cluster(c)` + `test x` | `uct_common.suest_wald` (stacked OLS influence functions, cluster sums, G/(G-1)) — StatsPAI gap |
| `stepdown reg (y1 … yK) treat …, iter(10000)` (authors' ado) | `uct_common.stepdown_perm` (vectorised port; same algorithm, different RNG stream) — StatsPAI gap |
| `leebounds y t [, select() vce(bootstrap, reps(100))]` | `replicate_spillover_lee.leebounds_port` (exact, incl. macro-precision quirk); `sp.lee_bounds` for comparison |
| `sqreg y treat controls, q(.1 … .9)` | `sp.qreg(data, formula, quantile=q)` (point estimates; analytic not bootstrap SE) |

Results: see `../../Results/comparison.md`. StatsPAI bugs and friction are documented in
`../../Materials/论文模型解读与StatsPAI复现分析.md` §5.
