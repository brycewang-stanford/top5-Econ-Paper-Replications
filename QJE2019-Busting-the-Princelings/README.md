# QJE 2019 — Busting the "Princelings"

> Chen & Kung (2019), *Quarterly Journal of Economics* 134(1): 185–226. DOI [10.1093/qje/qjy027](https://doi.org/10.1093/qje/qjy027)
> **"Busting the 'Princelings': The Campaign Against Corruption in China's Primary Land Market"**

A reading-and-replication workspace for the paper above. It is built on the official replication package (Harvard Dataverse **doi:[10.7910/DVN/XW6OJT](https://doi.org/10.7910/DVN/XW6OJT)**, CC0) and adds a StatsPAI re-implementation with modern-DID extensions.

## Layout

```text
.
├── Data/                     原始数据 — Dataverse originals (.dta, ~1.07 GB; local only, not tracked by git)
│   └── README.md             provenance, file ids, exact curl re-download commands
├── Program/                  原始代码
│   ├── Tables&Figures.do     the author's single do-file (unmodified)
│   ├── run_original.do       wrapper: splits the do-file per exhibit, path fixes, logs rc + seconds
│   └── statspai/             StatsPAI re-implementation (see its README)
│       ├── replicate_statspai.py   end-to-end runner
│       ├── rep_price.py  rep_firm.py  rep_promotion.py  rep_descriptive.py
│       ├── modern_did.py     extensions: Bacon / CS / Sun-Abraham / BJS / HonestDiD / power / WCB
│       ├── paper_values.py   published coefficients transcribed from the journal full text
│       └── make_comparison.py
├── Results/
│   ├── Tables/               esttab CSVs from the author's code (table5.csv … table11.csv)
│   ├── Figures/              figure4–7 (.png tracked, .gph ignored)
│   ├── statspai/             StatsPAI CSV/PNG/JSON outputs and logs
│   ├── run_original_steps.csv    rc and runtime per exhibit
│   ├── log_run_original_full.log Stata log of the full run
│   └── comparison.md         paper vs original Stata vs StatsPAI, number by number
└── Materials/                其它材料
    ├── QJE2019-Busting-the-Princelings-fulltext-OUP-wayback-20200729.html / -fulltext.txt
    ├── Busting the Princelings (QJE 2019).md          Chinese reading note
    ├── 论文模型解读与StatsPAI复现分析.md                Chinese equation-by-equation + StatsPAI analysis
    ├── Manso2026-Are-Princelings-Truly-Busted-arXiv2502.07692.pdf   replication critique (duplicates, "lnarea")
    └── Wiebe2024-Replicating-meritocratic-promotion-ch2.pdf         replication critique (promotion variable)
```

**Paper text.** The journal PDF is behind Cloudflare and could not be downloaded from here. `Materials/` holds the complete journal full text instead: the bronze open-access OUP HTML, Wayback snapshot of 2020-07-29, plus a plain-text extraction. All published numbers used in `comparison.md` come from that text.

## How to run

1. Download the data into `Data/` (commands in [Data/README.md](Data/README.md)).
2. Stata (tested on 18 MP; needs `reghdfe`, `ftools`, `estout`, `coefplot` from SSC):
   ```stata
   do Program/run_original.do "/path/to/QJE2019-Busting-the-Princelings"
   ```
   The wrapper splits `Tables&Figures.do` at its `*Table N*` / `*Figure N*` markers into `Results/_steps/`. It applies path fixes only, plus one documented esttab fix, runs every step under `capture`, and writes `Results/run_original_steps.csv`. A full run takes about 15 minutes; Table 10 has 11.5M observations with two-way clustering.
3. StatsPAI (Python 3.13, `statspai` 1.28.0):
   ```bash
   cd Program/statspai && python3.13 replicate_statspai.py
   ```
   Everything except the prefecture-level ordered probits finishes in about 20 minutes. Tables IX and XII took about 45 CPU-hours here: 1.5–5 h per prefecture model in `sp.oprobit` on a heavily loaded machine, versus under 1 s in Stata or `oprobit_fast.py`.

### Edits to the author's code (all applied by the wrapper; the original file is untouched)

| # | Edit | Why |
|---|---|---|
| 1 | drop `cd "D:\Dropbox\princeling\"` | author's machine path |
| 2 | `use X.dta` → `use "$DATA/X.dta"` | data live in `Data/`, tables are written to `Results/Tables/` |
| 3 | `graph save Graph "f.gph"` → `"$FIG/f.gph", replace` (and the paths in `graph combine`) | figures go to `Results/Figures/` |
| 4 | Table 11 `esttab … drop(… _cons)` → remove `_cons` | all 12 models are `oprobit` (no `_cons`); current estout aborts with r(111) |

## Replication status

Paper table numbers are roman numerals; the do-file uses working-paper numbers (Table 5 = V, …, Table 11 = XII).

| Exhibit | Content | Original code | Matches paper? | StatsPAI | Matches paper? |
|---|---|---|---|---|---|
| Table III | land-transaction summary | ✅ rc 0 | ✅ all N / means / shares | pandas | ✅ |
| Table VII | political-turnover summary | ✅ rc 0 | ✅ | pandas | ✅ 60/60 |
| **Table V** | princeling price discount | ✅ rc 0 | ✅ 15/15 | `sp.feols` two-way cluster | ✅ 15/15 |
| **Table VI** | quantity, firm-year (5.7M) | ✅ rc 0 | ✅ 5/5 | `sp.feols` | ✅ 5/5 |
| **Table VIII** | provincial promotion | ✅ rc 0 | ✅ 34/34 | `sp.oprobit` + `sp.feols` | ✅ 32/34, ⚠️ 2 SEs off by ≤0.001 |
| **Table IX** | municipal promotion | ✅ rc 0 | ✅ 34/34 | `sp.oprobit` + `sp.feols` | ✅ 31/34, ⚠️ 3 cells off by ≤0.0016 |
| **Table X** | price after Xi took office | ✅ rc 0 | ✅ 24/24 | `sp.feols` | ✅ 24/24 |
| **Table XI** | quantity after Xi, firm-province-year (11.5M) | ✅ rc 0 | ✅ 14/14 | `sp.hdfe_ols` | ✅ 14/14 |
| **Table XII** | promotion after Xi | ✅ rc 0 (after edit 4) | ✅ 24/24 | `sp.oprobit` | ✅ 24/24 |
| Figure IV | price scatter vs 500 m neighbours | ✅ | graph | matplotlib | ✅ |
| **Figure V** | price event study | ✅ | graph (Stata log) | `sp.feols` | ✅ 11/11 vs Stata |
| **Figure VI** | quantity event study | ✅ | graph (Stata log) | `sp.feols` | ✅ 11/11 vs Stata |
| Figure VII | daily prices around inspection | ✅ | graph | matplotlib | ✅ |
| Tables I, II, IV; Figures I–III; appendix | — | not in package | — | — | — |

Details, cell by cell: [Results/comparison.md](Results/comparison.md).

### Modern-methods extensions (StatsPAI, not replication)

* **Staggered DID**: province×year princeling price-gap panel, with treatment = party secretary replaced by a Xi appointee (2013–2016; 7 provinces never treated).
  * TWFE 0.29 (0.07).
  * Goodman-Bacon decomposition: 37% of the weight sits on timing-group comparisons.
  * Callaway-Sant'Anna 0.33 (0.09), Sun-Abraham 0.31 (0.12), BJS 0.27 (0.07). The paper's campaign effect survives heterogeneity-robust estimation and is larger.
* **HonestDiD** (Rambachan-Roth) on Figure V re-based to 2012: the 2016 narrowing of the discount is robust to relative-magnitude violations up to M̄ = 2; the 2013 effect is not (M̄ = 0.5).
* **Roth (2022) pre-trend power**: 44% for the individual tests (15% for the joint test).
* **Wild cluster bootstrap** (999 Rademacher draws, 31 province clusters) for the 500 m specifications: Table V col 3 and Table X cols 2, 4 and 6 all stay significant at p < 0.001. For example, princeling × Xi-appointed is 0.572, CI [0.46, 0.69].
* **StatsPAI bugs found**:
  * `callaway_santanna` ignores `control_group="notyettreated"` on unbalanced panels.
  * `callaway_santanna` aggregates ATT(g,t) cells that have no valid comparison as 0.
  * `oprobit` stops early and is very slow: an analytic-Newton cross-check (`oprobit_fast.py`, not StatsPAI) fits the same prefecture models in under a second and matches Tables VIII, IX and XII exactly.

  Minimal repros are in `Materials/论文模型解读与StatsPAI复现分析.md`.

## Known data issues (literature)

* **Manso (2026, arXiv 2502.07692):**
  * About one third of `price.dta` rows are exact duplicates; conclusions survive de-duplication.
  * `lnarea` in the firm panels is area/10⁶ m², not a log.
* **Wiebe (2024):** the municipal promotion variable is miscoded.
* **This replication:** table notes and code disagree in several places:
  * Table notes say "robust SE"; the code uses the default OIM.
  * Table IX says "Province FE"; the code uses prefecture FE.
  * Table VI notes list industry FE; the code has none.
  * Table XII column 11 omits `ties`.
  * Table XII columns 10 and 12 use `post2012` rather than `inspection` as the main effect.
  * The code uses `xi` for `xi_assign`, which only works through Stata's variable-name abbreviation.

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [Busting the Princelings (QJE 2019).md](<Materials/Busting the Princelings (QJE 2019).md>) | anyone curious about the paper | question, data, identification, core equations, findings tagged to tables/figures, 2022–2026 modern-DID reassessment |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | researchers reproducing it | equation-by-equation dissection, do-file ↔ paper mapping, StatsPAI implementation details, bugs with minimal repros, improvement list |

## License

- **Reading notes and code in this repository** (everything except the author's package) are released under the [MIT License](LICENSE).
- **The paper** is © the President and Fellows of Harvard College / Oxford University Press; the saved HTML full text is for private study.
- **The replication package** (data and `Tables&Figures.do`) is by Ting Chen and James Kai-sing Kung, distributed under CC0 via Harvard Dataverse.
