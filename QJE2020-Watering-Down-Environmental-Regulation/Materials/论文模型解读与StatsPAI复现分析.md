# 论文模型解读与 StatsPAI 复现分析

**论文**：He, Wang & Zhang (2020), "Watering Down Environmental Regulation in China", *QJE* 135(4)。
**复现包**：Harvard Dataverse doi:10.7910/DVN/LVS8VX（CC0，3.4 MB 压缩 / 16 MB 解压）。
**环境**：Stata 18 MP，rdrobust 10.0.0（SSC），mdrd 26Apr2017（Wayback 存档）；Python 3.13，statspai 1.28.0，rdrobust（rdpackages Python 版）作带宽参照。

---

## 一、逐方程拆解

### 1. 样本与变量（作者已完成的前处理）

复现包没有原始 ASIF/ESR 数据，只给出**最终分析样本**，其中结果变量已残差化：

| 变量 | 含义 | 构造（论文描述，代码未提供） |
|---|---|---|
| `distance_new` | 沿河道到监测站的距离（km），上游 < 0 | 企业位置投影到最近河段，高程比较判断上下游 |
| `neg_ind0` | 1 = 16 个水污染行业 | 环保部行业目录 |
| `site_id` | 监测站 ID（聚类变量） | 159 站 |
| `tfpop_s` | Olley–Pakes TFP（企业层 2000–07 均值） | "上游污染"作为附加状态变量 |
| `resid1_*` | 吸收站点 FE + 行业 FE 后的残差 | OLS 残差 |
| `resid2_*` | 吸收站点×行业 FE 后的残差 | OLS 残差 |
| T2 `resid2_tfpop_s` | 吸收企业 FE、站点×年 FE、行业×年 FE | 面板 |

因此复现的边界是"给定残差化结果变量的 RD 估计"，TFP 估计与 FE 吸收步骤无法独立核验。

### 2. 基准 RD（表 I、III–VII 的全部 159 个单元格）

$$
\hat\tau(h)=\hat\mu_+(0)-\hat\mu_-(0),\qquad
\hat\mu_\pm=\arg\min_{\beta}\sum_i \mathbf 1\{\pm x_i\ge0\}K\!\left(\tfrac{x_i}{h}\right)(y_i-\beta_0-\beta_1x_i)^2
$$

- p = 1，q = 2（偏误估计），核 ∈ {三角, Epanechnikov, 均匀}
- h：`mserd`（左右共同 MSE 最优带宽），**`masspoints(off)`**（不做质点调整）
- 方差：`vce(cluster site_id)`，CR1 型聚类夹心（rdrobust 的 $\frac{n-1}{n-k}\frac{G}{G-1}$ 调整）
- 报告：`e(tau_cl)` 与 `e(se_tau_cl)`（**常规估计 + 常规聚类 SE**），不是 CCT 稳健偏误校正推断
- 例外：表 III 第 4–6 列（2003 年前）印的是 `tau_bc`（偏误校正点估计）配常规 SE

驱动变量质点严重：污染行业 6,224 个观测只有 787 个不同距离值 → `masspoints(off)` 与默认 `adjust` 的带宽差别很大（表 I Panel A 第 1 列 h = 4.203 vs 3.753，估计 0.343 vs 0.229）。**这是 StatsPAI 原生结果与论文不一致的根本原因。**

### 3. 断点中的差分（表 II）

`mdrd y x, time(post03) all kernel(k)`：在同一带宽 (h, b) 下分别估计 post03 = 1 与 post03 = 0 的 RD，取差；带宽由 `ddbwsel` 对"差分估计量"整体做 CCT 选择；报告偏误校正系数与常规 SE。

等价分解（本项目验证）：
$$
\hat\alpha_2=\hat\tau_{post}(h,b)-\hat\tau_{pre}(h,b),\qquad \widehat{se}\approx\sqrt{V_{post}+V_{pre}}
$$
用 mdrd 选出的 (h, b)，StatsPAI 两次 `rdrobust` 相减得到的常规和偏误校正估计与 mdrd **4 位小数完全一致**；SE 差 < 0.001（mdrd 没有聚类，且对两期用联合方差）。

