# 论文模型解读与 StatsPAI 复现分析

> Cengiz, Dube, Lindner & Zipperer (2019), *The Effect of Minimum Wages on Low-Wage Jobs*, QJE 134(3)。
> 复现包：Harvard Dataverse doi:10.7910/DVN/TJCTC7。StatsPAI 1.28.0，Python 3.13，Stata 18 MP。
> 本文档面向准备复现本文的研究者：逐个方程拆解 → 对应到作者 Stata 代码 → StatsPAI 实现细节 → 数值一致性陷阱 → StatsPAI 的缺口与 bug → 现代 DID 扩展结果。

---

## 0. 一页结论

| 项目 | 结论 |
|---|---|
| 可复现性 | 复现包提供全部**中间数据**（州 × $0.25 工资档 × 季度面板等，约 16 GB），但**不含 CPS-MORG 原始微观数据**，所以数据构建步骤（`state_panels_cents_new_QJE.do` 等）无法重跑；分析步骤全部可跑。 |
| 原始 Stata 代码 | 无需任何修改即可运行（只需在包装脚本里设置全局路径宏）；但有若干 do-file 直接 `est use` 作者预先存好的 `.ster`（其回归被注释掉），必须先把作者的 `estimates/` 复制到 `${estimates}`。机器负载下 Table 1 的 12 个 reghdfe 回归需要 20 小时以上（第 3、6 列的工资档 × 州二次趋势最慢）；Figure 2/4 与 Table 2 第 6–8 列的回归吸收约 180 个线性斜率，单个回归 2.5 小时未完成，因此改用只注释掉 reghdfe/est save 行的 est-use 副本从作者 `.ster` 重建，并由 StatsPAI 独立重估验证。 |
| StatsPAI 复现 | 主文所有回归表（Table 1 全 7 列、Table 2 全 8 列、Table 3 全 8 列、Table 4）以及 Figure 2/3/4 均用 `sp.hdfe_ols` 重写；系数与作者 `.ster` 在 1e-9 量级一致，聚类标准误一致到 1e-8，发表表格数字（3 位小数）全部吻合（细节见 `Results/comparison.md`）。 |
| 关键陷阱 | ① Stata float 存储 + 精确相等比较；② Stata 缺失值 = +∞；③ `A or B or C or D & year>=b & cleansample==1`（Stata 中 `&` 优先于 or） 的运算符优先级；④ Table 2 第 1–5 列与 Table 4 用了**不同的工资效应公式**；⑤ 第 7 列简化方法中 `treat` 在 1979q1–q3 缺失导致样本少 153 个州-季度。 |
| StatsPAI 缺口 | `sp.stacked_did` 不支持权重、不支持多次（非吸收）处理与自定义"干净对照"规则、也不接受事件 × 工资档的多结果堆叠；`sp.callaway_santanna` 州级聚类必须 bootstrap；`sp.did_imputation` 对 pretrends 个数的检查；`hdfe_ols` 结果对象 `vcov` 是无标签 ndarray。详见 §5。 |

---

## 1. 方程拆解

### 1.1 结果变量

$$y_{sjt}=\frac{E_{sjt}}{N_{st}}$$

- 代码：`overallcountpc = count/population`（`state_panels_tercile1979_QJE.do`）。
- **QCEW 校准**（`Table1_for_QJE.do`）：`count = count*emp/countall if emp!=0`，即把 CPS 州-季度总就业按 QCEW 就业 `emp` 等比例缩放；`overallcountpcall = emp/population`。
  Figure 2 则用 `qcew_multiplier.dta` 的乘子（数值上几乎相同，但不是同一文件）。
- 权重：`wtoverall1979 = mean(pop)` by 州-季度（仅 `cleansample==1` 行非缺失）。

### 1.2 处理变量（方程 1 的 $I^{\tau k}_{sjt}$）

```stata
_treat_pk = 1 if D.MW_real>0.25 & D.MW_real<. & D.MW>0 & wageM25 in [MW_realM25+k, MW_realM25+k+1) & overallcountgroup>0 & fedincrease!=1
treat_pk  = _treat_pk + L._treat_pk + L2._treat_pk + L3._treat_pk      // 事件年（4 个季度）
L4treat_pk = L4.treat_pk ... L16treat_pk ; F4/F8/F12treat_pk          // 年度 leads / lags
window_pk = F12 + F8 + F4 + L0 + L4 + L8 + L12 + L16                    // 8 年窗口指示
```

