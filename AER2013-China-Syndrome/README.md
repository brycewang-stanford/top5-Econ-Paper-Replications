# AER 2013 — The China Syndrome

> Autor, Dorn & Hanson (2013), *American Economic Review* 103(6): 2121–2168.
> **"The China Syndrome: Local Labor Market Effects of Import Competition in the United States"** · DOI [10.1257/aer.103.6.2121](https://doi.org/10.1257/aer.103.6.2121)

A reading-and-replication workspace for the above paper, built on the authors' public file archive
**Autor-Dorn-Hanson-ChinaSyndrome-FileArchive** from [ddorn.net/data.htm](https://www.ddorn.net/data.htm)
(the AEA openICPSR copy, project E112670, is login-walled). Everything is re-run with the original Stata code and
re-implemented in [StatsPAI](https://github.com/brycewang-stanford/StatsPAI), plus a modern shift-share / weak-IV inference audit.

## Layout

```text
.
├── Data/                  原始数据 — author archive dta/ + ddorn.net companion files + BHJ/GPSS/AKM share data (local only, see Data/README.md)
├── Program/               原始代码 — author's code
│   ├── do/                czone_analysis_ipw_final.do (T3–10, AT1–5), czone_analysis_preperiod_final.do (T2),
│   │                      import_stats_final.do (T1), figure1.do, czone_plot_import_long_final.do (F2)
│   ├── other/             CBP cleaners, sic87dd/ind1990dd definitions, NAICS→SIC crosswalk (documentation, not run)
│   ├── run_original.do    wrapper: runs the 5 do-files, logs rc + seconds, exports PNGs, copies tables
│   ├── modern_reference_stata.do   Stata reference for the modern extensions (ivreg2, weakivtest, weakiv, boottest)
│   └── statspai/          StatsPAI re-implementation (see Program/statspai/README.md)
├── Results/
│   ├── log/               Stata logs + esttab .scsv tables from the author's code, run_original_steps.txt
│   ├── Tables/            copies of the 16 .scsv tables
│   ├── Figures/           Figure 1, Figure 2 A/B (.png; .gph not tracked)
│   ├── statspai/          StatsPAI estimates, figures, modern-extension outputs
│   └── comparison.md      paper vs original Stata vs StatsPAI, cell by cell
└── Materials/             其它材料
    ├── AER2013-The China Syndrome- ….pdf        published AER version (from ddorn.net)
    ├── AER2013-China-Syndrome-Online-Appendix.pdf
    ├── package/            archive Readme.pdf, Manufacturing_Industry_Codes.pdf, tab-fig/*.xls, author's 2013 logs and gph
    ├── The China Syndrome (AER 2013).md
    └── 论文模型解读与StatsPAI复现分析.md
```

## How to run

1. Download the data (exact `curl` commands in [Data/README.md](Data/README.md)).
2. Stata 18 (needs `estout`; the modern reference also needs `ivreg2 ranktest weakivtest weakiv avar boottest`):
   ```stata
   global ROOT "/path/to/AER2013-China-Syndrome"
   do "$ROOT/Program/run_original.do"            // ~20 s
   do "$ROOT/Program/modern_reference_stata.do"  // ~40 s
   ```
3. StatsPAI (Python 3.13, statspai 1.28.0) and R (ShiftShareSE) — see [Program/statspai/README.md](Program/statspai/README.md).

**Edits to the author's code:** only relative paths in the five `Program/do/*.do` files
(`../dta/` → `../../Data/dta/`, `../log/` → `../../Results/log/`, `../gph/` → `../../Results/Figures/`); see commit `564cfbe`.

## Replication status

| Exhibit | Original Stata code | StatsPAI | Notes |
|---|---|---|---|
| Table 1 trade volumes | ✅ cols 1–4 · ❌ col 5 not produced | ✅ 30/30 | package summarises `l_totimp_ushi/othi`, not the published "rest of world" column; StatsPAI rebuilds it from `sic87dd_trade_data` |
| Figure 1 | ✅ drawn | ✅ redrawn | time series only |
| Table 2 pre-period falsification | ✅ | ✅ 6/6 | |
| Table 3 manufacturing emp. (+ first stage) | ✅ | ✅ 33/33 | published first-stage SEs are HC1, not clustered |
| Table 4 population | ✅ | ✅ 35/35 | incl. R² |
| Table 5 employment status | ✅ | ✅ 18/18 | |
| Table 6 wages | ✅ | ✅ 18/18 | |
| Table 7 mfg vs non-mfg | ✅ | ✅ 22 · ⚠️ 2 | R² two-step rounding in paper |
| Table 8 transfers | ✅ | ✅ 31 · ⚠️ 1 | |
| Table 9 household income | ✅ | ✅ 23 · ⚠️ 1 | |
| Table 10 alternative exposure | ✅ panels A, C–F · ❌ panel B | ✅ 37 · ⚠️ 6 · ❌ 6 | panel B: archive instrument ≠ published version (author's own 2013 log agrees with us) |
| Figure 2 first stage / reduced form | ✅ | ✅ 2/2 | 0.82 (0.09), −0.34 (0.07) |
| Appendix Tables 1, 3, 5 | ✅ | ✅ 54, 12, 24 | |
| Appendix Table 2 descriptives | ✅ (spot-checked) | — | not re-estimated |
| Appendix Table 4 other exporters | ✅ cols 1–4 · ❌ col 5 | ✅ 15 · ⚠️ 1 · ❌ 4 | archive `d_tradeushi_pw` differs from published (mean 9.04 vs 2.73) |
| **Total published cells** | all 16 esttab tables **byte-identical** to the author's 2013 logs | **360 ✅ · 11 ⚠️ · 10 ❌ of 381** | Stata = StatsPAI to ≤ 6e-5 on all 165 matched regressions |

**Modern-methods extensions** (Table 3 col 6 baseline β = −0.596, state-clustered SE 0.099; all numbers validated against Stata, R or the methods papers' own replication output, see `Results/statspai/modern_extensions.md`):
Olea–Pflueger effective F = 47.6 (col 1: 97.5) · cluster-robust AR 95% CI [−0.827, −0.388] · WRE wild-cluster bootstrap p < 0.0001, CI [−0.796, −0.326] (boottest) ·
AKM SE 0.126 (SIC3-clustered shocks), AKM0 CI [−1.018, −0.362] · BHJ shock-level IV −0.596 (0.114), shock-level F 185.6 ·
Rotemberg weights: Electronic computers 0.183, toys 0.138, household audio/video 0.085, telephone apparatus 0.066, computer peripherals 0.060; 98 % of the identifying variation comes from 2000–07 shocks. The headline finding survives every modern inference check; shift-share-robust intervals are ≈30 % wider.

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [The China Syndrome (AER 2013).md](<Materials/The China Syndrome (AER 2013).md>) | Anyone curious about the paper | 中文阅读笔记：问题、数据、识别、核心方程、主要发现（逐表标注）、2019–2025 shift-share 文献视角下的再评估 |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | Researchers reproducing the paper | 逐方程拆解 + StatsPAI 复现细节、差异解释、StatsPAI bug 与改进建议 |
| [Results/comparison.md](Results/comparison.md) | Replicators | cell-by-cell paper / Stata / StatsPAI table with explanations |
| [Materials/package/Readme.pdf](Materials/package/Readme.pdf) | Anyone running the code | Authors' archive README |

## License

- **Reading notes and replication scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper PDF and online appendix** are the property of the American Economic Association / the authors; see AER copyright terms before redistribution.
- **The file archive** (data, code, logs) is by Autor, Dorn and Hanson, distributed on ddorn.net; cite the paper when using it. BHJ, GPSS and AKM replication files are by their respective authors.
