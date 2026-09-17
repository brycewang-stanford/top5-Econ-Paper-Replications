---
title: "AI-tocracy"
authors: [Martin Beraja, Andrew Kao, David Y. Yang, Noam Yuchtman]
journal: Quarterly Journal of Economics
year: 2023
volume: "138(3)"
pages: 1349-1402
doi: 10.1093/qje/qjad012
method: [panel-FE, LASSO-IV, weather-IV, event-study, stacked-event-study, triple-difference]
field: [political-economy, innovation, artificial-intelligence, china]
status: read
read-date: 2026-09-17
tags:
  - paper/QJE
  - method/event-study
  - method/IV
  - topic/AI
  - topic/autocracy
  - topic/china
---

# AI-tocracy (QJE 2023)

> [!abstract] 一句话结论
> 中国地方"维稳"与人脸识别 AI 创新**相互强化**：① 上季度骚乱（unrest）每增加 1 个标准差，地方公安的人脸识别 AI 采购增加约 **0.20 SD**（OLS，Table II A）/ **0.38 SD**（天气 LASSO-IV，Table II B）；② 过去累积的公安 AI 采购存量**削弱了"适宜抗议的天气"对骚乱的推动作用**（交互项 −0.23，Table IV）；③ 在骚乱之后拿到第一份公安合同的 AI 企业，两年后累计软件多出约 **10.7 个**（Table VI），且商业软件也增加（数据共享的溢出机制），出口概率提高约 3.6 个百分点（Table VIII）。

