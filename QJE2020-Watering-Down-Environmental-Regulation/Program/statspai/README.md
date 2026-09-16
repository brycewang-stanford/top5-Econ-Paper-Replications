# StatsPAI re-implementation

Python re-implementation of every main-text exhibit of He, Wang & Zhang (2020, QJE) with
[StatsPAI](https://github.com/brycewang-stanford/StatsPAI) 1.28.0.

## Run order (from the project root)

```bash
# 0. original package (needed for Table II's mdrd bandwidths)       ~37 min
/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do Program/run_original.do && mv run_original.log Results/
# 1. per-cell e() export of every rdrobust call in the author's code  ~1 min
/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do Program/statspai/export_stata_estimates.do && mv export_stata_estimates.log Results/statspai/
# 2. StatsPAI replication + extensions                                 ~1 min
python3.13 Program/statspai/replicate_statspai.py
# 3. paper vs Stata vs StatsPAI table -> Results/comparison.md
python3.13 Program/statspai/build_comparison.py
```

Step 2 runs without steps 0–1 except for Table II (needs `mdrd`'s bandwidths from
`Results/run_original.log`) and the bandwidth fallback for one cell.

## Files

| file | role |
|---|---|
| `replicate_statspai.py` | Tables I, III–VII (159 `rdrobust` cells + 11 published-spec variants), Table II (diff-in-disc), Table VIII (cost calculation), Figures IV–V, modern-method extensions |
| `export_stata_estimates.do` | re-runs every author `rdrobust` call and posts `e()` to `Results/statspai/stata_estimates.csv` (outreg2 text output drops columns and rounds) |
| `build_comparison.py` | paper values (transcribed from the PDF) vs Stata vs StatsPAI → `Results/comparison.md` |
| `comparison_notes.md` | explanations inserted into `comparison.md` |

## Specification mapping

| paper / author code | StatsPAI |
|---|---|
| `rdrobust y distance_new if …, masspoints(off) kernel(tri\|epa\|uni) all vce(cluster site_id)` | `sp.rdrobust(df, y, x='distance_new', kernel=…, cluster='site_id', h=…, b=…)` |
| conventional coefficient + conventional cluster SE (reported) | `model_info['conventional']` |
| bias-corrected coefficient (Table III pre-2003, Table II) | `model_info['robust']['estimate']` |
| MSE-optimal bandwidth with `masspoints(off)` | **not available** in `sp.rdbwselect`/`sp.rdrobust` → h, b from the official rdpackages Python port `rdrobust.rdbwselect(..., masspoints='off')` (Stata `e(h_l,h_r,b_l,b_r)` as fallback) |
| `mdrd y x, time(post03) all kernel(k)` (Ribas) | no diff-in-disc estimator → `sp.rdrobust` on post03 = 1 and post03 = 0 with mdrd's (h, b); difference of estimates, SE = √(V₁+V₀) |
| `rdplot … p(3) kernel(uni) nbins(7 7) ci(90)` after `winsor2 … cuts(0.5 99.5) trim` | `sp.rdplot(p=3, kernel='uniform', nbins=7, ci_level=0.90)` after Stata-percentile trimming |
| Table VIII Excel | Python replay of the spreadsheet; MRS = (1−e^{−β_TFP})/(1−e^{−β_COD})/157.4 per 1 % COD (constant 1.574 implied identically by all six spreadsheet columns) |

## Results in brief

* With the author's bandwidth, StatsPAI equals Stata in **100 % of 170 RD cells** (b and SE, relative tolerance 1e-5; typical difference 1e-8).
* With StatsPAI's native (mass-point-adjusted) bandwidth, headline numbers move (Table I Panel A col 1: 0.23 vs 0.34; Panel B col 1: 0.364 vs 0.365).
* Table II diff-in-disc: StatsPAI composition reproduces `mdrd` point estimates to 4 decimals.

## StatsPAI issues found (details + minimal repros in `Materials/论文模型解读与StatsPAI复现分析.md`)

1. `sp.rdrobust(cluster=…)` crashes with `IndexError: boolean index did not match` when `y` has missing values (cluster vector not filtered with the NaN mask).
2. No `masspoints` option in `sp.rdrobust` / `sp.rdbwselect`; the adjustment is always applied.
3. `h`/`b` typed `Tuple[float, float]` but the validator rejects tuples (`MethodIncompatibility: h must be a finite number`) — asymmetric bandwidths cannot be passed (patched in-script).
4. `import statspai.rd.rdrobust` returns the re-exported function, not the module (name shadowing).
5. `sp.rd_honest`, `sp.rdbwsensitivity`, `sp.rdplacebo` have no `cluster` argument.
6. No difference-in-discontinuities estimator (Grembi–Nannicini–Troiano / `mdrd`).