面板为 `xtset wagebinstate quarterdate`（工资档 × 州为个体）。`overallcountgroup>0` 即"上调前一年新 MW 下工人占比 ≥ 2%"的显著事件（`belowshare≥0.02` 的三分位组 1–3），`fedincrease` 为联邦上调。

### 1.3 回归（方程 1）

```stata
reghdfe overallcountpc treat_{m4..p4} L4treat_* ... L16treat_* one  [aw=wtoverall1979] if year>=1979 & cleansample==1,
        a(i.wagebinstate i.wagequarterdate                          // μ_sj, ρ_jt
          postcont_m precont_m earlycont_m postcont_p precont_p earlycont_p       // 小额事件控制（类别 FE）
          postcontf_m ... earlycontf_p                                             // 联邦事件控制（类别 FE）
          i.one#c.F12treat_* i.one#c.F8treat_*                     // τ=-3,-2（线性吸收）
          i.one#c.window_*)                                         // 窗口 → τ=-1 归一化
        cluster(statenum)
```

要点：

1. `i.one#c.x` 在 `absorb()` 里等价于把 x 作为普通线性回归元偏出（FWL）。所以"before"回归（显示 F12/F8 系数）与"after"回归（显示 L0–L16 系数）是**同一个模型**，只是报告的系数块不同。
2. 由于 `window = ΣF + ΣL`，而 F4 不在回归元里，所以 L0..L16、F12、F8 的系数都是**相对 τ=−1（F4）的差分**，这就是论文 "α_τk − α_{−1,k}"。
3. 控制变量 `postcont_*` 等是计数变量（可取 0,1,2,…），被当作**类别型固定效应**吸收（不是线性项）。
4. Table 1 第 2–6 列：`i.wagebinstate##c.quarterdate`（工资档 × 州线性趋势）、`##c.quarterdatesq`（二次趋势）、`i.wagequarterdate##i.division`（工资档 × 分区 × 季度 FE）。

### 1.4 汇总常数

| 符号 | 代码 | 值（总体） |
|---|---|---|
| $\overline{EPOP}_{-1}$ = E | 事件前 4 季度 `overallcountpcall` 的加权均值 | 0.5711273 |
| $\bar b_{-1}$ = B | 事件前新 MW 以下累计就业（`overallcountpcrsum` 在 `(wagebins+25)/100==F{k}MW_realM25` 处）/E | 0.0865 |
| EWB | 同上，工资总额累计 `overallWBpcrsumFH` | 0.350835 |
| %ΔMW | `mean(DMW_real if 事件)/mean(MW_real if 事件前一季)` | 0.10129 |
| wagemult | `mean(wagebins if treat_p0==1)/100`，≈ 事件后新 MW 附近平均工资 | 8.7749 |

### 1.5 汇总统计量（`lincom`/`nlcom`）

- $\Delta b = 4\cdot\frac15\sum_{\tau=0}^{4}\sum_{j=1}^{4}\hat\beta_{\tau,m j}/E$；$\Delta a$ 同理取 p0..p4（乘 4 是因为每 $1 含 4 个 $0.25 档，除 5 是 5 年平均）。
- %Δ 受影响就业 = (Δa+Δb)/B；对 MW 弹性 = (Δa+Δb)·C，C = 1/(E·%ΔMW)。
- 工资总额变化：$\%\Delta wb = 4\cdot\frac15\sum_\tau\left[\sum_j\hat\beta_{\tau,mj}(\text{wagemult}-j)+\sum_j\hat\beta_{\tau,pj}(\text{wagemult}+j)\right]/EWB$。
- **方程 2**：%Δw = (%Δwb − %Δe)/(1 + %Δe)（Table 1、Table 3、Table 2 第 6–8 列、Table 4）。
- **注意**：`Table2_for_QJE.do` 第 1–5 列用的是 `lincomestadd (%Δwb − %Δe)`，**没有除以 (1+%Δe)**，对自身工资弹性也相应改为 %Δe/(%Δwb−%Δe)。因此同一人群（如"高中以下"）在 Table 2 里是 0.080，在 Table 4 里是 0.077。两者都被我们精确复现。
- Table 4 "无溢出"工资效应（`abovebelowWBbunch_alt, secondmethod(Y)`）：$-\frac{4}{5}\sum_\tau\sum_{j=1}^4 j\,\hat\beta_{\tau,mj}/EWB$（假设所有消失的低于 MW 岗位都恰好被抬到新 MW），溢出份额 = 1 − 无溢出/总效应。

