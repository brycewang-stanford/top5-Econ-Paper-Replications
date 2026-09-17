# StatsPAI 复现问题汇总（8 篇 top-5 论文）

> 环境：statspai 1.28.0 · Python 3.13 · 对照基准为作者原始 Stata 代码在本机 Stata 18 MP 上的重跑结果（以及 R `did`/`HonestDiD`、Stata `boottest`/`weakiv`、AKM/BHJ 作者包等参考实现）。
> 每条问题的最小复现、报错信息与数值证据见对应项目的 `Materials/论文模型解读与StatsPAI复现分析.md`。
> 标注 **[已独立复核]** 的条目由汇总者在全新脚本中重新复现过；其余条目由各项目复现过程发现并在项目笔记中给出证据。

## 项目代号

| 代号 | 项目 | 主要方法 |
|---|---|---|
| ADH | [AER2013-China-Syndrome](AER2013-China-Syndrome/) | 加权 shift-share 2SLS |
| UCT | [QJE2016-Cash-Transfers-Kenya](QJE2016-Cash-Transfers-Kenya/) | 两层随机 RCT、多重检验、Lee bounds |
| BP | [QJE2019-Busting-the-Princelings](QJE2019-Busting-the-Princelings/) | HDFE DID、ordered probit、交错 DID |
| KIN | [QJE2019-Kinship-Cooperation-Moral-Systems](QJE2019-Kinship-Cooperation-Moral-Systems/) | 截面 OLS + FE、敏感性分析 |
| MW | [QJE2019-Minimum-Wages-Low-Wage-Jobs](QJE2019-Minimum-Wages-Low-Wage-Jobs/) | 堆叠事件研究 / bunching |
| WD | [QJE2020-Watering-Down-Environmental-Regulation](QJE2020-Watering-Down-Environmental-Regulation/) | 空间 RD、diff-in-disc |
| AI | [QJE2023-AI-tocracy](QJE2023-AI-tocracy/) | 事件研究、天气 IV、LASSO IV |
| WoP | [QJE2023-Web-of-Power](QJE2023-Web-of-Power/) | 连续处理 DID、Conley SE、IV |

## 一、做得好的地方

- `sp.hdfe_ols` 的 reghdfe 口径（嵌套 FE 自由度、单例剔除、`aw` 权重、变斜率吸收）在 MW 的 190+ 个单元格上与作者 `.ster` 一致到 1e-9，无需任何调整。
- `sp.rdrobust` 在给定带宽时与 Stata `rdrobust` 在 WD 的 170 个 RD 单元格上完全一致（相对差 < 1e-5）。
- `sp.feols`（pyfixest 后端）配合显式 `ssc` 设置，可精确复现 `areg`/`reghdfe`/`ivregress` 的聚类标准误（UCT、KIN、ADH、WoP）。
- `sp.conley` 数值正确（KIN 与自写实现差 1e-13；WoP 与作者 `reg2hdfespatial` 一致到 3 位小数）。

## 二、静默给出错误结果（最高优先级）

这些问题不报错、不警告，直接返回错误数字。

