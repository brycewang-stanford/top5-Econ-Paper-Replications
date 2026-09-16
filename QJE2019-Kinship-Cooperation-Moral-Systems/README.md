# QJE 2019 — Kinship, Cooperation, and the Evolution of Moral Systems

> Enke (2019), *Quarterly Journal of Economics* 134(2): 953–1019. DOI [10.1093/qje/qjz001](https://doi.org/10.1093/qje/qjz001)
> **"Kinship, Cooperation, and the Evolution of Moral Systems"**

A reading-and-replication workspace for the above paper, built on the official replication package (Harvard Dataverse **[doi:10.7910/DVN/JX1OIU](https://doi.org/10.7910/DVN/JX1OIU)**, CC0), with a full re-implementation in [StatsPAI](https://github.com/brycewang-stanford/StatsPAI) and a set of modern robustness extensions.

## Layout

```text
.
├── Data/                  原始数据 — the 7 .dta files of data_programs.zip (local only, not tracked by git)
│   └── README.md          source, sizes, what each file feeds, re-download commands
├── Program/               原始代码 — author's replication code + our wrappers
│   ├── do-files/          author's code, UNMODIFIED (Generate_results.do, EA/, Country/, MFQ/, Kinship_index/)
│   ├── run_original.do    wrapper: builds the author's expected path tree via symlinks, runs every do-file, logs rc + seconds
│   ├── run_precise.do     re-runs the table do-files and dumps coefficients at 6 decimals (Results/Tables/precise/)
│   └── statspai/          StatsPAI re-implementation (replicate_statspai.py, extensions_statspai.py, build_comparison.py)
├── Results/
│   ├── Tables/            author's esttab .tex output (+ precise/*.csv)
│   ├── Figures/           author's Stata graphs (.pdf)
│   ├── statspai/          StatsPAI tables, figures, extensions (csv/md/png)
│   ├── run_original.log   full Stata log; run_original_steps.csv = rc + runtime per step
│   └── comparison.md      paper vs original Stata vs StatsPAI, number by number
└── Materials/             其它材料
    ├── QJE2019-Kinship, Cooperation, and the Evolution of Moral Systems.pdf   published version (author's website copy)
    ├── Kinship, Cooperation and Moral Systems (QJE 2019).md                    Chinese reading note
    └── 论文模型解读与StatsPAI复现分析.md                                        Chinese model dissection + StatsPAI replication report
```

The package ships no README of its own; the header of `Program/run_original.do` and [Data/README.md](Data/README.md) document it.

## How to run

1. Download the data into `Data/` (see [Data/README.md](Data/README.md), one `curl`).
2. Stata 18 (any Stata ≥ 13 should work; needs `estout`, `binscatter` — installed automatically from SSC):
   edit `global ROOT` at the top of `Program/run_original.do`, then `do Program/run_original.do` (≈ 50 s), optionally `do Program/run_precise.do` (≈ 25 s).
3. StatsPAI (Python 3.13, `statspai` 1.28.0):
   ```bash
   python3.13 Program/statspai/replicate_statspai.py     # ≈ 100 s
   python3.13 Program/statspai/extensions_statspai.py    # ≈ 25 s
   python3.13 Program/statspai/build_comparison.py       # writes Results/comparison.md
   ```

### Edits relative to the author's package

The author's do-files are **not modified**. The author's master `Generate_results.do` expects to run from a folder containing `Data_programs/Data`, `Data_programs/Do-files` and `Source_files/{Tables,Figs}`; `run_original.do` recreates that tree as symlinks under `Results/_run/` (deleted afterwards). Other wrapper-level differences:

| # | Difference | Why |
|---|---|---|
| 1 | globals copied verbatim from `Generate_results.do`; each file run with `do` (not `run`) inside `capture noisily`, timed | per-step rc + runtime log |
| 2 | `set seed 20190001` before each step | author sets no seed; bootstrap SEs (Table III cols 4–11, Table IV cols 1, 2, 6, 7, Figure IV) otherwise change run to run |
| 3 | Table X cols 1–3 exported to `Results/Tables/GPS_punish_cols1_3.tex` | author's do-file estimates them but its `esttab` is commented out (cols 4–6 need restricted Gallup data) |
| 4 | `run_precise.do` runs a temporary copy of each table do-file with `esttab using` → `esttab_precise using` (via `filefilter`) | 6-decimal dump for StatsPAI comparison; LaTeX tables still come from the unmodified run |
| 5 | `ssc install binscatter` | not installed on this machine |

## Replication status

| Exhibit | Content | Original Stata code | StatsPAI |
|---|---|---|---|
| Table I, II | conceptual overview / prisoner's dilemma payoffs | no data | — |
| Figure I | histogram of kinship index | no code in package | ✅ re-drawn |
| Figures II–III | binscatters: hunting-gathering, sickle-cell distance | ✅ rc 0 | ✅ re-drawn |
| Table III | determinants of kinship tightness (11 cols) | ✅ all coefficients & N; bootstrap SEs ⚠️ MC noise | ✅ 17 / ⚠️ 3 (bootstrap SE) |
| Table IV | enforcement devices in the EA (15 cols) | ✅ all coefficients & N; bootstrap SEs ⚠️ MC noise | ✅ 13 / ⚠️ 4 (bootstrap SE) |
| Figure IV | EA moral systems, tight vs loose | ✅ rc 0 | ✅ re-drawn |
| Table V | neighbouring ethnic groups, match FE (6 cols) | ✅ exact | ✅ 7/7 |
| Figure V | contemporary moral systems, tight vs loose | ✅ rc 0 | ✅ re-drawn |
| Table VI | in- vs out-group trust, countries + WVS (8 cols) | ✅ exact | ✅ 8/8 |
| Figure VI | trust scatter | ✅ rc 0 | ✅ re-drawn |
| Table VII | belief in hell (8 cols) | ✅ exact | ✅ 14/14 |
| Table VIII | MFQ migrants (8 cols) | ✅ exact | ✅ 8/8 |
| Figure VII | disgust, US migrants | ✅ rc 0 | ✅ re-drawn (13,751 US respondents vs 13,723 in text ⚠️) |
| Figure VIII | morality kernel (PCA) | ✅ rc 0 | ✅ re-drawn |
| Table IX | disgust, shame vs guilt (ISEAR, Google Trends) (8 cols) | ✅ exact | ✅ 8/8 |
| Table X | revenge vs altruistic punishment | cols 1–3 ✅ exact; **cols 4–6 ❌ restricted Gallup data** | cols 1–3 ✅ 3/3 |
| Table XI | EA population density & development (6 cols) | ✅ exact | ✅ 9/9 |
| Figure IX | kinship coefficient on pop. density / urbanization 1500–1950 | ✅ rc 0 | ✅ re-drawn, N = 123 countries as in paper |
| Online appendix | — | not in package | — |

Totals: **12/12 author do-file steps run with rc = 0 (≈ 51 s)**; 94 published coefficients compared → Stata and StatsPAI both match the paper at reported precision for all point estimates and N; 7 bootstrap SEs differ within Monte-Carlo noise. See [Results/comparison.md](Results/comparison.md).

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [Kinship, Cooperation and Moral Systems (QJE 2019).md](<Materials/Kinship, Cooperation and Moral Systems (QJE 2019).md>) | Anyone curious about the paper | Question, data, kinship index, identification, core equations, findings tagged to tables/figures, modern-methods reassessment |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | Researchers reproducing the paper | Equation-by-equation dissection; StatsPAI implementation details, extensions, API gaps and bugs, suggestions |
| [Results/comparison.md](Results/comparison.md) | Replicators | Number-by-number audit |

## License

- **Reading notes and replication scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper PDF** is © the President and Fellows of Harvard College / Oxford University Press; the copy in `Materials/` is the author-hosted version from benjamin-enke.com. Check OUP's terms before redistribution.
- **The replication package** (data and do-files) is by Benjamin Enke, released on Harvard Dataverse under CC0 1.0.
