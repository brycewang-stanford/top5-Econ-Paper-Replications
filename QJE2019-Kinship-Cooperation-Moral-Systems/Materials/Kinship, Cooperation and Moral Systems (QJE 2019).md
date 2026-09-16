---
title: "Kinship, Cooperation, and the Evolution of Moral Systems"
authors: Benjamin Enke
journal: Quarterly Journal of Economics
year: 2019
volume: 134(2): 953–1019
doi: 10.1093/qje/qjz001
package: Harvard Dataverse doi:10.7910/DVN/JX1OIU (CC0)
tags: [cultural-economics, kinship, morality, ethnographic-atlas, cross-country, epidemiological-approach]
---

# Kinship, Cooperation, and the Evolution of Moral Systems（QJE 2019）阅读笔记

> [!abstract] 一句话
> 历史上亲属关系（kinship）越紧密的社会，其“道德系统”越是**社群主义式**的——内群体偏袒、忠诚、复仇、羞耻、洁净/厌恶；亲属关系松散的社会则依靠**普世价值、内疚、利他惩罚与道德化宗教**来维持大范围合作。两种道德系统内部自洽，并随经济发展而差距扩大。

## 1. 研究问题

- 社会如何在囚徒困境、公共品、社会保险等**社会困境**中维持合作？心理学/人类学/演化生物学的答案是“道德系统”：道德化的神、道德价值、负互惠、羞耻/内疚/厌恶等情绪。
- Enke 把这些道德特征视为**功能性的一揽子制度**，其结构取决于历史上的**亲属关系紧密度**：紧密亲属网络在小范围内就能执行合作，因而不需要（甚至排斥）普世主义的执行装置。
- 贡献：(i) 把人类学/心理学的“道德系统”理论化为可检验的经济学模型；(ii) 用前工业时代民族志 + 当代个人/国家层面数据系统检验；(iii) 揭示“紧/松”差异随时间放大（Figure IX）。

## 2. 数据

| 层级 | 数据 | 规模 | 用在 |
|---|---|---|---|
| 前工业民族 | Murdock《Ethnographic Atlas》(EA) + SCCS 子样本 | 1,246 个民族；kinship index 非缺失 1,227 | Table III–V, XI；Figure I–IV |
| 相邻民族配对 | EA 同国、质心距 ≤ 500 km、kinship 不同的配对 | 2,468–7,601 对观测 | Table V |
| 国家 | 按祖先构成调整的 kinship（Putterman–Weil 迁移矩阵 / 语言匹配）+ WVS、GPS、MFQ、ISEAR 国家均值、HYDE 人口 | 70–79 国（不同变量），Figure IX 123 国 | Table VI, VII, IX, X；Figure V, VI, VIII, IX |
| 国内民族 | WVS 受访者按自报民族匹配 EA 民族 | 21,758–26,220 人 | Table VI, VII（5–8 列） |
| 移民 | yourmorals.org 的 MFQ（道德基础问卷）移民，按出生国赋 kinship | 27,994–28,432 人 | Table VIII；Figure VII |
| 情绪 | ISEAR 跨文化情绪问卷；Google Trends “shame/guilt” 搜索 | 2,490–2,626 人；71–72 国×语言 | Table IX |
| 惩罚 | GPS（Global Preferences Survey）复仇 vs 利他惩罚 | 74 国；移民 2,266–2,289 人（受限） | Table X |

**Kinship tightness 指数**（EA 变量，四个成分等权平均，至多缺 1 个）：

$$
\text{Kinship}_e=\tfrac14\big[\underbrace{\text{extended family}}_{1-\text{nuclear (v8)}}+\underbrace{\text{共同居住}}_{\text{locality (v11)}}+\underbrace{\text{单系继嗣}}_{1-\text{bilateral (v43)}}+\underbrace{\text{地方性氏族}}_{\text{clan (v15)}}\big]\in[0,1]
$$

均值 0.69，中位数 0.75（Figure I）。我们用包内成分重新计算，与作者的 `kinship_score` 1,227 个值**完全一致**。

## 3. 模型（Section III）