| # | 函数 | 问题 | 证据 | 来源 |
|---|---|---|---|---|
| S1 | `sp.iv` | `weights=` 参数被接受但**完全忽略**。 | **[已独立复核]** 异质效应模拟数据：linearmodels 加权 2.3845 / 未加权 1.7858；`sp.iv(weights="w")` 返回 1.7858，无警告。ADH Table 3 col 6：−0.303 vs 正确 −0.596。 | ADH |
| S2 | `sp.callaway_santanna` | 无有效对照组的 (g,t) 单元格记为 ATT=0、SE=inf，并**计入总体聚合**；同时对照组全部已处理的前期单元格仍给出估计（用已处理单位作对照）。 | **[已独立复核]** 3 个队列、无从未处理组、真实 ATT=1：总体估计 0.422；队列 2008 的 t≥2006 单元格 ATT=0、CI 上界 inf；队列 2008 的 2002–2005 前期"效应"≈1.0。BP 中央巡视队列返回 ATT 0 / SE 0。 | BP、AI |
| S3 | `sp.callaway_santanna` | 非平衡面板上 `control_group="notyettreated"` 被静默忽略（结果与 nevertreated 完全相同）；`estimator="reg"` 在非平衡面板上所有单元格返回 0 / inf。 | 项目笔记最小复现 | BP、AI |
| S4 | `sp.ssaggregate` | AKM 暴露稳健标准误公式错误。 | 0.018 vs AKM 作者 R 包 0.110 | ADH |
| S5 | `sp.shift_share_se` | 用结果变量的拟合值代替工具变量。 | 0.0076 vs 0.110 | ADH |
| S6 | `sp.hdfe_ols` | 不剔除被 FE 吸收后共线的回归元：精确共线时 `LinAlgError`；浮点近似共线时给出 ±4.8e5 的系数并改变目标系数（0.0196 vs 0.0214）。 | WoP Huai 列 | WoP |
| S7 | `sp.hdfe_ols` | 一个 FE 嵌套在另一个 FE 中（year ⊂ prefecture×year）时重复扣除自由度，SE 偏大约 0.8%。 | WoP | WoP |
| S8 | `sp.hdfe_ols(wild=True)` | wild cluster bootstrap 每次抽样不重新吸收 FE，p 值偏小。 | p=0.045 vs `boottest` 0.218 | WoP |
| S9 | `sp.romano_wolf` | 跨结果变量**整行删除**缺失值且不报告 N。 | 国家层面 6 个结果的样本从 70–79 缩到 15，调整后 p 值反而大于 Holm | KIN |
| S10 | `sp.romano_wolf` | 控制约 120 个村庄虚拟变量时，调整后 p 值出现下限（300 次抽样 0.027，2000 次约 0.07），即使 abs(t)≈10。疑为 bootstrap 抽样中设计矩阵奇异。 | UCT | UCT |
| S11 | `sp.anderson_rubin_test(absorb=, cluster=)` | 与约简式检验矛盾（p=0.068 vs 0.025）；tF 临界值用非稳健一阶段 F（749）而非有效 F（11.5）。 | WoP | WoP |
| S12 | `sp.honest_did` | 原生相对幅度（RM）近似严重高估稳健性。 | [0.085, 0.540] vs 精确 [−1.47, 1.71] | WoP |
| S13 | `sp.feols` | 共线虚拟变量的剔除集合与 Stata 不同，静默改变事件研究系数；回归元量级约 1e7 时去均值不收敛，返回 NaN 或错误的聚类 SE；静默丢弃全零回归元。 | AI、BP | AI、BP |
| S14 | `sp.rlasso_iv` | 未选中任何工具变量时返回 SE≈1e14 的数值，而不是报错。 | AI | AI |
| S15 | `sp.ivreg(vce="wild")` | 置信区间由 β=0 下的 bootstrap 分布平移到点估计构造，而非检验反演（`boottest` 做法）；p 值可比，区间不可比。 | ADH | ADH |
| S16 | `sp.oprobit` | BFGS + 有限差分梯度、默认 `maxiter=100`，未标准化回归元时提前停止（0.7397 vs 0.742）；`converged` 标志不可靠；约 300 个虚拟变量时比解析 Newton 慢 2,000–4,000 倍。 | BP | BP |
| S17 | `sp.BartikIV` | 默认 `leave_one_out=True`，缺少所需输入时静默退回普通工具变量。 | ADH | ADH |
| S18 | `sp.stacked_did` | 把已堆叠数据（单位 = 事件×州）传入时，g=0 对照单位被重复用于所有队列。 | MW | MW |
| S19 | `sp.lee_bounds` | 修剪约定与 Lee (2009) / Stata `leebounds` 不同。 | UCT Table III 资产上界 15.43 vs 论文 12.84 | UCT |

## 三、崩溃 / 不应出现的报错

| # | 函数 | 问题 | 来源 |
|---|---|---|---|
| C1 | `sp.rdrobust(cluster=...)` | `y` 有缺失值时 `IndexError`：聚类向量没有用同一个掩码过滤。 | WD |
| C2 | `sp.rdrobust` / `sp.rdbwselect` | `h`/`b` 类型标注允许 (左, 右) 元组，但输入校验拒绝元组。 | WD |
| C3 | `sp.regress` | 共线虚拟变量直接报错，而不是像 Stata 那样 omit。 | BP |
| C4 | `sp.feols` | 570 万行时内存峰值 12.4 GB，`hdfe_ols` 2 秒完成同一回归；不提示换用。 | BP |
| C5 | `sp.honest_did_from_result` | MCP 工具列表里有，Python 包里不存在（`AttributeError`）。 | MW |

