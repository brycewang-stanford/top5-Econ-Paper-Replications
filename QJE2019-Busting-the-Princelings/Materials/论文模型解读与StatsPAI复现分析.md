# 《Busting the Princelings》模型解读与 StatsPAI 复现分析

> **论文**：Chen, Ting and James Kai-sing Kung (2019). "Busting the 'Princelings': The Campaign Against Corruption in China's Primary Land Market." *QJE*, 134(1): 185–226. DOI: [10.1093/qje/qjy027](https://doi.org/10.1093/qje/qjy027)
> **复现包**：Harvard Dataverse [doi:10.7910/DVN/XW6OJT](https://doi.org/10.7910/DVN/XW6OJT)（7 个 .dta，约 1.07 GB；1 个 `Tables&Figures.do`，14 KB）
> **环境**：Stata 18 MP（reghdfe 6.13.1、ftools、estout、coefplot）；Python 3.13 + StatsPAI 1.28.0（pyfixest 0.50.1 后端）
> **本文目的**：逐个方程拆解论文模型 → 说明原始代码怎样实现 → StatsPAI 怎样复现、差在哪里 → 记录 StatsPAI 的 bug 与改进建议。论文内容综述见 `Busting the Princelings (QJE 2019).md`。

---

## 目录

1. [复现包结构与图表映射](#1-复现包结构与图表映射)
2. [逐方程拆解](#2-逐方程拆解)
3. [原始代码运行结果](#3-原始代码运行结果)
4. [StatsPAI 复现细节](#4-statspai-复现细节)
5. [现代方法扩展（非复现）](#5-现代方法扩展非复现)
6. [StatsPAI bug 与 API 摩擦（含最小复现）](#6-statspai-bug-与-api-摩擦含最小复现)
7. [对 StatsPAI 的改进建议](#7-对-statspai-的改进建议)

---

## 1. 复现包结构与图表映射

`Tables&Figures.do` 的编号**与期刊不一致**（do 文件按工作稿编号）。以下映射由对照期刊全文确定：

| do 文件 | 期刊 | 数据 | 命令 |
|---|---|---|---|
| Table 3A | Table III 土地交易描述统计 | price | `tabstat`, `tab` |
| Table 3B | Table VII 官员变动描述统计 | province/prefecture_panel | `tabstat`, `tab` |
| Table 5 | **Table V** 太子党折扣 | price | `reghdfe … ab(6 FE) cluster(provid firmid) keepsin` |
| Table 6 | **Table VI** 买地数量 | firm_panel | `reghdfe … ab(year state size) cluster(firmid)` |
| Table 7 | **Table VIII** 省级官员晋升 | province_panel | `xi: oprobit … i.year i.provid`；`xi: reg` |
| Table 8 | **Table IX** 市级官员晋升 | prefecture_panel | 同上，`i.prefid` |
| Table 9 | **Table X** 运动后价格 | price | `reghdfe`，加 `pp1–pp4` |
| Table 10 | **Table XI** 运动后数量 | firm_prov_panel | `reghdfe … ab(provid year state size) cluster(provid firmid)` |
| Table 11 | **Table XII** 运动后晋升 | province + prefecture | `xi: oprobit` |
| Figure 4–7 | Figures IV–VII | figure4 / price / firm_panel / figure7 | `twoway`, `coefplot` |

期刊中的 Tables I、II（太子党与企业特征）和 Table IV（按用途的交易数与均价）**不在复现包中**：代码与数据都没有提供（Table IV 所需的用途大类不在 `price.dta` 中）。Online Appendix 表格也未提供。

---

## 2. 逐方程拆解

### 2.1 式 (1)：价格折扣（Table V、Table X、Figure V）

$$
\ln P_{ickst} = \beta_1 \text{Princeling}_{k} + \beta_2 (\text{Princeling}\times Z) + \gamma_1 \text{Quality}_i + \gamma_2 \ln \text{Area}_i + \alpha_{c\times y\times s} + \mu_{m} + \eta_{ind} + \theta_{sale} + \kappa_{state} + \rho_{size} + \nu
$$

| 组成 | 论文描述 | 代码实现 | 注意 |
|---|---|---|---|
| 城市×年×用途 FE | $T_{cst}$ | `cityyearusage`（34,949 组） | 嵌套于省份 → reghdfe 在 DoF 中视作冗余 |
| 月份、行业 FE | 表注"Month / Industry FE" | `month`、`ind`（148 类） | — |
| 出让方式、所有制、企业规模 | 表注"control variables" | 作为 **FE 吸收**（`salemethod state size`） | 与"控制变量"的写法等价 |
| $Z$ | PSCM、Retired、post2012、inspection、Xi-appointed、pre-2012 inspection | `pscm retired pp1 pp2 pp3 pp4`（**已是交互项**） | $Z$ 的主效应没有放入 |
| SE | 两维聚类：省 × 企业 | `cluster(provid firmid)` | 省只有 31–32 个簇 |
| singleton | — | `keepsin` | N = 1,144,507 与论文一致的前提 |
| 匹配样本 | ≤1,500 m / ≤500 m | `if near1500==1` / `if near500==1` | — |

**解读**：$\exp(-0.808)-1 = -55.4\%$，$\exp(-0.904)-1 = -59.5\%$（摘要中的 59.9% 与表内数字不完全对应，属于论文正文的舍入/引用问题）。

**Figure V**：`reghdfe lnprice pt3-pt13, ab(6 FE) cluster(provid firmid)`，其中 $pt_x = \text{princeling}\times\mathbb 1[\text{year}=2003+x]$。**不含** princeling 主效应，也**不含** quality、lnarea。2004–05 年的太子党交易构成基期（2004 年无有效价格），因此系数是相对 2005 年的折扣水平，而不是"运动效应"。

### 2.2 数量方程（Table VI、Table XI、Figure VI）

$$
\text{lnarea}_{kt} = \beta\,\text{Princeling}_k [+\ \beta_2 \text{PSCM/Retired}] + \lambda_t + \kappa_{state} + \rho_{size} + \varepsilon,\qquad \text{cluster}(firm)
$$

$$
\text{lnarea}_{kpt} = \beta_1 \text{Princeling}_k + \beta_2 \text{PP1} + \delta\,\text{Inspection}_{pt} + \beta_3 \text{PP2} + \xi\,\text{XiAssign}_{pt} + \beta_4 \text{PP3} + \pi_p + \lambda_t + \kappa + \rho,\ \text{cluster}(prov, firm)
$$

- `lnarea` 在两个面板里是 **面积/10⁶ m²**，不是对数（Manso 2026）。
- Table VI 表注写有行业 FE，代码中没有。
- Table XI 代码写的是 `xi`，数据中的变量名是 `xi_assign`，靠 Stata 的**变量名缩写**才能运行（`set varabbrev off` 时会报错）。Python 端必须显式改名。

### 2.3 式 (2)：晋升（Tables VIII、IX、XII）

$$
\Pr(\text{Turnover}_{it}=j) = \Phi(\kappa_j - X_{it}'\phi) - \Phi(\kappa_{j-1} - X_{it}'\phi),\quad j\in\{0,1,2,3\}
$$

$X_{it}$：Princeling purchase（或 discount / area）、派系关系、GDP 增长、税收增长、log 人均 GDP、log 人口、年龄、年龄²、受教育年限、年份哑变量、省（市）哑变量。

| 细节 | 表注 | 代码 |
|---|---|---|
| SE | "Robust standard errors" | **OIM**（`oprobit` 默认，没有 `vce(robust)`） |
| 市级 FE | "Province fixed effects" | `i.prefid`（地级市 FE） |
| 样本期 | 2004–2016 | 地级市面板实际只到 2014（Wiebe 2024） |
| Table XII 第 11 列 | 控制变量同其他列 | **漏掉 `ties`**（do 文件笔误，照原样复现） |
| Table VIII/IX 第 2 列 | — | `lnpop` 写了两次（无影响） |

Table XII 的交互：$\text{PP}\times\text{post2012}$、$\text{PP}\times\text{inspection}$，以及 discount (PD)、area (ALP) 的对应交互；post2012 或 inspection 主效应放入模型，但在 esttab 中被 drop。

---

## 3. 原始代码运行结果

`Program/run_original.do` 把 do 文件按 `*Table N*` / `*Figure N*` 标记切成 13 步，每步 `capture` 运行，记录 rc 与秒数（`Results/run_original_steps.csv`）。

**对作者代码的修改（全部在 wrapper 中自动完成，原文件未改）**

1. 删除 `cd "D:\Dropbox\princeling\"`。
2. `use X.dta` → `use "$DATA/X.dta"`。
3. `graph save Graph "f.gph"` → `graph save Graph "$FIG/f.gph", replace`；`graph combine` 的路径同样处理。
4. **Table 11 的 esttab**：`drop(… _cons)` 在全部为 oprobit 的表中会报 `r(111) coefficient _cons not found`（当前 estout 版本对 drop 不存在的系数报错），wrapper 删去这一个 `_cons` 标记。其他表都含 `reg` 列（有 `_cons`），不受影响。
5. wrapper 自身的注意点：作者每步开头的 `clear all` 会关闭文件句柄，所以步骤日志改为每步追加写入。

其余小问题不影响运行：`coefplot … lpattern(solild)` 拼写错误，Stata 只给 note；`xi:` 前缀对 reghdfe 无作用。

结果：**13/13 步 rc=0**，所有回归表与期刊逐位一致（见 `Results/comparison.md`）。

---

## 4. StatsPAI 复现细节

### 4.1 价格表（Table V、X；Figure V）——`sp.feols`

```python
sp.feols("lnprice ~ princeling + pscm + quality + lnarea | cityyearusage + ind + month + salemethod + state + size",
         data=s, vcov={"CRV1": "provid + firmid"})
```

- pyfixest 默认 `fixef_rm="none"`（保留 singleton）= `keepsin`，N 一致。
- 两维聚类的小样本校正与 reghdfe 一致（嵌套 FE 的 DoF 处理也一致）。
- 结果：**Table V 15/15、Table X 24/24 个系数+SE 单元格 在三位小数上与论文一致**；Figure V 11 个系数与 Stata 日志一致。全样本每列约 55–85 秒，匹配样本 5–13 秒。

### 4.2 数量表（Table VI、XI；Figure VI）

- Table VI（5.69M obs）：`sp.feols(…, vcov={"CRV1": "firmid"})`，5/5 一致，但**峰值内存 12.4 GB**。
- Table XI（11.5M obs）：如果继续用 `sp.feols`，预计超过 24 GB，所以改用 StatsPAI 原生的 `sp.hdfe_ols`：

```python
sp.hdfe_ols("lnarea ~ princeling + pp1 | provid + year + state + size", data=d,
            cluster=["provid", "firmid"], drop_singletons=False)
```

  **14/14 一致**，4 列合计 90 秒，峰值 5.4 GB。先在 Table V 第 3 列上验证过：`hdfe_ols` 与 reghdfe 的系数、两维聚类 SE、嵌套 FE DoF、adj. R² 完全相同（−0.8440 / 0.0327 / 0.755），而且比 `sp.feols` 快约 5–20 倍。

### 4.3 晋升表（Tables VIII、IX、XII）——`sp.oprobit`

```python
X = s[xs].join(dummies(s, ["year", unit]))          # 手工构造 i.year i.unit
keep = drop_collinear(X, keep_first=xs)            # 按列序贪心剔除共线列（模拟 xi + oprobit）
XX[c] = XX[c] / sd[c] for c in xs                  # 标准化实质性回归元
r = sp.oprobit(data=..., y="promote", x=keep, maxiter=1000)
b, se = r.params[c] / sd[c], r.std_errors[c] / sd[c]   # 反变换（精确）
```

LPM 列：`sp.feols("promote1 ~ … | year + provid", vcov="iid")`，与 `reg … i.year i.provid` 完全等价（系数、SE、adj. R² 均一致）。

**关键发现**：直接把原始尺度的回归元（age² ≈ 3,500）交给 `sp.oprobit` 时，BFGS 在 `maxiter=100` 或精度极限处提前停止，系数在第三位小数偏离（Table VIII 第 2 列 0.7397 vs Stata 0.742）。把 `maxiter` 提高到 2000 也没有用；**标准化**之后得到 0.7422，与 Stata 一致。

结果：

- Table VIII：34 个单元格中 32 个在三位小数上一致；另外 2 个 SE 差 ≤ 0.001（有限差分 Hessian 的精度）。
- Tables IX、XII：见 §4.4。

**速度**：省级（k≈50，N≈400）每个模型 10–25 秒；地级市（k≈300，N≈2,700）每个模型 **20–50 分钟**（Stata < 1 秒），Tables IX + XII 必须 3 进程并行跑数小时。

### 4.4 地级市有序 probit 结果（Tables IX、XII）

（运行结束后填入，见下文更新。）

---

## 5. 现代方法扩展（非复现）

详见 `Results/statspai/modern_*` 与阅读笔记 §7.2。要点：

| 分析 | 函数 | 结果 |
|---|---|---|
| 省×年价差面板（301 格）× 习任命书记（交错：2013/14/15/16，7 省从未处理） | `sp.feols` TWFE | 0.290 (0.066) |
| Goodman-Bacon 分解（2007–2016 平衡面板，18 省） | `sp.bacon_decomposition` | TWFE 0.215；处理 vs 从未处理 63% 权重、均值 0.254；早 vs 晚 28%、0.135；晚 vs 早（已处理对照）9%、0.184 |
| Callaway–Sant'Anna | `sp.callaway_santanna` + `sp.aggte(type="dynamic")` | 简单加总 0.330 (0.093)，动态加总 0.364 (0.107)；处理前系数都不显著 |
| Sun–Abraham | `sp.sun_abraham` | 0.310 (0.119) |
| BJS 插补 | `sp.did_imputation` | 0.267 (0.068) |
| HonestDiD（CS，e=0，RM） | `sp.honest_did` | M̄=0：[0.18, 0.60]；M̄=0.5：[−0.005, 0.78] |
| Figure V 以 2012 为基期 + HonestDiD | `sp.feols` + 手工 `CausalResult` + `sp.honest_did` | e=3（2016）在 M̄=2 时仍显著；e=0 在 M̄=0.5 时失去显著性 |
| Roth (2022) 前趋势检验力 | `sp.pretrends_power` | 逐期检验 44%，联合检验 15% |
| Wild cluster bootstrap（省簇，999 次） | `sp.feols(vcov="wild", cluster="provid")` | 见 `modern_wild_cluster_bootstrap.csv` |

**结论**：论文"习任命书记使太子党折扣缩小"的结论在异质性稳健估计量下同向且更大（TWFE 被"早 vs 晚"比较向下拉）；Figure V 的长期效应对平行趋势违反稳健，2013 年的即时效应则不稳健。

---

## 6. StatsPAI bug 与 API 摩擦（含最小复现）

### Bug 1：`sp.callaway_santanna` 在非平衡面板下忽略 `control_group="notyettreated"`

```python
import numpy as np, pandas as pd, statspai as sp
rng = np.random.default_rng(0); rows = []
coh = {**{i: 4 for i in range(30)}, **{i: 6 for i in range(30, 60)}, **{i: 0 for i in range(60, 90)}}
for i, g in coh.items():
    a = rng.normal()
    for t in range(1, 9):
        te = (1 + (t - g)) if (g > 0 and t >= g) else 0
        rows.append(dict(i=i, t=t, g=g, y=a + (0.3*t if g == 0 else 0) + te + rng.normal(scale=.5)))
df = pd.DataFrame(rows); un = df.drop(df.sample(frac=0.1, random_state=1).index)
for d in (df, un):
    a = sp.callaway_santanna(d, y="y", g="g", t="t", i="i", estimator="reg", control_group="nevertreated", allow_unbalanced_panel=True)
    b = sp.callaway_santanna(d, y="y", g="g", t="t", i="i", estimator="reg", control_group="notyettreated", allow_unbalanced_panel=True)
    print(a.estimate, b.estimate)
# 平衡：1.804 vs 1.8614（正确，不同）；非平衡：1.932 vs 1.932（错误，完全相同）
```

`model_info["control_group"]` 仍显示 `notyettreated`，但非平衡路径实际使用的是从未处理组。本项目的省×年价差面板中，两种设定的 ATT(g,t) 表逐元素相同。

### Bug 2：`sp.callaway_santanna` 把"无可用对照"的 ATT(g,t) 记为 0、SE=inf，并纳入加总

```python
d2 = df[df.g > 0]      # 只有 g=4、g=6 两个队列，无从未处理组
c = sp.callaway_santanna(d2, y="y", g="g", t="t", i="i", estimator="reg", control_group="notyettreated")
c.detail.head(6)       # (g=4, t=6)、(g=4, t=7) : att=0.000, se=inf
c.estimate             # 0.35（真实 ATT ≈ 2），被这些 0 拉低
```

在本项目中，以"首次中央巡视年份"为队列（2013 vs 2014，几乎没有从未处理省）时，整体估计直接返回 ATT=0、SE=0、p=1。R `did` 会把这些 ATT(g,t) 设为 NA 并在 `aggte` 中剔除。

### Bug 3：`sp.oprobit` 优化器提前停止且收敛标志不可靠

- 实现（`regression/multinomial.py::_ordered_model`）：`scipy.optimize.minimize(method="BFGS", options={"maxiter": 100, "gtol": 1e-8})`，**没有解析梯度**（有限差分）；Hessian 用数值差分。
- 复现：Table VIII 第 2 列（N=380，k=50，原始尺度回归元）→ princeling 0.7397，Stata 0.742；`maxiter=2000` 仍为 0.7397（`converged=False`）；标准化后 0.7422。同一次运行中，标准化后已收敛到正确似然（−166.2162），标志却仍是 `False`；而第一次默认参数运行时标志为 `True`，系数却是错的。
- 建议：解析 score 与 Hessian（有序 probit 都有闭式），用 Newton-Raphson / BHHH；内部自动标准化；收敛判据用相对梯度或对数似然变化。

### 摩擦 4：`sp.oprobit` 极慢（k≈300）

地级市模型 20–50 分钟/个（Stata `oprobit` < 1 秒）。原因：有限差分梯度（每步 k 次似然计算）+ 数值 Hessian + 逐变量 Brant 检验循环。建议提供 `absorb=`/`fe=` 参数，或至少提供 `brant=False` 开关与解析导数。

### 摩擦 5：`sp.oprobit` 公式不支持因子项

`sp.oprobit("promote ~ princeling + C(year) + C(provid)", data=s)` → `KeyError: "['C'] not in index"`，只能手工构造哑变量。

### 摩擦 6：`sp.regress` 遇到共线哑变量直接报错

`sp.regress("promote1 ~ … + C(year) + C(provid)", data=s)` → `NumericalInstability: Regressor 'C(provid)[T.54.0]' is constant (no variation)`。Stata `reg` 会自动 omit。复现时改用 `sp.feols(… | year + provid, vcov="iid")`。

### 摩擦 7：`sp.feols` 内存占用大，且没有提示 `sp.hdfe_ols`

5.69M obs × 3 FE、一维聚类：`sp.feols` 峰值 12.4 GB、18 秒；`sp.hdfe_ols` 1.9 秒、内存很小，结果完全相同。11.5M obs 的 Table XI 只能用 `hdfe_ols`。建议在文档或 `sp.feols` 中根据 N 给出提示，或统一后端。

### 摩擦 8：结果对象缺少 N / adj. R²

- `sp.feols` 返回的 `EconometricResults`：`diagnostics` 只有 R² 与 within R²，没有 adjusted R²；N 只在 `data_info["nobs"]` 中，没有顶层属性（`r.nobs` 不存在）。
- `sp.hdfe_ols` 返回的 `FEOLSResult`：只有 `r2_within`，没有总体 R²/adj. R²。
- 本项目用残差和 `df_resid` 手算。建议两者都提供 `r2`, `r2_adj`, `nobs`，与 `e(r2_a)` 对齐。

### 摩擦 9：`sp.honest_did` 只接受 `CausalResult`，无 (betahat, sigma) 接口

对 `reghdfe`/`feols` 得到的事件研究系数，必须手工构造 `sp.CausalResult(model_info={"event_study": df})`；这时联合协方差不可得，只能按对角协方差处理（忽略事件研究系数之间的相关）。R `HonestDiD::createSensitivityResults_relativeMagnitudes(betahat, sigma, …)` 直接接收向量和协方差矩阵。建议增加 `sp.honest_did_from_moments(beta, sigma, num_pre, num_post)`，并让 `sp.feols` 事件研究结果携带 vcov。

### 摩擦 10：`sp.bacon_decomposition` 只接受严格平衡面板

非平衡时抛 `MethodIncompatibility: Unbalanced Panel`，需要用户自己挑选平衡窗口。建议提供 `balance="drop_units"` 选项并报告丢弃了多少。

### 其他

- `sp.feols` 对全零回归元（`pt_2004`：2004 年没有有效价格的太子党交易）静默删除，params 中不再出现该变量；建议给 warning。
- `sp.feols(vcov="wild", cluster=…)` 可用（192k obs、6 FE、999 次，约 170 秒），CI 与 p 值合理。

---

## 7. 对 StatsPAI 的改进建议

| 优先级 | 建议 | 涉及 |
|---|---|---|
| P0 | 修复 CS 非平衡面板忽略 not-yet-treated；无对照的 ATT(g,t) 设为 NaN 并从加总中剔除 | `did/callaway_santanna` |
| P0 | `oprobit/ologit`：解析梯度 + Newton，自动标准化，可靠的收敛判据；收敛失败时发出 warning | `regression/multinomial.py` |
| P1 | `oprobit` 支持 `C()` 因子项与 FE 吸收参数；关闭 Brant 检验的开关 | 同上 |
| P1 | `regress` 对共线列自动 omit（与 Stata 一致）并报告 | `regression/ols` |
| P1 | `feols` 与 `hdfe_ols` 统一输出 `nobs / r2 / r2_adj`；大 N 时提示或自动切换到 `hdfe_ols` | `panel/feols`、`fixest` 包装 |
| P2 | `honest_did` 增加 (beta, sigma) 接口；`feols` 事件研究保留 vcov | `did/honest_did.py` |
| P2 | `bacon_decomposition` 提供自动平衡选项 | `did/bacon` |
| P2 | 删除全零/共线回归元时给出 warning | `feols` |