> [!info] 元信息
> **原文**：Beraja, Martin, Andrew Kao, David Y. Yang and Noam Yuchtman (2023). "AI-tocracy." *Quarterly Journal of Economics*, 138(3): 1349–1402.
> **DOI**：[10.1093/qje/qjad012](https://doi.org/10.1093/qje/qjad012)（开放获取，本地 PDF：`Materials/AI-tocracy (QJE 2023).pdf`）
> **复现包**：Harvard Dataverse [doi:10.7910/DVN/GCOVGX](https://doi.org/10.7910/DVN/GCOVGX)（CC0，Replication.zip 610 MB，解压 5.2 GB，数据全部公开）
> **配套长文**：`论文模型解读与StatsPAI复现分析.md`（逐方程拆解、复现细节、StatsPAI bug）

---

## 1. 为什么值得读

- **问题重要**：经典政治经济学认为专制与前沿创新相冲突（产权不稳、租金侵蚀）。本文提出并检验"AI 这种**预测/监控技术**可能与专制互相强化"的均衡——"AI-tocracy"。
- **数据独特**：299 万份政府采购合同 + 7,837 家人脸识别 AI 企业 + 工信部软件著作权登记（LSTM 文本分类为政府/商业）+ GDELT 骚乱事件 + 逐日气象站数据。
- **两个方向都做了**：政权 → 买 AI（因果方向 1）；买 AI → 企业创新（因果方向 2），并讨论溢出与总量效应。
- **方法上的教学价值**：高维天气工具变量的 **cross-fit partialing-out LASSO IV**（`xpoivregress`）、"天气冲击 × 存量"的异质性识别、带对照企业的堆叠事件研究。

## 2. 研究问题

1. 地方政府是否因为**政治动荡**而采购人脸识别 AI（而不是反过来）？
2. 采购的 AI 是否真的**提高了政治控制能力**（压低骚乱）？
3. 出于政治动机的公安合同是否**促进了 AI 企业的创新**——不仅是政府软件，也包括商业软件？是否导致出口？是否挤出其他企业？

## 3. 数据（§II）

| 数据 | 来源 | 层级 | 本文用法 |
|---|---|---|---|
| 政治骚乱 | GDELT 2014–2020，9,267 起（protest / demand / threat） | 事件 → 地级市×季度 | 解释变量 Unrest，Table I A |
| 天气 | NOAA/WMO GSOD，18 个变量，260 个站匹配 344 个地级市 | 站×日 | 构造 IV：天气×天气、天气×"当天全国其他地方有骚乱" |
| AI 采购 | 中国政府采购网 2013–2019，28,023 份公安 AI 合同，6,557 份非公安 | 合同 → 地级市×季度 | 被解释变量（人均公安 AI 合同，标准化） |
| 监控摄像头 | 同上（高清摄像头采购量） | 地级市×月 | Table III |
| AI 企业与软件 | 天眼查、Pitchbook；工信部软件登记；13,000 条人工标注训练 LSTM | 软件×企业×季度 | Tables VI–VII、IX |
| 出口 | Feldstein (2019) 卡内基 AI 监控报告书目 + 新闻 | 企业 | Table VIII |

## 4. 识别策略与核心方程

### 4.1 骚乱 → AI 采购（式 1 ≡ Table II、III；Figure II、III）

$$AI_{i,t+1} = \beta\,Unrest_{it} + \alpha_t + \gamma_i + \delta_t X_i + \varepsilon_{it}$$

- $i$ 地级市，$t$ 季度；$X_i$ 为 GDP / log 人口 / 财政收入，**与季度虚拟变量交互**；列 (4)(5) 另控制 $t-2$ 期 AI 存量；按地级市聚类。
- **Panel B（LASSO IV）**：把 18 个天气变量两两交互、再与"当天全国其他地方是否发生骚乱"交互，约 380 个候选工具，用 `xpoivregress`（10 折 cross-fit、plugin λ、`rseed(1)`）做 partialing-out LASSO IV。
- **Figure II**：同时放入 $t-2$ 到 $t+3$ 的骚乱（各期对 $t$ 期正交化），检验"先买后乱"——只在 $t+1$ 显著。
- **Figure III**：OLS / LASSO-IV / 简约 IV（雨、阵风、雷暴）/ 7 天窗口 / LIML / JIVE，系数都在 0.2–0.4 之间。

### 4.2 AI 存量 → 骚乱（式 2 ≡ Table IV、V；Figure IV）

$$Unrest_{it} = \beta_1 AIstock_{i,t-1} + \beta_2 ConduciveWeather_{it} + \beta_3\, ConduciveWeather_{it}\times AIstock_{i,t-1} + \alpha_t+\gamma_i+\delta_tX_i+\varepsilon_{it}$$

- $ConduciveWeather$ = 用 LASSO 选出的天气项预测的骚乱（第一阶段拟合值，标准化）；样本限制在 1,000 km 圆内。
- 识别来自**外生天气 × 内生存量**：若 AI 真能压制骚乱，$\beta_3<0$。
- 安慰剂：非公安 AI 存量（Table V A）、滞后骚乱（Table V B）的交互项都≈0；摄像头×AI 存量交互更大（Table IV B）。

### 4.3 政治动机合同 → 企业软件（式 3–4 ≡ Tables VI、VII；Figures V、VI）

$$y_{it} = \sum_T \beta_{1T} T_{it} + \alpha_t + \gamma_i + \delta_t X_i + \varepsilon_{it}\quad(3)$$
$$y_{it} = \sum_T \beta_{1T} T_{it} + \sum_T \beta_{2T} T_{it}\times PublicSecurity_i + \alpha_t + \gamma_i + \delta_t X_i + \varepsilon_{it}\quad(4)$$

- 样本：第一份政府合同签订于**上季度骚乱高于中位数**的地级市的企业；"政治动机合同" = 这类环境下的公安合同。
- $y_{it}$ = **累计**软件数；Table VI 报告 $T=+8$（"总效应"，代码里是交互项+基准事件时点系数之和）；Table VII 报告相对非公安合同企业的差异（三重差分思路）。
- 列 (4)–(6) 用天气 LASSO 预测的骚乱定义"高骚乱"；列 (2)(5) 加企业规模×年份指数；列 (3)(6) 给对照组加权（BJS 2017 思路）。

### 4.4 出口与溢出（Table VIII、IX）

- Table VIII：企业截面，$\Delta$出口状态 对"第一份合同是否为公安合同"，合同季度 FE + 合同地 FE，按子公司数加权，稳健 SE。
- Table IX：从未拿合同企业的软件，围绕 (A) 本地骚乱、(B) 同城他企拿到政治动机合同、(C) 同母公司子公司拿到合同 的事件研究（A 用 `xtevent`，连续政策变量）。

## 5. 主要发现（逐项对应图表）

| 发现 | 数值 | 出处 |
|---|---|---|
| 骚乱 1 SD → 下季度公安 AI 采购 | +0.199 SD (0.043)，加全部控制 0.205 | Table II A |
| 天气 LASSO-IV | 0.377 (0.084)，列 (5) 0.348 | Table II B |
| 骚乱 → 高清摄像头 / AI×摄像头 | 0.436 / 0.681 (OLS)；0.593 / 1.054 (IV) | Table III |
| 事件研究：只有 $t+1$ 显著 | — | Figure II |
| 适宜天气×公安 AI 存量 | −0.2265* (0.1153)，全部控制 −0.2662** | Table IV A |
| 摄像头×AI 存量 | −0.5688** | Table IV B |
| 非公安 AI 存量 / 滞后骚乱（安慰剂） | −0.044 / −0.011，均不显著 | Table V |
| 政治动机合同 8 季度后累计软件 | 10.671*** (3.664)；政府 3.465；商业 5.098 | Table VI |
| 相对非公安合同企业 | +9.825*** (3.368)，商业 +5.482** | Table VII |
| 新出口企业概率 | +3.2 至 +3.9 pp | Table VIII |
| 溢出（本地骚乱 / 同城 / 同母公司） | 23.968** / 0.003 / −0.498（商业 1.365***） | Table IX |

## 6. 本复现的结论（2026-09）

> 详见 `Results/comparison.md`；过程与 bug 见配套长文。

- **原始代码能跑通**：21 个 section 中 20 个在 Stata 18 MP 上 rc=0（需补齐包里缺失的 `make_index_gr`、并把 `xtevent` 回退到 1.0.0）。唯一未跑的是 Figure A.10（100 个随机种子 × cross-fit LASSO IV，按本机实测 ≈30 分钟/次估计需 >50 小时）。
- **与论文逐位一致**：Table I、II（含 cross-fit LASSO IV，单表 3 小时）、III、V A、VIII、IX A（xtevent 1.0.0）、A.2–A.7；Figure II、III 的 LASSO/简约 IV/OLS 柱。Table IV、V B 仅第 4 位小数的 SE 差 0.0001（版本/数值精度）。Figure III 的 LIML 柱（0.289）在 Stata 中**数值不稳定**：工具是量级 1e13 的天气乘积，先标准化工具（不应改变估计量）后同一命令给出 0.268。
- **不能逐位复现的部分都有明确原因**：Tables VI、VII、IX B/C 的结果**依赖随机排序**——`collapse (lastnm) place` 在 425 个"同一企业-季度有多个合同地"的格子里随机取值（既改变聚类归属也改变 `place != 0` 样本筛选），`bys firm_contract qofd: drop if _n > 1` 也随机丢重复值；同一份代码换 `set sortmethod qsort` 又得到另一组数（10.663 vs 论文 10.671 vs 默认 fsort 10.783）。论文数字是作者某次运行的随机结果，差异在 1 个 SE 以内，定性结论不变——Table IX C（同母公司溢出）除外，作者单独运行过这一格，复现差异较大。
- **StatsPAI 复现**：除 cross-fit LASSO IV（StatsPAI 无对应估计量，只能近似）外，全部主文回归表逐位对上本机 Stata 结果（166/181 行 ✅，15 行 LASSO-IV 近似 ⚠️），Figure II、Figure III 的 OLS 与简约 IV 柱也逐位相同。

## 7. 用 2022–2026 的标准回看

### 7.1 论文做法 vs 现代做法

| 维度 | 论文做法 | 现代标准 | 本项目补做 |
|---|---|---|---|
| 企业事件研究的结果变量 | 已签约企业从事件时点 −1 起用**累计**软件数，事件前与"从未签约"对照副本用**当季流量** | 同一口径（全用流量或全用累计）；Borusyak–Jaravel–Spiess / Callaway–Sant'Anna 的交错 DID | E1、E2 |
| 交错处理时点 | TWFE + 堆叠副本 + 手工加权 | CS / SA / BJS 插补 | E2 |
| 预趋势 | 目测事件图 | Roth (2022) 预趋势检验功效、Rambachan–Roth honest DID | E3 |
| 聚类数 | Table VI 实际只有 38 个聚类 | 野聚类自助法 | E4 |
| 高维天气 IV | cross-fit PO-LASSO IV；简约 IV 未报告第一阶段 F | 弱工具稳健推断（AR 置信集） | E5 |
| SE 合成 | `addQuarterInter` 把两个系数的方差相加、**忽略协方差** | lincom / delta method | E1 报告两种 SE |

### 7.2 本项目补做的扩展（StatsPAI，`Results/statspai/ext_*`，`extensions_summary.csv`）

（数值见配套长文 §5 与 `Results/statspai/extensions_summary.csv`，此处列结论）

- **E1 结果变量口径**：用作者 Table VI 列 (1) 的**原样回归**，只把因变量换成当季流量 `n_software`：+8 季度效应 −0.27 (0.74)，0..8 季度流量效应加总 −4.15 (3.94)；Stata `lincom` 独立复核一致。对应 Table VII 的差分口径（公安 vs 非公安合同）也变为 +8 季度 −0.19 (0.60)、加总 −1.85 (4.24)。即论文"两年多出约 10 个软件"的主体来自**累计变量 vs 流量基准的机械差**，而不是签约后产出流量的上升（以 −1 季度为基准时）。
- **E2 交错 DID（流量）**、**E3 honest DID / 预趋势功效**、**E4 野聚类自助**（Table VI 交互项 p≈0.002，38 个聚类下仍显著）、**E5 弱工具**（简约天气 IV 的聚类第一阶段 F≈0.46，AR 置信集覆盖整个 [−1, 2] 网格）——详见长文。

## 8. 我的评注

- 方向 1（骚乱 → 采购）证据扎实：OLS 与多种 IV 一致，Figure II 的时序也支持。但 IV 的强度依赖高维 LASSO；简约天气 IV 第一阶段极弱，"IV 大于 OLS"的解读要谨慎。
- 方向 2（采购 → 创新）是论文最有新意也最脆弱的部分：结果变量在事件前后口径不一致、面板是同一企业的多个堆叠副本（从未签约副本 / 公安合同副本 / 非公安合同副本共享企业 FE），加之 `lastnm` 随机性导致结果不可逐位复现。建议读者把 Table VII 的差分（两组都累计）看作更可信的证据，并参考流量口径与现代交错 DID 的结果。
- 附带收获：`xtevent` 1.0 → 2.x 对连续政策变量端点的处理改变，会让 Table IX A 的符号翻转（23.968 → −8.678）——复现包应锁定用户命令版本。

## 9. 复现与代码

- 原始代码：`Program/Analysis/Analysis.do`（两处路径参数化修改），运行 `Program/run_original.sh`；地图 `Program/make_map_sf.R`（rgdal/rgeos/maptools → sf 移植）。
- StatsPAI：`Program/statspai/replicate_statspai.py`。
- 对照：`Results/comparison.md`。