### 4. 成本核算（表 VIII）

表格逻辑（从 `8_Cost_Estimates.xlsx` 反推）：

$$
\text{MRS}_{1\%}=\frac{1-e^{-\beta_{TFP}}}{1-e^{-\beta_{COD}}}\Big/157.4,\qquad
\text{VA loss}_t=VA^{poll}_t\left(\frac{1}{1-\text{MRS}_{1\%}\cdot 100\cdot \Delta COD_t}-1\right)
$$

$\beta_{TFP}$ 取表 I Panel B（或表 II），$\beta_{COD}$ 取表 V Panel A，均为论文四舍五入后的两位小数；常数 1.574 在六列中**完全相同**（反推验证了公式），其含义（ASIF/ESR 抽样口径换算）在 Online Appendix F，复现包未给出。Panel B 为 2001–2007 实际 COD 减排路径的累计增加值损失；Panel C 以 2015 为基年，每年减排 2%、五年 10%，"年均损失" = 五年合计 / 5。Python 重算与 Excel 和论文六列全部一致。

---

## 二、复现结果概览

详见 `Results/comparison.md`（逐单元格：论文 | 原始 Stata | StatsPAI 匹配带宽 | StatsPAI 原生带宽）。

| 表 | 单元格 | ✅ | ⚠️ | ❌ | StatsPAI(匹配带宽) = Stata |
|---|---|---|---|---|---|
| I | 18 | 18 | 0 | 0 | 100% |
| II | 6 | 1 | 5 | 0 | 100%（点估计） |
| III | 42 | 42 | 0 | 0 | 100% |
| IV | 12 | 12 | 0 | 0 | 100% |
| V | 24 | 16 | 5 | 3 | 100% |
| VI | 27 | 23 | 3 | 1 | 100% |
| VII | 36 | 30 | 2 | 4 | 100% |
| VIII | 6 | 6 | 0 | 0 | Python 重放 |
| 合计 | 171 | 148 | 15 | 8 | |

原始代码总运行时间 2,219 s（表 II 的 6 次 `mdrd` 占 2,132 s）。

### 差异逐条解释

1. **表 V 均匀核列**：代码为默认 `mserd`，论文数字对应 `bwselect(msecomb1)`（COD 0.734 (0.353)、COD 强度 0.844 (0.328)、废水强度 0.556 (0.258) 均精确命中）；SO2/NOx 对应 `mserd`；NH3-N 与 NH3-N 强度两格在 {mserd, msetwo, msesum, msecomb1, msecomb2, cerrd, certwo} × {masspoints off, adjust} 的 14 种组合中均无法命中 → ❌。废水强度第 2 列 0.40 vs 0.38（差 0.02）→ ❌（边界）。
2. **表 VI Panel A**：代码为 `certwo`，第 1、2 列与 `mserd` 精确一致（−0.913 (0.443)、−1.124 (0.454)），第 3 列与 `certwo` 一致 → 论文列混用了两个版本的代码。
3. **表 VI Panel C 非污染×自动站**：第 6 列代码为 `bwselect(msecomb1)` 且漏写 `masspoints(off)` → −0.54 (1.61)，论文 −0.43 (0.32)，网格无法命中 → ❌；第 5 列系数一致、SE 0.71 vs 0.76 → ⚠️。
4. **表 VII**：SOE 污染（N = 513）第 1 列 −0.13 (0.42) vs −0.11 (0.44)、第 3 列 0.62 (0.41) vs −0.01 (0.61)；南水北调非污染第 5–6 列 → ❌。Panel C 代码核函数顺序 `epa tri uni`，论文列标为 Triangle/Epanech./Uniform，数字与代码顺序一致（标签错置）。
5. **表 II**：存档 mdrd（2017）带宽 6.39/5.69/5.35 与 6.33/6.44/6.42，论文印 10.39/10.20/9.89 与 8.96/8.87/9.17；系数与 SE 仍在 ±0.01 内。作者 T2 压缩包日期为 2020-09，应使用了更新的 `mdrd`/`ddbwsel`（其带宽选择改动过）。论文脚注称"报告局部二次估计"，但代码未设 `p(2)`，与正文表注"局部线性"矛盾。
6. **不可复现单元格的共同点**：都是小样本子集（N ≤ 1,815）、质点比例高，估计对带宽高度敏感；rdrobust 在 2020 年（作者代码已使用 `masspoints` 选项）至 10.0.0（2025）之间对带宽选择器的方差/正则项实现有过多次修订，论文所用的具体版本未记录，这是最可能的来源（无法在本机验证旧版本）。

