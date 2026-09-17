# 《AI-tocracy》模型解读与 StatsPAI 复现分析

> **论文**：Beraja, Martin, Andrew Kao, David Y. Yang and Noam Yuchtman (2023). "AI-tocracy." *Quarterly Journal of Economics*, 138(3): 1349–1402. DOI: [10.1093/qje/qjad012](https://doi.org/10.1093/qje/qjad012)
> **复现包**：Harvard Dataverse [doi:10.7910/DVN/GCOVGX](https://doi.org/10.7910/DVN/GCOVGX)（`Analysis/Analysis.do` 11,755 行单文件 + `make_map.R`；数据 5.2 GB 全部公开）
> **环境**：Stata 18 MP（reghdfe 6.13.1、ivreghdfe 1.1.4、estout、项目内 ado：carryforward、xtevent 1.0.0、make_index_gr、jive）；R 4.5.2 + sf/scatterpie；Python 3.13 + statspai 1.28.0（pyfixest 后端）
> **读者对象**：想逐方程核对本文、或想用 StatsPAI 复现类似"HDFE 事件研究 + 高维天气 IV"设计的研究者

---

## 目录

1. [复现包结构与图表映射](#1-复现包结构与图表映射)
2. [逐方程拆解](#2-逐方程拆解)
3. [原始代码运行结果](#3-原始代码运行结果)
4. [StatsPAI 复现细节](#4-statspai-复现细节)
5. [现代方法扩展（非复现）](#5-现代方法扩展非复现)
6. [StatsPAI bug 与 API 摩擦（含最小复现）](#6-statspai-bug-与-api-摩擦含最小复现)
7. [给 StatsPAI 的改进建议](#7-给-statspai-的改进建议)

---

## 1. 复现包结构与图表映射

`Analysis.do` 用局部宏 `output` 选择 21 个 section（`"all"` 全跑）。本项目做了两处一行级修改（均加 `[REPLICATION EDIT]` 注释）：根目录可由全局宏 `$AITOC_ROOT` 覆盖；section 号可作为 `do Analysis.do 8` 的参数传入。`Program/run_original.sh` 把 section 分组并行跑批处理 Stata，`Program/_root/{Analysis,Data,Output}` 是指向项目 `Program/Analysis`、`Data`、`Results/Output` 的相对软链接，跑完后 `.tex/.log` 归档到 `Results/Tables`、图归档到 `Results/Figures`。

| section | 图表 | 数据 | 主要命令 |
|---|---|---|---|
| 1 | Figure I、A.5（地图数据）→ `make_map.R` | GDELT、合同 | collapse / export csv |
| 2 | Figure II、A.12、A.13 | GDELT 日度 + 气象站日度 + 合同 + 摄像头 | ivreghdfe（6 个超前/滞后骚乱） |
| 3 | Figure III、Table A.3 | 同上 | xpoivregress、ivreghdfe（简约 IV、LIML）、jive |
| 4 | Figure IV | GDELT 地级市对×季度（3.1 GB） | ivreghdfe + 预测值 |
| 5 / 6 | Figure V / VI、A.11、A.14 | firm_data（917 MB） | reghdfe 事件研究 |
| 7 | Table I | 多个 | file write |
| 8 / 9 | Table II / III | 同 section 2 | ivreghdfe（OLS）、xpoivregress（LASSO IV） |
| 10 | Table IV、V、A.5–A.7 | GDELT 地级市对×季度 | ivreghdfe 两步 |
| 11 / 12 | Table VI、A.8–A.10 / Table VII、A.11–A.13 | firm_data | reghdfe + `addQuarterInter` |
| 13 | Table VIII | export_regression | ivreghdfe robust |
| 14 | Table IX、Figure A.16 | firm_data + 合同 | xtevent（A）、reghdfe（B、C） |
| 15 / 16 | Figure A.4 / A.6 | 合同、企业资本 | twoway / binscatter |
| 17 | Figure A.10（100 个种子） | 同 section 2 | xpoivregress × 100 |
| 18 | Figure A.15 | firm_data | reghdfe |
| 19 | Table A.2 | 同 section 2 | ivreghdfe + xpoivregress（抗议/诉求/威胁） |
| 20 | Table A.4 | 警察招聘 | reghdfe |
| 21 | Table A.14、A.15 | firm_data 及稳健性数据 | reghdfe |

---

## 2. 逐方程拆解

### 2.1 式 (1)：骚乱 → 公安 AI 采购（Table II、III；Figure II、III）

**变量构造**（section 8 代码，逐日→季度）：

1. `GDELT_China_072920` 事件级数据合并摄像头采购（年份前后错位合并得到 lead/lag）、合同数据（按城市累计的公安合同数 `lead_police`，**月份向后平移 3 个月 = 1 个季度**，所以 `lead_police_pc` 是 $t+1$ 季度的累计合同/人口在季度内的均值）。
2. 合并地级市-气象站对照、逐日天气；`tsfill, full` 补齐日历，`carryforward` 填补控制变量。
3. 骚乱 `event = protest + demand + threat`；`event_elsewhere = 1{当天全国有骚乱}`。
4. collapse 到地级市×季度：骚乱与工具**求和**，结果与控制变量**取均值**；`prefecture_city_population = log(1+pop)`；`AI_stock_t2` = 截至 $t-2$ 的累计。
5. 结果与骚乱都在全样本**标准化**。

**Panel A（OLS）**：`ivreghdfe y blank c.X##qofd, absorb(place qofd) cl(place)`；列 4：`blank AI_stock_t2`（Table II）或 `blank AI_stock_t2 + 全部 X×季度`（Table III，代码中列 4 与列 5 相同，论文数值也相同）。

**Panel B（LASSO IV）**：

```stata
xpoivregress y (blank = c.(w1-w18)##c.(w1-w18) c.(wI1-wI18)##c.(wI1-wI18)), ///
    control((i.qofd i.place) prefecture_gdp gdp_*) vce(cl place) rseed(1)
```

- 候选工具 ≈ 2×(18 + 171) = 378 个（含平方项；我们在去掉零方差项后得到 340 个）；Table III 只用 36 个线性项。
- 括号内 `i.qofd i.place` 强制进入，`prefecture_gdp gdp_*`（GDP×季度哑变量）参与 LASSO 选择。
- `xpoivregress` 默认 10 折 cross-fit、plugin λ；单次在本机（与其他任务共享 8 核）约 **30 分钟**。

**Figure II**：对 $t-2,\dots,t+3$ 六个骚乱变量，除 $t$ 期外其余都先对 $t$ 期骚乱回归取拟合值（"正交化"）后再同时放入回归。

### 2.2 式 (2)：AI 存量 × 适宜天气 → 骚乱（Table IV、V；Figure IV）

section 10 从 3.1 GB 的"地级市对×季度"面板中保留 `place == place_lag`（即普通地级市×季度面板），然后：

1. **第一阶段（"conducive weather"）**：`ivreghdfe event event_elsewhere i3, absorb(qofd place)`，`i3` 是写死在代码里的 LASSO 选出的天气项（Table IV 与 Table V B 用两组不同的 `i3`）；`predict event_hat`（xb）。
2. `event_hat` 去均值 → 标准化为 `blank_hat`；结果 `event` 标准化；
3. 缺失的 GDP / 人口（取 log）/ 财政收入用**省均值插补**（Table V B 不插补、人口不取 log、也没有 `epop`）；
4. `pol` = 标准化的 $AI\ stock_{t-1}$（公安合同/人口；Table IV B 为 AI×摄像头；Table V A 为非公安合同；Table V B 为 $t-1$ 骚乱）；`blank_pol = blank_hat × pol`；
5. 第二阶段：`ivreghdfe event pol blank_hat blank_pol prefecture_gdp c.X##qofd if circle_1000k==1, absorb(qofd place) cl(place)`。

注意：第一阶段是**生成回归元**，第二阶段 SE 没有考虑第一阶段估计误差（论文未讨论）。

### 2.3 式 (3)–(4)：政治动机合同 → 企业软件（Table VI、VII；Figure V、VI）

section 11/12 的核心代码（Table VI 列 1）：

```stata
use firm_data, clear
bys city: egen protest_count = count(event) ...           // 无骚乱城市补 0
gen t0_event = event if quarter_to_first==0 | missing(quarter_to_first)
bys sub_fe: egen mt0_event = mean(t0_event)
su mt0_event, d
keep if mt0_event > r(p50)                                   // "高骚乱"合同
collapse (count) n_software (lastnm) place, by(company ... quarter_to_first qtf qofd with_contract_dummy sub_fe police_data)
sort police_data company qofd qtf
gen n_software_cum = n_software
replace n_software_cum = n_software_cum[_n-1] + n_software_cum ///
        if company==company[_n-1] & with_contract_dummy==1 & quarter_to_first >= -1
keep if inrange(quarter_to_first,-24,24) & place != 0
replace quarter_to_first = quarter_to_first + 24            // 基期 23 = 事件时 -1
gen semi_to_f_x_ca_x_with_c = quarter_to_first * police_data * with_contract_dummy
reghdfe n_software_cum b(23).semi_to_f_x_ca_x_with_c b(23).quarter_to_first ///
        i.with_contract_dummy i.qofd ca_x_with_c semi_to_f_x_with_c semi_to_f_x_ca police_data, ///
        absorb(sub_fe) cl(place)
addQuarterInter                                               // b_k(交互)+b_k(基准)，方差直接相加
```

我们在导出的面板上发现三个对解读很重要的**数据结构事实**：

1. **堆叠副本**：同一企业（`sub_fe`）在面板中最多出现三份——"从未签约"对照副本（`with_contract_dummy=0`，`quarter_to_first` 被置为 0，即 24）、公安合同副本、非公安合同副本；三份共享企业 FE。Table VI 列 1 实际只有 146 个企业、**38 个聚类**。
2. **结果变量口径不一致**：`n_software_cum` 只对"已签约副本、事件时 ≥ −1"的行做累计；事件前各期和对照副本保留**当季流量**。公安合同企业在事件时 −2 的平均流量 0.55，−1 为 1.40，+8 时累计值已到 19.6。于是 +8 期系数在"签约后流量完全不变"的情况下也会机械地上升约 9 个季度的流量之和。
3. **SE 合成**：`addQuarterInter` 用 `V[inter]+V[base]`，忽略两系数协方差；用完整 vcov 的 lincom，Table VI 列 1 的 SE 是 2.165 而非 3.888。

Table VII 的"差分"把公安合同副本与非公安合同副本（两者都累计）比较，机械累计大体被抵消，所以更可信；但它的 `quarter_to_first` 基准系数在企业 FE + 季度 FE 下只能识别到一个线性趋势（Stata 自动省略 47、48 两期和三个线性项），单独解读"8 quarters before/after contract"行没有意义。

**另一个代码细节**：Table VII 列 2 的 `scale_yyyy` 是用 `if qofd == yyyy` 生成的（`qofd` 是季度序号 212–237，永远不等于年份），全部为 0 被省略；真正起作用的是 `scale* capital_usd_m*` 通配展开中的水平项 `scale`、`capital_usd_m`（主要通过缺失值改变样本）。Table VI 列 3 的对照组权重是 10（论文正文写 1000），Table VII 列 3 才是 1000。

### 2.4 Table VIII：出口

`ivreghdfe export_diff police_data scale [software] [year_founded] if ever_contract==1 [aw=sub_weight], robust [absorb(contract_ym place)]`。`ivreghdfe` 默认带 `small`：稳健方差乘 $N/(N-K)$，$K$ 含吸收的 FE 自由度，且先删 32 个单例。

### 2.5 Table IX：溢出

- **Panel A** 用 `xtevent`（连续政策变量 `event` = 企业总部所在地的季度骚乱）：

  xtevent **1.0.0** 对非二元政策变量的构造（`_eventgenvars.ado`）：
  $$\_k\_eq\_m_k = z_{t+k}-z_{t+k-1}\ (k=1..8),\quad \_k\_eq\_p_k = z_{t-k}-z_{t-k-1}\ (k=0..8)$$
  $$\_k\_eq\_m9 = 1 - z_{t+8},\qquad \_k\_eq\_p9 = z_{t-9}\ \text{（缺失保留缺失）}$$
  省略 `_k_eq_m1`，`areg y _k* i.qofd, absorb(sub_fe) vce(cluster place)`，报告 `_k_eq_p8`。`1 - F8.z` 这一端点公式对连续变量并无意义（是为二元变量设计的），2.x 版改写了端点逻辑，导致同一代码得到 −8.678 而不是 23.968。
- **Panels B/C**：`joinby` 构造"企业 × 同城（同母公司）他企合同"对，`reghdfe n_software b(23).quarter_to_first if n_contracts==0, absorb(firm_contract qofd) cl(place)`；`collapse (lastnm)` 与 `bys firm_contract qofd: drop if _n>1` 都依赖随机排序。

---

## 3. 原始代码运行结果

分组并行批处理（`Results/logs/run_original_steps.csv` 记录每个 section 的 rc 与秒数）：

| section | 图表 | rc | 秒 | 与论文/作者原输出比较 |
|---|---|---|---|---|
| 7 | Table I | 0 | 6 | 四个面板与作者 `.tex` **逐字节相同** ✅ |
| 8 | Table II | 0 | 11,078 | A、B（LASSO IV，每列选中 9 个工具）均逐字节相同 ✅ |
| 9 | Table III | 0 | 5,511 | 四个面板逐字节相同 ✅ |
| 10 | Table IV、V、A.5–A.7 | 0 | 137 | 系数全同；Table IV A 列 4 等 5 个 SE 在第 4 位小数差 0.0001 ⚠️ |
| 13 | Table VIII | 0 | 2 | 逐字节相同 ✅ |
| 14 | Table IX、A.16 | 0 | 864 | A 逐位相同 ✅（需 xtevent 1.0.0）；B、C 不同 ❌（随机排序，见下） |
| 11 / 12 | Table VI / VII | 0 | 417 / 155 | 数值接近但不逐位相同 ⚠️/❌（随机排序） |
| 2 | Figure II、A.12、A.13 | 0 | 314 | 系数文件与作者 `Fig2.dta` 等差 < 1e-6 ✅ |
| 5 / 6 | Figure V / VI、A.11、A.14 | 0 | 105 / 183 | 图形一致，系数文件差 0.1–9（随机排序） |
| 3 | Figure III、Table A.3 | 首次 199（缺 `jive`），补装 SJ st0108 后 0 | 5,491 | A.3 的 LASSO 系数日志除标签折行外相同 ✅；Figure III：LASSO、7 天窗口、简约 IV、OLS 四根柱逐位相同 ✅，JIVE 0.3005 vs 0.3007 ⚠️，LIML 0.2936 vs 0.2894 ❌（数值不稳定，§4.5） |
| 1 + R | Figure I、A.5 | 0 | 1 | sf 移植版地图与作者 PDF 目视一致（图例上限标签略异） |
| 15, 16, 18, 20, 21 | Figure A.4、A.6、A.15，Table A.4、A.14、A.15 | 0 | 3–1767 | A.4 逐位相同；A.14/A.15 随机排序导致差异 |
| 19 | Table A.2 | 0 | 12,060 | 六个面板逐字节相同 ✅ |
| 17 | Figure A.10 | **未运行** | — | 100 × cross-fit LASSO IV，按实测 ≈30 min/次 需 >50 小时；作者包内图文件日期 2022-04 |

### 3.1 跑通需要的修复

1. **`make_index_gr` 未随包提供**：section 5、6、11 的列 2/5 调用它，缺失时 r(199) 中止整个 section。来源：Cyrus Samii 的 GitHub `cdsamii/make_index`（V.0.2，2017-12），保存为 `Program/ado/make_index_gr.ado`。
2. **`xtevent` 版本**：SSC 当前 3.1.0（以及 GitHub 上的 2.1.1、2.2.0）得到 Table IX A = −8.678 / 3.961 / −5.343；**1.0.0（2021-08）**逐位复现 23.968 (10.122) / 1.372 (1.102) / 9.812 (4.709)。
3. **`jive`（Poi 2006，Stata Journal st0108）** 未在 README 列出，section 3 的 JIVE 估计需要它。
4. **`carryforward`** 在 README 中已列出，装到项目内 ado。
5. **R 地图**：`rgdal`、`rgeos`、`maptools` 已从 CRAN 下架，本机无 GDAL/GEOS 开发库，改用 `sf` 移植（`Program/make_map_sf.R`，只换空间 I/O 层）。

### 3.2 为什么 Table VI、VII、IX B/C 无法逐位复现

- `collapse (count) n_software (lastnm) place, by(company … sub_fe police_data)`：在 firm_data 中有 **425 个 collapse 格子含多个 `place`**（同一企业同一季度的软件对应不同合同地）。`lastnm` 取排序后最后一个非缺失值，而此前的 `bys city:`、`bys sub_fe:` 排序在并列时用随机数打破（`set sortseed 2` 只固定种子，结果还取决于排序算法与此前消耗的随机数）。`place` 同时是**聚类变量**和**样本筛选条件**（`keep if place != 0`），所以系数和 SE 都会变。
- 实验：同一份代码，默认 `sortmethod`（fsort）得 10.783 (3.888)；`set sortmethod qsort` 得 10.663 (3.667)；论文 10.671 (3.664)；2022 年 10 月工作论文版 10.746 (3.917)。
- 同理，section 5（Figure V）与 section 11（Table VI）虽然是同一回归，因循环顺序不同消耗的随机数不同，本机两者也不完全一致。
- Table IX C 在作者的输出时间戳中比 A/B 晚 26 小时单独生成（2023-01-31 00:01），`estout nc_reg_*` 在我们整段运行时还会把 Panel A 的三个空列带进表里（作者文件只有 3 列），说明作者是分段运行的；Panel C 结果（−0.498 / −0.102 / 1.365***）与我们的（0.810** / −0.228 / 0.070）差异较大，无法判断是随机性还是代码在作者运行后又被修改。

---

## 4. StatsPAI 复现细节

### 4.1 起点：用"导出钩子"拿到与 Stata 完全相同的分析样本

作者的全部数据构造都在 `Analysis.do` 内存中完成（逐日天气合并、collapse、`lastnm`），不落盘。`Program/statspai/make_export_do.py` 自动生成 `export_analysis_data.do`：复制 `Analysis.do`，在每个估计命令前插入 `save "Data/Intermediate/statspai/…dta"`（共 30 个钩子），并把耗时的 `xpoivregress` 替换为一个空 `regress`。**Tables IV–V 的全部变量构造**（第一阶段、去均值、标准化、插补）在 Python 中从"第一阶段之前"的面板重新实现，与 Stata 快照的最大差 1.8e-6（float 存储精度）；其余表从回归前一刻的面板出发（随机 `lastnm` 使 Python 独立构造无法逐位对齐）。

### 4.2 小样本校正：`common.hdfe()`

`sp.feols(..., ssc=pf.ssc(adj=False, cluster_adj=False))` 取未校正三明治，再按 Stata 公式乘校正因子：

| Stata 命令 | 校正 | $K$ |
|---|---|---|
| `ivreghdfe …, cl()`（默认 small） | $\frac{N-1}{N-K}\frac{G}{G-1}$ | rank(X) + df_a，df_a = Σ 各 FE 水平数 − (FE 个数 − 1) − 嵌套于聚类的 FE 水平数；**不含常数** |
| `reghdfe …, cl()` | 同上 | 再 **+1**（reghdfe 报告 `_cons`） |
| `ivreghdfe …, robust` | $N/(N-K)$ | 同 ivreghdfe，先删单例 |
| `areg …, vce(cluster)`（xtevent 1.0） | $\frac{N-1}{N-K}\frac{G}{G-1}$ | rank(含 i.qofd) + 1 + (企业数 − 1)，**不做嵌套调整** |

校准依据：Table IV 列 1 Stata 的 e(df_a)=21、rankxx=25，实际因子 1.009650 与 $K=46$ 吻合；Table VI 列 1 e(df_a)=0、rank=121，需 $K=122$。

### 4.3 共线性省略顺序：`common.stata_keep_order()`

企业 FE + 季度 FE 下，事件时哑变量与"日历时间 − 队列"完全共线，**哪个系数被省略决定了其余系数的标准化**。pyfixest 用带主元的 QR，Stata 按变量出现顺序依次剔除。起初 Table VII "8 quarters before/after contract" 在 StatsPAI 中 SE 高达 5×10⁵，换成手工哑变量后又与 Stata 差 0.14——都来自省略集合不同。我们按 Stata 命令行顺序显式生成哑变量，在 FE 去均值后逐列做 Gram–Schmidt，残差范数 ≤ 1e-8 的列剔除，精确复现了 Stata 的省略（Table VII 列 1–3：47、48 期 + 三个线性项；列 4–6：仅三个线性项）。

### 4.4 逐表结果

| 表 | StatsPAI 调用 | 结果 |
|---|---|---|
| II A、III A/C | `sp.feols("y ~ blank + X + i(qofd, X) | place + qofd", vcov={"CRV1":"place"})`（X 先除以标准差，见摩擦 F2） | 15 列 × (b, se) 全部 ✅ |
| II B、III B/D | FWL 去 FE 与控制 → `sp.lasso_iv(penalty="cv", cluster="place")`；`sp.rlasso_iv` 作诊断 | **近似** ⚠️：II B 0.245–0.264（论文 0.348–0.377）；III B 0.69–0.74（0.559–0.599）；III D 0.87–0.90（0.966–1.070）。StatsPAI 没有 cross-fit PO-LASSO-IV；plug-in rigorous LASSO 在本数据上**一个工具都不选** |
| IV、V | 第一阶段 `sp.feols` → Python 构造 → 第二阶段 `sp.feols` | 12 行 × 4 列系数全同；SE 与本机 Stata 全同（论文有 5 个 SE 第 4 位差 0.0001，本机 Stata 本身如此） |
| VI | 显式设计矩阵 + `sp.feols(... | sub_fe)` + addQuarterInter | 18 格全同 ✅ |
| VII | 显式设计矩阵 + `sp.feols(... | sub_fe + qofd)` | 72 格全同 ✅ |
| VIII | `sp.feols(..., weights="sub_weight", vcov="hetero")` + small | 4 列全同 ✅ |
| IX | A：Python 实现 xtevent 1.0.0 设计 + `sp.feols`；B/C：`sp.feols` | A 系数全同，SE 差 < 3e-6 相对量 ✅；B/C 与本机 Stata 全同 ✅ |
| Figure II、A.12、A.13 | `sp.feols` | 18 个系数与 Stata 系数文件全同 ✅ |
| Figure V | `t6_t7` 的事件时剖面 | 与 section 11 全同；与 section 5 的 `Fig5` 文件差异来自随机排序 |
| Figure III | OLS：`sp.feols`；简约 IV：`sp.feols("… | place + qofd | blank ~ rain + gust + thunder + …")`；LIML：FWL + `sp.liml(cluster=…)` | OLS 0.1995 (0.0434)、简约 IV 0.3131 (0.1598) 与作者 `Fig3.dta` **逐位相同** ✅；LIML 0.267 vs 作者 0.289 ❌（见 §4.5）；LASSO IV、7 天窗口、JIVE 无对应估计量 |

### 4.5 一个意外发现：Figure III 的 LIML 柱在 Stata 中数值不稳定

LIML/2SLS 使用约 340 个"季度加总天气变量的乘积"作工具，量级达 1e13。我们在同一数据上用 numpy、`sp.liml` 和 Stata 对比：

| 实现 | 工具处理 | 2SLS | LIML | λ |
|---|---|---|---|---|
| Stata `ivreghdfe … liml`（作者写法） | 原始量级乘积 | 0.2956 | 0.2936 | 1.0139 |
| Stata 同命令 | **每个工具先标准化** | 0.2488 | 0.2678 | 1.0621 |
| numpy k-class / `sp.liml` | 标准化，FWL 去 FE | 0.2479 | 0.2667 | 1.0627 |

工具标准化是线性重参数化，不应改变 2SLS/LIML 的点估计；Stata 结果随量级改变，说明原始写法下的叉积矩阵求逆已经失去精度（Stata 还因此多删了 1–2 个"共线"工具）。作者图中的 LIML 0.289 (0.133) 应视为数值误差主导，稳定实现给出 ≈0.267。StatsPAI 本身没有问题（与 numpy 手算一致），但同样**不会对这种病态设计给出警告**。

总计（`Results/comparison.md` 的 181 行主文系数，StatsPAI 对本机 Stata）：**166 行 ✅、15 行 ⚠️（LASSO IV 近似）、0 行 ❌**；另有 Figure II/A.12/A.13 的 18 个系数、Figure III 的 2 根柱逐位相同。本机 Stata 对论文：80 ✅、57 ⚠️、44 ❌（⚠️/❌ 几乎全部来自 Tables VI、VII、IX B/C 的随机排序）。

---

## 5. 现代方法扩展（非复现）

数值文件：`Results/statspai/extensions_summary.csv`、`ext_E2_eventstudy_flow.csv/png`、`ext_E3_honest_did.csv`、`ext_E5_ar_grid.csv`。

### E1 结果变量口径：累计 vs 流量（最重要）

在**完全相同的样本与回归**（Table VI 列 1、Table VII 列 1）中只把因变量从 `n_software_cum` 换成 `n_software`：

| 规格 | 因变量 | +8 期（作者口径） | 0..8 期流量效应之和 |
|---|---|---|---|
| Table VI 列 1 | 累计（作者） | 10.783，SE 3.888（作者无协方差）/ **2.165（完整 vcov）** | — |
| Table VI 列 1 | 流量 | −0.272 (0.743) | **−4.151 (3.943)** |
| Table VII 列 1 交互项 | 累计（作者） | 9.751 (3.290)；0..8 期之和 59.4 (24.3) | — |
| Table VII 列 1 交互项 | 流量 | −0.191 (0.595) | **−1.851 (4.235)** |

Stata `lincom` 独立复核，数字完全一致。含义：以事件时 −1 为基准，签约后企业的**季度软件产出并未上升**；论文"两年后多出约 10 个软件"主要是把事件后累计量与事件前（及对照副本）流量相比较产生的机械差。注意 −1 期本身是一个产出尖峰（流量 1.40 vs −2 期 0.55），以 −1 为基准会压低流量效应，因此需要 E2。

### E2 交错 DID（流量口径，公安合同副本，未处理/尚未处理对照）

面板：147 家企业 × 季度（2,734 行），队列 = 第一份政治动机公安合同所在季度，窗口 ±24。

| 估计量 | 平均每季度 ATT（0..8） | 0..8 期之和 | 0..8 期之和减去事前均值（−8..−2）×9 |
|---|---|---|---|
| TWFE 动态（省略 −1 与 ≤−12） | — | −6.58 | 0.93 |
| Callaway–Sant'Anna（DR，not-yet-treated，cohort cutoff，bootstrap 聚类） | −0.33 (0.46) | −4.76 | 3.89 |
| Sun–Abraham（末期队列为对照） | 0.12 (0.24) | 1.08 | 4.96 |
| Borusyak–Jaravel–Spiess 插补（删 21 家无未处理期企业） | 0.33 (0.39) | 2.94 | 2.46 |

结论：用整个事前期作基准的稳健估计量给出每季度 +0.1 到 +0.3 个软件、累计约 1–5 个，**均不显著**，量级明显小于论文的 10.7。

### E3 预趋势功效与 honest DID

- `sp.pretrends_power`：BJS 0.42、SA 0.48（低功效警告）、CS 0.84。
- `sp.honest_did`（e=0）：BJS 在 M=0 时 95% CI 已含 0（−0.76, 0.81），SA 同（−1.12, 0.75）。注意 StatsPAI 原生 RM 近似已知会高估稳健性（兄弟项目确认），这里只作方向性参考。

### E4 少聚类：野聚类自助法

Table VI 列 1 只有 38 个聚类。对 FWL 去 FE 后的回归做 `sp.wild_cluster_bootstrap`（Webb 权重，9,999 次）：交互项（+8 期 × 公安）9.993，常规聚类 SE 3.506，**自助 p = 0.0021**，95% CI [2.94, 16.93]——在作者自己的累计口径下推断稳健；E1/E2 显示问题在估计量的含义而非推断。

### E5 弱工具：简约天气 IV（Figure III 第三根柱）

雨、阵风、雷暴及其与"全国其他地方有骚乱"的交互（6 个工具），地级市 + 季度 FE、GDP×季度：
- 2SLS 0.313 (0.160)；**聚类稳健第一阶段 F = 0.46**；
- 聚类稳健 Anderson–Rubin 置信集（`sp.feols` Wald 检验逐点反演，网格 [−1, 2] 步长 0.02）**覆盖整个网格**，即无界；
- `sp.anderson_rubin_ci` 只有 iid 版本，无法给出聚类 AR 集。

---

## 6. StatsPAI bug 与 API 摩擦（含最小复现）

### Bug 1：`sp.callaway_santanna(estimator="reg", allow_unbalanced_panel=True)` 静默返回全 0

```python
f = extensions_modern.firm_flow_panel()      # 147 家企业、非平衡、无从未处理组
r = sp.callaway_santanna(f, y="y", g="g", t="qofd", i="sub_fe",
                         control_group="notyettreated", allow_unbalanced_panel=True, estimator="reg")
r.estimate, r.se                   # (0.0, 0.0)
r.detail[["att","se"]].head()      # att=0.0, se=inf，全部 (g,t) 格子
# 同一数据 estimator="dr" 或 "ipw" → overall -0.331 (0.462)，46/49 个事件时点非零
```

合成的非平衡面板上未能复现，属数据相关，但应至少报错或警告。

### Bug 2：CS 把"无可用对照"的 ATT(g,t) 记为 0（SE=0/inf）并纳入加总

```python
rows=[]; rng=np.random.default_rng(0)
for u in range(200):
    g=[5,7,9,11][u%4]
    for t in range(1,13): rows.append(dict(i=u,t=t,g=g,y=rng.normal()+(t>=g)))
S=pd.DataFrame(rows)
r=sp.callaway_santanna(S,y="y",g="g",t="t",i="i",control_group="notyettreated")
r.estimate        # 0.549，真值 1.0；事件时 +6、+7 的 att=0.0、se=0.0
```

R `did` 会把这些格子设为 NA 并警告。兄弟项目（QJE2019）独立发现同一问题。

### Bug 3：`sp.rlasso_iv` 选不出工具时仍返回数值

Table II B 数据上 plug-in 惩罚一个工具都不选，`fit.selection["n_selected_Z"]==0`，却返回系数 0.33、**SE 8.3×10¹⁴**（五列都如此）。应当抛出 `NoInstrumentsSelected` 或返回 NaN。

### 摩擦 F1：`sp.feols` 在大量级回归元下去均值失败

```python
sp.feols("event ~ event_elsewhere + fog_visib + ... + stp_stp | qofd + place", data=s10_raw_b1)
# ValueError: Demeaning failed after 10000 iterations.
```

回归元量级到 1e13（`stp²` 的季度和）。把回归元除以标准差即可收敛；StatsPAI 可在内部做列缩放。

### 摩擦 F2：量级悬殊时 CRV1 SE 为 NaN 或错误，且无警告

Table IV 列 3/4 的 `i(qofd, prefecture_fiscal_revenue)`（量级 1e7）使 `sp.feols` 返回 `blank_hat` 的 SE 0.4499（正确 0.1613）或 NaN；把控制变量除以标准差后完全正确。应在求逆前做列均衡或至少报条件数警告。

### 摩擦 F3：共线性处理与 Stata 不同，改变事件研究系数的标准化

完全共线的事件时哑变量 + 双向 FE 下，`sp.feols` 保留了一个近奇异集合（SE ~5×10⁵），或省略与 Stata 不同的列。建议提供 `collinear="stata"`（按公式顺序逐列剔除）选项，并在结果中列出被省略的项。

### 摩擦 F4：小样本校正无法对齐 reghdfe / ivreghdfe

`ssc` 无法表达"嵌套于聚类的 FE 不计入 K""reghdfe 的常数计入 K""ivreghdfe 不计常数""areg 不做嵌套调整"。建议 `sp.feols(..., small="reghdfe"|"ivreghdfe"|"areg")`。

### 摩擦 F5：`i(var, ref=[a, b])` 不支持多个基期

```python
sp.feols("y ~ i(relc, ref=[-1, -12]) | sub_fe + qofd", ...)
# ValueError: Value `[-1, -12]` for `TreatmentContrasts.base` is not among the provided levels.
```

所有单位最终都被处理时动态 TWFE 必须省略两期，只能手工生成哑变量。

### 摩擦 F6：缺少的估计量

- 没有 cross-fit partialing-out LASSO IV（Stata `xpoivregress` / `poivregress`），也没有带聚类稳健惩罚的 `ivlasso`；`sp.lasso_iv` 的 diagnostics 只有 "N instruments"，不返回被选中的工具名。
- `sp.anderson_rubin_ci` 无 `cluster=` 选项。
- 没有 xtevent 式"连续政策变量"事件研究（`sp.event_study` 只接受二元处理时点）。
- `sp.did_imputation` 遇到无未处理期的单位直接报错，没有 Stata `did_imputation, autosample` 那样的自动剔除选项。
- `sp.callaway_santanna` 在聚类层级高于单位时强制 `bstrap=True`（合理），但错误信息之前没有提示可用的解析替代。

### 摩擦 F7：`sp.ivreg` 公式语法

`"y ~ 1 + [d ~ z]"` 报 `MethodIncompatibility`，需写作 `"y ~ (d ~ z)"`；错误提示给出了恢复方法，体验尚可。

---

## 7. 给 StatsPAI 的改进建议

1. `sp.feols`：内部列缩放 + 条件数警告（F1、F2）；`collinear="stata"`（F3）；`small=` 的 Stata 兼容族（F4）；`i()` 多基期（F5）。
2. 增加 `sp.po_lasso_iv` / `sp.xpo_lasso_iv`（cross-fit、plugin/CV 惩罚、聚类稳健），并在 `sp.lasso_iv` 结果中返回选中工具名。
3. `sp.callaway_santanna`：修复 Bug 1、Bug 2；无对照格子设 NaN 并从加总中剔除。
4. `sp.rlasso_iv`：零工具时抛异常（Bug 3）。
5. `sp.anderson_rubin_ci(cluster=...)`；`sp.event_study(policy="continuous")`（xtevent 兼容，含版本约定说明）。
