# 《Kinship, Cooperation, and the Evolution of Moral Systems》模型解读与 StatsPAI 复现分析

> **论文**：Enke, Benjamin (2019). "Kinship, Cooperation, and the Evolution of Moral Systems." *Quarterly Journal of Economics* 134(2): 953–1019. DOI: [10.1093/qje/qjz001](https://doi.org/10.1093/qje/qjz001)
> **复现包**：Harvard Dataverse [doi:10.7910/DVN/JX1OIU](https://doi.org/10.7910/DVN/JX1OIU)（CC0；一个 `data_programs.zip`，7 个 .dta + 13 个 do-file）
> **本文目的**：逐式拆解论文实证模型 → 说明 StatsPAI 如何逐列复现 → 记录差异、StatsPAI 的缺口/摩擦/可改进之处 → 现代稳健性扩展。

---

## 目录

1. [实证设计总览](#1-实证设计总览)
2. [逐式拆解](#2-逐式拆解)
3. [StatsPAI 复现实现](#3-statspai-复现实现)
4. [复现结果与差异解释](#4-复现结果与差异解释)
5. [现代方法扩展](#5-现代方法扩展)
6. [StatsPAI 缺口、Bug 与 API 摩擦](#6-statspai-缺口bug-与-api-摩擦)
7. [改进建议](#7-改进建议)

---

## 1. 实证设计总览

论文没有准实验，核心是**同一关系在三个层级、七个数据源上的符号一致性**：

| 层级 | 单位 | 核心自变量 | 识别来源 | SE |
|---|---|---|---|---|
| A. 前工业民族 | EA 民族 $e$ | 本民族 kinship | 大洲/国家 FE；相邻民族配对 FE | 语言子语族聚类（`cluster`，116 类）；小样本用聚类 bootstrap |
| B. 国家 | 国家 $c$ | 按祖先构成加权的 kinship | 大洲 FE、语言 FE | HC1 / 国家聚类 |
| C. 国内个人 | WVS 民族成员、MFQ 移民、ISEAR 个人 | 本人民族/原籍国 kinship | 居住国 FE + 波次/年份 FE（流行病学方法） | 民族（`group`）或原籍国聚类 |

所有因变量都是 z 分数；kinship ∈ [0,1]，系数 = “完全松散 → 完全紧密”对应的 SD 变化。

**kinship 指数**（`Program/do-files/Kinship_index/Generate_kinship_index.do`）：

$$
K_e=\frac{\text{locality}_e+(1-\text{nuclear}_e)+(1-\text{bilateral}_e)+\text{clan}_e}{\#\text{非缺失成分}},\quad\text{仅当缺失成分}<2
$$

- `locality` = 1 若婚后与父系/母系亲属共同居住（EA v11 ∈ {1,3}）；`nuclear` = 1 若核心家庭（v8 ∈ {1,2}）；`bilateral` = 1 若双系继嗣（v43 = 6）；`clan` = 1 若存在地方性氏族（v15 ∈ {2,5,6}）。
- 包里没有原始 EA 变量，do-file 无法运行，但成分变量已随数据给出。我们在 Python 里按上式重算：1,227 个非缺失值与作者 `kinship_score` **逐个完全相等**（最大绝对差 0）。

---

## 2. 逐式拆解

### 2.1 起源：病原体生态 → kinship（Table III）

$$
K_e=\alpha+\beta\,\text{Pathogen}_e+\delta\,\text{HG}_e+\phi\,\ln(\text{年数自观测})_e+\mu_{\text{cont}(e)}+\varepsilon_e
$$

- `Pathogen` ∈ {疟疾生态指数 `s_malariaindex`, 到镰状细胞突变起源距离 `s_distance_mutation`, 采采蝇适宜度 `s_tsi`}，均标准化。
- 列 1–3 全样本（疟疾）；列 4–11 **非洲共同样本**（`malaria_sample==1`，约 500 个民族），SE 为 `bs, reps(500): reg ..., cluster(cluster)`——即**按语言子语族整群重抽样**的 pairs bootstrap。
- 注意：列 4–11 没有大洲 FE（非洲内部）。

### 2.2 前工业道德系统（Table IV）

$$
Y_e=\alpha+\beta K_e+\delta\,\text{HG}_e+[\phi\ln T_e]+[\kappa\,\text{HighGod}_e]+[\mu_{\text{cont}}\ \text{或}\ \mu_{\text{country}}]+\varepsilon_e
$$

| 列 | $Y_e$ | 额外控制 | FE | SE |
|---|---|---|---|---|
| 1–2 | 对外 vs 对内暴力可接受度差（SCCS, N=61） | lnT | — | 聚类 bootstrap |
| 3–5 | 道德化神 | 有高位神、lnT | —/大洲/国家 | 聚类 |
| 6–7 | 对本地社区忠诚（SCCS, N=83） | lnT | — | 聚类 bootstrap |
| 8–9 | 产后性禁忌长度 | lnT | —/大洲 | 聚类 |
| 10–12 | 地方以上司法层级数 | lnT | —/大洲/国家 | 聚类 |
| 13–15 | 是否有村级司法层级 | lnT | —/大洲/国家 | 聚类 |

作者脚注 16：小样本下 bootstrap 无法可靠处理大洲 FE，因此列 1–2、6–7 不加 FE。

### 2.3 相邻民族配对（Table V）

$$
Y_{e}=\beta K_e+\delta\,\text{HG}_e+[\phi\ln T_e]+[\kappa\,\text{HighGod}_e]+\mu_{m}+\varepsilon_{e m}
$$

- 数据 `EA_contiguous.dta` 已是“长”格式：每个配对 $m$（同国、质心 ≤ 500 km、kinship 不同）两行；一个民族可出现在多个配对里。
- `keep if geodist<=500` 后**在该样本上重新标准化**因变量（`egen std()`）——复现时必须在筛选后再算 z 分数，否则系数差一个尺度因子。
- `areg ..., a(match) cluster(cluster)`：配对 FE + 语言子语族聚类。

### 2.4 当代：国家层面（Table VI 1–4, VII 1–4, X 1–3）

$$
Y_c=\alpha+\beta\bar K_c+\mathbf X_c'\gamma+[\mu_{\text{cont}}]+\varepsilon_c,\qquad \bar K_c=\sum_{e}\omega_{ce}K_e
$$

- $\omega_{ce}$：当今国家 $c$ 人口中祖先来自民族 $e$ 的份额。论文结合两种方法：语言匹配（Giuliano–Nunn 2017a，把 Ethnologue 语言映射到 EA 民族）与 Putterman–Weil (2010) 迁移矩阵的**祖先调整**；包里只给最终的 `kinship_score`。
- `X_c` = 祖先加权的狩猎采集依赖度与 lnT；SE = `ro`（HC1）。

### 2.5 当代：国内民族（WVS，Table VI 5–8, VII 5–8）

$$
Y_{i}=\beta K_{e(i)}+\mathbf Z_i'\gamma+\mathbf X_{e(i)}'\delta+\mu_{c(i)}+\tau_{\text{wave}(i)}+\varepsilon_i
$$

- $\mathbf Z_i$：性别 + 年龄 FE（`i.age`）；$\mathbf X_{e}$：民族层面 HG 与 lnT（`ln_time_obs_ea_e`）。
- 国家 FE 用 `dum_country*`（33 个虚拟变量）——**不是** `isonum`（32 个代码）：有一个 ISO 国家被作者拆成两组。复现时若用 `isonum` 吸收，Table VII 列 6–8 会差 1e-4（见 §4）。
- 聚类：`group`（民族），识别完全来自同国不同民族的比较。

### 2.6 当代：移民（MFQ，Table VIII）

$$
Y_{i}=\beta K_{o(i)}+\mathbf Z_i'\gamma+\mathbf X_{o(i)}'\delta+\mu_{r(i)}+\tau_{\text{year}(i)}+\varepsilon_i
$$

$o$ = 出生国，$r$ = 居住国；聚类在出生国（`isocode_past`）。这是 Fernández 式“流行病学方法”：同一居住国的制度环境相同，祖先文化随人迁移。

### 2.7 情绪与搜索（Table IX）

- ISEAR（列 1–6）：个人层面，`i.age female` + 国家层面控制，按国家聚类（kinship 在国家层面变异，实质有效样本只有 36 个国家）。
- Google Trends（列 7–8）：国家×语言观测，**语言 FE**（`i.lang`，只用同语言不同国家的差异），按国家聚类。

### 2.8 发展（Table XI、Figure IX）

- Table XI：EA 民族层面，因变量为 HYDE 人口密度、聚落复杂度、社区规模。
- Figure IX：对每个年份 $t\in\{1500,1600,1700,1710,\dots,1950\}$，在“本土人口 ≥ 50%”的 123 国上跑
  $\ln(1+\text{popd}_{ct})=\alpha_t+\beta_t K_c+\delta_t\text{HG}_c+\varepsilon_{ct}$（HC1），画 $\beta_t$ 路径并按显著性着色；城市化率同理。do-file 还跑了加殖民者虚拟变量的版本但未作图。

### 2.9 描述性图

- Figure IV / V：以 kinship = 0.25 为界分“紧/松”两组，画 z 分数均值 ± s.e.m.。Figure IV 的 s.e. 来自 `reg y if type==j, cluster(cluster)` 的常数项 SE（两个 SCCS 变量用 bootstrap）；Figure V 用 `collapse (semean)`。
- Figure VIII：`pca` 5 个道德变量（相关矩阵），`predict` 第一主成分得分。

---

## 3. StatsPAI 复现实现

脚本：`Program/statspai/replicate_statspai.py`（statspai 1.28.0，pyfixest 后端，Python 3.13，约 100–140 s）。

| Stata | StatsPAI 调用 | 说明 |
|---|---|---|
| `reg y x, cluster(cluster)` | `sp.feols("y ~ x", data, vcov={"CRV1":"cluster"})` | CR1 小样本校正与 Stata `regress` 一致 |
| `reg y x, ro` | `sp.feols(..., vcov="hetero")` | HC1 |
| `reg y x cont_*` | `sp.feols("y ~ x | cont", ...)` | 吸收 FE 后斜率、SE 与虚拟变量版本一致（pyfixest 默认 `fixef_k="nested"` 在这里不改变 df） |
| `reg y x dum_country* i.wave i.age female` | `"y ~ x + female | wctry + wave + age"` | 多维吸收 |
| `areg y x, a(match) cluster(cluster)` | `"y ~ x | match"` + `ssc=pf.ssc(fixef_k="full")` | 本例中默认 ssc 与 `full` 给出相同 SE |
| `bs, reps(500): reg y x, cluster(c)` | `sp.feols` 取点估计；`sp.bootstrap(d, stat, n_boot=500, cluster="c", seed=...)` 的 `.se` 作 SE | 每个系数一个 bootstrap；统计量为 numpy OLS |
| `binscatter`、`pca`、`collapse (semean)` | pandas/numpy + matplotlib | 描述性，非估计 |

**两处需要“读懂数据”才能精确复现的细节**：

1. **全零的大洲虚拟变量**。`EAShort.dta` 中 Manihikians、Futunans、Uveans（波利尼西亚）的 7 个 `cont_*` 全为 0。Stata `reg ... cont_*` 保留它们（7 个虚拟变量与常数项不共线，于是一个也不删，全零行自成基准组）。若把 `cont_*` 转成类别变量时把全零行当缺失，Table III 列 3、Table IV 列 4/11/14、Table XI 列 4 的 N 会少 3（我们第一版脚本即如此）。正确做法是给全零行单独编码。
2. **WVS 国家 FE**（见 §2.5）。

---

## 4. 复现结果与差异解释

完整逐数对照：`Results/comparison.md`。

| | 结果 |
|---|---|
| 作者代码 | 12 个 do-file 全部 rc = 0（Stata 18 MP，≈ 51 s）。LaTeX 表 9 张（含我们补导出的 Table X 列 1–3）、图 9 个 PDF。 |
| 论文 vs Stata | 94 个系数：点估计与 N **全部**在报告精度下一致；7 个 bootstrap SE 与论文差 0.005–0.02（作者未设种子，属蒙特卡洛误差）。 |
| Stata vs StatsPAI | 见下方“精度”一段。 |
| 无法复现 | Table X 列 4–6（GPS 个人出生国数据受 Gallup 许可限制）；Table I–II 为概念表；在线附录不在包中。 |

**精度**：94 个系数中，StatsPAI 与 Stata（6 位小数导出）的点估计最大绝对差 **5e-7**，非 bootstrap 列 SE 最大绝对差 **6e-7**（即导出精度本身），N 全部相同。第一版脚本在 Table VII 列 6–8 差 1e-4：用 `isonum` 而非作者的 `dum_country*` 做国家 FE 所致（§2.5），修正后消失；此前还排除了 float32 读入精度的可能（转 float64 结果不变）。

**Bootstrap 列**（Table III 列 4–11、Table IV 列 1/2/6/7）：点估计一致，SE 不可能逐位一致——Stata 与 StatsPAI 的随机数流不同，且作者原始运行没有种子。B = 500 时 bootstrap SE 自身的蒙特卡洛相对标准差约 $1/\sqrt{2B}\approx3.2\%$；Stata/StatsPAI 与论文印刷值的差，扣除四舍五入（±0.005）后相对差 ≤ 9%，约 3 个 MC 标准差以内。判定规则：|SE − 论文值| ≤ 0.005（四舍五入半宽）+ 10%。

**图**：Figure IX 样本 123 国与论文一致；Figure VII 数据中美国受访者 13,751 人，正文写 13,723 人（差 28 人，疑为正文引用了早期数据版本，不影响图）。

---

## 5. 现代方法扩展

脚本 `Program/statspai/extensions_statspai.py`（≈ 20 s），输出 `Results/statspai/ext_E*.csv`。**这些不是复现，是再评估。**

### E1 Conley 空间 HAC（Table IV）

EA 民族在地理上高度聚集（非洲占比大），语言子语族聚类未必覆盖空间相关。`sp.conley(result, data, lat, lon, dist_cutoff)`，均匀核，haversine 距离。我们用 numpy 手写 Conley 估计量校验：500 km 下 SE = 0.1633270，与 `sp.conley` 在 1e-13 内一致。

| 规格 | β | 聚类 SE | Conley 250 | 500 | 1000 | 2000 km |
|---|---|---|---|---|---|---|
| IV(3) 道德化神 | −0.77 | 0.19 | 0.14 | 0.16 | 0.21 | 0.28 |
| IV(4) +控制+大洲 | −0.51 | 0.13 | 0.12 | 0.14 | 0.16 | 0.21 |
| IV(8) 性禁忌 | 0.83 | 0.20 | 0.19 | 0.22 | 0.26 | 0.29 |
| IV(10) 地方以上层级 | −0.39 | 0.20 | 0.15 | 0.18 | 0.22 | 0.32 |
| IV(11) +控制+大洲 | −0.36 | 0.12 | 0.13 | 0.13 | 0.12 | 0.15 |
| IV(13) 村级制度 | 0.83 | 0.12 | 0.13 | 0.18 | 0.23 | 0.31 |
| IV(14) +控制+大洲 | 0.87 | 0.12 | 0.12 | 0.14 | 0.16 | 0.20 |

结论：大截断距离下 SE 最多放大约 2.5 倍，但除列 10（聚类下已是 p ≈ .05）外 |t| 在 1000 km 与 2000 km 均 > 2。

### E2–E4 不可观测混淆

短回归 = 只有 kinship；长回归 = 论文最全控制；R²max = min(1, 1.3·R²_long)。

| 结果 | N | β_long | Oster δ* | β(δ=1) | RV_q | RV_q,α | E 值（点/CI） |
|---|---|---|---|---|---|---|---|
| EA 道德化神 | 770 | −0.51 | −1.22 | −0.92 | 0.16 | 0.10 | 2.56 / 1.96 |
| EA 村级制度 | 1,141 | 0.87 | 21.8 | 0.83 | 0.20 | 0.15 | 3.80 / 3.09 |
| EA 性禁忌 | 371 | 0.46 | **0.55** | −0.38 | 0.13 | 0.03 | 2.40 / 1.45 |
| 国家 信任（内−外） | 70 | 1.44 | 13.5 | 1.33 | 0.42 | 0.25 | 6.76 / 3.32 |
| 国家 信任（家人−他人） | 70 | 1.24 | −3.84 | 1.56 | 0.32 | 0.12 | 5.54 / 2.04 |
| 国家 地狱信仰 | 78 | 0.47 | **0.24** | −1.49 | 0.21 | 0 | 2.44 / 1.12 |
| 国家 复仇 vs 利他惩罚 | 74 | 0.83 | 1.30 | 0.19 | 0.20 | 0 | 3.68 / 1.00 |

- δ* < 0：加入可观测控制后系数**远离** 0（道德化神、家人信任），按 Oster 逻辑，与可观测变量同向的选择只会加强结果。
- 性禁忌与地狱信仰 |δ*| < 1 属于脆弱结果；地狱信仰在国家层面主要被“大洲 FE + 神信仰”吸收（Table VII 列 1→4：1.16 → 0.47）。

### E5 规格曲线

8 组控制集（EA：无 / HG / +lnT / +地理 / +大洲 / +地理+大洲 / +农牧业 / 全部；国家：+疟疾 / +log GDP / +天主教与穆斯林占比 / 全部），EA 结果另外交叉 {聚类, HC1} SE，每个结果都在所有规格的共同样本上估计。

- 符号 100% 稳定：道德化神（−0.38 至 −0.83）、村级制度（0.78–0.93）、性禁忌、国家信任、复仇惩罚。
- 地方以上层级：只有不控制狩猎采集时为正（HG 是重要混淆）。
- 国家层面**社群−普世价值**：加入 log GDP 后变号且在 5% 水平从不显著（共同样本 61 国）；**地狱信仰**仅在“收入+宗教占比+大洲”全控制下变号。

### E6 Romano–Wolf 多重检验

- EA 族（道德化神、性禁忌、地方以上层级、村级制度；控制 HG；按语言子语族整群 bootstrap，B = 2000；共同样本 N = 293）：RW 调整 p = 0.003 / 0.001 / 0.071 / < 0.001。
- 国家族（Figure V 的 6 个变量）：`sp.romano_wolf` 按所有结果的交集删行，只剩 15 国，结果无信息量（见 §6）。

---

## 6. StatsPAI 缺口、Bug 与 API 摩擦

| # | 函数 | 问题 | 最小复现 / 证据 | 严重度 |
|---|---|---|---|---|
| 1 | `sp.romano_wolf` | **所有结果变量一起做 listwise deletion**，且结果对象不报告 N。结果变量缺失模式不同时会静默丢掉大部分样本。本例 6 个国家层面结果，单独回归各有 70–79 国，交集只剩 15 国；RW 调整 p（如厌恶 0.241）反而远大于同表的 Holm p（0.016），因为 15 个观测下 bootstrap-t 分布厚尾，而 Holm 用 t 分布 p 值。 | `sp.romano_wolf(cty, y=[6 个 s_* 变量], x="kinship_score")` → 源码 `df = data[all_cols].dropna()` | 高（静默，易误读） |
| 2 | `sp.bootstrap` | 没有 Stata `bs: reg ..., cluster()` 的回归快捷方式：`statistic` 必须返回**标量**，每个系数要单独调用一次 bootstrap（固定种子可以复现同一批重抽样，但重复计算，且不返回系数间的联合协方差矩阵）。 | 见 `replicate_statspai.py::fit_boot` | 中 |
| 3 | `sp.oster_bounds` | δ* 在返回字典里叫 `delta_for_zero`；`sp.oster_delta` 返回的 `BoundsResult` **没有** δ* 属性（只有 `lower/upper` 识别集）。函数名与返回值命名不一致，第一次调用时容易拿不到最关键的数字。 | `sp.oster_bounds(beta_short=..., r2_short=..., beta_long=..., r2_long=..., r_max=...)` → keys `['beta_short', …, 'delta_for_zero', 'beta_adjusted', 'identified_set', 'robust', 'interpretation']` | 中 |
| 4 | `sp.feols` ssc | 模仿 Stata `areg` 的自由度校正需要 `import pyfixest as pf; ssc=pf.ssc(fixef_k="full")`；StatsPAI 未再导出 `ssc`（`hasattr(sp, "ssc") == False`），也没有 `ssc="stata_areg"`、`"stata_reghdfe"` 这类预设。 | — | 低 |
| 5 | `EconometricResults` | N 与 R² 不在顶层属性（`r.nobs` 不存在），分散在 `r.data_info["nobs"]`、`r.diagnostics["R-squared"]` 与 `r.glance()` 中。 | `sp.feols(...).nobs` → AttributeError | 低 |
| 6 | `sp.spec_curve` | 控制集只能是变量列表，不支持吸收 FE（大洲 FE 只能展开成虚拟变量），也不支持按规格改变聚类变量；`results_df` 里的 `controls` 是逗号拼接字符串，不便筛选。 | — | 低 |
| 7 | `sp.conley` | 数值正确（已与手写估计量对到 1e-13）。但接口要求另传 `data`，且不检查它与 `result` 的估计样本逐行对齐——若 `result` 内部删过缺失行而 `data` 没删，可能静默错配。建议从 result 取估计样本，或至少校验行数。 | 我们对 `dropna().reset_index()` 后的数据估计以规避 | 低（潜在） |
| 8 | `sp.evalue(measure="OLS")` | 需手动提供结果变量 SD；对 kinship 这类 0–1 连续处理变量，默认“一单位变化”的含义需在文档中说明。 | — | 低 |

**没有问题的部分**：`sp.feols` 的 CRV1/HC1 与多维 FE 吸收在 94 个系数上与 Stata 一致；字符串型聚类变量可直接使用；`sp.sensemakr`、`sp.evalue` 输出完整。

---

## 7. 改进建议

1. `romano_wolf`：提供“每个结果用各自估计样本”的选项（可参考 Stata `rwolf`/`rwolf2` 的实现），或至少在结果中报告每个结果的 N 并对 listwise deletion 发出警告；同时提供 `method="t"`/`"coef"` 的选择，说明小样本下与 Holm 的差异。
2. `feols(..., vcov="bootstrap", reps=500, cluster="c", seed=...)`：一次性给出所有系数的 pairs cluster bootstrap SE 与协方差矩阵，对齐 Stata `bs: reg, cluster()`。
3. 统一 Oster API：`oster_delta` 返回 `delta_star`；`oster_bounds` 同时提供 `delta_star` 别名；支持直接从两个 `EconometricResults`（短/长回归）调用。
4. 导出 `sp.ssc` 并提供 Stata 预设：`ssc="stata"`（regress/areg）、`ssc="reghdfe"`。
5. `EconometricResults` 增加 `.nobs`、`.r2`、`.n_clusters` 顶层属性。
6. `spec_curve` 支持 `fe=[[], ["cont"], ...]` 作为一个选择维度，以及按规格的聚类变量。
7. `conley` 接受 `result` 自带的估计样本，或校验 `len(data) == result.data_info["nobs"]`。
8. 文档加一个“从 Stata 横截面文化经济学论文迁移”的例子：`reg ... cont_*`（全零虚拟变量陷阱）、`areg`、`bs: reg`、`binscatter`，本项目可作模板。
