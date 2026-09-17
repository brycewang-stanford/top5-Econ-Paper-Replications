---
title: "Busting the “Princelings”: The Campaign Against Corruption in China’s Primary Land Market"
authors: [Ting Chen, James Kai-sing Kung]
journal: Quarterly Journal of Economics
year: 2019
volume: "134(1)"
pages: 185-226
doi: 10.1093/qje/qjy027
method: [high-dimensional-FE, spatial-matching, triple-difference, ordered-probit, event-study]
field: [political-economy, corruption, land-market, china]
status: read
read-date: 2026-09-16
tags:
  - paper/QJE
  - method/DID
  - method/HDFE
  - topic/corruption
  - topic/china-political-economy
---

# Busting the Princelings (QJE 2019)

> [!abstract] 一句话结论
> 2004–2016 年中国一级土地市场（地方政府是唯一卖方）上，与**政治局委员有亲属关系的"太子党"企业**买地，比同城、同年、同用途、同月、500 米以内的非关联企业便宜 **55.4%–59.9%**（Table V：log 价格系数 −0.808 至 −0.904）。卖地给他们的**省委书记晋升概率高 23.4%**（Table VIII）。2012 年后习近平的**中央巡视**和**更换省委书记**使这一折扣缩小（Table X），靠"送折扣"换晋升的通道也随之关闭（Table XII）。

