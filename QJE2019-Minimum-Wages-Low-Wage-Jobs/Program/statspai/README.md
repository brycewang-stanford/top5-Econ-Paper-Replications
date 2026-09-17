# StatsPAI re-implementation

Python 3.13 + `statspai` 1.28.0 (`sp.hdfe_ols` for every reghdfe call; `sp.stacked_did`,
`sp.callaway_santanna`, `sp.sun_abraham`, `sp.did_imputation`, `sp.honest_did` for the extensions).
All scripts start from the authors' shipped intermediate datasets in `Data/data/` (no CPS microdata rebuild).

| Script | Reproduces | Author do-file(s) | Outputs (`Results/statspai/`) |
|---|---|---|---|
| `bunching.py` | shared machinery: Stata-semantics helpers (float32 comparisons, missing = +∞, `&` vs `\|` precedence), panel lead/lag operator, constants E / B / EWB / %ΔMW / wage multiplier, placebo bins, `sp.hdfe_ols` wrapper, delta-method post-estimation | `create_programs.do` | — |
| `replicate_table1.py` | Table 1 cols 1–6, Figure 3 path, Table 4 "Overall" row | `Table1_for_QJE.do`, `wage_estimate_base.do` | `table1_cols1_6.csv`, `figure3_eventtime.csv`, `table4_overall.csv`, `constants_overall.json` |
| `replicate_table1_col7.py` | Table 1 col 7 (state-quarter "simpler method") | `Table1_last_column_for_QJE.do` | `table1_col7.csv` |
| `replicate_figure2.py` | Figure 2 (bins −4…17+) | `Figure2_for_QJE.do` | `figure2_bins.csv/png` |
| `replicate_table2_3.py` | Table 2 (5 demographic + 3 Card–Krueger groups), Table 3 (8 sectors, 1992–2016), Table 4 group rows | `Table2_for_QJE.do`, `CK_groups_regressions_longfigure_QJE.do`, `Table3_for_QJE.do`, `wage_estimate_*_groups.do` | `table2_demog.csv`, `table2_ck.csv`, `table3.csv` |
| `make_figures.py` | Figure 3 plot with author-.ster overlay | — | `figure3_eventtime.png` |
| `modern_extensions.py` | **extensions**: stacked TWFE vs `stacked_did` / CS / SA / BJS on event×state×quarter bunching outcomes, HonestDiD | (data from `create_stacked_events.do`) | `ext_*.csv`, `ext_eventstudy_compare.png` |

Run order (each regression on the 847k-row panel takes 5–30 min; coefficients are cached in
`Results/statspai/estimates/` and `--reuse` skips finished ones):

```bash
cd Program/statspai
python3.13 replicate_table1.py            # writes constants_overall.json needed next
python3.13 replicate_table1_col7.py
python3.13 replicate_figure2.py
python3.13 replicate_table2_3.py
python3.13 make_figures.py
python3.13 modern_extensions.py
```

Why one regression per Figure 2 instead of three: the Stata do-file estimates three
reghdfe models, each absorbing the other coefficient blocks as linear controls
(`i.one#c.x`). By Frisch–Waugh–Lovell the coefficients *and* cluster-robust vcov blocks
are identical to a single regression with all blocks as regressors.
