## Figures

The paper prints no numbers for its figures, so the check is: does the author's code run, does StatsPAI reproduce the same underlying statistics, and do the sample sizes and patterns match what the text says.

| Figure | Content | Original Stata (`Results/Figures/`) | StatsPAI (`Results/statspai/`) | Check against paper | Status |
|---|---|---|---|---|---|
| I | Histogram of kinship tightness | no code in package | `Figure_1_kinship_histogram.png` | 1,246 EA societies, index 0–1 in steps of 1/8 | ✅ (StatsPAI only) |
| II | Binscatter: kinship vs hunting-gathering | `Hunter_kinship.pdf` rc 0 | `Figures_2_3_binscatter.png`; slope −0.45 | negative, as in text | ✅ |
| III | Binscatter: kinship vs sickle-cell distance (15 bins) | `Sickle_kinship.pdf` rc 0 | same png; slope −0.058 = Table III col 6 | ✅ |
| IV | EA moral systems, tight (≥ .25) vs loose | `Overview_ea.pdf` rc 0 | `Figure_4_overview_ea.png`, `Figure_4_means.csv` | tight: more in-group favoritism, loyalty, purity, village institutions; loose: moralizing gods, higher-level hierarchy | ✅ (bootstrap SEs for 2 bars are MC draws) |
| V | Contemporary moral systems by tight/loose | `Overview_country.pdf` rc 0 | `Figure_5_overview_country.png`, `Figure_5_means.csv` | same sign pattern on all 6 outcomes | ✅ |
| VI | Country scatter: trust out-in vs kinship | `Trust_kinship.pdf` rc 0 | slope 1.461, N = 72 = Table VI col 1 | ✅ |
| VII | US migrants: disgust by country of origin (≥ 20 resp.) | `Disgust_kinship.pdf` rc 0 | slope 0.388, 88 origin countries | text: 13,723 US migrants; data has 13,751 US respondents (all with origin kinship) | ⚠️ 28-person gap between text and posted data; figure itself unaffected |
| VIII | Morality kernel (PCA of 5 moral variables) | `Kernel_kinship.pdf` rc 0 | slope 3.83, N = 33 complete-case countries | ✅ |
| IX | Kinship coefficient on log pop. density / urbanization, 1500–1950 | `Pd.pdf`, `Urbfrac.pdf` rc 0 | `Figure_9_development.png`, `Figure_9_coefs.csv` | N = 123 countries (text: 123); coefficients ≈ 0 before 1700 and increasingly negative after 1800 | ✅ |

## Exhibits that cannot be replicated

| Exhibit | Reason |
|---|---|
| Table X, cols 4–6 (GPS migrants) | Individual GPS data with country of birth are restricted under the Gallup World Poll license; the author's code comments these regressions out. Published: 0.31 (0.11), 0.29 (0.11), 0.28 (0.10); N = 2,289 / 2,279 / 2,266. |
| Tables I, II | Conceptual tables (overview of hypotheses; prisoner's-dilemma payoffs): no data. |
| Online Appendix tables/figures | Not in the replication package. |
| Kinship index construction | `Kinship_index/Generate_kinship_index.do` needs the raw Ethnographic Atlas (v8, v11, v15, v43), which is not included; its output `kinship_score` is shipped in every dataset. We re-derived it from the shipped components: see `Materials/论文模型解读与StatsPAI复现分析.md`. |

## Extensions (not replication) — headline numbers

Full output: `Results/statspai/ext_E*.csv`. Details in `Materials/论文模型解读与StatsPAI复现分析.md` §5.

* **E1 Conley spatial SEs (Table IV).** Language-subfamily clustered SEs are close to Conley SEs with a 500 km cut-off; at 2000 km they grow up to ~2.5× (village institutions col 13: 0.12 → 0.31). Still, every non-bootstrap column except col 10 (hierarchy above local, clustered p ≈ .05) keeps |t| > 2 at both 1000 km and 2000 km.
* **E2 Oster δ\*** (R²max = 1.3·R²): village institutions 21.8, trust out-in 13.5 (robust); revenge punishment 1.30; sex taboo 0.55 and belief in hell 0.24 (fragile, |δ\*| < 1). For moralizing god and trust in family the coefficient moves *away* from zero when controls are added (δ\* < 0).
* **E3 sensemakr robustness value RV_q**: 0.13–0.42; the partial R² needed to push the estimate to insignificance (RV_q,α) is 0 for belief in hell and revenge punishment (already p > .05 with continent FE).
* **E5 specification curves** (8 control sets; EA outcomes × {cluster, HC1} SEs): moralizing god, village institutions, sex taboo, trust out-in and revenge punishment keep their sign in every specification. Hierarchy above local is positive only without the hunting-gathering control. Belief in hell turns negative (insignificant) only in the richest set (log GDP + Catholic/Muslim shares + continent FE, N = 75); communal-vs-universal values turns negative whenever log GDP is added (N = 61) and is never significant at 5% in this common sample.
* **E6 Romano–Wolf**: EA family (4 outcomes, N = 293 common sample) — all adjusted p < .01 except hierarchy above local (0.07). The country family collapses to N = 15 because `sp.romano_wolf` drops rows missing *any* outcome — not informative (see StatsPAI friction log).