### 1.6 Figure 2 的占位（placebo）工资档

`placebowindows1/2` + `placebosamplecorr1/2` 把 MW+5 到 MW+16 的每个 $1 档、以及 ≥MW+17 的开放档（"17+"）也做成处理变量。作者跑三次 reghdfe，每次把另外两块作为线性项吸收。开放档的缩放因子不是 4，而是 `sum_inf`（开放档里 $0.25 档的个数）的加权均值 19.32。

### 1.7 Table 1 第 7 列（州 × 季度简化方法）

结果为 $15 以下就业/人口与工资总额/人口，两个结果堆叠，`i.statenum#i.epopoutcome i.quarterdate#i.epopoutcome` + 控制 × 结果类别；回归元为 F12/F8/F4/L0..L16 × 结果类别（**此处 F4 在回归元里**，效应算作 Σ(L − F4)/5）。常数 E、B、EWB、%ΔMW 沿用 Table 1 循环留下的全局宏。

---

## 2. StatsPAI 实现映射

| Stata | StatsPAI / Python |
|---|---|
| `reghdfe y X [aw=w], a(FE… i.one#c.Z) cluster(statenum)` | `sp.hdfe_ols("y ~ X + Z &#124; FE…", data, weights="w", cluster="statenum")` —— Z 作为普通回归元（FWL 等价） |
| `i.wagebinstate##c.quarterdate` | 公式 FE 部分写 `i.wagebinstate#c.quarterdate`（hdfe_ols 支持变斜率吸收） |
| `i.wagequarterdate##i.division` | 先 `groupby([...]).ngroup()` 生成交互 id 再作 FE |
| 三次 reghdfe（Figure 2） | 一次联合回归，读三个系数块（系数与 vcov 块完全一致，已验证到 1e-9） |
| `lincom` / `nlcom` | `bunching.delta()`：数值梯度 + 三明治 vcov（线性组合时与 lincom 完全等价） |
| `L.` / `F.` 时间序列算子 | `bunching.Panel.shift()`：在 (个体 × 季度) 稠密网格上 O(n) 查表，缺行 → 缺失 |
| `sum x if cond [aw=w]` | `bunching.wmean()`，并用 `s_ne`/`s_gt` 复刻 Stata 缺失值语义 |

脚本：`Program/statspai/`（`bunching.py` 公共模块 + 各表脚本）。所有回归系数与 vcov 缓存在 `Results/statspai/estimates/`。

---

## 3. 数值一致性陷阱（逐一踩过）

1. **float 精确比较**。`(wagebins+25)/100 == F1MW_realM25`：右侧是 float 存储。若 Python 里用 `np.isclose` 会**多**匹配一些行，B/EWB 就偏了。pyreadstat 读入 float32 列时保留原二进制值，因此直接 `==` 即可复刻 Stata。
2. **缺失值 = +∞**。`fedincrease!=1` 对缺失为真，`overallcountgr>0` 对缺失为真。事件前 E 的条件里作者专门加了 `F.fedincrease!=.`，而 %ΔMW 分母的条件没有加——Python 必须逐条照抄。
3. **运算符优先级**。`(c1) or (c2) or (c3) or (c4) & year>=b & cleansample==1`：`&` 先结合，所以样本限制只作用于第 4 项。我们照原样复刻（这也是作者本意之外的一个小瑕疵，但对数值影响极小）。
4. **Table 2 第 1–5 列的线性工资公式**（§1.5）。
5. **第 7 列样本**。`treat = _treat + L._treat + L2._treat + L3._treat` 在前 3 个季度缺失 → reghdfe 丢弃这些行（N=14,484）。如果先 `fillna(0)`，N=14,790，工资效应 0.066 而非 0.065。
6. **单例（singleton）剔除**。Table 1 估计样本 865,215 行，reghdfe 与 `sp.hdfe_ols` 都剔除 17,901 个单例后 N=847,314，与论文一致。
7. **Figure 4 的长数据**。匹配 CPS 数据按 `emp_prev` 长格式存放：面板个体用 `wagebinstateprev`，开放档 `sum_inf` 要除以 2，运行累计和要在 (emp_prev, 州, 季度) 内做。

---

## 4. 复现结果摘要

详见 [Results/comparison.md](../Results/comparison.md)。