- 基于 Tabellini (2008)：个体分布在周长为 2 的圆上，距离 = 亲缘距离。两个社会只在“视为家人”的主观距离 $d_f$ 上不同：$d_f^{tight}>d_f^{loose}=0$。
- 年轻时与他人玩囚徒困境（Table II），效率收益 $g_t=\beta_t d_{ij}$：**越远的配对越有效率**（分工/互补）；$\beta_t$ 随时间上升（经济发展）。
- 效用（式 1）：$U^{PD}_{i,t}=y_i+\gamma y_j[1-\mathbf 1_{d_{ij}>d_f}\,d_{ij}(1-\theta_{i,t})]$。$\theta$ = 普世价值（利他心随距离衰减的斜率），父母可通过灌输**道德化的神**投资 $\theta$。
- 社会保险（式 2）：个体可能染病；父母投资**厌恶** $\lambda$ 以识别病原体；只有远方的人能帮忙，因此只有普世价值高才有人帮。
- 预测（Table I）：紧密亲属社会 → 合作范围 $d^*$ 小、内群体偏袒、$\theta$ 低（社群价值、羞耻、复仇）、$\lambda$ 高（洁净/厌恶）；前工业期**松散社会更信道德化神**，但随 $\beta_t$ 上升紧密社会也会补投资——“道德化宗教的兴衰”；紧/松之间的发展差距随时间扩大。

## 4. 识别与计量设定

全部是**横截面 OLS**，因变量标准化为 z 分数，系数解读为“kinship 从 0 到 1 时因变量变动多少个标准差”。

$$
Y_{e}=\alpha+\beta\,\text{Kinship}_e+\mathbf X_e'\gamma+\mu_{c(e)}+\varepsilon_e
$$

| 层级 | 控制 | 固定效应 | 标准误 |
|---|---|---|---|
| EA 民族（Table III, IV, XI） | 狩猎采集依赖度、log(EA 观测距今年数) | 大洲（7 个世界银行区域）或国家 FE | 按语言子语族聚类；小样本 SCCS 变量（61/83 个民族）用 500 次**聚类 bootstrap** |
| 相邻配对（Table V） | 同上 | **配对（match）FE**，仅用配对内差异 | 语言子语族聚类 |
| 国家（Table VI, VII, IX 7–8, X） | 同上（国家层面平均） | 大洲 FE / 语言 FE | HC1 稳健；Google Trends 按国家聚类 |
| 国内个人（WVS/MFQ/ISEAR） | 性别、年龄 FE；民族/原籍国层面控制 | 居住国 FE + 波次/年份 FE | 按民族或原籍国聚类 |

识别论证不依赖外生冲击，而是：(i) Table III 显示 kinship 由**病原体生态**（疟疾生态、镰状细胞突变距离、采采蝇适宜度）部分决定——近似“深层外生”来源；(ii) 国家 FE / 配对 FE 吸收地理与制度；(iii) **流行病学方法**：移民与国内民族的 kinship 来自祖先，居住国环境相同（Table VI–VIII）。作者明确承认这些是相关性证据。

## 5. 主要发现（每条对应表/图）