## 四、缺失功能（阻碍精确复现）

**RD**
- `rdrobust`/`rdbwselect` 没有 `masspoints` 选项，因此用 `masspoints(off)` 的论文无法用 StatsPAI 自选带宽复现（WD Table I col 1：0.23 vs 0.34）。
- 没有 diff-in-discontinuities 估计量。
- `rd_honest`、`rdbwsensitivity`、`rdplacebo`、`rdplot` 没有 `cluster`。

**IV / shift-share**
- IV、弱 IV、shift-share 系列函数都不接受权重。
- `sp.iv` 不能关闭聚类小样本校正（`ivregress` 默认无校正）。
- 没有聚类的 Anderson–Rubin 置信集，没有 cross-fit LASSO IV。
- Rotemberg 权重输出缺少 GPSS 标准表，没有 BHJ 行业层面转换。

**DID / 事件研究**
- `stacked_did` 没有 `weights=`，没有事件内"干净对照"规则，也不支持非吸收的多次处理。
- `did_imputation` 没有权重，也不自动剔除单位。
- `honest_did` 不能直接接收 (β, Σ)。
- `cgs_continuous_did` 没有聚类 SE。
- `bacon_decomposition` 只接受严格平衡面板。
- `hdfe_ols(vce="conley")` 只支持截面。
- 没有 xtevent 风格的连续政策事件研究。
- formula 里 `i(..., ref=[a, b])` 不支持两个基期。
- `sp.bunching` 是 Saez/Kleven 扭结聚集估计量，不是 CDLZ 的分工资档事件研究。
- 事件研究表在 `aggte`、`stacked_did`、`sun_abraham` 三个函数里放在三个不同位置。
- `sun_abraham` 在约 100 个队列时很慢。

**RCT / 推断**
- 没有 `suest` 式的跨方程聚类联合检验，`sureg` 没有 cluster。
- 没有基于置换的 stepdown FWER。
- `ri_test` 不能分层置换，也不能用回归统计量。
- `lee_bounds` 只返回中点 SE，不支持协变量收紧。
- `bootstrap` 没有 Stata `bootstrap: regress` 式的聚类 bootstrap 回归（只能逐个标量，无协方差矩阵）。
- `qreg` 只返回第一个回归元，无多分位数 bootstrap，每次拟合约 6 秒。

**其他**
- 没有 `sp.ssc` 预设来一键匹配 `areg`、`reghdfe`、`ivreghdfe` 的小样本校正。
- 结果对象没有调整 R²，也没有顶层 `.nobs`/`.r2`。
- `spec_curve` 不能吸收 FE。
- `oprobit` 的公式不支持 `C()`。

## 五、API 摩擦

- `import statspai.rd.rdrobust` 得到的是函数而不是模块（名字遮蔽）。
- `oster_bounds` 把 δ* 放在 `delta_for_zero` 键下，`oster_delta` 则不返回 δ*。
- `regress(...).pvalues` 是裸 ndarray，而 `params`、`std_errors` 是带标签的 Series；`hdfe_ols` 的 `vcov` 也是无标签 ndarray。
- `sp.conley` 不检查传入数据与模型估计样本是否逐行对齐。
- `callaway_santanna` 在高于个体层级聚类时强制 `bstrap=True`，与 R `did` 默认行为不同。

## 六、建议的修复顺序

1. **S1、S2/S3、S4/S5：** 直接改变论文结论（ADH 系数减半；CS 总体 ATT 偏向 0）。
2. **S6–S8、S13：** HDFE 共线处理、自由度与 wild bootstrap 是复现 Stata 结果的基础设施。
3. **S9–S12：** 推断工具的静默错误（多重检验、弱 IV、HonestDiD）。
4. **C1–C5** 和 RD 的 `masspoints`、`stacked_did` 的权重等高频缺失功能。
