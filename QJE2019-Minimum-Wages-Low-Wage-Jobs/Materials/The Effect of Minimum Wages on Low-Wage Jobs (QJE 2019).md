---
title: "The Effect of Minimum Wages on Low-Wage Jobs"
authors: Doruk Cengiz, Arindrajit Dube, Attila Lindner, Ben Zipperer
journal: Quarterly Journal of Economics
year: 2019
volume: "134(3): 1405–1454"
doi: 10.1093/qje/qjz014
package: Harvard Dataverse doi:10.7910/DVN/TJCTC7
tags: [minimum-wage, bunching, stacked-event-study, labor-demand, CPS]
---

# The Effect of Minimum Wages on Low-Wage Jobs（QJE 2019）阅读笔记

> 本地 PDF 为 NBER 工作论文版 w25434（2019 年 1 月）；QJE 正式版在 OUP 付费墙后。对照作者复现包中 `tables/Table1.tex` 等文件，工作论文版主表数字与发表版一致。图表编号沿用工作论文/复现包（Figure 1 = 概念图，Figure 2 = 分工资档估计，Figure 3 = 事件时间路径）。

## 1. 研究问题

最低工资（MW）上调究竟消灭了多少低薪岗位？传统文献把州级总就业（或青少年就业）对 log MW 做双向固定效应回归，结论在 −0.1 到 −0.3 的弹性之间争论不休，且对控制趋势的方式极其敏感。作者提出 **"bunching"（聚集）估计量**：MW 上调后，新 MW 以下的岗位会"消失"（missing jobs, Δb），而新 MW 附近及略高处的岗位会"增多"（excess jobs, Δa）。二者之和 Δa+Δb 就是被 MW 直接影响的岗位净变化。

优点：
- 只看工资分布底部，天然过滤掉上尾（高薪岗位）的随机冲击——TWFE-logMW 模型的"负效应"很大一部分来自上尾就业变动，这显然不是 MW 造成的（Figure 6）；
- Δb 本身就是"第一阶段"：可以直接看 MW 是否真的有牙齿（binding）；
- 同时给出受影响工人的工资变化 %Δw 和就业变化 %Δe，从而得到"对自身工资的就业弹性"（竞争模型下的劳动需求弹性）。

## 2. 数据

| 数据 | 用途 |
|---|---|
| NBER CPS-MORG 1979–2016 | 按州 × 季度 × $0.25（2016 年美元）实际工资档汇总就业人数；剔除工资插补观测；1994q1–1995q3 无可靠插补标记而整段剔除 |
| QCEW | 把 CPS 州-季度总就业人口比校准到 QCEW（降低抽样误差，显著提高精度） |
| Vaghul & Zipperer (2016) 州最低工资日度序列 | 取季度最大值；CPI-U-RS 平减 |
| OR/MN/WA 行政工资数据 | 附录 D：检验 CPS 工资测量误差 |

样本：117 个工资档 × 51 州 × 季度，回归观测 847,314（Table 1），底层约 469 万个人观测。

**事件定义（138 个"显著"州级上调）**：实际 MW 上调 > $0.25，且上调前一年新 MW 以下的工人占比 ≥ 2%；联邦上调单独控制（不作为事件，因为没有"对照州"）。

## 3. 识别与核心方程

### 3.1 分工资档事件研究（方程 1）

$$\frac{E_{sjt}}{N_{st}}=\sum_{\tau=-3}^{4}\sum_{k=-4}^{4}\alpha_{\tau k}\,I^{\tau k}_{sjt}+\mu_{sj}+\rho_{jt}+\Omega_{sjt}+u_{sjt}$$

- $E_{sjt}$：州 s、$0.25 工资档 j、季度 t 的就业；$N_{st}$：16 岁以上人口。
- $I^{\tau k}_{sjt}=1$：若 τ 年前（按 4 个季度年化）MW 上调，且档 j 位于新 MW 的 [k, k+1) 美元区间。τ=−1 为基期。
- $\mu_{sj}$：州 × 工资档 FE；$\rho_{jt}$：季度 × 工资档 FE（吸收全国工资不平等演变）。
- $\Omega_{sjt}$：小额上调与联邦上调的控制（{BELOW, ABOVE} × {EARLY, PRE, POST} 共 6+6 个变量，代码中作为类别型吸收项）。
- 按州聚类；按州-季度人口加权。

代码实现要点（`create_programs.do`）：τ=−1 的归一化是通过在吸收项中加入 `window_*`（8 个年度虚拟变量之和）实现的，于是 τ=0..4 的系数直接就是相对 τ=−1 的差。

### 3.2 汇总统计量

- $\Delta b=\frac{1}{5}\sum_{\tau=0}^{4}\sum_{k=-4}^{-1}(\alpha_{\tau k}-\alpha_{-1,k})/\overline{EPOP}_{-1}$，$\Delta a$ 同理取 k=0..4；代码里乘 4 是因为每个 $1 区间含 4 个 $0.25 档。
- %Δ 受影响就业 $=(\Delta a+\Delta b)/\bar b_{-1}$，$\bar b_{-1}$=上调前新 MW 以下岗位占比（8.6%）。
- 对 MW 的就业弹性 $=(\Delta a+\Delta b)/\%\Delta MW$（%ΔMW=10.1%）。
- 受影响工人平均工资变化（方程 2）：$\%\Delta w=\frac{\%\Delta wb-\%\Delta e}{1+\%\Delta e}$，工资总额变化 $\Delta wb=\sum_k (k+\overline{MW})(\alpha_k-\alpha_{-1,k})$。
- 对自身工资的就业弹性 $=\%\Delta e/\%\Delta w$，delta 方法求标准误。

