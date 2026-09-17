# QJE 2023 — AI-tocracy

> Beraja, Kao, Yang & Yuchtman (2023), *Quarterly Journal of Economics* 138(3): 1349–1402.
> **"AI-tocracy"** — DOI [10.1093/qje/qjad012](https://doi.org/10.1093/qje/qjad012)

A reading-and-replication workspace for the above paper, built on the official replication package (Harvard Dataverse **doi:[10.7910/DVN/GCOVGX](https://doi.org/10.7910/DVN/GCOVGX)**, CC0), with a full re-implementation of the main-text regressions in [StatsPAI](https://github.com/brycewang-stanford/StatsPAI).

## Layout

```text
.
├── Data/                  原始数据 — Replication/Data of the package, 5.2 GB (local only, not tracked by git)
│   ├── *.dta, map_prefecture_2015/        28 datasets + prefecture shapefile
│   ├── Intermediate/                      written by Analysis.do (Fig*.dta, China_map_*.csv)
│   ├── Intermediate_shipped/              untouched copy of the package's Intermediate/
│   └── Intermediate/statspai/             regression-ready panels exported for the StatsPAI scripts
├── Program/               原始代码 — author's code + wrappers
│   ├── Analysis/Analysis.do               author's master (21 sections); 2 documented one-line edits
│   ├── Analysis/make_map.R                author's map script (unmodified; needs archived rgdal/rgeos/maptools)
│   ├── make_map_sf.R                      sf port of make_map.R (Figure I, A.5)
│   ├── run_original.do / run_original.sh  wrapper: sets the root, runs sections (parallel groups), logs rc + seconds
│   ├── _root/{Analysis,Data,Output}       relative symlinks = the author's expected folder layout
│   ├── ado/                               project-local ados: carryforward, xtevent 1.0.0, make_index_gr, jive
│   └── statspai/                          StatsPAI re-implementation (see Program/statspai/README.md)
├── Results/
│   ├── Tables/  Figures/                  output of Analysis.do (+ make_map_sf.R)
│   ├── statspai/                          StatsPAI outputs (csv/png)
│   ├── logs/run_original_steps.csv        per-section rc and runtime
│   └── comparison.md                      paper vs original Stata vs StatsPAI, number by number
└── Materials/             其它材料
    ├── AI-tocracy (QJE 2023).pdf          published open-access article
    ├── package/README.pdf, README.md      package README
    ├── package/Output_shipped/            the authors' own Output/ folder (Jan 2023) — reference for appendix tables
    ├── AI-tocracy (QJE 2023).md           Chinese reading note
    └── 论文模型解读与StatsPAI复现分析.md   Chinese equation-by-equation dissection + StatsPAI replication & bug report
```

## How to run

1. Download and unpack the package into `Data/` (exact `curl` commands in [Data/README.md](Data/README.md)).
2. Original code (Stata 18 MP; `reghdfe`, `ivreghdfe`, `ftools`, `ivreg2`, `ranktest`, `estout`, `binscatter`, `balancetable` from SSC; the rest ships in `Program/ado/`):
   ```bash
   cd Program
   ./run_original.sh "7 8 9" "4 10" "5 6 11 12" "13 14 15 16 18 20 21 2 1" "19" "3"   # quoted list = one Stata process
   /usr/local/bin/Rscript make_map_sf.R
   ```
   `stata-mp -b do run_original.do "8 9"` runs a list sequentially. Section 17 (Figure A.10, 100 LASSO-IV seeds) is excluded from the default list — it needs more than two days.
3. StatsPAI (Python 3.13, statspai 1.28.0):
   ```bash
   Program/statspai/run_export.sh "10 11 12 8 9 2 14"         # once, ~40 min
   /usr/local/bin/python3.13 Program/statspai/replicate_statspai.py
   ```

### Edits to the author's code

| File | Edit | Why |
|---|---|---|
| `Analysis/Analysis.do` line 16–17 | `if "$AITOC_ROOT" != "" global dir = "$AITOC_ROOT"` added after the Dropbox path | wrapper sets the root |
| `Analysis/Analysis.do` line 31–32 | `if "`1'" != "" local output = "`1'"` added after `local output = "all"` | run one section per call / in parallel |
| `ado/make_index_gr.ado` | added (Samii 2017, GitHub `cdsamii/make_index`) | called by sections 5, 6, 11 but not shipped |
| `ado/x/xtevent*.ado` | **xtevent 1.0.0** (GitHub tag) instead of SSC 3.1.0 | only 1.0.0 reproduces Table IX A |
| `ado/j/jive.ado` | Stata Journal st0108 | used by section 3, not listed in the package README |
| `make_map_sf.R` | new port | `rgdal`/`rgeos`/`maptools` archived; no GDAL/GEOS on this machine |

## Replication status

Full number-by-number tables: [Results/comparison.md](Results/comparison.md).

| Exhibit | Original code (Stata 18) | StatsPAI |
|---|---|---|
| Table I (summary statistics) | ✅ byte-identical to the authors' output and the paper | — (not a regression) |
| Table II A, III A/C (OLS) | ✅ identical | ✅ identical (`sp.feols`) |
| Table II B, III B/D (cross-fit LASSO IV) | ✅ identical (4.6 h of `xpoivregress`) | ⚠️ approximation only (no PO-LASSO-IV in StatsPAI) |
| Table IV, V | ✅ coefficients identical; 5 SEs differ by 0.0001 | ✅ identical to Stata re-run (variables rebuilt in Python) |
| Table VI, VII | ⚠️ close but not digit-identical: results depend on random tie-breaking in `collapse (lastnm) place` (425 multi-location cells) | ✅ identical to Stata re-run |
| Table VIII | ✅ identical | ✅ identical |
| Table IX A | ✅ identical with xtevent 1.0.0 (❌ with any later xtevent) | ✅ identical (xtevent-1.0 design rebuilt in Python) |
| Table IX B/C | ❌ random tie-breaking (`lastnm`, `drop if _n>1`); C differs materially | ✅ identical to Stata re-run |
| Figure I, A.5 (maps) | ✅ via sf port | — |
| Figure II, A.12, A.13 | ✅ coefficient files identical (<1e-6) | ✅ identical |
| Figure V, VI, A.11, A.14–A.16 | ✅ produced; firm-level ones subject to the same randomness | Figure V ✅ |
| Figure III, Table A.3 | ✅ after installing `jive`: LASSO, 7-day LASSO, parsimonious IV, OLS bars and the A.3 lasso log identical; JIVE 0.3005 vs 0.3007; LIML 0.2936 vs 0.2894 — numerically unstable (instrument scale 1e13), stable value 0.267 | OLS ✅, parsimonious IV ✅, LIML (stable) |
| Appendix Tables A.2, A.4–A.7 | ✅ identical (A.5: 4 SEs differ in the 4th decimal) | — |
| Appendix Tables A.8–A.15 | ⚠️ same random tie-breaking as Tables VI–VII; A.14/A.15 Panel A.1 are not written by `Analysis.do` | — |
| Figure A.10 (100 seeds) | not run (> 50 h) | — |

**Extensions (StatsPAI, not replication):** re-estimating Table VI/VII with the *flow* of software instead of the author's flow-before/cumulative-after outcome removes the effect (Table VI: −4.15 (3.94) summed over quarters 0–8); staggered-robust estimators on the flow panel (Callaway–Sant'Anna, Sun–Abraham, BJS) give small, insignificant effects; wild-cluster bootstrap (38 clusters) keeps the author's own estimate significant; the parsimonious weather IV has a cluster-robust first-stage F of 0.46 and an unbounded Anderson–Rubin set. Details in the analysis note §5.

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [AI-tocracy (QJE 2023).md](<Materials/AI-tocracy (QJE 2023).md>) | Anyone curious about the paper | Question, data, identification, core equations, findings tagged to tables/figures, replication verdict, 2022–2026 methods reassessment (Chinese). |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | Researchers reproducing the paper | Section ↔ exhibit map, equation-by-equation code dissection, run log, reasons for every mismatch, StatsPAI implementation details, extensions, StatsPAI bugs with minimal repros (Chinese). |
| [package/README.pdf](Materials/package/README.pdf) | Anyone running `Analysis.do` | Official package README: data sources and file list. |

## License

- **Reading notes and replication scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper PDF** is © the authors / Oxford University Press (published open access); see the QJE terms before redistribution.
- **The replication package** (data, code) is by the paper's authors and released on Harvard Dataverse under CC0 1.0; data are obtained from the official portal and not redistributed here.
