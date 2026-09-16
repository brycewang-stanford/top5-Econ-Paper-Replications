# StatsPAI re-implementation

All scripts run with `/usr/local/bin/python3.13` (statspai 1.28.0, pyfixest backend) from any directory; paths are resolved relative to the project root. They read the original `.dta` files in `Data/`.

| Script | What it does | Output (`Results/statspai/`) | Runtime |
|---|---|---|---|
| `replicate_statspai.py` | Every column of Tables III–XI (Table X cols 1–3) with `sp.feols` (clustered / HC1 / absorbed FEs) and `sp.bootstrap` (cluster bootstrap for the `bs, reps(500)` columns); Figures I–IX | `statspai_main_tables.csv/.md`, `Figure_*.png`, `Figure_*_means.csv`, `Figure_9_coefs.csv`, `statspai_figures_summary.csv` | ~100 s |
| `extensions_statspai.py` | Modern-methods extensions (not in the paper): Conley spatial SEs (E1), Oster δ* (E2), sensemakr robustness values (E3), E-values (E4), specification curves (E5), Romano–Wolf FWER (E6) | `ext_E1_*.csv` … `ext_E6_*.csv`, `ext_E5_spec_curve_*.png`, `extensions_api_log.md` | ~25 s |
| `build_comparison.py` | Paper vs Stata (6-decimal dump from `Program/run_precise.do`) vs StatsPAI, coefficient by coefficient; appends `comparison_notes.md` | `Results/comparison.md` | <1 s |

Order: `Program/run_original.do` → `Program/run_precise.do` (Stata) → `replicate_statspai.py` → `extensions_statspai.py` → `build_comparison.py`.

## Stata → StatsPAI mapping

| Author's Stata | StatsPAI |
|---|---|
| `reg y x, cluster(cluster)` | `sp.feols("y ~ x", data, vcov={"CRV1": "cluster"})` |
| `reg y x, ro` | `sp.feols("y ~ x", data, vcov="hetero")` (HC1) |
| `reg y x cont_*` / `i.isonum` / `dum_country*` / `i.wave` / `i.age` / `i.year` / `i.lang` | absorbed: `"y ~ x | cont + ..."` (identical slope and SE; see note on all-zero `cont_*` rows) |
| `areg y x, a(match) cluster(cluster)` | `sp.feols("y ~ x | match", vcov={"CRV1": "cluster"})` |
| `bs, reps(500): reg y x, cluster(cluster)` | point estimate from `sp.feols`; SE = s.d. of `sp.bootstrap(data, stat, n_boot=500, cluster="cluster")` |
| `egen s_x = std(x)` after `keep if geodist<=500` | pandas z-score on the kept sample |
| `pca ...; predict` (Fig. VIII) | first eigenvector of the correlation matrix (numpy) |
| `binscatter` (Figs. II–III) | quantile-bin means + OLS line (matplotlib) |

Note: in `EAShort.dta` three Polynesian societies (Manihikians, Futunans, Uveans) have all seven `cont_*` dummies equal to 0. Stata's `reg ... cont_*` keeps them as an extra base group (no dummy is collinear with the constant), so the absorbed-FE version codes them as an eighth category.