### 3.3 事件逐个估计（Section 4 / Figure 5）

为每个事件 h 构造"干净对照"数据集（窗口内没有任何其他事件的州作对照），在州 × 季度层面对 [MW−4, MW) 与 [MW, MW+5) 的就业人口比做 TWFE 事件研究；把 138 个数据集**堆叠**（stacked），事件 × 州、事件 × 季度 FE —— 这就是后来被称为 **stacked DID** 的估计量（Baker, Larcker & Wang 2022 等把它作为应对交错处理 TWFE 偏误的方案之一）。

## 4. 主要发现

| 发现 | 证据 |
|---|---|
| MW 以下岗位显著减少：Δb = −0.018 (0.004)，约 3/4 集中在新 MW 下方 $1 档 | Figure 2, Table 1 col 1 |
| MW 处及以上 $4 以内岗位增加：Δa = 0.021 (0.003)；$5 以上各档接近 0，累计和平坦 → 溢出效应有限（约到 $3 以上，≈ 第 23 百分位） | Figure 2 |
| 受影响就业变化 +2.8% (2.9%)，不显著；对 MW 就业弹性 0.024 (0.025)；受影响工资 +6.8% (1.0%)；对自身工资就业弹性 0.411 (0.430)，95% CI 排除 < −0.45 | Table 1 col 1 |
| 事件时间路径：τ=0 时 Δb 骤降、Δa 骤升，持续 5 年；前趋势很弱 | Figure 3 |
| 加入工资档 × 州线性/二次趋势、工资档 × 分区 × 时期 FE，结论稳健（工资 +4.3%–6.8%，就业 −1.9% 到 +2.8%，均不显著） | Table 1 cols 2–6 |
| 州 × 季度"简化方法"（$15 以下就业与工资总额）给出几乎相同的结果：就业 0.027 (0.028)、工资 0.065 (0.010) | Table 1 col 7 |
| 分人群（高中以下、青少年、女性、黑人/西裔、Card–Krueger 高暴露概率组）：Δb 更大，但就业变化都不显著 | Table 2 |
| 分行业：可贸易部门（制造业）点估计为负但极不精确；餐饮零售部门无负效应 | Table 3 |
| 工资溢出约占工资上涨的 40%（0.397） | Table 4 |
| 事件异质性：Kaitz 指数（MW/中位工资）在 0.4–0.55 区间内，就业变化与 Kaitz 指数无关（slope 0.006 (0.048)） | Figure 5 |
| TWFE-logMW 的"负效应"（弹性 −0.089）主要来自 $15 以上岗位的变化 → 模型设定问题 | Figure 6 |

## 5. 现代方法再审视（2021–2026 视角）

1. **交错处理与负权重**：论文主规格（方程 1）是含 leads/lags 的"动态 TWFE"，事件又大量重叠（同一州多次上调）。Goodman-Bacon (2021)、Sun & Abraham (2021)、de Chaisemartin & D'Haultfœuille (2020) 表明此类回归在效应随事件时间/队列异质时可能被"已处理单位作为对照"污染。作者在 Section 4 的 **stacked + clean controls** 设计正好规避了这一点，且结果（Figure 5、附录 G）与主规格一致——这是论文被广泛引用为 stacked DID 起源的原因。
2. **多次处理（非吸收型）**：CS/SA/BJS 都假定处理吸收（一旦处理永远处理），而最低工资是多次、不断上调的连续强度处理。严格套用只能取"首次显著事件"或用堆叠的事件级单位，这会改变估计对象（estimand）。本项目的 StatsPAI 扩展按事件 × 州单位、干净对照做 CS / SA / BJS 比较，明确标注为扩展。
3. **前趋势与 HonestDiD**：Figure 3 在 τ=−3 有轻微偏离。Rambachan & Roth (2023) 的平滑性约束 ΔSD(M) 可以量化"前趋势外推"下 τ=0..4 效应的稳健置信区间；本项目在州-季度汇总的 Δa+Δb 事件研究上报告 honest_did 结果。
4. **测量误差**：Δa+Δb 对工资误报是稳健的（误报只在 [MW, W) 内部重新分配），这是 bunching 设计相对于"MW 附近工人就业"类估计的核心优势；附录 D/F 用行政数据与解卷积（deconvolution）验证。
5. **外部有效性**：138 个事件的 MW/中位工资比最高约 0.55；对 $15 联邦最低工资（在低工资州 Kaitz > 0.7）的外推需要谨慎——作者在 Figure 5 的讨论中也承认这一点。

## 6. 复现状态（本仓库）

见 [Results/comparison.md](../Results/comparison.md) 与 [论文模型解读与StatsPAI复现分析.md](论文模型解读与StatsPAI复现分析.md)。
