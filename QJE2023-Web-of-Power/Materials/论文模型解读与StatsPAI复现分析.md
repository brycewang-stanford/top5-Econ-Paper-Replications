# 《Web of Power》模型解读：逐式拆解、StatsPAI 复现与现代化对照

> **论文**：Bai, Ying, Ruixue Jia and Jiaojiao Yang (2023). "Web of Power: How Elite Networks Shaped War and Politics in China." *QJE* 138(2): 1067–1108. DOI: [10.1093/qje/qjac041](https://doi.org/10.1093/qje/qjac041)
> **复现包**：Harvard Dataverse doi:10.7910/DVN/0H4HG2（Stata do-file，CC0）
> **本文目的**：(1) 逐个拆解论文的计量方程、标准误与变量构造细节；(2) 记录用 StatsPAI 1.28.0 复现全部正文表图的做法、精度与遇到的问题；(3) 用 2022–2026 的方法做扩展检验；(4) 给 StatsPAI 的改进建议。
> 数字对照见 `Results/comparison.md`，内容性笔记见 `Web of Power (QJE 2023).md`。

---

## 目录

1. [逐式拆解](#1-逐式拆解)
2. [原始代码复现：细节与坑](#2-原始代码复现细节与坑)
3. [StatsPAI 复现：映射、精度与标准误约定](#3-statspai-复现映射精度与标准误约定)
4. [现代方法扩展（E1–E7）](#4-现代方法扩展e1e7)
5. [StatsPAI bug / API 摩擦清单（含最小复现）](#5-statspai-bug--api-摩擦清单含最小复现)
6. [对 StatsPAI 的改进建议](#6-对-statspai-的改进建议)
7. [一句话总结](#7-一句话总结)

---

## 1. 逐式拆解

### 1.1 式 (1)：连续强度 DID（≡ Table 2, `Table_2.do`）

$$
\ln(\text{martyr}_{ct}+1)=\beta\,C_c\times\text{Post}_t+\alpha_c+\lambda_t+\theta' X_c\times\text{Post}_t+\varepsilon_{ct},\qquad \text{Post}_t=\mathbb 1[1854\le t\le1864]
$$

| 元素 | 代码中的变量 | 细节 |
|---|---|---|
| $Y$ | `lnmartyr1` = ln(1+阵亡) | 55% 的县-年为 0 |
| $C_c$ | `Zeng_all0_invdist`（加权）/ `Zeng_all0_invdist_pc`（人均）/ `Zeng_all0`（不加权）/ `Zeng_all0_pc` | $\sum_n 1/d_{c,n}$，时间不变 |
| Post | `gen Post=0 if year<1854; replace Post=1 if year>=1854&year<=1864` | 1853 算"前期" |
| $X_c\times$Post | 列 2：`lnurbanpop mainriv dist2canal lnwheat lnrice lnpop lnarea`；列 3 加 `capital lnjinshi lnquotas`；列 4 再加 `route1 dist_nanjing` | 共 12 个 |
| FE | `absorb(year cntyid)` | 75 县 × 15 年 |
| SE | `cluster(cntyid)` | 75 个聚类 |

**系数解读**：$\hat\beta=0.214$ → 1 个直接联系（$1/d=1$）使阵亡增加约 $e^{0.214}-1\approx 24\%$（论文按近似写 21%）。

### 1.2 Table 3：联系类型 + 县×姓氏面板

- 列 1–4：把 $C_c$ 换成扩展网络 / 血缘姻亲师友 / 省试同年 / 会试同年，**FE 加府×年**（`egen prefidXyear=group(prefid year)`）。
- 列 5–7：`HunanSurname.dta`（75 县 × 360 姓 × 15 年 = 405,000 行），只保留"该县-姓氏曾有联系或曾有阵亡"的格子（`subsample`，49,680 行），

$$
\ln(\text{martyr}_{cst}+1)=\beta\,C_{cs}\times\text{Post}_t+\gamma\,C_{c,-s}\times\text{Post}_t+\alpha_{cs}+\mu_{st}+\delta_{pt}\;(\text{或 }\delta_{ct})+\varepsilon_{cst}
$$

  FE：府×年、姓×年、县×姓（列 7 换成县×年），**双向聚类（县、姓）**。$C_{c,-s}$ = 同县其他姓氏的联系（`oth_sur_invdis_zeng_all0`）。

### 1.3 Table 4：安慰剂网络与 IV

- 列 1–3（OLS，剔除曾国藩家乡湘乡 `cntyid!=25`）：会试同年联系 + 假设曾国藩早一科/晚一科中进士的"安慰剂同年联系"（`invdist0_L1`, `invdist0_F1`）。
- 列 4–6（`ivreghdfe`）：以会试同年联系为工具，工具化全部基准联系，控制安慰剂联系。
- 列 7–11：淮军地区（`HuaiYr.dta`，133 县）同样的回归，FE 含数据中已有的 `prefidXyear`，聚类 `samcntyid`。

### 1.4 式 (2)：全国 DD / DDD（≡ Table 5, `Table_5.do`）

$$
\text{alloff}_{ct}=\rho_1 H_c C_c P_t+\rho_2 H_c P_t+\rho_3 C_c P_t+\alpha_c+\lambda_t+\theta'X_c P_t+\varepsilon_{ct},\quad P_t=\texttt{period}=\mathbb 1[t\ge1854]
$$

- 样本 `keep if year>=1820`：1,646 县 × 91 年 = 149,786；FE `absorb(year samcntyid)`；**府级聚类**（255 个府；湖南子样本只有 15 个府）
- 控制变量写法 `lnurbanpopXperiod-Taiping_route1Xperiod` 是 Stata **变量区间**，取决于数据集中变量顺序 → 在 Table 5/6 中 = 12 个 `X×period`

### 1.5 Table 6：机制与过度识别

- 列 2–3：加入 `martyrs_tot_postXperiod`（县 1854–64 阵亡总数（千）× period）
- 列 4–6：`ivreghdfe alloff (martyrs_tot_postXperiod = hXZeng_Extraexam_invdistXperiod hXZeng_exam0_invdistXperiod) ...`，两个工具 = 湖南×{会试同年联系, 其他联系}×period；列 5/6 各放一个工具、另一个作外生控制——"一个工具不应有直接效应"的过度识别逻辑。

### 1.6 事件研究

- **Figure 4**（`Figure_4.do`）：$\sum_{t\ne1853}\beta_t C_c\mathbb 1[\text{year}=t]$ + 12 个 $X\times$Post + 县、年、府×年 FE；参照年 1853。四个面板 = 四种 $C_c$。
- **Figure 6**（`Figure_6.do`）：**全 1800–1910 样本**（没有 `keep if year>=1820`），`tab year, gen(year)` 后 `year22`–`year111` = 1821–1910 与 $H_cC_c$、$(1-H_c)C_c$（或 $C_c$）、$H_c$ 交互 → 基期为 **1800–1820 整段**。

> [!warning] 坑：Figure 6 / Figure C1 的控制变量区间
> 这两个 do-file 在循环中按 `xXperiod1, xXperiod2, xXperiod` 交替生成变量，于是同一个写法 `lnurbanpopXperiod-Taiping_route1Xperiod` 在这里展开为 **34 个变量**（含 period1=1850–64、period2=1865–1910 的交互），而不是 Table 5/6 中的 12 个。复现时若按 12 个控制，年度系数会差到 0.005；按 34 个则与作者 parmest 输出差 <1e-8。（parmest 文件 305 个参数 = 270 + 34 + 常数，是破案线索。）

### 1.7 EG 指数反事实（Figure 7 / Table C7）

`EG_Index.dta` 为 县×年，已附带 Figure 6 回归的逐年系数 `estimate`。湖南县反事实官职数 = `alloff − estimate×Zeng_all0_invdist`；按省×年加总，基准份额 $x_p$ = 进士份额（`labor`），EG 指数
$\gamma=\big(G-(1-\sum x^2)H\big)/\big((1-\sum x^2)(1-H)\big)$，$H=1/\text{总官职数}$。只取 `provcd==10` 那行（年度指标对每省相同）。

---

## 2. 原始代码复现：细节与坑

| 问题 | 处理 |
|---|---|
| 所有路径是 Windows 反斜杠（`use Data\HunanCntyYr.dta`、`Results\\...`），macOS Stata 不识别 | 32 个 do-file 统一 `\`→`/`（唯一改动，git 历史可见） |
| `All_in_One.do` 写死 `cd D:\Dropbox\...` | 新写 `Program/run_original.do`：设根目录、`adopath ++ Program/ado`、`version 16`、逐个 do-file `capture noisily`、记录 rc 与秒数、输出分拣到 `Results/Tables|Figures` |
| 缺 `parmest`、`tabout`、`reg2hdfe`、`tmpdir`、`reg2hdfespatial`（非 SSC） | SSC 安装前四个；`reg2hdfespatial` 放项目内 `Program/ado/` |
| **`reg2hdfespatial` 版本陷阱**：GitHub 上较新的版本（带权重，682 行 `ols_spatial_HAC`）默认**均匀**空间核，B1.III 的 SE 比作者大约 7%（0.059 vs 0.055），其 `bartlett` 选项还会报 `weights not allowed` | 作者日志里有 "(NOTE: LINEAR BARTLETT WINDOW USED FOR SPATIAL KERNAL)" → 换成 2015 原版（`reg2hdfespatial` 内部硬编码 `bartlett`），三张 B1.III 表逐字相同 |
| Table 3 列 1–4 / Table B2：论文印 N=1,125，代码给 1,110 | 新版 `reghdfe` 删 15 个单例（府×年只有 1 县）；作者 2022 年日志本身已是 1,110，系数/SE 在 3 位小数不变（I4R 也指出） |
| Table 4 IV 列 4–6 三个 SE 差 0.001 | 作者当年 `ivreghdfe` 多计 1 个吸收自由度（日志 .1374985 vs 现在 .1374197） |
| Table 3 列 6 论文 0.057 (0.016) vs 代码 0.056 (0.017) | 论文排版/抄录差异，作者日志与我们一致 |
| Table 1 Panel A 人均联系均值论文印 4.48 | 数据与作者日志均为 4.458 → 论文笔误 |
| Table 1 Panel B 标注 1820–1910 但代码对 1800–1910 全部行求 summary | 时间不变变量不受影响，仅 N 不同（I4R 也指出） |
| 包内遗留 `Table_4b.txt`、`Appendix_Table_B6.txt` 当前代码不再生成 | 内容与新 `Table_4.txt` 列 7–11、`Appendix_Table_B6_I.txt` 列 4–5 相同 |

**结果**：31/31 个 do-file rc=0，总耗时 674 秒；所有 `.txt` 输出与作者输出**逐字相同**（Table 4 三个 SE 的第三位小数除外）。

---

## 3. StatsPAI 复现：映射、精度与标准误约定

### 3.1 结构

```text
Program/statspai/
├── common.py             数据构造（逐行翻译 do-file）、ols()/iv() 包装、outreg2 txt 解析、比对
├── replicate_tables.py   Table 1–6 全部列 + hdfe_ols 问题记录
├── replicate_figures.py  Figure 3–8（数值与作者 tabout/parmest 输出逐格比对）
├── extensions.py         E1–E7 现代方法扩展
├── make_comparison.py    生成 Results/comparison.md
└── crosscheck_boottest.do  用 Stata boottest 交叉验证 E2
```

### 3.2 估计量映射

| Stata | StatsPAI 调用 | 精度 |
|---|---|---|
| `reghdfe y x, absorb(fe) cluster(c)` | `sp.feols("y ~ x | fe", vcov={"CRV1": c}, ssc=pf.ssc(adj=False, cluster_adj=False))`，先手动删单例，SE × $\sqrt{\frac{G}{G-1}\frac{N-1}{N-K-1-df_a}}$ | 与 Stata 完全一致（到 1e-8） |
| `reghdfe ..., cluster(c1 c2)` | `sp.hdfe_ols("y ~ x | fe", cluster=[c1, c2])` | 完全一致（Table 3 列 5–7） |
| `ivreghdfe y (d=z) x, absorb(fe) cluster(c)` | `sp.feols("y ~ x | fe | d ~ z", ...)` × $\sqrt{\frac{G}{G-1}\frac{N-1}{N-K-df_a}}$ | 与当前 ivreghdfe 完全一致 |
| `parmest` + `twoway` | 系数表 + matplotlib，CI 用 $t_{G-1}$ | 56 + 360 个年度系数/SE 差 <1e-8 |
| `tabout ... sum` | `pivot_table` | 与 3 位小数输出一致 |
| `reg2hdfespatial` | 手动双向去均值 → `sp.regress` → `sp.conley(kernel="bartlett", time=, lag_cutoff=20, unit=)` | 与 Stata 到 3 位小数一致（E1） |

其中 $df_a$ = 不嵌套于聚类变量的 FE 虚拟变量矩阵的秩 − 1（reghdfe 的 "Absorbed degrees of freedom" 表：year 14 + prefidXyear 195 = 209 = rank([year, prefXyear]) − 1）。OLS 比 IV 多减 1：reghdfe 把常数计入 K，ivreg2 不计。

### 3.3 精度汇总

| 表图 | 格数 | vs 我们的 Stata 重跑 | vs 论文 |
|---|---:|---|---|
| Table 2 | 10 | 10/10 完全一致 | ✅ |
| Table 3 | 8 | 8/8 一致 | ⚠️ 5 格（N 与列 6 抄录差异，见 §2） |
| Table 4 | 23 | 23/23 一致 | ⚠️ 3 格（ivreghdfe 版本） |
| Table 5 | 10 | 10/10 | ✅ |
| Table 6 | 24 | 24/24 | ✅ |
| Figure 3–8 | 1,000+ 个数 | 差 <1e-7（均值类为 5e-4 的 3 位小数舍入） | ✅ |

---

## 4. 现代方法扩展（E1–E7）

> **扩展，不是复现**。数字全部来自 `Results/statspai/ext_E*.csv/json`，汇总于 `Results/comparison.md` §5。

### E1 Conley 空间-序列 HAC：`sp.conley` 精确重现 `reg2hdfespatial`

做法：手动按县、年双向去均值（与 `reg2hdfe` 相同）→ `sp.regress` → `sp.conley(kernel="bartlett", time="year", lag_cutoff=20, unit="cntyid")`。

| 列 | 截断 | sp.conley (Bartlett) | Stata B1.III | sp.conley (uniform) |
|---|---:|---:|---:|---:|
| (1) 加权无控制 | 50 km | 0.0554 | 0.055 (.0553997) | 0.0592 |
| (1) | 100 km | 0.0569 | 0.057 | 0.0550 |
| (4) 加权全控制 | 200 km | 0.0579 | 0.058 | 0.0639 |
| (7) 不加权 | 50 km | 0.0398 | 0.040 | 0.0424 |

18 个组合全部在 3 位小数上一致。**uniform 核恰好给出"新版 reg2hdfespatial"的 0.059**——这正是 §2 版本陷阱的数值证据。结论：Conley SE 与县级聚类 SE（0.058）几乎相同，空间相关不改变推断。

### E2 少聚类的 wild cluster bootstrap（发现 StatsPAI bug）

作者 Table 2 按县聚类（75 个）、Table 5 按府聚类（全国 255 个）。但**处理变异在湖南内部只来自 15 个府**；若按府聚类（湖南样本）应使用 WCR 自助法。

| 回归 | G | b | CR1 p | `sp.hdfe_ols(wild=True)` p | **修正 WCR p** | Stata `boottest` p |
|---|---:|---:|---:|---:|---:|---:|
| Table 2 列 1（无控制），府聚类 | 15 | 0.214 | <0.001 | 0.210 (Webb) | **0.306** | 0.305 |
| Table 2 列 4（全控制），府聚类 | 15 | 0.213 | <0.001 | 0.039 | **0.048** | 0.046 |
| Table 5 列 1（湖南 DD），府聚类 | 15 | 0.053 | <0.001 | 0.045 | **0.226** | 0.218 |
| Table 5 列 2（湖南 DD+控制），府聚类 | 15 | 0.054 | <0.001 | 0.010 | **0.012** | — |

- **实质结论**：在"府"这一更保守的聚类层级下，**无控制变量**的两个核心系数不再显著（p≈0.3、0.2），**加控制后**仍在 5% 水平显著。说明识别变异高度依赖少数府，控制变量（尤其府治、学额、太平军路线）吸收了府际差异后，府内变异才是干净的。
- **StatsPAI bug**：`hdfe_ols(wild=True)` 在每次自助抽样后没有重新吸收（re-absorb）不嵌套于聚类的固定效应（这里是 year FE），CR1 统计量用错了残差 → p 值系统性偏小（Table 5 列 1：0.045 vs 0.22）。我在 `extensions.wcr_fe` 中实现了正确版本，并用 `Program/statspai/crosscheck_boottest.do`（Stata `boottest`，`areg`+`i.year`）交叉验证，二者只差蒙特卡洛误差。

### E3 Figure 4A 事件研究诊断：pretrends / HonestDiD

- `sp.pretrends_test`（用 `model_info["vcv_pre"]` 全协方差）：χ²(3)=0.85, p=0.84，与手算完全一致。
- `sp.pretrends_power`：对"1 SE 线性违背"的**功效只有 0.18** → 前趋势不显著几乎没有信息量（只有 1850–52 三个前期）。
- **R `HonestDiD` + 全协方差（基准）**，对 1854 年效应（e=0，$\hat\beta=0.287$）：
  - 相对幅度 $\bar M$：$\bar M=1$ 时 95% CI [0.040, 0.518] 仍排除 0；$\bar M=1.5$ 时 [−0.033, 0.588] 不再排除 → **breakdown $\bar M\approx1.3$**
  - 平滑性 $M$（FLCI）：$M=0.1$ 时 [0.008, 0.591]，$M=0.15$ 时包含 0
  - 对 1858 年效应（e=4）：$\bar M=0.25$ 就接近失去显著性（[0.033, 0.588]），$\bar M=0.5$ 包含 0 —— 越远离前期，外推越脆弱
- **StatsPAI 的问题**：对这种"连续暴露×年份"的自定义事件研究，`honest_did` 无法接收用户给定的 $(\hat\beta,\Sigma)$：
  - `backend="native"`，`relative_magnitude`：最坏偏差近似（文档已警告），e=4、$\bar M=2$ 时给出 [0.085, 0.540]（**仍显著**），而精确 R 结果是 [−1.47, 1.71] —— **近似严重高估稳健性**；
  - `backend="r"`：只能传对角协方差，e=0 时与全协方差结果接近（$\bar M=1$：[0.019, 0.553] vs [0.040, 0.518]），但仍非精确；
  - `smoothness` native：因无 CS 影响函数而退回最坏偏差近似，M 网格以 SE 为单位，与 R 的 M 不可直接比较。
- `sp.breakdown_m(e=0)` = 0.115（smoothness 近似口径）。

### E4 连续处理 DID（Callaway, Goodman-Bacon & Sant'Anna 2024）

| 估计量 | 结果 |
|---|---|
| TWFE 斜率（Table 2 列 1） | 0.214 (0.058) |
| `sp.cgs_continuous_did` degree=1：ACRT | **0.191** (0.015) |
| degree=2 / 3：ACRT | 0.421 / 0.636 |
| 二值 TWFE（任一联系×Post） | 0.978 (0.269) |
| 剂量三分位 × Post（vs 无联系）T1 [0.5,1] / T2 [1.33,2.33] / T3 [2.5,15.8] | 0.274 (0.247) / 1.505 (0.456) / 1.208 (0.493) |

- 线性 CGS 的 ACRT（0.19）与 TWFE（0.21）接近 → 在"强平行趋势"下，TWFE 斜率可以解释为平均因果响应。
- 但剂量-反应**明显非线性**：低剂量组几乎无效应，中高剂量组效应相近（饱和），高阶 B 样条 ACRT 随之变大。论文"每多 1 个联系 +21%"是线性近似，更准确的表述是"有实质联系（≥1.33）的县阵亡显著更多"。
- 注意：`cgs_continuous_did` 的 ACRT SE（0.015）来自逐格回归的影响函数、未按县聚类，明显小于聚类 TWFE 的 0.058，不宜直接用于推断（StatsPAI 摩擦 #6）。

### E5 大量零值下的函数形式（Chen & Roth 2024；I4R 评论）

| 结果 | 模型 | 系数 | p |
|---|---|---:|---:|
| 阵亡人数 | FE Poisson，无控制 | 0.285（+33%） | 0.071 |
| 阵亡人数 | FE Poisson，全控制 | 0.138（+15%） | 0.093 |
| 1[阵亡>0] | LPM，无控制 / 全控制 | 0.034 (p<0.001) / 0.022 (p=0.31) | |
| ln(1+阵亡)（论文） | OLS，无控制 / 全控制 | 0.214 / 0.213 | <0.001 |
| 国家级官职数 | FE Poisson DDD（Table 5 列 6 设定） | 0.059（+6%） | 0.52 |

- 与 I4R 一致：换成单位不变的 Poisson 百分比效应后，阵亡效应只在 10% 水平边际显著、幅度随控制减半。
- **新发现**：全国 DDD 的"权力效应"在 FE-Poisson 下**完全不显著**（+6%，p=0.52）。原因是国家级官职 92% 为零、FE-Poisson 丢弃全零县，且效应集中于少数高官职数的湖南县（强度边际），而 OLS 的 0.049 在均值 0.093 上换算为 52%。结论依赖水平值 OLS 的"均值换算"口径。

### E6 全国 DDD 事件研究（Figure 6C）的前期检验

- 1821–1853 共 33 个 Hunan×联系×年份系数（相对 1800–1820 基期）联合为零被强烈拒绝（Wald p≈1e-45），均值 0.036；前期彼此相等也被拒绝（p≈1e-38）——**逐年噪声很大**（湖南县少，单年系数波动大）；
- 但前期**没有线性趋势**：斜率 −0.0003/年（t=−0.66），1850–53 四年联合不显著（p=0.20）；
- 1854–1910 均值减 1821–1853 均值 = 0.048，恰好等于 Table 5 的 DDD 0.049。
- 解读：DDD 的识别来自"前期水平 vs 后期水平"的跳跃，而非前期平稳为零；1800–1820 基期的选择会影响图形观感，但不影响 Table 5（其前期是 1820–1853）。

### E7 Table 4 IV 的弱工具稳健推断

| | 列 4 | 列 5 | 列 6 |
|---|---:|---:|---:|
| 2SLS b（t） | 0.329 (2.39) | 0.323 | 0.330 |
| Kleibergen–Paap F（Stata） / effective F（StatsPAI） | 11.68 / 11.50 | – / 9.74 | – / 10.89 |
| tF 临界值（Lee et al. 2022，按 F=11.7） | **2.88** > 2.39 → 5% 不显著 | | |
| 手动聚类稳健 AR 95% 置信集 | **[0.06, 0.74]**，排除 0 | [0.05, 0.79] | [0.06, 0.78] |
| `sp.anderson_rubin_test(absorb=, cluster=)` | p=0.068，CI [−0.08, 3.38] | p=0.090，CI (−∞, ∞) | p=0.063 |

- 恰好识别时 AR 检验在 $\beta_0=0$ 处就是简约式（Table 4 列 1）的 t 检验：t=2.29、p=0.025 → AR 集排除 0；tF 更保守，不显著。IV 结论"在 AR 意义下稳健，在 tF 意义下边际"。
- **StatsPAI bug**：`sp.anderson_rubin_test` 在同样的 FE/聚类下给出 AR p=0.068，与简约式 t 检验矛盾；且其 `tF_critical_value` 用非稳健第一阶段 F（749）算出 1.96，而不是 effective F（11.5）→ 2.9。

---

## 5. StatsPAI bug / API 摩擦清单（含最小复现）

| # | 函数 | 问题 | 最小复现 / 证据 | 严重性 |
|---|---|---|---|---|
| 1 | `sp.hdfe_ols` / `sp.absorb_ols` | **不检测被 FE 吸收后共线的回归元**。精确共线 → `LinAlgError: Singular matrix`；因 float32 存储噪声而"近似共线"→ 不报错、系数爆炸（±4.8e5）并**悄悄改变其他系数**（Huai 列 9：0.0196 vs Stata/pyfixest 0.0214） | 见下方代码块 | 🔴 高：静默错误 |
| 2 | `sp.hdfe_ols` | 一个 FE 嵌套于另一个 FE（year ⊂ prefid×year）时，**吸收自由度多计**（Table 4 列 1：隐含吸收自由度比 reghdfe 的 209 多 14，SE 大 0.8%）| 合成数据：`y ~ x1 + x2 | year + unit + regionXyear` 的 `dof_fe`=368，去掉冗余的 year 后 354，系数相同 | 🟡 中 |
| 3 | `sp.hdfe_ols(wild=True)` | **wild bootstrap 不重新吸收不嵌套于聚类的 FE**，t* 用错残差 → p 值偏小 | `sp.hdfe_ols("alloff ~ Zeng_all0_invdistXperiod | year + samcntyid", data=湖南子样本, cluster="prefid", wild=True, wild_weight_type="webb")` p=0.045；Stata `boottest` 0.218；正确实现 0.226 | 🔴 高：推断错误 |
| 4 | `sp.anderson_rubin_test(absorb=, cluster=)` | AR 统计量与"简约式 t 检验"不一致（恰好识别时应相同）；`tF_critical_value` 用非稳健 F | Table 4 列 4：AR p=0.068 vs 简约式 p=0.025；tF 1.96（按 F=749）而非 2.88（按 F_eff=11.5） | 🔴 高 |
| 5 | `sp.honest_did` / `sp.breakdown_m` | 不能接收用户提供的 $(\hat\beta,\Sigma)$；非 CS/SA 结果只能走最坏偏差近似或 R 对角协方差，**relative_magnitude native 近似严重高估稳健性** | e=4, $\bar M=2$：native [0.085, 0.540] vs R 全协方差 [−1.47, 1.71] | 🟡 中（文档有警告） |
| 6 | `sp.cgs_continuous_did` | ACRT SE 未聚类（0.015 vs 聚类 TWFE 0.058）；无 `cluster=` 参数 | E4 | 🟡 中 |
| 7 | `sp.hdfe_ols(vce="conley")` | 只做截面 Conley，没有时间维（lag）与 FE-aware；需要手动去均值后调用 `sp.conley` | E1 | 🟢 摩擦 |
| 8 | `sp.feols` IV（pyfixest 后端） | 无法用 `ssc` 复现 ivreghdfe 的 $\frac{G}{G-1}\frac{N-1}{N-K-df_a}$（`adj=True` 把嵌套 FE 也算入 K）；也不自动删单例 | `common.iv()` 手动缩放 | 🟢 摩擦 |
| 9 | `sp.pretrends_power` | 返回 dict 中混有数组，不能直接 `json.dump` | E3 | 🟢 摩擦 |
| 10 | 生态 | `pd.read_stata` 把 id 读成 int8，`cntyid*1000` 溢出（非 StatsPAI 本身，但 `sp` 的数据读取工具可统一 upcast） | Table 3 构造 `cntyXsur` | 🟢 |

**Bug #1 最小复现**（合成数据）：

```python
import numpy as np, pandas as pd, statspai as sp, pyfixest as pf
rng = np.random.default_rng(1)
d = pd.DataFrame([(c, c // 10, t) for c in range(100) for t in range(10)], columns=["unit", "region", "year"])
d["regionXyear"] = d.region * 100 + d.year
post = (d.year >= 5).astype(float)
d["x"] = rng.normal(size=100)[d.unit] * post + rng.normal(size=len(d)) * 0.1
d["v"] = rng.normal(size=10)[d.region] * post          # spanned by region x year FE
d["y"] = 0.5 * d.x + rng.normal(size=len(d))
pf.feols("y ~ x + v | unit + regionXyear", data=d)       # drops v, estimates x
sp.hdfe_ols("y ~ x + v | unit + regionXyear", data=d)    # LinAlgError: Singular matrix
d["v"] += rng.normal(size=len(d)) * 1e-7                  # float noise (as in HuaiYr.dta)
sp.hdfe_ols("y ~ x + v | unit + regionXyear", data=d)    # no error, v coefficient explodes, x coefficient perturbed
```

---

## 6. 对 StatsPAI 的改进建议

1. **`hdfe_ols` 共线检测**：在 FWL 去均值后对 $\tilde X$ 做带容差的 pivoted QR（reghdfe 用相对容差、pyfixest 用 `collin_tol`），打印 "omitted because of collinearity" 并在结果中记录——这是 Stata 用户默认期待的行为。
2. **`hdfe_ols` 自由度**：用 FE 之间的嵌套关系（或 reghdfe 的 connected-components / pairwise 冗余计算）计算 $df_a$；输出与 reghdfe 相同的 "Absorbed degrees of freedom" 表，便于核对。
3. **wild bootstrap + HDFE**：每次抽样后必须对 $y^*$ 重新做 FE 投影（或利用 $M_D$ 的线性性预先计算），并加 `boottest` 数值回归测试；同时建议支持 `enumerate=True`（G≤12 时穷举 Rademacher）。
4. **`anderson_rubin_test`**：以简约式 $(y-\beta_0 d)$ on $z$ 的聚类 Wald 为定义，加单元测试"恰好识别、$\beta_0=0$ 时 = 简约式 t²"；`tF_critical_value` 必须基于 effective / KP F。
5. **`honest_did_from_moments(beta, sigma, num_pre, num_post, l_vec)`**：开放一个直接接收 $(\hat\beta,\Sigma)$ 的入口（与 R `HonestDiD` 同签名），让任何 TWFE / 连续暴露事件研究都能得到精确 FLCI / ARP 置信集；`hdfe_ols` 结果可提供 `.event_study(names)` 辅助函数自动抽取子向量与协方差。
6. **`cgs_continuous_did(cluster=...)`**：提供聚类/乘子自助标准误；并在结果中给出 dose-bin 平均效应，便于与 TWFE 对照。
7. **FE-aware Conley**：`hdfe_ols(vce="conley", conley_time=..., conley_lag=..., conley_kernel="bartlett")`，内部先吸收 FE 再调用 `sp.conley`（本复现证明 `sp.conley` 本身已与 `reg2hdfespatial` 精确一致）。
8. **Stata 迁移助手**：`sp.from_stata` 可识别 `lnurbanpopXperiod-Taiping_route1Xperiod` 这类**变量区间**并提示"依赖数据集变量顺序"——本论文中同一写法在不同 do-file 展开为 12 或 34 个变量。
9. **IV 小样本约定**：`sp.iv` / `sp.feols` IV 增加 `small="ivreghdfe"|"reghdfe"|"none"` 选项，自动删单例并按 Stata 约定缩放。

---

## 7. 一句话总结

原始代码在 Stata 18 上**完整复现**（31/31 个 do-file，除 3 个 IV 标准误第三位小数的版本差异外逐字相同，前提是装对 2015 版 `reg2hdfespatial`）；StatsPAI（以 `sp.feols` + reghdfe 自由度公式为主力）**逐格复现全部正文表图**（与 Stata 重跑到 1e-8）。现代方法扩展显示：核心结论在县级聚类、Conley、AR 推断下稳健，但在 **15 个府聚类的 wild bootstrap（无控制时 p≈0.3）**、**Poisson 函数形式（全国权力效应 p=0.52）** 与 **HonestDiD（$\bar M$ breakdown≈1.3，远期效应更脆弱）** 下明显变弱；过程中发现 StatsPAI 的 `hdfe_ols` 共线/自由度、wild bootstrap、`anderson_rubin_test` 三个会**静默给出错误数字**的问题。
