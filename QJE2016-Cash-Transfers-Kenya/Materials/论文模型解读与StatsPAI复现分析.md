# 《The Short-Term Impact of Unconditional Cash Transfers》模型解读与 StatsPAI 复现分析

> **论文**：Haushofer, Johannes and Jeremy Shapiro (2016). "The Short-Term Impact of Unconditional Cash Transfers to the Poor: Experimental Evidence from Kenya." *QJE* 131(4): 1973–2042. DOI: [10.1093/qje/qjw025](https://doi.org/10.1093/qje/qjw025)；勘误 2017-04-22。
> **复现包**：Harvard Dataverse doi:10.7910/DVN/M2GAZN（Stata 13.1 代码 + 自带 ado）
> **复现环境**：Stata 18 MP；Python 3.13 + statspai 1.28.0（内部调用 pyfixest）
> **本文目的**：逐个方程拆解论文的估计量与推断，说明 StatsPAI 如何（以及在哪里无法）复现，记录 StatsPAI 的缺口与 bug。

---

## 目录

1. [数据结构与样本标志](#1-数据结构与样本标志)
2. [逐方程拆解](#2-逐方程拆解)
3. [StatsPAI 实现细节](#3-statspai-实现细节)
4. [复现结果汇总](#4-复现结果汇总)
5. [StatsPAI 缺口、bug 与 API 摩擦](#5-statspai-缺口bug-与-api-摩擦)
6. [现代方法扩展](#6-现代方法扩展)
7. [对 StatsPAI 的改进建议](#7-对-statspai-的改进建议)

---

## 1. 数据结构与样本标志

`UCT_FINAL_CLEAN.dta`：2,880 行 = 1,440 户 × {主女, 主男}；981 个变量。关键变量：

| 变量 | 含义 |
|---|---|
| `treat` / `spillover` / `purecontrol` | 处理户 / 处理村对照户 / 纯对照村户（1006 / 1010 / 864 行） |
| `maleres` | 男性受访者行；**户层面结果只用 `maleres==0` 行**，个人层面（心理）用两行 |
| `treatXfemalerecXmarried`, `treatXsinglerec` | 双亲户妻子收款 / 单亲户收款（省略组 = 双亲户丈夫收款） |
| `treatXmonthlyXsmall`, `treatXlumpXsmall`, `treatXlarge` | 小额月付 / 小额一次性 / 大额 |
| `<y>0`, `<y>1` | 基线 / 终线结果 |
| `<y>_full0`, `<y>_miss0` | 基线值（缺失置 0）/ 基线缺失指示 |
| `asset_niceroof1`, `asset_valroof_ppp1` | 终线铁皮屋顶 / 屋顶价值（溢出表中从资产中扣除） |

所有变量构造在 Dataverse 之外完成，分析 do-file 只做样本标志：`drop if purecontrol==1`、`drop if endlinedate==.`、`include=0 if maleres==1`（心理指数除外）。Python 端逐行复刻（`uct_common.py`）。

> **pyreadstat 注意**：含缺失的整数列（如 `psy_cesdscore1`）会被读成 `object`，pyfixest 报 "dependent variable must be numeric"；`load()` 中统一 `pd.to_numeric`。

## 2. 逐方程拆解

### 2.1 基线平衡（式 1，Table I）

$$y_{vhB}=\alpha_v+\beta_1T_{vh}+\varepsilon,\quad \text{cluster}=h$$

Stata：`areg y0 treat if include, absorb(village) cluster(surveyid)`；列 3–5 分别换成臂变量并加 `spillover`（以及 `treatXsinglerec`/`treatXlarge`）。

- **列 1 控制组均值**：`sum y0 if spillover`（注意：基线表**不**限 `include`，但心理指数外 `y0` 已在男性行缺失）。
- **FWER**：`stepdown reg (y1..y8) treat fev*, options(cluster(surveyid)) iter(10000)`。
- **联合检验**：8 个方程 `reg y treat fev*`（无聚类）→ `suest ..., cluster(surveyid)` → `test treat`（跨方程 χ²(8)）。

### 2.2 主处理效应（式 2，Table II/IV/V/VI）

$$y_{vhiE}=\alpha_v+\beta_1T_{vh}+\delta_1\tilde y_{vhiB}+\delta_2M_{vhiB}+\varepsilon$$

`areg y1 treat y_full0 y_miss0, absorb(village) cluster(surveyid)`。当 `y_miss0` 全为 0（资产、消费等）时 Stata 自动 omit；pyfixest 同样剔除并给出 multicollinearity 警告。

臂比较（列 3–5）：

| 列 | 回归元 | 报告系数 | 含义 |
|---|---|---|---|
| 3 | `treatXfemalerecXmarried treatXsinglerec spillover` | `treatXfemalerecXmarried` | 妻子 − 丈夫收款（双亲户） |
| 4 | `treatXmonthlyXsmall treatXlarge spillover` | `treatXmonthlyXsmall` | 月付 − 一次性（小额户） |
| 5 | `treatXlarge spillover` | `treatXlarge` | 大额 − 小额 |

注意这些回归**没有**单独的 `treat`：省略组是"处理户中的参照臂"，而 `spillover` 吸收对照户。

### 2.3 FWER：作者的置换 stepdown（`Program/Ado/stepdown.ado`）

算法（与 Romano-Wolf 的 bootstrap 版不同）：

1. 对每个结果 $k$ 回归得 $|t_k|$，实际 p 值 $p_k=2\,\text{ttail}(N,|t_k|)$（注意自由度用 N 而非 G−1）。
2. 每次迭代：对**内存中每一行**抽 $U\sim U(0,1)$，安慰剂处理 $\tilde T=\mathbf 1[U\le \bar T]$（$\bar T$ 是变量 `treat` 的均值，即使被检验的是臂变量）；把被检验回归元换成 $\tilde T$，其余回归元不变，重跑全部 $K$ 个回归得 $\tilde p_k$。
3. 按实际 p 值升序排列，从最大者开始取后缀最小值 $\tilde p^{\min}_k=\min_{j\ge k}\tilde p_j$，计数 $\tilde p^{\min}_k\le p_k$。
4. 调整 p = 计数/迭代数，强制单调并还原顺序。

这是 Westfall-Young (1993) free step-down 的置换版本：注意安慰剂分配**不按村分层**、也**不按户捆绑男女两行**（心理指数的两行会得到不同安慰剂处理）——属于作者实现的近似。

### 2.4 联合 SUR 检验

`suest` 把各方程的得分按聚类求和，得跨方程三明治方差 $\hat V=\frac{G}{G-1}\sum_g s_g s_g'$，然后 Wald χ²。不同方程的样本可不同（教育、女性赋权、心理指数 N 不同），`suest` 在未进入某方程的观测上得分为 0。

### 2.5 溢出（式 10，Table III）

$$y_{vhiE}=\beta_0+\beta_1S_{vh}+[\gamma'X_{vh}]+\varepsilon,\quad\text{cluster}=v$$

- 列 1–2：全部非处理户（资产中扣除铁皮屋顶价值）；列 3–4：去掉终线铁皮屋顶户；列 2/4 加 `b_age b_married b_children b_hhsize b_edu`。
- 列 5–6：`suest spec1 spec3, cluster(village)` 后检验两列 $\beta_1$ 相等。
- 列 7–8 **Lee 界**：在数据后追加 5 行（心理指数 10 行）`spillover=1, y=.` 的"虚拟流失户"，代表因溢出而升级屋顶、被排除的户；`leebounds y spillover, vce(bootstrap, reps(100))`。因为溢出组"保留率"更低，被修剪的是**纯对照组**。
- 列 9–10 **Horowitz-Manski**：用观测到结果的 5%/95% 分位数填补虚拟户，再 `reg, r`。

### 2.6 Lee 界的实现细节（`leebounds.ado`）

修剪比例 $q=(s_1-s_0)/s_1$；上界 = 保留组（被修剪组）去掉最低 $q$ 份额后的均值 − 另一组均值，下界反之。作者的 ado 有两个影响数值的实现细节：

1. **分位点先存入 local 宏**：`_pctile ... ; local uth = r(r1)`。Stata 把双精度数写成 16 位有效数字（|x|<1 时小数点后 16 位，四舍五入），而结果变量是 **float** 存储——宏值与数据值不再相等，于是"处理并列值"的分支被跳过，阈值观测是否被保留取决于舍入方向（向上舍入时 `y>=uth` 排除阈值点、`y<=lth` 包含阈值点）。
2. 真并列（如收入=0 或 0.0320307 这种十进制位数少的值）时走分数权重分支：$\text{stie}=(n(1-q)-n_{>})/n_{=}$。

Python 端 `leebounds_port` 逐行复刻（含宏精度舍入），Table III 与 OA §8.2 的全部界及解析 SE 与已发表值逐位一致；若按"教科书"修剪（精确分数修剪），资产界为 [−3.00, 14.28] 而非发表的 [−3.38, 12.84]。

### 2.7 MDE（Table A.1）

$\text{MDE}=2.8\times SE$（α=0.05 双侧、power 0.8），百分比 = MDE / 控制组均值（均值先 `round(.,.01)`）。

### 2.8 分位数回归（OA §14）

`sqreg y1 treat y_full0 y_miss0, q(.1 … .9)`：系数确定、SE 为 bootstrap（未设种子 → SE 随机）。

## 3. StatsPAI 实现细节

| 组件 | StatsPAI / Python 调用 | 与 Stata 的一致性 |
|---|---|---|
| `areg …, absorb(village) cluster(surveyid)` | `sp.feols("y ~ x + ctrl \| village", d, vcov={"CRV1":"surveyid"})` | b、SE 到 8 位小数一致（例：资产女性收款 −79.45712328 / 50.38302450），p 值用 t(G−1) 一致 |
| `reg …, cluster(village)` | `sp.feols(..., vcov={"CRV1":"village"})` | 一致 |
| `reg …, r` | `sp.regress(..., robust="hc1")` | 一致 |
| `suest` + `test` | 自写 `suest_wald`（影响函数聚类求和） | Table I–VI、III 联合 p 值全部一致 |
| `stepdown.ado` | 自写 `stepdown_perm`（向量化：残差化一次，每批 500 次置换矩阵运算；10,000 次 × 4 臂 × 8 结果约 20 秒） | 差 ≤0.03（随机流不同；Stata 18 重跑自身也差 ±0.01） |
| 多重检验对照 | `sp.bonferroni` / `sp.holm` / `sp.benjamini_hochberg` / `sp.romano_wolf` | 见 `Results/statspai/table2_multiple_testing.md` |
| `leebounds` | 自写 port；`sp.lee_bounds` 对照 | port 逐位一致；sp 版有差异（§5） |
| `sqreg` 系数 | `sp.qreg(d, formula=..., quantile=q)` | 70/72 一致，2 格差 0.01（分位回归解不唯一） |

## 4. 复现结果汇总

| 表 | 单元格 | 原始 Stata 重跑 | StatsPAI |
|---|---|---|---|
| Table I | 124 | ✅118 ⚠️6（FWER ±0.01） | ✅116 ⚠️8（FWER ≤0.02） |
| Table II | 124 | ✅114 ⚠️10 | ✅109 ⚠️15（FWER ≤0.03） |
| Table III | 148 | ✅137 ⚠️11（Lee bootstrap SE） | ✅135 ⚠️13（Lee bootstrap SE） |
| Table IV | 136 | ✅136 | ✅136 |
| Table V | 103 | ✅103 | ✅103 |
| Table VI | 140 | ✅140 | ✅140 |
| Table A.1 | 60 | ✅60 | ✅60 |
| OA Lee 界 | 32 | ✅32 | ✅32 |
| OA 分位数 | 144（72 系数 + 72 bootstrap SE） | ✅136 ⚠️8 | ✅70 ⚠️2（SE 未复现） |

**❌ 为 0。** 勘误：两条路线都对应更正版；以加权规格重跑心理指数溢出得 0.109/0.100/0.105/0.097，即发表版的 0.11/0.10/0.11/0.10。

## 5. StatsPAI 缺口、bug 与 API 摩擦

### B1（bug）`sp.romano_wolf` 在大量虚拟变量控制下 p 值出现下限

- **调用**：`sp.romano_wolf(data, y=[4 个结果], x="treat", controls=<119 个村虚拟变量>, cluster="surveyid", n_boot=300, seed=1)`
- **现象**：资产 |t|=10.02 时 `p_rw=0.0267`，消费 |t|=5.63 时也是 0.0267；去掉虚拟变量（或先村内去均值）后 `p_rw=0.000`。`n_boot=2000` 时下限约 0.07。
- **推测原因**：cluster bootstrap 抽样使部分村虚拟变量全为 0 → 设计矩阵奇异 → 该次重抽的 t 统计量为 inf/nan，被计为"≥ 实际值"。
- **最小复现**：
  ```python
  import statspai as sp, pandas as pd, pyreadstat
  df,_ = pyreadstat.read_dta("Data/UCT_FINAL_CLEAN.dta")
  u = df[(df.purecontrol!=1)&df.endlinedate.notna()&(df.maleres!=1)].copy()
  vd = pd.get_dummies(u.village.astype(int), prefix="v", drop_first=True, dtype=float)
  u = pd.concat([u, vd], axis=1)
  ys = ["asset_total_ppp1","cons_nondurable_ppp1","ent_total_rev_ppp1","med_hh_healthindex1"]
  sp.romano_wolf(u, y=ys, x="treat", controls=list(vd.columns), cluster="surveyid", n_boot=300, seed=1).table
  # p_rw = 0.0267 for t = 10.0; without controls p_rw = 0.0
  ```
- **规避**：先对 y、treat、控制变量做村内去均值再调用（本仓库做法）。**建议**：支持 `fe=`/`absorb=` 参数，丢弃奇异重抽并报告失败比例。

### B2（API 不一致）`sp.regress(...).pvalues` 是裸 `ndarray`

`params`、`std_errors` 是带变量名的 `Series`，而 `pvalues` 是 `numpy.ndarray`，`r.pvalues["spillover"]` 抛 `IndexError`；`sp.feols` 的 `pvalues` 则是 Series。

### B3（API 摩擦 + 性能）`sp.qreg`

- 返回 `CausalResult`，`params` 只含**第一个回归元**，索引名为 `"Q(0.5) treat"`；控制变量系数不可得。
- 无 `sqreg` 式同时估计多个分位数与 bootstrap VCV；无种子化 bootstrap SE 选项。
- 很慢：N≈940–1,474，72 次拟合约 450 秒（约 6 秒/次，明显慢于 Stata `sqreg`）。

### G1（缺口）没有 `suest`（跨方程聚类稳健联合检验）

`sp.sureg` 是 Zellner FGLS，无 `cluster=`、不允许各方程样本不同；`sp.test` 只能在单一模型内做 Wald。论文每张表的"Joint test"行都依赖 `suest …, cluster()`。本仓库用 OLS 影响函数手写（`uct_common.suest_wald`），全部联合 p 值与 Stata 一致。

### G2（缺口）没有置换式 Westfall-Young / 自定义重随机化的 stepdown

`sp.romano_wolf` 只做 bootstrap，要求所有结果共用同一样本与控制变量；本文 8 个指数样本不同（N=940/823/1474/698）、控制变量随结果变化（各自的 `_full0/_miss0`），无法直接使用。建议提供 `sp.westfall_young(models=[...], permute=callable, strata=, cluster=)`。

### G3（差异）`sp.lee_bounds` 的修剪/并列约定与 Stata `leebounds` 不同

| 样本 | Stata 下界 | sp 下界 | Stata 上界 | sp 上界 |
|---|---|---|---|---|
| Table III 资产 | −3.38 | −3.38 | 12.84 | 15.43 |
| Table III 消费 | −9.47 | −9.47 | −4.08 | −3.76 |
| Table III 收入 | −4.29 | −4.29 | 2.32 | 2.79 |
| OA 流失 资产 | 283.39 | 282.95 | 302.19 | 302.42 |
| OA 流失 收入 | 8.72 | 8.56 | 13.71 | 13.58 |

另：只返回一个 `se`（中点的 bootstrap SE），没有上下界各自的解析 SE（Lee 2009 的公式）；不支持 `tight()` 协变量紧化；`covariates` 参数"保留未用"。建议加 `stata_compat=True`、分别报告两个界的 SE 与 Imbens-Manski CI。

### G4（缺口）`sp.ri_test` 不支持分层重排与回归统计量

只能整体置换或按 `cluster` 整簇置换；本文第二阶段随机化是**村内**分配，需要 `strata="village"`；统计量 callable 只接收 `(Y, D)`，无法带固定效应与基线控制。扩展中手写了村内置换（`extensions_modern.ri_table2`）。

### G5（语义差异）`sp.horowitz_manski`

是按协变量分格、用 y 的最小/最大值（或给定上下限）求最坏情形界，与论文"用 5%/95% 分位数填补流失户后回归"的做法不同，未采用；列 9–10 用 `sp.regress(..., robust="hc1")` 直接复刻。

### G6（定位差异）`sp.balance_diagnostics`

面向倾向得分加权：内部拟合 logit 并报告加权 SMD；随机实验中需要的是"带村 FE、按户聚类的逐变量回归 + 联合检验"（论文 Table I）。建议增加 `sp.balance_table(data, treat, covariates, fe=, cluster=, joint="suest")`。

## 6. 现代方法扩展（标注为扩展，非复现）

见 `Results/statspai/extensions.md`：

1. **随机化推断**：村内重排处理状态 2,000 次（户内男女两行绑定），统计量为 areg 系数：资产/消费/食品安全/心理 p_RI=0，收入 0.003，健康 0.58，教育 0.17，女性赋权 0.89——与聚类渐近 p 值结论一致。`sp.ri_test`（不分层差分均值）给出的教育 p=0.70，说明不分层会严重损失功效。
2. **溢出的 wild cluster bootstrap / 村级 RI**（`sp.wild_cluster_bootstrap`，1,999 次 Rademacher；123 村）：村聚类 SE 与 Table III 列 1 一致（例如消费 7.1998）；女性赋权溢出 wild p=0.022、RI p=0.014，其余不显著。
3. **因果森林**（`sp.causal_forest`，1,000 棵树，11 个基线协变量）：ATE 资产 333、消费 32、食品安全 0.27、心理 0.19；按基线资产四分位，消费 CATE 23→33→38→35，心理 0.10→0.18→0.24→0.25——基线较富户心理收益更大（探索性，未做 BLP/GATES 检验）。
4. **Romano-Wolf**：村内去均值后 6 个户层面指数，资产/消费/食品安全 p_rw=0，收入 0.001，健康、教育 0.23。
5. **分位数效应图**：`Results/statspai/fig_oa_quantile_effects.png`；资产效应在 q=.6–.7 最大（~+500），收入效应集中在右尾。
6. **平衡诊断**：`sp.balance_diagnostics` 下 11 个基线协变量原始 SMD 绝对值均 ≤0.10（最大为教育 0.100）。

## 7. 对 StatsPAI 的改进建议（按优先级）

1. **P1** 修复 `romano_wolf` 奇异重抽问题并支持 `absorb=`；支持"每个结果不同样本/控制变量"的模型列表输入。
2. **P1** 新增 `sp.suest(models, cluster=)` 与跨方程 `test`——实验经济学几乎每张表都用。
3. **P1** 新增置换式 Westfall-Young stepdown（可传入自定义重随机化函数、strata、cluster）。
4. **P2** `ri_test` 增加 `strata=`、回归型统计量（`formula=` + `absorb=`）。
5. **P2** `lee_bounds` 增加上下界分别的解析 SE、`tight=` 协变量、`stata_compat`。
6. **P2** 统一 `pvalues` 返回类型（Series），`qreg` 返回全部系数并支持多分位 + bootstrap VCV、提速。
7. **P3** 实验平衡表 `balance_table(fe=, cluster=)` 与 Anderson (2008) 加权标准化指数构造器 `sp.index_anderson()`。