1. **起源**：疟疾生态高 1 SD → kinship +0.12（Table III 列 1）；非洲内镰状细胞距离、采采蝇适宜度同样显著（列 6–11）；狩猎采集社会 kinship 更松（Figure II，Table III 列 2）。
2. **前工业内群体偏袒**：kinship 0→1，对外群体 vs 内群体暴力可接受度差 +1.27 SD（Table IV 列 1）；对本地社区忠诚 +1.16 SD（列 6）。
3. **道德化的神**：紧密社会信奉道德化神的概率低 0.77 SD（列 3），控制“是否有高位神”、国家 FE 后仍为 −0.41（列 5）。相邻民族配对内 −0.34 至 −0.38（Table V 列 1–2）。
4. **洁净**：产后性禁忌 +0.83 SD（Table IV 列 8）。
5. **制度**：紧密社会**村级**司法层级更强（+0.76–0.87，列 13–15，Table V 列 5–6 稳健），**地方以上**层级更弱（−0.26 至 −0.39，列 10–12；配对内不显著）。
6. **当代信任**：国家层面内群体 vs 外群体信任差 +1.46 SD（Table VI 列 1，Figure VI）；WVS 国内民族间 +0.35–0.40（列 5–6）。
7. **地狱信仰**：国家 +1.16，控制神信仰和大洲 FE 后 +0.47（Table VII 列 1–4）；国内民族 +0.17–0.26（列 5–8）——与前工业期符号**相反**，对应模型的“道德化宗教兴衰”。
8. **社群 vs 普世价值（MFQ 移民）**：忠诚 +0.11、权利 −0.23、社群−普世 +0.29–0.37（Table VIII 列 1–4）；**厌恶/洁净** +0.36–0.41（列 5–8，Figure VII）。
9. **情绪**：ISEAR 厌恶 +0.30（Table IX 列 1），羞耻−内疚 +0.27（列 4–5），Google 搜索羞耻 vs 内疚 +0.79–0.88（列 7–8）。
10. **惩罚**：复仇 vs 利他惩罚，国家 +1.20（Table X 列 1），加大洲 FE 后 +0.83（p < .10，列 3）；GPS 移民 +0.28–0.31（列 4–6，数据受限）。
11. **道德“内核”**：5 个道德变量的第一主成分与 kinship 强相关（Figure VIII）；紧/松两组在全部当代变量上符号一致（Figure V）。
12. **发展**：前工业民族层面 kinship 与人口密度/聚落复杂度不负相关（Table XI，控制狩猎采集后不显著）；但国家层面 kinship 与人口密度/城市化的系数从 1500 年近 0 逐步变为强负（Figure IX，123 国），符合“差距随时间放大”。

## 6. 现代方法再评估（我们的扩展，见 `Results/statspai/ext_*`）

| 问题 | 方法 | 结论 |
|---|---|---|
| EA 民族空间相关，语言聚类是否足够？ | Conley 空间 HAC（250–2000 km） | 500 km 下与语言聚类 SE 接近；2000 km 时 SE 最多扩大 ~2.5 倍，但除 Table IV 列 10（本就边缘显著）外 |t| 仍 > 2 |
| 不可观测混淆 | Oster (2019) δ*（R²max = 1.3R²） | 村级制度 δ* = 21.8、信任 13.5，非常稳健；复仇惩罚 1.30；**性禁忌 0.55、地狱信仰 0.24 脆弱**；道德化神加控制后系数反而远离 0（δ* < 0） |
| 同上 | Cinelli–Hazlett 稳健值 / E 值 | RV_q = 0.13–0.42；E 值 2.4–6.8（点估计），地狱与惩罚的 CI E 值 ≈ 1（本已不显著） |
| 研究者自由度 | 规格曲线（8 组控制） | 道德化神、村级制度、性禁忌、信任、复仇惩罚符号 100% 稳定；**社群价值（国家层面）加入 log GDP 后变号且不显著**；地狱信仰仅在“收入+宗教+大洲”全控制下变号 |
| 多重检验（一篇文章 30+ 个结果变量） | Romano–Wolf stepdown | EA 四个结果（共同样本 293）调整后除地方以上层级（p = 0.07）外 p < .01 |

**总体判断**：前工业 EA 与国内个人层面（配对 FE、居住国 FE）证据在现代稳健性工具下表现良好；**国家层面**（70–79 国）的部分结果（地狱信仰、社群价值、复仇惩罚）对控制集和不可观测混淆较敏感，更宜视为描述性模式。道德系统“内部一致”的核心论点主要由多数据源的**符号一致性**支撑，而非单个系数的因果精度。

## 7. 复现状态（详见 `Results/comparison.md`）

- 作者 12 个 do-file 全部 rc = 0（Stata 18，≈ 51 s）；94 个系数中点估计与 N **全部**与论文一致，7 个 bootstrap SE 在蒙特卡洛误差内（作者未设种子）。
- StatsPAI 重做全部正文表格（Table X 第 4–6 列需 Gallup 受限数据除外）与图 I–IX，与 Stata 点估计差 < 1e-6。