| 展品 | 原始 Stata 代码 | StatsPAI |
|---|---|---|
| Table 1 第 1–6 列 | ✅ 全量运行完成（12 个 reghdfe，共享机器上约 22 小时）；重新生成的 `Table1.tex` 与作者提供的逐字节相同；`.ster` 系数差 ≤ 9e-16，标准误差 ≤ 3e-10 | ✅ 36/36 格与论文一致 |
| Table 1 第 7 列 | ✅ 在 Table 1 do-file 末尾运行完成，包含在逐字节相同的 `Table1.tex` 中 | ✅ 4/4，N=14,484 |
| Table 2 | ✅ `Table_2.tex` 与作者提供的逐字相同（第 1–5 列 do-file 本身就是 `est use`；第 6–8 列用 est-use 副本） | ✅ 48/48（重新估计 8 个回归） |
| Table 3 | ✅ 全量 8 个回归（3.6 小时），与作者提供的逐字相同 | ✅ 48/48 |
| Table 4 | ✅ 逐字相同 | ✅ 30/30（10 行 × 3 列，含匹配 CPS 的在职者/新进入者） |
| Figure 2 | ✅ est-use 副本重绘 | ✅ 22 个工资档与作者 `.ster` 差 1e-10 |
| Figure 3 | ✅ Table 1 运行中生成 | ✅ 14 个点差 1e-9 |
| Figure 4 | ✅ est-use 副本重绘 | ✅ 就业/工资效应一致；在职者 Δa/Δb 图框 ⚠️（作者 do-file 中硬编码的旧注释 0.014/−0.013，作者自己的 `.ster` 给出 0.0126/−0.0122，与 StatsPAI 相同） |
| Figure 5、6、A11 | ✅ 斜率 0.139/−0.133/0.006、弹性 −0.089 全部一致 | — |
| 附录 | 约 45 个步骤；Table A3、A5、A7、F1、F2、G3、G4、G6、G7、G8 与作者提供/论文一致；Table A4 第 9 列 10 行全部与论文一致；Table F3 第 2 列有 3 格差 0.001；失败项见 `Results/comparison.md`（3 个作者 bug 已打补丁：G2 第 1 列缺 tempfile 且遗留调试用 `stop`、A4 第 9 列缺参数、F3 数据路径错误；A4 第 1–8 列缺数据；A1_A2 所需 `_estadd.ster` 无任何 do-file 生成；G5 panel C 缺存储估计） | —（以现代 DID 扩展代替） |

自动生成的比较表共 167 个 ✅、0 个 ⚠️、0 个 ❌（仅统计主文表格单元）。

---

## 5. StatsPAI 缺口、bug 与 API 摩擦（附最小复现）

环境：`statspai` 1.28.0（`/Users/brycewang/Documents/GitHub/StatsPAI/src` 开发版安装），Python 3.13，pandas 2.2.3，pyfixest 0.50.1。

### 5.1 做得好的地方（先说结论）

- `sp.hdfe_ols` 的 reghdfe 口径非常到位：嵌套于聚类变量的 FE 不计入自由度、单例剔除、`[aw=]` 权重、变斜率吸收 `i.g#c.x`。Table 1–4 全部 190+ 个单元格、Figure 2–4 的系数和聚类标准误与作者 `.ster` 在 1e-9 量级一致，**无需任何 ssc 调整**。

### 5.2 缺口 / 摩擦（按严重程度）

