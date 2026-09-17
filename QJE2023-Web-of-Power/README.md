# QJE 2023 — Web of Power

> Bai, Jia & Yang (2023), *Quarterly Journal of Economics* 138(2): 1067–1108.
> **"Web of Power: How Elite Networks Shaped War and Politics in China"** — DOI [10.1093/qje/qjac041](https://doi.org/10.1093/qje/qjac041)

A reading-and-replication workspace for the above paper, built on the official replication package
(Harvard Dataverse **doi:[10.7910/DVN/0H4HG2](https://doi.org/10.7910/DVN/0H4HG2)**, CC0), plus a full re-implementation of
the main-text analysis in Python with **[StatsPAI](https://github.com/brycewang-stanford/StatsPAI) 1.28.0** and a set of
modern-DID extensions.

**Design in one line:** county-year DID with a *continuous* treatment — pre-war elite connections to Zeng Guofan × Post-1853
(Zeng takes command of the Hunan Army) — for soldier deaths in 75 Hunan counties (1850–64), then DD/DDD with all 1,646
Chinese counties (1820–1910) for national-level offices; year-by-year event studies, placebo networks, IV/over-id, and an
Ellison–Glaeser power-localisation counterfactual.

## Layout

```text
.
├── Data/                     原始数据 — 9 Stata datasets from Dataverse (original .dta, 94 MB; git-ignored) + README.md (re-download commands)
├── Program/                  原始代码 — author's do-files (unmodified except backslash→slash path fixes)
│   ├── All_in_One.do         author's master (Windows `cd D:\...`; not used directly)
│   ├── Table_*.do Figure_*.do Appendix_*.do
│   ├── run_original.do       our wrapper: runs all 31 do-files in All_in_One order, logs rc + seconds
│   ├── ado/                  project-local reg2hdfespatial + ols_spatial_HAC (Fetzer 2015 original; see SOURCE.md)
│   └── statspai/             StatsPAI re-implementation (common.py, replicate_tables.py, replicate_figures.py,
│                             extensions.py, make_comparison.py, README.md)
├── Results/
│   ├── Tables/  Figures/     output of the author's code (our Stata 18 rerun)
│   ├── run_original.log      full Stata log; run_original_steps.csv (rc, seconds per do-file)
│   ├── author_outputs/       the authors' own outputs shipped in the package (All_in_One.log, .txt/.doc/.png/.gph, parmest .dta)
│   ├── statspai/             StatsPAI outputs (csv / png / json)
│   └── comparison.md         paper vs original Stata vs StatsPAI, number by number
└── Materials/                其它材料
    ├── NBER-w28667-Web of Power (working paper version).pdf   (Apr 2021, rev. Aug 2022; the QJE PDF is paywalled)
    ├── Package_README.pdf / .docx                             (official codebook)
    ├── I4R-DP115-Comment-on-Bai-Jia-Yang-2023.pdf             (Institute for Replication comment, 2024)
    ├── Web of Power (QJE 2023).md                             (Chinese reading note)
    └── 论文模型解读与StatsPAI复现分析.md                          (Chinese model dissection + StatsPAI replication notes)
```

## How to run

1. Download the data into `Data/` (commands in [Data/README.md](Data/README.md)).
2. **Original code** (Stata 16+; tested on Stata 18 MP): install SSC packages `reghdfe ftools ivreghdfe ivreg2 ranktest
   outreg2 parmest tabout reg2hdfe hdfe tmpdir`, edit the `root` local in `Program/run_original.do`, then
   `stata-mp -b do Program/run_original.do` (≈11 min). To run a subset: `global ONLY Table_2 Figure_4` before `do`.
3. **StatsPAI** (Python 3.13, `pip install statspai==1.28.0 pyfixest matplotlib tabulate`):
   ```bash
   cd Program/statspai
   python3.13 replicate_tables.py && python3.13 replicate_figures.py
   python3.13 extensions.py          # E1–E6, ~30 min (wild bootstrap + R HonestDiD)
   python3.13 make_comparison.py     # rebuilds Results/comparison.md
   ```
   E3 additionally calls R (`HonestDiD` package) through `Rscript`.

### Edits to the author code

| File(s) | Edit | Why |
|---|---|---|
| all 32 `.do` files | `\` → `/` in paths (`Data\x.dta` → `Data/x.dta`, `Results\\` → `Results/`) | macOS/Linux Stata does not translate Windows separators |
| none else | — | the wrapper `run_original.do` handles `cd`, `adopath`, `version 16`, and moves outputs to `Results/Tables` / `Results/Figures` |

`Program/ado/reg2hdfespatial.ado` must be the **original 2015 release** (Bartlett spatial kernel hard-wired); the newer
GitHub version defaults to a uniform kernel and does not reproduce Table B.1.III (details in `Program/ado/SOURCE.md`).

## Replication status

| Exhibit | Original code (Stata 18) | StatsPAI 1.28.0 |
|---|---|---|
| Table 1 Summary statistics | ✅ | ✅ (paper typo: 4.48 vs data 4.458) |
| Table 2 DD, soldier deaths (10 cols) | ✅ identical | ✅ 10/10 coef·SE·N |
| Table 3 Types of links, surname panel (7 cols) | ⚠️ N 1,110 vs printed 1,125 (singletons); col 6 0.056 vs printed 0.057 | ⚠️ = Stata to 3 d.p. |
| Table 4 Placebo networks, IV, Huai (11 cols) | ⚠️ 3 IV SEs ±0.001 (ivreghdfe dof version) | ⚠️ = current Stata to 3 d.p. |
| Table 5 DD/DDD, national offices (6 cols) | ✅ identical | ✅ |
| Table 6 Role of soldier deaths, OLS + IV (6 cols) | ✅ identical | ✅ |
| Figures 3–8 | ✅ | ✅ (event-study coefs/SEs to 1e-8, EG index to 1e-7) |
| Appendix A3, A5, B1.I–IV, B2, B4, B5.I–II, B6.I–II, C1–C7 (19 do-files) | ✅ 19/19 identical to author outputs | not re-implemented (extensions cover B1.III Conley) |

31/31 do-files run with rc = 0 (≈674 s). Nothing in the package is restricted; the maps (Figures 1–2) are not part of it.
Full number-by-number comparison: [Results/comparison.md](Results/comparison.md).

**StatsPAI issues found** (details in the analysis note): `sp.hdfe_ols` keeps FE-collinear regressors (silently wrong coefficients) and
over-counts absorbed dof with nested FEs; `hdfe_ols(wild=True)` does not re-absorb FEs in bootstrap draws (p-values too small);
`sp.anderson_rubin_test(absorb=, cluster=)` disagrees with the reduced form and computes tF from the non-robust F; no ivreghdfe-compatible small-sample option for HDFE-IV; `honest_did`/`breakdown_m` cannot take a
user-supplied (β, Σ) from a continuous-treatment event study, so its intervals ignore covariances; `sp.conley` needs manual
FE demeaning (no FE-aware Conley in `hdfe_ols`, whose `vce="conley"` is cross-section only).

## Reading notes

| File | Audience | Content |
|---|---|---|
| [Web of Power (QJE 2023).md](<Materials/Web of Power (QJE 2023).md>) | anyone curious about the paper | question, data, identification, core equations, findings tagged to tables/figures, modern-methods reassessment |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | researchers reproducing it | equation-by-equation dissection, StatsPAI mapping, SE conventions, bugs, extension results, improvement suggestions |
| [Package_README.pdf](Materials/Package_README.pdf) | anyone running the package | official codebook: datasets, variables, do-file ↔ exhibit map |
| [I4R-DP115 comment](Materials/I4R-DP115-Comment-on-Bai-Jia-Yang-2023.pdf) | referees / replicators | independent reproduction + robustness (Poisson, FE structure, spatial) |

## License

- **Reading notes and StatsPAI scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper** is © the authors / Oxford University Press; the NBER working-paper PDF is included for scholarly reference only.
- **The replication package** (data, do-files, outputs) is by the paper's authors, published on Harvard Dataverse under CC0 1.0.
- `Program/ado/reg2hdfespatial.ado`, `ols_spatial_HAC.ado` are by Thiemo Fetzer and Solomon Hsiang (see file headers).
- The I4R discussion paper is © its authors (EconStor terms of use).
