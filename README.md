# top5-Econ-Paper-Replications

Replications and model walkthroughs of papers from top economics journals.

Each paper folder follows the same layout: `Data/` (the replication package's data), `Program/` (the authors' code plus `run_original.*` wrappers and a `statspai/` Python re-implementation), `Results/` (regenerated output and `comparison.md`), and `Materials/` (paper, package README, and two Chinese notes: a reading note and `论文模型解读与StatsPAI复现分析.md`).

## Projects

| Project | Paper | Design | Original code | StatsPAI re-implementation |
|---|---|---|---|---|
| [AER2022-Rebel-on-the-Canal](https://github.com/brycewang-stanford/AER2022-Rebel-on-the-Canal) | Cao & Chen, *Rebel on the Canal* (AER 2022) | DID, Conley SE | Main Tables 1–7 match | Reading note + reproduction skeleton |
| [AER2013-China-Syndrome](AER2013-China-Syndrome/) | Autor, Dorn & Hanson, *The China Syndrome* (AER 2013) | Shift-share 2SLS | 5/5 do-files run; tables identical to the authors' 2013 logs | 360/381 published cells ✅; misses are rounding or package-vs-print vintage |
| [QJE2016-Cash-Transfers-Kenya](QJE2016-Cash-Transfers-Kenya/) | Haushofer & Shapiro, *Unconditional Cash Transfers* (QJE 2016) | Two-level RCT, FWER, Lee bounds | 37/37 steps; 153/183 tables byte-identical, rest differ only in random draws | Tables I–VI, A.1 all cells match (erratum version) |
| [QJE2019-Busting-the-Princelings](QJE2019-Busting-the-Princelings/) | Chen & Kung, *Busting the "Princelings"* (QJE 2019) | HDFE DID, ordered probit | 13/13 exhibits; 150/150 regression cells | 307/314 cells ✅; 7 oprobit cells off ≤0.0016 |
| [QJE2019-Kinship-Cooperation-Moral-Systems](QJE2019-Kinship-Cooperation-Moral-Systems/) | Enke, *Kinship, Cooperation, and the Evolution of Moral Systems* (QJE 2019) | Cross-sectional OLS + FE | 12/12 steps; all coefficients and N match | 87 ✅ / 7 ⚠️ (unseeded bootstrap SEs) / 0 ❌ |
| [QJE2019-Minimum-Wages-Low-Wage-Jobs](QJE2019-Minimum-Wages-Low-Wage-Jobs/) | Cengiz, Dube, Lindner & Zipperer, *The Effect of Minimum Wages on Low-Wage Jobs* (QJE 2019) | Stacked event study / bunching | Tables 2–4 identical to shipped; Figures 2–6 rebuilt; see project README for Table 1 | Tables 1–4 and Figures 2–4: 167 ✅ / 0 ❌ |
| [QJE2020-Watering-Down-Environmental-Regulation](QJE2020-Watering-Down-Environmental-Regulation/) | He, Wang & Zhang, *Watering Down Environmental Regulation in China* (QJE 2020) | Spatial RD, diff-in-disc | 10/10 exhibits; 148/171 cells exact, 8 non-headline cells unmatched | 170/170 RD cells equal Stata at the authors' bandwidths |
| [QJE2023-AI-tocracy](QJE2023-AI-tocracy/) | Beraja, Kao, Yang & Yuchtman, *AI-tocracy* (QJE 2023) | Event study, weather IV, LASSO IV | 20/21 sections; Tables I–III, V A, VIII, IX A exact; VI/VII/IX B–C not digit-identical (random tie-breaking in `collapse`) | 166/181 rows exact; LASSO-IV panels approximated |
| [QJE2023-Web-of-Power](QJE2023-Web-of-Power/) | Bai, Jia & Yang, *Web of Power* (QJE 2023) | Continuous-treatment DID, Conley SE, IV | 31/31 do-files; appendix identical to authors' outputs | 75/75 table cells equal the Stata rerun |
| [2025-ML-Causal-Review](2025-ML-Causal-Review/) | Review of machine-learning methods for causal inference | — | — | Figure scripts |

Each project's `Results/comparison.md` lists paper vs original code vs StatsPAI number by number, with every mismatch explained.

## StatsPAI findings

[StatsPAI复现问题汇总.md](StatsPAI复现问题汇总.md) consolidates the StatsPAI bugs, gaps, and API friction found across the eight replications, ordered by severity (silent wrong results first), with pointers to minimal reproductions in each project.

## Data sources

Packages were downloaded from Harvard Dataverse (QJE) and the authors' public archive (ADH). Each project's `Data/README.md` gives the DOI, license, file checksums, and the exact download commands.

## Clone

```bash
git clone --recurse-submodules https://github.com/brycewang-stanford/top5-Econ-Paper-Replications.git
```