| # | 函数 | 问题 | 最小复现 / 证据 | 建议 |
|---|---|---|---|---|
| G1 | `sp.stacked_did` | **不支持权重**（签名里没有 `weights=`），而 CDLZ 原文按州人口加权；也不能传入"事件 × 工资档"多结果堆叠。 | `inspect.signature(sp.stacked_did)` → 无 weights；本项目扩展中 `stacked_did` 点估计 0.005 (0.003) vs 加权手工堆叠 −0.000 (0.003) | 增加 `weights=`；允许 `outcome_by=` 结果维度 |
| G2 | `sp.stacked_did` | 只接受"首次处理时间"面板并**自己重建堆叠**；无法使用作者那种"事件内干净对照"（对照州在窗口内不得有其他主要事件）与**多次（非吸收）处理**；把已堆叠的数据（单位 = 事件 × 州）喂进去时，g=0 的对照单位会被重复用于所有队列。 | `modern_extensions.py` 第 2 段 | 增加 `event_id=`/`clean_control_rule=`，或提供 `stacked_from_prebuilt=True` |
| G3 | `sp.callaway_santanna` | `clustervars=` 高于个体层级时强制 `bstrap=True`，否则抛 `MethodIncompatibility`。设计上合理（解析 SE 不含组内相关），但与 R `did` 默认行为不同，且 biters=1000 很慢。 | `sp.callaway_santanna(..., clustervars="statenum")` → `MethodIncompatibility: Clustering beyond the unit level requires bstrap=True` | 文档中提示；默认 biters 可在大样本时自适应 |
| G4 | `sp.aggte` 返回值 | 事件研究表放在 `result.detail`，而 `stacked_did` 放在 `model_info['event_study']`，`sun_abraham` 又是另一处。统一取表需要写三套分支。 | `modern_extensions.es_table()` | 统一 `result.event_study` 属性 |
| G5 | `sp.did_imputation` | 无 `weights=`（BJS Stata 版支持 `wtr()`）；`pretrends=` 若等于最短处理前期数会报共线性错误（报错信息清楚，给了恢复建议）。 | `pretrends=12` → `MethodIncompatibility ... pretrends=11` | 增加权重 |
| G6 | `sp.honest_did` | 只接受 CS / SA 的 `CausalResult`；不能直接喂 `hdfe_ols` 的事件研究系数 + vcov（即论文主规格 / 手工堆叠 TWFE）。MCP 工具列表中有 `honest_did_from_result`，但 Python 包里**不存在**该函数（`AttributeError`）。 | `sp.honest_did_from_result` → `AttributeError: module 'statspai' has no attribute 'honest_did_from_result'` | 暴露 `honest_did(betahat=, sigma=, num_pre=, num_post=)` 纯数组接口；MCP 与 Python API 对齐 |
| G7 | `FEOLSResult.vcov` | 返回无行列名的 `ndarray`，而 `params` 是带名 Series；取子块必须自己对齐索引。 | `type(sp.hdfe_ols(...).vcov)` → `numpy.ndarray` | 返回 DataFrame 或提供 `vcov_df` |
| G8 | `sp.hdfe_ols` 性能 | 含 5,967 个工资档 × 州线性 **加二次** 斜率时（Table 1 第 3、6 列），MAP 收敛极慢（共享机器上单个回归 2–4 小时）；无迭代进度输出。 | `replicate_table1.py --specs 10` 日志 | 加 `verbose=`/进度条；对斜率吸收用 LSMR 默认或先正交化 t 与 t² |
| G9 | 方法覆盖 | `sp.bunching` 是 Saez/Kleven 的"税收扭结聚集"估计量，**不是** CDLZ 的"分工资档事件研究 bunching"。后者需要像本项目 `bunching.py` 这样手写（处理变量 × 工资档、E/B/EWB 常数、delta 方法）。 | — | 提供 `sp.cdlz_bunching(data, wage_bin=, event_time=, ...)` 封装 |
| G10 | `sp.sun_abraham` | 11 万行、约 100 个队列时单次 340 秒，明显慢于 `eventstudyinteract`；`weights=` 已支持。 | extensions 日志 | 稀疏交互矩阵 |

### 5.3 本次没有发现的 bug

- 未发现 `hdfe_ols` 在权重、聚类或 FE 上的静默错误（与作者 `.ster` 逐系数对上）。
- 兄弟项目报告的 `sp.iv` 忽略权重、`sp.romano_wolf` 行删除问题在本项目未涉及。

---

## 6. 现代方法扩展（非复现，明确标注为扩展）

脚本：`Program/statspai/modern_extensions.py`；输出：`Results/statspai/ext_*.csv`、`ext_eventstudy_compare.png`。

### 6.1 设计

