# 《The China Syndrome》模型解读与 StatsPAI 复现分析

> **论文**：Autor, David H., David Dorn, and Gordon H. Hanson (2013). "The China Syndrome: Local Labor Market Effects of Import Competition in the United States." *AER* 103(6): 2121–2168. DOI: [10.1257/aer.103.6.2121](https://doi.org/10.1257/aer.103.6.2121)
> **复现包**：ddorn.net 公开文件包 Autor-Dorn-Hanson-ChinaSyndrome-FileArchive（2013-01-09；openICPSR E112670 需登录）
> **环境**：Stata 18 MP；Python 3.13 + statspai 1.28.0（pyfixest 0.50.1 后端）；R + ShiftShareSE 1.1.0（仅作参考）

---

## 1. 模型逐方程拆解

### 1.1 理论动机（式 1–2）
CZ $i$ 的劳动需求变化分解为各行业产出需求变化按就业份额加权：
$$\Delta L_{it}\;\propto\;\sum_j \frac{L_{ijt}}{L_{ujt}}\,\frac{\Delta X_{cjt}}{L_{it}}$$
即"中国对行业 $j$ 的出口增量按 CZ 在全国该行业就业中所占份额分摊，再除以 CZ 总就业"。这是 shift-share 结构的来源：**份额** $L_{ijt}/L_{ujt}$（CZ 层面）× **冲击** $\Delta M_{cjt}$（行业层面）。

### 1.2 暴露度与工具变量（式 3–4）
| | 份额年份 | 冲击 | 分母 | 变量名 |
|---|---|---|---|---|
| 内生暴露 $\Delta IPW_{uit}$ | $t$（1990/2000） | 美国自中国进口 $\Delta M_{ucjt}$ | $L_{it}$ | `d_tradeusch_pw` |
| 工具 $\Delta IPW_{oit}$ | $t-1$（1980/1990） | 8 个高收入国家自中国进口 $\Delta M_{ocjt}$ | $L_{i,t-1}$ | `d_tradeotch_pw_lag` |

注意 BHJ 复现包中的冲击 $g_{jt}=\Delta M_{ocjt}/L_{uj,t-1}$，份额 $s_{ijt}=L_{ij,t-1}/L_{i,t-1}$（只含制造业，行和 = 期初制造业份额 <1）。本项目验证 $\sum_j s_{ijt}g_{jt}$ 与 `d_tradeotch_pw_lag` 最大差 5.9e-6。

### 1.3 主回归（式 5）
$$\Delta L^m_{it}=\gamma_t+\beta_1\Delta IPW_{uit}+X_{it}'\beta_2+e_{it},\qquad i=1..722,\;t\in\{1990,2000\}$$
- 堆叠两期一阶差分，$\gamma_t$ = 常数 + `t2`；
- $X_{it}$（表 3 列 6）：期初制造业就业份额、大学学历人口比例、外国出生比例、女性就业率、常规职业就业份额、离岸外包指数、8 个人口普查大区虚拟变量；
- 权重 `timepwt48` = 期初 CZ 人口占全国份额（每期和为 1）；
- `ivregress 2sls …, cluster(statefip)`，48 个州聚类。

### 1.4 其它方程
| 表 | 被解释变量 | 设定变化 |
|---|---|---|
| 表 2 | 制造业就业/人口 | 分期估计；列 4–6 用 1970s/1980s 结果对"未来暴露"（两期平均）做证伪 |
| 表 4 | log 劳动年龄人口（按教育/年龄） | panel A 仅 t2，B 加大区，C 全控制 |
| 表 5 | log 人数、人口份额：制造业就业/非制造业就业/失业/NILF/SSDI | 全控制 |
| 表 6–7 | 平均 log 周工资（性别×教育；制造/非制造） | 全控制 |
| 表 8 | 人均转移支付（log、美元） | 全控制 |
| 表 9 | 劳动年龄成人家庭人均收入（% 变化、美元） | 全控制 |
| 表 10 | 6 个核心结果 | B：含第三国市场的暴露；C：扣除中间投入（双工具）；D：净进口（进口、出口双工具）；E：引力残差 OLS 简约式；F：要素含量（双工具） |
| 附表 3 | 1990s 制造业变化 | 2000s 暴露增长最快的四分位 CZ（N=180）vs 全部 |
| 附表 4 | 制造业就业/人口 | 不同出口国组合的 OLS 与 2SLS |

---

## 2. 原始代码复现

- 5 个 do 文件全部 rc=0，总耗时约 20 秒（`Results/log/run_original_steps.txt`）。唯一改动：相对路径。
- **16 个 esttab 表（.scsv）与作者 2013 年随包提供的日志逐字节相同**。
- 包内 `Table 1` 第 5 列（"其余国家进口"）并未由 `import_stats_final.do` 生成：该 do 文件汇总的 `l_totimp_ushi_*` 为 905.8/1865.5/2365.9（十亿美元），与发表值 322.4/650.0/763.1 不符。发表值 = `sic87dd_trade_data.dta` 中 CAN+ROW 的进口（B 组再加 USA），StatsPAI 版本据此精确复现。
- 与发表表格不一致、但与作者 2013 日志一致的格子：表 10 panel B（含第三国市场暴露）6 格，附表 4 第 5 列（"其他所有出口国"）4 格 → 文件包的变量版本与论文排版时不同，公开数据无法修复。

---

## 3. StatsPAI 复现细节

### 3.1 估计量映射（关键：标准误的小样本因子）

| Stata | StatsPAI（精确一致） |
|---|---|
| `ivregress 2sls y (x=z) X [aw=w], cluster(statefip)` | `sp.feols("y ~ X \| x ~ z", data, weights="timepwt48", vcov={"CRV1":"statefip"}, ssc=pf.ssc(adj=False, cluster_adj=False))` |
| `regress y x X [aw=w], cluster(statefip)` | `sp.feols("y ~ x + X", data, weights=…, vcov={"CRV1":"statefip"})`（默认 ssc） |
| `ivreg2 …, cluster()` 的 KP rk Wald F / weakivtest $F_{eff}$ | 第一阶段 `sp.feols(..., vcov CRV1, 默认 ssc)` 的 $t^2$（单工具时二者相等，误差 1e-6） |

发现：**Stata `ivregress` 不加 `small` 时聚类方差不乘任何有限样本因子**；pyfixest 默认 $G/(G-1)\cdot(N-1)/(N-K)$ 会让 SE 大 1.1%（列 1：0.0688 vs 0.0680）到 1.6%（列 6：0.1004 vs 0.0988），在 3 位小数下足以造成"不一致"。

### 3.2 结果
- 381 个发表格子：**360 ✅、11 ⚠️、10 ❌**；与 Stata 日志匹配的 165 个回归系数，最大 |Δb| = 6.3e-5、|ΔSE| = 4.6e-5（受 Stata 7 位有效数字打印限制）。
- ⚠️ 全部是论文"两步舍入"（先 esttab 3 位，再手工 2 位：0.3447→0.345→0.35）或表 10 注释中第一阶段 SE 类型混用；❌ 全部是 §2 所述文件包版本问题（Stata 同样不一致）。
- **新发现：发表的第一阶段 SE（表 3 panel II、附表 4）是 HC1 异方差稳健 SE，而非表注所说的州聚类 SE**：HC1 = 0.0787/0.0864/0.0870 → 0.079/0.086/0.087，与发表值完全一致；作者自己 `ivregress …, first` 打印的聚类 SE 是 0.0802/0.0891/0.0914。
- 图 2 AV 图：0.82 (0.09, t=8.88)、−0.34 (0.07, t=−4.77) 精确复现；论文图中标注"robust SE"实为州聚类 SE。
- 附表 1 加权分位数需按 Stata `summarize, detail [aw]` 规则实现（`common.stata_wpctile`），附表 3 的四分位阈值需用 `_pctile` 默认定义（`common.stata_pctile`），否则 N≠180。

### 3.3 现代方法扩展（均有外部参考值，详见 `Results/statspai/modern_extensions.md`）

| 方法 | 结果（表 3 列 6） | 参考 | 一致性 |
|---|---|---|---|
| Olea–Pflueger 有效 F | 47.64（列 1：97.54） | Stata `weakivtest` | 6e-8 |
| AR 95% CI，score 形式（原假设下残差估计聚类方差） | [−0.827, −0.3875] | Stata `weakiv`（同网格 0.0015） | 完全相同 |
| AR 95% CI，Wald 形式（`sp.feols` 简约式 t²） | [−0.854, −0.434] | — | 两种形式定义不同，weakiv 采用 score 形式 |
| WRE 野聚类自举 | Stata：CI [−0.796, −0.326]，p<1e-4 | `boottest` 9999 次 | StatsPAI CI 不同（见 bug 5） |
| AKM SE（SIC3 冲击聚类） / AKM0 CI | 0.1265 / [−1.018, −0.362] | R ShiftShareSE；BHJ 表 C2 | 1e-9 |
| BHJ 冲击层面 IV | −0.596 (0.114)，F=185.6 | BHJ 表 4 列 1 | 3 位小数完全一致 |
| GPSS Rotemberg 权重 | 计算机 0.183、玩具 0.138、音像 0.085、电话 0.066、外设 0.060；负权重和 −0.067；2000 期 0.983 | GPSS `rotemberg_summary_adh.tex` | 3 位小数完全一致 |

注：Rotemberg 与 AKM 用的是 Python 端移植（`modern_extensions.py` 中的 `akm()` 逐行移植 `ShiftShareSE::ivreg_ss.fit`），因为 StatsPAI 内置函数不支持权重且 AKM 实现有误（见 §5）。

---

## 4. 复现差距（gaps）

1. `sp.iv` / `sp.ivreg` 无分析权重（aweights）参数，AER 常见的人口加权 IV 无法直接做。
2. `sp.iv` 聚类 SE 的小样本因子不可关闭，无法匹配 `ivregress`（默认无因子）。目前只能走 `sp.feols`（pyfixest）的 `ssc=` 参数。
3. `sp.effective_f_test`、`sp.iv_diag`、`sp.weakrobust`、`sp.anderson_rubin_ci` 均无权重；`sp.anderson_rubin_ci`、`sp.weakrobust` 还无聚类。在 √w 变换数据上调用会被函数自动加入的截距污染（有效 F 47.88 vs 47.64）。
4. `sp.bartik` / `sp.BartikIV`：无权重、无聚类（只有 HC1）、期别特定份额需手工展开为 unit×(period×industry) 宽矩阵；Rotemberg 权重没有 $\hat\beta_k$、$F_k$、按行业跨期加总、负权重汇总等 GPSS 标准输出；内部构造 n×n 投影矩阵（O(n²) 内存）。
5. 无 BHJ 意义上的 "shock-level aggregation"（把 CZ 层面回归转换为行业层面等价回归）工具，只能使用 BHJ 预先生成的 `industry_level.dta`。
6. 无 AKM0（原假设施加的）置信区间、无冲击聚类（sector_cvar）、无共线份额自动剔除。

---

## 5. StatsPAI bug 清单（含最小复现）

以下 `d = pd.read_stata("Data/dta/workfile_china.dta")`，`FULL` 为表 3 列 6 控制变量。

**Bug 1 — `sp.iv(..., weights=)` 被静默忽略**
```python
sp.iv("d_sh_empl_mfg ~ (d_tradeusch_pw ~ d_tradeotch_pw_lag) + t2", data=d, cluster="statefip", weights="timepwt48")
# -> -0.6216 (0.1649) = 未加权结果；正确（Stata）为 -0.7460 (0.0680)。无任何警告。
```
原因：`ivreg()` 的 `reject_unknown_kwargs(known=("method","alpha","weights","small","iv_diag"))` 把 `weights` 视为已知参数放行，但 `IVRegression.fit(**kwargs)` 从未使用它；`weights` 只被写入 provenance。建议：实现 WLS-2SLS，或至少对未使用的 `weights`/`small` 抛出 `MethodIncompatibility`。

**Bug 2 — `sp.ssaggregate` 的 AKM 标准误错误**（该函数名取自 BHJ 的 Stata 命令，实现的却是 AKM）
```python
sp.ssaggregate(dfu, y="y", x="x", shares=S, shocks=g, controls=ctrl)   # BHJ 份额 S(1444×794)、冲击 g、未加权
# SE(AKM) = 0.0182；R ShiftShareSE::ivreg_ss(..., method="akm") = 0.1103（β 均为 -0.3028）
```
原因：代码用 $u_k=\sum_i s_{ik}\tilde Z_i\hat\varepsilon_i$、分母 $(\hat\gamma\tilde Z'\tilde X)^2$；AKM (2019, Prop. 4) 应为 $u_k=\hat{\tilde g}_k\sum_i s_{ik}\hat\varepsilon_i$，其中 $\hat{\tilde g}$ 是残差化工具对份额矩阵回归的系数，分母 $(\tilde Z'\tilde X)^2$。建议直接移植 `ShiftShareSE::ivreg_ss.fit`（本项目 `akm()` 函数已验证到 1e-9），并加入权重、sector_cvar、AKM0、共线份额剔除（R 用 `qr()` 默认 tol=1e-7）。

**Bug 3 — `sp.shift_share_se` 用"拟合值去均值"代替工具变量**
```python
res = sp.BartikIV(dfu, y="y", endog="x", shares=S, shocks=g, covariates=ctrl, leave_one_out=False).fit()
sp.shift_share_se(res, shares=S.values).diagnostics["SE (AKM)"]    # 0.0076，正确值 0.1103
```
原因：`Z_tilde = fitted - mean(fitted)`（结果方程拟合值），分母 `Z_tilde'Z_tilde`。该函数拿不到工具变量和控制变量，无法正确计算，建议弃用或要求传入 `instrument`/`controls`。

**Bug 4 — `sp.BartikIV` 的 HC1 SE 与构造** — 未加权 β 正确（1e-9），SE 为 HC1（0.0907，R EHW 无自由度调整 0.0902）；`leave_one_out=True` 默认值在缺少 `regional_shocks` 时退回普通 Bartik 并只发警告，默认值应改为 `False`。

**Bug 5 — `sp.ivreg(vce="wild")` 的置信区间不是检验反演**
```python
sp.ivreg("d_sh_empl_mfg ~ (d_tradeusch_pw ~ d_tradeotch_pw_lag) + " + "+".join(FULL), data=d, cluster="statefip",
         vce="wild", wild_reps=9999, seed=20130601)
# CI [-0.496, -0.078], p = 0.0027；Stata boottest（同一未加权模型）CI [-0.580, -0.112], p = 0.0020
```
原因（`inference/iv_wild.py` L370–372）：在 $H_0:\beta=0$ 施加下生成 bootstrap-t，再以 $\hat\beta\pm t^*_{q}\,\widehat{se}$ 构造区间。施加原假设的 WRE 分布只对 $\beta_0=0$ 有效，区间应通过对 $\beta_0$ 网格反演检验得到（boottest 做法）。p 值基本可比。

**API 摩擦**
- `sp.feols` IV 每次都触发 `RuntimeWarning: predict() not supported for IV`，需手动过滤；
- `sp.iv(...).params` 在 √w 变换公式 `- 1` 下正常，但 `sp.effective_f_test(exog=...)` 不允许去掉截距（没有 `add_const=False`）；
- `sp.anderson_rubin_ci` 返回对象有 `.lower/.upper`，而 `sp.iv_diag` 返回 `.effective_F` 属性、`sp.effective_f_test` 返回 dict，接口不统一。

---

## 6. 对 StatsPAI 的改进建议（按优先级）

1. **P0**：修复 Bug 1–3；为所有 IV/弱工具/shift-share 函数加 `weights=`（aweights 语义）与 `cluster=`，并对不支持的关键字参数报错而非静默忽略。
2. **P0**：`sp.iv` 增加 `small=`/`ssc=` 选项，文档写清与 `ivregress`/`ivreg2`（不加 `small` 时系数 SE 无因子；注意 `ivreg2` 的 KP rk Wald F 仍含 $G/(G-1)(N-1)/(N-K)$ 因子）、`reghdfe` 的对应关系。
3. **P1**：新增 `sp.shift_share(..., method=["akm","akm0","bhj"])`：接受长表份额（unit×period×industry）与冲击（industry×period），实现 AKM/AKM0、BHJ shock-level 聚合（含 `ssaggregate` 的 controls 残差化与 `s_n` 权重）、冲击层面第一阶段 F 与平衡性检验。
4. **P1**：Rotemberg 输出对齐 GPSS：$\hat\alpha_k,\hat\beta_k,F_k$、按行业跨期加总、正负权重汇总、前 5 行业的弱工具稳健 CI；用残差化向量代替 n×n 投影矩阵。
5. **P2**：WRE 置信区间用检验反演；AR/CLR/K 同时提供 Wald 与 score（null-imposed）两种方差形式，并在输出中注明与 `weakiv` 对应的是哪一种。
