# StatsPAI re-implementation

StatsPAI 1.28.0 (`import statspai as sp`) under `/usr/local/bin/python3.13`. All scripts read the original
`.dta` files in `Data/` and write to `Results/statspai/`.

```bash
cd Program/statspai
python3.13 replicate_statspai.py                 # everything, then Results/comparison.md
python3.13 replicate_statspai.py price compare   # a subset
```

| Script | Exhibits | StatsPAI call (Stata original) | Runtime |
|---|---|---|---|
| `rep_descriptive.py` | Table VII, Figures IV, VII | pandas / matplotlib (`tabstat`, `twoway`) | seconds |
| `rep_price.py` | Tables III, V, X; Figure V | `sp.feols("lnprice ~ … \| cityyearusage + ind + month + salemethod + state + size", vcov={"CRV1": "provid + firmid"})` (`reghdfe …, cluster(provid firmid) keepsin`) | ~12 min |
| `rep_firm.py` | Table VI, Figure VI | `sp.feols(…, vcov={"CRV1": "firmid"})` | ~1 min, 12 GB RAM |
| `rep_firm.py` | Table XI (11.5M obs) | `sp.hdfe_ols(…, cluster=["provid", "firmid"], drop_singletons=False)` | minutes |
| `rep_promotion.py` | Tables VIII, IX, XII | `sp.oprobit(data, y, x=[…, year & unit dummies])` (`xi: oprobit … i.year i.provid`); LPM columns `sp.feols(… \| year + unit, vcov="iid")` (`xi: reg …`) | VIII ~2 min; IX + XII hours (3 worker processes) |
| `oprobit_fast.py` | Tables VIII, IX, XII cross-check (**not StatsPAI**) | analytic-score Newton ordered probit; ≤0.75 s per model vs 20–50 min for `sp.oprobit` | seconds |
| `modern_did.py` | **Extensions** (not replication) | `sp.bacon_decomposition`, `sp.callaway_santanna` + `sp.aggte`, `sp.sun_abraham`, `sp.did_imputation`, `sp.honest_did`, `sp.pretrends_power`; `python3.13 modern_did.py wcb` → wild cluster bootstrap `sp.feols(vcov="wild")` | ~3 min (+ WCB 15–45 min) |
| `make_comparison.py` | `Results/comparison.md` | parses `Results/Tables/*.csv` (esttab) + StatsPAI CSVs + `paper_values.py` | seconds |
| `check_vs_paper.py` | quick check of one StatsPAI CSV vs paper | — | seconds |

Implementation notes

* **Singletons.** reghdfe is run with `keepsingletons`; `sp.feols` keeps singletons by default (`fixef_rm="none"`) and `sp.hdfe_ols` needs `drop_singletons=False`. Ns then match the paper exactly.
* **Two-way clustering.** `vcov={"CRV1": "provid + firmid"}` (pyfixest) and `sp.hdfe_ols(cluster=[…])` both reproduce reghdfe's CGM two-way SEs, including the nested-FE degrees-of-freedom rule (city-year-usage nested in province).
* **Ordered probit.** `sp.oprobit` has no formula support for factor terms, so year and unit dummies are built by hand. Collinear dummies are dropped greedily in column order, as Stata's `xi` + `oprobit` does. The substantive regressors are standardized before fitting and the coefficients and SEs back-transformed, because the default BFGS with finite-difference gradients stops early on the raw scale (age² ≈ 3,500). See the gap list in `Materials/论文模型解读与StatsPAI复现分析.md`.
* **Table XII cols 10 and 12** enter `post2012` (not `inspection`) as the main effect next to `alp2`. This is a do-file quirk, reproduced on purpose.
* **Adjusted R².** `sp.feols` results expose only R² and within-R². Adjusted R² is computed as `1-(1-R²)(N-1)/(N-K-df_FE)`. For `sp.hdfe_ols` it comes from residuals and `df_resid`.
* **`lnarea` in the firm panels** is area/10⁶ m², not a logarithm (Manso 2026). It is replicated as coded.