- 数据：作者的堆叠事件文件 `stackedevents_regready_pre12.dta`（138 个主要事件 × 51 州 × 事件时间 −12…19 季度），按作者 `stacked_events_event_specific_regressions_DC_fulltable_clean_controls_QJE.do` 的规则保留 `cleansample==1` 且剔除"窗口内有其他主要事件"的对照州（干净对照）→ 109,326 行、3,947 个事件 × 州单位。
- 结果：州-季度层面 [MW−4, MW) 岗位/人口（missing）、[MW, MW+5) 岗位/人口（excess）及二者之和（affected = 聚集就业变化），均除以 EPOP₋₁ = 0.5726。
- 估计量：① 手工堆叠 TWFE（`sp.hdfe_ols`，事件 × 州 FE + 事件 × 事件时间 FE + 事件 × 联邦/其他事件控制 FE，州人口加权，州聚类）；② `sp.stacked_did`；③ `sp.callaway_santanna`（control_group="nevertreated" 即干净对照，回归调整，州聚类 bootstrap 199 次）；④ `sp.sun_abraham`（IW，加权）；⑤ `sp.did_imputation`（BJS）；⑥ `sp.honest_did`（Rambachan–Roth 平滑性约束）作用于 SA 结果。
- CS/SA/BJS 中单位 = 事件 × 州，时间 = 日历季度，队列 = 该事件的处理季度（对照州 g=0）。这是把**非吸收、多次**的最低工资上调强行放进"吸收处理"框架的一种近似；估计对象与论文不同，只能作为稳健性参照。

### 6.2 结果（5 年平均，除以 EPOP₋₁）

| 估计量 | Δ(missing+excess) | 备注 |
|---|---|---|
| 手工堆叠 TWFE（hdfe_ols） | −0.000 (0.003) | missing −0.017 (0.003)，excess +0.017 (0.002)，与 Table 1 第 1 列 −0.018 / +0.021 同量级 |
| `sp.stacked_did` | 0.005 (0.003) | 无权重、对照非事件特定 |
| `sp.callaway_santanna`（dynamic，e=0..19 均值） | −0.003 (0.005) | 前趋势点估计为正（τ=−3 约 0.009），CI 覆盖 0 |
| `sp.sun_abraham`（IW，e=0..19 均值） | 0.000 (0.004) | |
| `sp.did_imputation`（BJS 总 ATT，未加权） | 0.002 (0.002) | |

年度路径（手工堆叠）：missing jobs 在 τ=0 骤降到 −0.019，τ=4 仍为 −0.013；excess jobs τ=0 为 +0.021，τ=4 为 +0.013；两者之和在 τ=−3…4 都在 ±0.002 之内——与论文 Figure 3 的"镜像"形态一致。唯一值得注意的是 τ=−2 的 missing jobs 前趋势 +0.004 (0.0007) 与 excess −0.004 (0.002)：在 MW 上调前一年半，低于新 MW 的岗位略多、高于的略少——这与论文解释一致（上调前实际 MW 被通胀侵蚀），且二者相互抵消。

**HonestDiD（SA，e=0，平滑性约束 M 以每季度 EPOP 单位计）**：M=0 时 95% 稳健 CI（除以 EPOP₋₁）为 [−0.009, 0.004]；M=0.005（相当于允许每季度 0.9% 的线性趋势偏离斜率变化，远大于估计出的前趋势）时为 [−0.018, 0.013]，始终包含 0 且排除大幅负效应。

**结论**：用 2021 年以后的异质性稳健估计量重估"聚集就业变化"，结论与原文一致——最低工资上调消灭的低于新 MW 岗位几乎被新 MW 附近新增岗位完全抵消，总就业效应统计上为零，负效应的置信上界很窄。原文 Section 4 的"干净对照堆叠"本身就是现代 stacked DID 的原型，所以原结论对交错处理偏误不敏感并不意外。

---

## 7. 对 StatsPAI 的改进建议

1. **新增 CDLZ 分布式 bunching 估计量**：输入（州 × 工资档 × 季度）面板、MW 序列、事件定义，输出 Δa、Δb、%Δw、%Δe 与两种弹性；内部即 `hdfe_ols` + delta 方法。本项目 `Program/statspai/bunching.py` 可作为参考实现。
2. **`stacked_did` 增强**：权重、事件级干净对照规则、非吸收处理、可传入预先堆叠的数据、按年度合并 event time（`bin_width=`，`event_study` 已有）。
3. **HonestDiD 纯数组接口**，并让任意 `hdfe_ols` 事件研究结果可直接进入 `honest_did`；修正 MCP 工具与 Python API 不一致（`honest_did_from_result`）。
4. **统一事件研究结果结构**（`result.event_study` DataFrame：relative_time / att / se / ci）。
5. **Stata 语义工具**：提供 `sp.stata.lag(df, var, k, panel=)`、缺失值比较（missing = +∞）与 float32 精确比较的辅助函数——这类复现最容易出错的地方都在这里。
6. **性能**：高维变斜率吸收的进度输出与更好的默认求解器。