> [!info] 元信息
> **原文**：Chen, Ting and James Kai-sing Kung (2019). "Busting the 'Princelings': The Campaign Against Corruption in China's Primary Land Market." *Quarterly Journal of Economics*, 134(1): 185–226.
> **DOI**：[10.1093/qje/qjy027](https://doi.org/10.1093/qje/qjy027)
> **复现包**：Harvard Dataverse [doi:10.7910/DVN/XW6OJT](https://doi.org/10.7910/DVN/XW6OJT)（CC0；7 个 .dta 共约 1.07 GB + 一个 `Tables&Figures.do`）
> **全文来源**：OUP 期刊 HTML 全文（bronze OA，Wayback 2020-07-29 快照），存为 `QJE2019-Busting-the-Princelings-fulltext-OUP-wayback-20200729.html` / `.txt`。期刊 PDF 被 Cloudflare 拦截，未能下载。
> **配套长文**：`论文模型解读与StatsPAI复现分析.md`

---

## 1. 为什么值得读

- **把"腐败"量化成价格**：土地出让记录（中国土地市场网）中每一宗交易都有价格、面积、用途、出让方式，太子党关联是企业层面的哑变量。价格差就是租金转移，比问卷或新闻计数的腐败指标干净得多。
- **"交换"的两端都能看到**：一端是企业拿到的折扣（Table V），另一端是官员得到的晋升（Tables VIII–IX）。一篇文章同时刻画了"送"和"收"。
- **反腐运动作为冲击**：中央巡视组进驻时点和"习近平任命的省委书记"在各省之间先后不同，提供了（交错的）准实验变异（Tables X–XII）。
- **后续争议很有教学价值**：Manso (2026, *JAE*/arXiv 2502.07692) 发现约 1/3 交易是完全重复行，并且企业面板里所谓 "log 面积" 实为 面积/10⁶。Wiebe (2024) 发现晋升变量存在编码错误。复现者应当知道这些。

---

## 2. 研究问题

1. 与政治局委员（及常委）有亲属关系的企业，在地方政府垄断的一级土地市场上是否拿到价格折扣？折扣多大？（§IV）
2. 地方官员给折扣能换到什么？是否提高晋升概率？（§V）
3. 习近平 2012 年后的反腐运动（中央巡视、撤换省委书记）是否压缩了这种交换？（§VI）

---

## 3. 数据

| 数据 | 单位 / 规模 | 来源 | 用于 |
|---|---|---|---|
| `price.dta` | 1,208,621 宗土地交易，2004–2016 | 中国土地市场网（国土资源部） | Tables III, V, X；Figure V |
| 太子党关联 | 企业层面 0/1；另有 PSCM（常委）、Retired（已退休） | 作者整理政治局委员亲属与其持股/任职企业（Table I, II） | 全文 |
| 空间匹配样本 | `near1500` / `near500`：与某宗太子党地块距离 ≤ 1,500 m / 500 m 的交易 | 作者地理编码 | Table V (2)(3)(5)(6)… |
| `firm_panel.dta` | 企业×年，5,690,984 obs | 同上汇总 | Table VI；Figure VI |
| `firm_prov_panel.dta` | 企业×省×年，11,516,622 obs | 同上汇总 | Table XI |
| `province_panel.dta` | 省×年×(书记/省长)，806 obs | 官员履历 + 统计年鉴 | Tables VII, VIII, XII |
| `prefecture_panel.dta` | 地级市×年×(书记/市长)，7,326 obs | 同上 | Tables VII, IX, XII |
| 反腐变量 | `post2012`；`inspection`（中央巡视组当年进驻该省）；`xiappointed`（省委书记为习 2012 年后任命） | CCDI 公告、官员履历（Online Appendix Table AV） | Tables X–XII |

> [!warning] 数据质量（后续文献）
> * **重复行**：`price.dta` 约 1/3 是完全相同的行。Manso (2026) 去重后，Table V 第 (3) 列从 −0.844 变为 −0.804，结论不变。
> * **"log 面积"**：`firm_panel` / `firm_prov_panel` 里的 `lnarea` 实为 面积(m²)/1,000,000。Table VI 的 "0.2% 更多土地" 应读作 "每年多约 2,000 m²"（Manso 2026）。
> * **晋升变量**：地级市长的 `promote` 常连续多年取值为晋升，Wiebe (2024) 认为 Table IX 市长列 GDP 增长的正效应是编码错误造成的。

---

## 4. 识别策略与核心方程

### 4.1 价格折扣（式 1 ≡ Table V）

$$
\ln Price_{ickst} = \beta_0 + \beta_1\,PrincelingPurchase_{ikjt} + \gamma X_i + T_{cst} + \nu_{ickst}
$$

- $i$ 地块，$c$ 城市，$k$ 企业，$s$ 用途，$t$ 年-月。
- $X_i$：土地质量（20 级）、log 面积、出让方式、企业规模、所有制（代码中出让方式、规模、所有制以固定效应吸收）。
- $T_{cst}$：**城市×年×用途** 固定效应，外加月份、三位数行业固定效应。
- 标准误：按 **省份 和 企业 双向聚类**（reghdfe，保留 singleton）。
- **选择偏误对策**：太子党可能专挑好地（高价值地段），这会使折扣被低估，所以用 1,500 m / 500 m 空间匹配样本（列 2–3），系数反而更大（−0.904 / −0.844）。
- 列 4–6 加 `Princeling × PSCM`（常委亲属再多 −0.40 至 −0.44），列 7–9 加 `Princeling × Retired`（退休后折扣不消失，系数不显著）。

### 4.2 数量（≡ Table VI）

$$
\text{Area}_{kt} = \alpha + \beta\,Princeling_k + \dots + \text{Year FE} + \text{State FE} + \text{Size FE},\quad \text{cluster: firm}
$$

系数 0.002（代码没有行业 FE，与表注不符；Manso 2026 指出）。

### 4.3 官员晋升（式 2 ≡ Tables VIII–IX）

$$
Turnover_{it} = \phi_0 + \phi_1 PrincelingPurchase_{it} + \phi_2 FactionalTies_{jt} + \phi_3 GDPGrowth_{it} + \kappa X_{it} + \omega W_j + \lambda_i + T_t + \varphi_j + \tau_{ijt}
$$

- 因变量四档：终止 0 / 退休 1 / 平调或留任 2 / 晋升 3，用**有序 probit**。列 3、8 为晋升 0/1 的 LPM。
- 控制：派系关系、GDP 增长、税收增长、log 人均 GDP、log 人口、年龄、年龄²、受教育年限；省（地级市）固定效应 + 年固定效应。
- 代码细节：`xi: oprobit … i.year i.provid`，**默认 OIM 标准误**（表注写 "robust"，代码并没有）。地级市用 `i.prefid`（表中写的是 Province FE）。

### 4.4 反腐运动（≡ Tables X–XII）

$$
\ln Price_{ickst} = \beta_1 Princeling + \beta_2\,Princeling \times Campaign_{pt} + \gamma X_i + T_{cst} + \nu
$$

$Campaign_{pt} \in \{\text{post2012},\ \text{Central inspection},\ \text{Xi-appointed},\ \text{Pre-2012 inspection (安慰剂)}\}$。

- Campaign 主效应在代码中**没有放入**（post2012 被 city-year-usage FE 吸收；inspection / xiappointed 是省-年变量，并不会被该 FE 完全吸收，代码中也省略了）。
- Table XI：企业×省×年面板，省 FE + 年 FE，双向聚类。
- Table XII：晋升方程加入 `PP × post2012` / `PP × inspection`，同理用于 discount (PD) 与 area (ALP)。

### 4.5 事件研究（≡ Figures V, VI）

$$
\ln Price = \sum_{y=2006}^{2016} \delta_y\,Princeling \times \mathbb{1}[year=y] + T_{cst} + \dots
$$

基期是 2004–2005（`pt1`、`pt2` 省略；Figure V 回归**不含** princeling 主效应和质量/面积控制）。

---

## 5. 主要发现（逐项对应图表）

| # | 发现 | 数字 | 图表 |
|---|---|---|---|
| 1 | 太子党企业买地价格折扣 | −0.808 (全样本) → −0.904 (≤1,500 m) → −0.844 (≤500 m)，即 55.4%–59.9% | Table V (1)–(3) |
| 2 | 常委亲属折扣更大 | PSCM 交互 −0.442 / −0.420 / −0.396 | Table V (4)–(6) |
| 3 | 退休后折扣不消失 | Retired 交互 −0.001 至 −0.051，不显著 | Table V (7)–(9) |
| 4 | 84.5% 的太子党地块价格低于其 500 m 内非太子党地块的平均价格 | 散点图（12,133 对） | Figure IV |
| 5 | 太子党企业买地略多 | 0.002（实为 2,000 m²/年） | Table VI；Figure VI |
| 6 | 送折扣的省委书记更易晋升，省长不然 | oprobit 0.652 (0.229)；LPM 0.114 → +23.4% | Table VIII |
| 7 | 地级市书记同样成立，市长不然 | 0.469 (0.070)；LPM 0.088 | Table IX |
| 8 | 2012 年后折扣缩小 | Princeling×post2012 = 0.318 / 0.257 | Table X (1)(2) |
| 9 | 中央巡视、习任命书记所在省折扣缩小更多 | 0.819 / 0.695；0.614 / 0.572 | Table X (3)–(6) |
| 10 | 2012 年前的巡视无效（安慰剂） | 0.109 / 0.037，不显著 | Table X (9)(10) |
| 11 | 太子党买地数量优势在运动后下降 | PP×post2012 −0.022；PP×inspection −0.053；PP×Xi −0.056 | Table XI |
| 12 | 运动后"送折扣→晋升"消失 | PP×post2012 −1.165；PP×inspection −2.769 | Table XII |
| 13 | 事件研究：折扣在 2013 年后逐年收窄，2016 年接近 0 | δ₂₀₁₂ = −0.874 → δ₂₀₁₆ = −0.075 | Figure V |
| 14 | 巡视组进驻前后 60 天的日度价格差距明显收窄 | 进驻前平均价差 −466 元/m²，进驻后 −68 | Figure VII |

---

## 6. 本复现的结论（2026-09）

- 原始 Stata 代码逐表运行，结果与期刊发表值**逐位一致**（Tables V, VI, VIII, IX, X, XI, XII；Tables III, VII 描述统计；Figures IV–VII）。详见 `Results/comparison.md`。
- StatsPAI (`sp.feols` / `sp.hdfe_ols` / `sp.oprobit`) 复现全部回归表：Tables V、VI、X、XI、XII 逐位一致；Tables VIII、IX 分别 32/34、31/34，其余单元格差 ≤ 0.0016。有序 probit 需要标准化回归元，否则 StatsPAI 的 BFGS 会提前停止；地级市模型每个需要数小时（Stata < 1 秒）。

---

## 7. 用 2022–2026 的标准回看

### 7.1 论文做法 vs 现代做法

| 主题 | 论文做法 | 现代做法 | 评价 |
|---|---|---|---|
| 价格折扣（Table V） | 高维 FE + 空间匹配 + 双向聚类 | 同样做法；可加 wild cluster bootstrap（只有 31–32 个省簇） | ✅ 基本达标；省簇数少，建议补 WCB |
| 运动效应（Table X） | TWFE 三重交互，交错时点（习任命书记 2013–2016） | CS / Sun-Abraham / BJS + Bacon 分解 | ⚠️ 存在"早处理省当对照"的比较（见 7.2） |
| 事件研究（Figure V） | 基期 2004–05，系数是折扣**水平** | 基期取处理前最后一期（2012），报告前趋势 + HonestDiD | ⚠️ 原图不能直接检验平行趋势 |
| 晋升（Tables VIII–IX） | 有序 probit，非稳健 SE，未聚类 | 按省/市聚类；多重假设检验校正 | ⚠️ 表注"robust"与代码不符 |
| 数据质量 | — | 去重、变量定义核对 | ❌ 重复行与 "lnarea" 定义问题（Manso 2026） |

### 7.2 本项目补做的扩展（StatsPAI，`Results/statspai/modern_*`）

**A. 交错 DID：省×年"太子党价差"面板 × 习任命书记时点。** 先用 Table V (1) 的设定估计折扣，再把每个省-年太子党地块的平均残差加回，得到该省-年的价差（≥3 宗太子党交易，301 个省-年，31 个省）。处理时点：2013 (14 省)、2014 (7)、2015 (1)、2016 (2)，从未处理 7 省。

| 估计量 | ATT（价差缩小，log 点） | SE |
|---|---|---|
| TWFE（全部 301 格） | 0.290 | 0.066 |
| TWFE（2007–2016 平衡面板，18 省） | 0.215 | 0.075 |
| Callaway–Sant'Anna（简单加总） | 0.330 | 0.093 |
| CS 动态加总 | 0.364 | 0.107 |
| Sun–Abraham | 0.310 | 0.119 |
| BJS 插补 | 0.267 | 0.068 |

- **Goodman-Bacon 分解**（平衡面板）："处理 vs 从未处理" 权重 63%，平均 0.254；"早处理 vs 晚处理（以晚处理组为对照）" 权重 28%，平均 0.135；"晚处理 vs 早处理（以已处理组为对照，forbidden comparison）" 权重 9%，平均 0.184。TWFE 被向下拉，异质性稳健估计量更大。**论文"习任命书记使折扣缩小"的结论在现代估计量下成立，且更强。**
- **CS 事件研究**：处理前 −9…−2 期系数都接近 0（最大 |t| ≈ 1.5），处理后 0、1 期为 0.39、0.34。
- **HonestDiD（CS，e=0，相对幅度）**：M̄ = 0 时 CI [0.18, 0.60]；M̄ = 0.5 时下界降到 −0.005，即允许处理后违反达到处理前最大违反的一半，结论就不再显著。

**B. Figure V 以 2012 为基期重新估计 + HonestDiD + Roth 检验力。** 以 2012 为基期后，处理前系数（2006–2011）在 −0.15 到 +0.26 之间波动；2013–2016 为 0.28、0.43、0.50、0.80。
- 相对幅度约束：e=3（2016）在 M̄ = 2 时 CI 仍为 [0.03, 1.57]，**稳健**；e=0（2013）在 M̄ = 0.5 时 CI 已包含 0。
- 平滑度约束（ΔSD）：e=0 在 M ≈ 0.13 时失去显著性。
- Roth (2022) 检验力：对"每期线性偏离 1 个最小 SE"的违反，逐期前趋势检验只有 **44%** 的检验力（联合检验 15%），所以"前趋势不显著"并不能说明平行趋势成立。

**C. 以首次中央巡视年份作队列（2013 vs 2014，无从未处理省）。** StatsPAI 的 CS 返回 ATT = 0、SE = 0，这是一个 **bug**：没有可用对照的 ATT(g,t) 被写成 0 并参与加总，见分析文档。

---

## 8. 我的评注

- 文章最有力的是 Table V：在同城同年同用途同月、500 米以内比较，折扣仍有 57%。这个数字对重复行和空间匹配都稳健。
- 最脆弱的是数量表和晋升表：变量定义有误（"log 面积"）、晋升编码可疑、表注与代码不一致（robust SE、Province FE vs Prefecture FE、2004–2016 vs 数据实际到 2014）。
- 反腐运动部分的识别本质上是交错 DID，现代估计量给出同向且更大的效应；但 Figure V 的事件研究在 2013 年的效应对平行趋势违反并不稳健，逐年扩大的长期效应（2016）才稳健。

---

## 9. 复现与代码

- 原始代码：`Program/Tables&Figures.do`（未修改）+ `Program/run_original.do`（路径修正、按图表拆分、记录 rc/秒）。
- StatsPAI：`Program/statspai/`（`replicate_statspai.py` 一键运行）。
- 逐数对照：`Results/comparison.md`。
