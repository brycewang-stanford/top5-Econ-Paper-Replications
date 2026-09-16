# StatsPAI re-implementation

Python 3.13 · statspai 1.28.0 · pyfixest 0.50.1 (used through `sp.feols`) · R 4 + ShiftShareSE 1.1.0 (reference only).

| script | what it does | runtime |
|---|---|---|
| `common.py` | paths, control sets, weighted 2SLS/OLS wrappers with the exact Stata SE conventions, Stata percentile rules, Stata-log parser | — |
| `paper_values.py` | every published coefficient/SE/R² transcribed from the AER PDF | — |
| `replicate_statspai.py` | Tables 1–10, Figures 1–2, Appendix Tables 1, 3, 4, 5 → `Results/statspai/estimates_statspai.csv`, `figure1.png`, `figure2.png`, `native_iv_crosscheck.csv` | ~7 s |
| `make_comparison.py` | parses the original-code Stata logs (7 significant digits) and writes `Results/comparison.md` | ~2 s |
| `akm_reference.R` | AKM/AKM0 reference values from the AKM authors' R package → `Results/statspai/akm_reference_R.csv` | ~5 s |
| `modern_extensions.py` | effective F, Anderson–Rubin (Wald and score form), WRE wild cluster bootstrap, AKM SEs, BHJ shock-level IV, GPSS Rotemberg weights → `modern_extensions.{csv,md,png}`, `rotemberg_top10_weighted.csv`, `iv_diag_c*.csv` | ~4 min |

Order: run `Program/run_original.do` (Stata) and `Program/modern_reference_stata.do` first (they create the logs and reference CSV used for comparison), then

```bash
cd Program/statspai
/usr/local/bin/python3.13 replicate_statspai.py
/usr/local/bin/python3.13 make_comparison.py
/usr/local/bin/Rscript akm_reference.R
/usr/local/bin/python3.13 modern_extensions.py
```

## Estimator mapping

| Stata (author) | StatsPAI |
|---|---|
| `ivregress 2sls y (x=z) ctrl [aw=timepwt48], cluster(statefip)` | `sp.feols("y ~ ctrl \| x ~ z", weights="timepwt48", vcov={"CRV1":"statefip"}, ssc=pf.ssc(adj=False, cluster_adj=False))` |
| `regress y x ctrl [aw=…], cluster(statefip)` | `sp.feols("y ~ x + ctrl", weights=…, vcov={"CRV1":"statefip"})` (default ssc) |
| first stage as published | `sp.feols("x ~ z + ctrl", weights=…, vcov="HC1")` (the published first-stage SEs are HC1, not clustered) |
| `summarize, detail [aw]` percentiles, `_pctile` | `common.stata_wpctile`, `common.stata_pctile` |

`sp.iv` (StatsPAI's native k-class IV) has no weights argument: it accepts `weights=` and **silently ignores it**
(T3 c6: −0.3028 instead of −0.5964). On √w-transformed data (`y·√w ~ (x·√w ~ z·√w) + √w + ctrl·√w − 1`) it reproduces the
point estimates exactly, but its CRV1 factor (G/(G−1)(N−1)/(N−K)) cannot be switched off, so SEs are 1.1–1.6 % larger than
`ivregress`. See `Results/statspai/native_iv_crosscheck.csv` and `Materials/论文模型解读与StatsPAI复现分析.md` §5.