---

## 三、StatsPAI 复现实现细节

脚本：`Program/statspai/replicate_statspai.py`（全部运行约 1 分钟）。

| 论文/Stata | StatsPAI 调用 | 结果 |
|---|---|---|
| `rdrobust …, masspoints(off) kernel(k) all vce(cluster site_id)` | `sp.rdrobust(df, y, x='distance_new', kernel=k, cluster='site_id', h=h, b=b)`，h、b 取自 `rdrobust.rdbwselect(…, masspoints='off')`（Python 官方移植版） | 常规估计与 SE 与 Stata 相对误差 ≤ 3e-6（来自带宽舍入） |
| 同上，原生带宽 | `sp.rdrobust(…, bwselect=…, cluster='site_id')` | 带宽 = Stata 默认 `masspoints(adjust)`，与论文不同 |
| `rdplot … p(3) kernel(uni) nbins(7 7) ci(90)` | `sp.rdplot(p=3, kernel='uniform', nbins=7, ci_level=0.90)` | 图形一致（`Results/statspai/figure4_rdplot.png`） |
| `mdrd …, time(post03) all` | 两次 `sp.rdrobust`（mdrd 带宽）相减 | 点估计 4 位小数一致 |
| Excel 成本 | pandas 重放 + StatsPAI 未舍入系数 | 与论文一致；StatsPAI 输入版本差异 ≤ 2% |

---

## 四、StatsPAI 问题清单（bug / API 摩擦，含最小复现）

### Bug 1：`cluster=` 与缺失 y 同时出现时崩溃（严重）

```python
import pandas as pd, statspai as sp
d = pd.read_stata("T1_Baseline/tfp_small_QJE_final.dta"); p = d[d.neg_ind0 == 1]   # tfpop_s 有 87 个缺失
sp.rdrobust(p, y="tfpop_s", x="distance_new", cluster="site_id")
# IndexError: boolean index did not match indexed array along axis 0;
#   size of axis is 6311 but size of corresponding boolean axis is 6224
#   (statspai/rd/rdrobust.py:2086, _rd_estimate: cluster_vals[left])
```
原因：`rdrobust()` 对 Y/X 做了缺失剔除，但 `cl_vals_all = data[cluster].values`（rdrobust.py 第 690 行）未同步使用同一掩码。**修复建议**：在构造 `X_c`/`Y` 的同一掩码上切片 cluster（以及 weights、covs）。临时绕过：先 `dropna(subset=[y, x, cluster])`。

### Bug 2：`h`/`b` 类型标注允许元组，但校验拒绝

```python
sp.rdrobust(q, y="tfpop_s", x="distance_new", h=(4.2, 4.5), b=(6.3, 6.6))
# MethodIncompatibility: `h` must be a finite number.   (rdrobust.py:541 _require_positive_float)
```
签名 `h: Union[float, Tuple[float, float], None]`，下游 `_rd_estimate`（2075 行）也支持元组，但入口校验调用 `float(tuple)`。导致 `msetwo/certwo/msecomb2` 等非对称带宽无法手工复用。脚本中对 `_require_positive_float` 打了逐元素校验补丁。**修复建议**：校验函数识别长度为 2 的序列。

### Bug 3（API 设计）：无法关闭质点调整

