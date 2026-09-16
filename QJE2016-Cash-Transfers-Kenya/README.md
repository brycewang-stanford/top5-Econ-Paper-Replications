# QJE 2016 — Unconditional Cash Transfers in Kenya

> Haushofer & Shapiro (2016), *Quarterly Journal of Economics* 131(4): 1973–2042. DOI [10.1093/qje/qjw025](https://doi.org/10.1093/qje/qjw025)
> **"The Short-Term Impact of Unconditional Cash Transfers to the Poor: Experimental Evidence from Kenya"**
> Erratum: Haushofer & Shapiro (2017), corrected Tables I–III (in `Materials/Erratum/`).

A reading-and-replication workspace built on the official replication package, Harvard Dataverse
**[doi:10.7910/DVN/M2GAZN](https://doi.org/10.7910/DVN/M2GAZN)** (~30 MB: Stata code, ado files, four `.dta` files,
the author-version paper, online appendix, erratum, and the authors' own table/figure outputs).

## Layout

```text
.
├── Data/                     原始数据 — Dataverse M2GAZN (local only, not tracked; see Data/README.md)
│   ├── UCT_FINAL_CLEAN.dta   main analysis file (2,880 respondent rows, 1,440 households, 123 villages)
│   ├── UCT_MetalRoofHHs.dta, UCT_UNMATCHED.dta, UCT_Village_Collapsed.dta
│   └── raw_download/         the original Dataverse tar archives
├── Program/                  原始代码
│   ├── Do/                   author's do-files (MASTER.do + 31 analysis files; 2 documented path edits in MASTER.do)
│   ├── Ado/                  author-bundled ados: stepdown, pstar, leebounds, estout, grqreg3, …
│   ├── run_original.do       wrapper: sets root, runs MASTER step by step, logs rc + seconds per step
│   └── statspai/             StatsPAI re-implementation (Python 3.13) — see Program/statspai/README.md
├── Results/
│   ├── Tables/               183 .tex tables produced by the Stata re-run
│   ├── Figures/              30 figures (.eps/.gph) produced by the Stata re-run
│   ├── logs/                 per-step csv (rc, seconds); full Stata logs are local only (up to 31 MB)
│   ├── statspai/             StatsPAI outputs (csv/md/png) incl. modern-methods extensions
│   └── comparison.md         paper vs original Stata vs StatsPAI, every published cell
└── Materials/                其它材料
    ├── Paper/                author version of the paper (erratum-corrected, 21 Apr 2017) + LyX source
    ├── Online Appendix/      online appendix PDF + LyX
    ├── Erratum/              2017 erratum (paper + online appendix)
    ├── package_outputs/      authors' shipped Tables/ and Figs/ (reference for the comparison)
    ├── Cash Transfers Kenya (QJE 2016).md          Chinese reading note
    └── 论文模型解读与StatsPAI复现分析.md              Chinese equation-by-equation dissection + StatsPAI report
```

The published QJE typeset PDF is paywalled; the package's author version (`Materials/Paper/Haushofer_Shapiro_UCT.pdf`)
is used instead. It already incorporates the 2017 erratum; `build_comparison.py` verifies that every two-decimal
number of Tables I–VI and A.1 in that PDF equals the shipped `.tex` tables (786/786 tokens).

## How to run

1. Download the package into `Data/` (exact `curl` commands in [Data/README.md](Data/README.md)).
2. Original code (Stata ≥ 13; run here with Stata 18 MP):
   `stata-mp -b do Program/run_original.do all` (edit `UCT_PROJECT` at the top of the wrapper).
   The four FWER "stepdown" steps use 10,000 placebo permutations and take 1.5–3.3 h each; the package was run
   here as 7 parallel groups, e.g. `stata-mp -b do Program/run_original.do g1_table1 maketable1`.
3. StatsPAI: `cd Program/statspai && python3.13 replicate_main_tables.py && python3.13 replicate_spillover_lee.py && python3.13 extensions_modern.py && python3.13 build_comparison.py`.

### Edits to the author's code

| File | Edit | Why |
|---|---|---|
| `Program/Do/MASTER.do` | `data_dir`, `output_dir`, `figs_dir` now point to `../Data`, `../Results/Tables`, `../Results/Figures` | project layout (package expected `Data/`, `Tables/`, `Figs/` next to `Do/`) |
| `Program/Do/MASTER.do` | block that sets all `*_flag` globals from `$UCT_ONLYSTEP` when that global is non-empty | lets the wrapper time/log each step; no effect when run directly |

No analysis code was changed; all ados come from the package (`sysdir set PERSONAL "${ado_dir}"`).

## Replication status

Original Stata code: **37/37 MASTER steps ran with rc = 0** (wall 5 h 09 min in 7 parallel groups; 19.3 CPU-h
sequential equivalent). **183 tables and 30 figure files** re-created — the same file set the authors shipped
(except 2 hand-written LyX tables A.2/A.3 and 3 "markup" tables hand-coloured for the erratum). 153/183 tables are
byte-identical; the other 30 differ only in Monte-Carlo cells (FWER permutation p-values ±0.01, unseeded bootstrap SEs
of Lee bounds and sqreg) except 3 appendix tables on the tiny "conditional on business ownership" subsample, where
Stata 18 omits a different collinear regressor than the authors' Stata 13/14.

| Exhibit | Original Stata | StatsPAI | Notes |
|---|---|---|---|
| Table I — baseline balance | ✅ (FWER p ±0.01 ⚠️) | ✅ coef/SE/N/joint; FWER ⚠️ ≤0.02 | ported stepdown, 10,000 permutations |
| Table II — index outcomes | ✅ (FWER p ±0.01 ⚠️) | ✅ coef/SE/N/joint; FWER ⚠️ ≤0.03 | + Bonferroni/Holm/BH/Romano–Wolf |
| Table III — spillovers, Lee & H-M bounds | ✅ (Lee bootstrap SE ⚠️) | ✅ cols 1–6, 9–10, Lee point estimates; Lee SE ⚠️ | exact `leebounds.ado` port |
| Table IV — psychological wellbeing | ✅ 136/136 | ✅ 136/136 | |
| Table V — consumption | ✅ 103/103 | ✅ 103/103 | |
| Table VI — assets & business | ✅ 140/140 | ✅ 140/140 | |
| Table A.1 — MDEs | ✅ 60/60 | ✅ 60/60 | |
| OA §8.2 Lee bounds (attrition) | ✅ 32/32 | ✅ 32/32 (bounds + analytic SEs) | `sp.lee_bounds` itself differs slightly |
| OA §14 quantile effects | ✅ coef; bootstrap SE ⚠️ | ✅ 70/72 coef (2 ⚠️ ±0.01) | `sp.qreg` |
| Figure I (timeline) | n/a (drawn by hand) | n/a | |
| Other OA tables/figures (§5–19, 174 tex) | ✅ ran; identical or MC-only diffs | not re-implemented | see Results/Tables |
| Erratum | corrected numbers reproduced | corrected numbers reproduced; pre-erratum weighted psych row (0.11, 0.10, 0.11, 0.10) also reproduced | |

Details, cell by cell: [Results/comparison.md](Results/comparison.md).

## Reading Notes

| File | Audience | Content |
|---|---|---|
| [Cash Transfers Kenya (QJE 2016).md](<Materials/Cash Transfers Kenya (QJE 2016).md>) | Anyone curious about the paper | Question, GiveDirectly setting, two-level randomization, core equations, main findings tagged to tables, modern-methods reassessment |
| [论文模型解读与StatsPAI复现分析.md](Materials/论文模型解读与StatsPAI复现分析.md) | Researchers reproducing the paper | Equation-by-equation dissection, StatsPAI implementation, gaps, bugs, improvement suggestions |
| [Erratum](Materials/Erratum/) | Anyone citing Tables I–III | 2017 corrections (10,000 FWER iterations; unweighted psych spillovers; Lee bounds sample) |

## License

- **Reading notes and StatsPAI scripts in this repository** are released under the [MIT License](LICENSE).
- **The paper, online appendix and erratum** are the property of the authors / Oxford University Press (QJE).
- **The replication package** (data, do-files, bundled ados, shipped outputs) is by the paper's authors and governed by
  the Harvard Dataverse terms of doi:10.7910/DVN/M2GAZN; data are obtained from the official portal.
