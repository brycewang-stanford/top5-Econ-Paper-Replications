# QJE 2020 — Watering Down Environmental Regulation in China

> He, Guojun, Shaoda Wang & Bing Zhang (2020), *Quarterly Journal of Economics* 135(4): 2135–2185.
> **"Watering Down Environmental Regulation in China"** — doi:[10.1093/qje/qjaa024](https://doi.org/10.1093/qje/qjaa024)

A reading-and-replication workspace for the above paper, built on the official replication package
(Harvard Dataverse **doi:[10.7910/DVN/LVS8VX](https://doi.org/10.7910/DVN/LVS8VX)**, CC0), with a full
re-implementation in [StatsPAI](https://github.com/brycewang-stanford/StatsPAI).

**Design.** Spatial regression discontinuity at China's national water-quality monitoring stations: firms
just upstream (whose discharge enters the station's reading) vs just downstream, running variable = river
distance to the station, local-linear `rdrobust` with MSE-optimal bandwidth and station-clustered SEs; plus a
difference-in-discontinuities across the 2003 tightening of water-quality targets.

## Layout

```text
.
├── Data/                   原始数据 — Dataverse package (local only, not tracked; see Data/README.md)
│   └── Replication Materials/   one folder per exhibit: F4_RD, F5_Trend, T1_Baseline … T8_Cost_Estimates
├── Program/                原始代码 — author's do-files, one folder per exhibit (copied from the package)
│   ├── run_original.do     wrapper: sets $data/$result/$figure, runs every exhibit, logs rc + seconds
│   ├── ado/                mdrd (Ribas) — archived copy, the original site is offline
│   ├── F4_RD/ F5_Trend/ T1_Baseline/ T2_MDRD/ T3_Channels/ … T7_Burden/ T8_Cost_Estimates/
│   └── statspai/           StatsPAI re-implementation (replicate_statspai.py, export_stata_estimates.do,
│                           build_comparison.py, README.md)
├── Results/
│   ├── Tables/             outreg2 output of the author's code (.txt tracked; .xml/.xlsx ignored)
│   ├── Figures/            Figure IV (F3_TFP.png) and Figure V (F5_by_year.png)
│   ├── run_original.log, run_original_steps.csv
│   ├── statspai/           StatsPAI tables (csv), figures (png), extensions (ext_*)
│   └── comparison.md       paper vs original Stata vs StatsPAI, cell by cell
└── Materials/              其它材料
    ├── QJE2020-Watering Down Environmental Regulation in China.pdf   published version (author's website copy)
    ├── LVS8VX-0_ReadMe.pdf                                             package README
    ├── Watering Down Environmental Regulation (QJE 2020).md            Chinese reading note
    └── 论文模型解读与StatsPAI复现分析.md                                 equation-by-equation + StatsPAI replication note
```

## How to run

1. Download the package into `Data/` (exact commands in [Data/README.md](Data/README.md)).
2. Stata 18 with `rdrobust` (tested 10.0.0), `outreg2`, `winsor2`, `blindschemes` from SSC (the wrapper installs missing ones). `mdrd` is loaded from `Program/ado`.
3. From the project root: `stata-mp -b do Program/run_original.do` (≈ 37 min; Table II's six `mdrd` calls take 35 min), then `mv run_original.log Results/`.
4. StatsPAI: see [Program/statspai/README.md](Program/statspai/README.md) (`python3.13 Program/statspai/replicate_statspai.py`, then `build_comparison.py`).

### Edits to the author's code (all documented)

| file | edit | reason |
|---|---|---|
| `F5_Trend/F5_Trend.do` | `"$data\graph_by_year"` → `"$data/graph_by_year"` | Windows path separator fails on macOS |
| `T2_MDRD/2_Within_Firm_RD_replication.do` | commented out `net describe/install mdrd` | `sites.google.com/site/r4ribas` is offline; archived 2017 build (Wayback Machine) placed in `Program/ado` |

Everything else runs unmodified. Table VIII is an Excel workbook (`T8_Cost_Estimates/8_Cost_Estimates.xlsx`), no code.

## Replication status

| Exhibit | Original code | Match with paper | StatsPAI | Notes |
|---|---|---|---|---|
| Table I (baseline RD, 18 cells) | ✅ rc 0 | ✅ 18/18 (coef, SE, bandwidth, N) | ✅ identical with author bandwidth | native StatsPAI bandwidth differs (mass-point adjustment always on) |
| Table II (diff-in-disc, `mdrd`) | ✅ rc 0 (archived mdrd) | ✅ 1, ⚠️ 5 (coef & SE within ±0.01; bandwidths smaller than printed) | ✅ RD(post)−RD(pre) = mdrd to 4 dp | later `mdrd` build used by authors |
| Table III (inputs/outputs, 42 cells) | ✅ | ✅ 42/42 | ✅ | pre-2003 columns print bias-corrected coefs |
| Table IV (abatement, 12 cells) | ✅ | ✅ 12/12 | ✅ | |
| Table V (emissions, 24 cells) | ✅ | ✅ 16, ⚠️ 5, ❌ 3 | ✅ | uniform column published with `bwselect(msecomb1)`; NH3-N uniform cells not reproducible |
| Table VI (political economy, 27 cells) | ✅ | ✅ 23, ⚠️ 3, ❌ 1 | ✅ | Panel A published with `mserd` (code: `certwo`) |
| Table VII (heterogeneity, 36 cells) | ✅ | ✅ 30, ⚠️ 2, ❌ 4 | ✅ | SOE (N=513) and SNWD-nonpolluting cells not reproducible; SNWD kernel labels permuted |
| Table VIII (costs) | Excel | ✅ 6/6 columns | ✅ Python replay; StatsPAI-based inputs within 2 % | |
| Figure IV (RD plot) | ✅ | ✅ | ✅ `sp.rdplot` | |
| Figure V (by year) | ✅ | ✅ (pre-computed estimates shipped) | ✅ re-plot | yearly RD microdata not in package |

Totals: 171 numeric cells in Tables I–VIII; 148 ✅, 15 ⚠️, 8 ❌ (all ❌ are non-headline subsample/placebo cells). Every headline result reproduces. Full detail: [Results/comparison.md](Results/comparison.md).

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [Watering Down Environmental Regulation (QJE 2020).md](<Materials/Watering Down Environmental Regulation (QJE 2020).md>) | Anyone curious about the paper | Question, data, identification, core equations, findings tagged to tables/figures, modern-RD reassessment (honest CIs, donut, bandwidth sensitivity, density test). |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | Researchers reproducing the paper | Equation-by-equation dissection, exact Stata ↔ StatsPAI mapping, every discrepancy, StatsPAI bugs with minimal repros, improvement suggestions. |
| [LVS8VX-0_ReadMe.pdf](Materials/LVS8VX-0_ReadMe.pdf) | Anyone running the package | Official package README (data permissions). |

## License

- **Reading notes and replication scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper PDF** is © the President and Fellows of Harvard College / Oxford University Press; the copy in `Materials/` is the authors' posted version — see OUP's terms before redistribution.
- **The replication package** (data and code) is by the paper's authors, published on Harvard Dataverse under CC0 1.0; the ASIF/ESR extracts are de-identified by the authors. `mdrd` is © Rafael P. Ribas.