`sp.rdrobust` / `sp.rdbwselect` 没有 `masspoints` 参数，带宽选择总是按 Stata/R 默认 `masspoints="adjust"` 处理。任何用 `masspoints(off)` 的已发表论文（本文全部 159 个单元格）都无法用 StatsPAI 原生带宽复现：表 I Panel A 第 1 列 StatsPAI h = 3.753、估计 0.229；论文 h = 4.203、估计 0.343。**建议**：增加 `masspoints={'adjust','check','off'}`，与 rdrobust ≥ 8 对齐；`model_info` 中记录所用设置。

### Bug 4（命名遮蔽）：`statspai.rd.rdrobust` 子模块被同名函数遮蔽

```python
import statspai.rd.rdrobust as m   # m 是函数，不是模块
m._require_positive_float           # AttributeError: 'function' object has no attribute ...
```
`statspai/rd/__init__.py` 用 `from .rdrobust import rdrobust` 把子模块属性覆盖为函数，`import a.b.c as m` 走属性查找拿到函数。需 `sys.modules["statspai.rd.rdrobust"]`。**建议**：子模块改名（如 `_rdrobust_impl.py`）。

### 缺口 5：RD 周边工具不支持聚类

`sp.rd_honest`、`sp.rdbwsensitivity`、`sp.rdplacebo`、`sp.rdplot` 均无 `cluster` 参数。本文所有推断都是站点聚类的，所以带宽敏感性只能手写循环调用 `sp.rdrobust(h=…, cluster=…)`；honest CI 只能给出未聚类版本（偏窄）。`sp.rd_robustness_table` 支持 `cluster`，但同样无 `masspoints`。

### 缺口 6：没有断点中的差分估计量

无 Grembi–Nannicini–Troiano / `mdrd` 式 difference-in-discontinuities（含对差分整体的带宽选择）。本项目用"同带宽两次 RD 相减"近似，点估计精确一致，但带宽只能借用 mdrd、SE 需手工合成且忽略两期协方差。**建议**：`sp.rd_diff_in_disc(y, x, time=…, cluster=…)`，带宽对差分估计量的 MSE 选择。

### 小问题

- 官方 Python rdrobust（参照实现）在 T7 南水北调非污染均匀核一格 `rdbwselect(cluster=…)` 抛 `ZeroDivisionError`（某侧偏误回归只剩 1 个聚类，`g/(g-1)`），Stata 能算出结果 —— 这是 rdpackages Python 版的问题，已回退到 Stata `e(h,b)`；StatsPAI 在该格的偏误校正估计 0.0749 与 Stata 0.0807 不同（单聚类侧的方差/偏误处理差异），常规估计一致。
- `sp.rdrobust(...).model_info['bandwidth_h']` 对称时返回 float、非对称时返回 tuple，下游代码需分支处理。
- 稳健（RBC）SE 与 Stata 在第 4 位小数不同（0.70282 vs 0.70245），常规 SE 完全一致 —— 疑为偏误项方差中聚类小样本调整的自由度不同，建议对照 rdrobust 10.0.0 的 `rdrobust_vce` 复核。

---

## 五、改进建议（面向 StatsPAI）

1. `masspoints` 参数（最高优先级；影响所有质点驱动变量的已发表 RD 复现）。
2. 修复 cluster 掩码（Bug 1）与元组带宽校验（Bug 2），并加回归测试：含缺失值 + 聚类、非对称手工带宽。
3. RD 周边工具（`rd_honest`、`rdbwsensitivity`、`rdplacebo`）统一支持 `cluster`；`rd_honest` 可接受聚类方差（Armstrong–Kolesár 允许一般方差估计）。
4. 新增 difference-in-discontinuities 估计量。
5. `rdrobust` 结果对象加 `to_stata_e()`：直接输出 `tau_cl/se_tau_cl/tau_bc/se_tau_rb/h_l/h_r/b_l/b_r/N_h_l/N_h_r`，便于与 Stata 逐格对照。
6. 文档中明确"默认带宽 = Stata 默认 `masspoints(adjust)`"，并在检测到大量质点时的警告里提示该选择对结果的影响。
