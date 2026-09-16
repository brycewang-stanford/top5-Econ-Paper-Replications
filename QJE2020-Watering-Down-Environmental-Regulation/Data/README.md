# Data — 原始数据

来源：Harvard Dataverse, *The Quarterly Journal of Economics* Dataverse
**"Replication Data for: 'Watering Down Environmental Regulation in China'"**, doi:[10.7910/DVN/LVS8VX](https://doi.org/10.7910/DVN/LVS8VX)（版本 3，许可 CC0 1.0）。

| 文件 | 大小 | MD5 |
|---|---|---|
| `0_ReadMe.pdf` | 89,779 B | 0afcc7020282e4cd8c8a2ab6ff5c0f5a |
| `Replication Materials.zip` | 3,336,561 B | 3df7666ed4c37d8ee40443356ecae7f7 |

解压后约 16 MB。数据为作者去标识化后的 ASIF（中国工业企业数据库）与 ESR（环境统计调查）分析抽取，足以复现论文全部结果；原始带企业标识的数据需向国家统计局 / 生态环境部申请。

```text
Data/
├── pkg.zip                         Dataverse 整包下载（0_ReadMe.pdf + Replication Materials.zip）
├── 0_ReadMe.pdf
├── Replication Materials.zip
└── Replication Materials/          每个图表一个子文件夹（作者原始结构，已解压）
    ├── F4_RD/        tfp_small_QJE_final.dta                     (Figure IV)
    ├── F5_Trend/     graph_by_year.dta                           (Figure V)
    ├── T1_Baseline/  tfp_small_QJE_final.dta, rdrobust_senate.dta (Table I)
    ├── T2_MDRD/      T2_MDRD.dta                                 (Table II)
    ├── T3_Channels/  channels_QJE_final.dta, channels_Pre_QJE_final.dta (Table III)
    ├── T4_Abatement/ abatement_QJE_final.dta                     (Table IV)
    ├── T5_Emissions/ water_emission_QJE_final.dta, air_emission_QJE_final.dta (Table V)
    ├── T6_PE/        pwf_QJE_final.dta, PE_QJE_final.dta, auto_QJE_final.dta (Table VI)
    ├── T7_Burden/    soe_vs_private_QJE_final.dta, big_vs_small_QJE_final.dta, NSBD_QJE_final.dta (Table VII)
    └── T8_Cost_Estimates/ 8_Cost_Estimates.xlsx                  (Table VIII)
```

所有 `.dta` 均为最终分析样本：TFP 与各结果变量已由作者预先残差化（`resid1_*` = 吸收站点 FE + 行业 FE；`resid2_*` = 站点×行业 FE；Table II 为企业 FE + 站点×年 FE + 行业×年 FE），因此无法（也无需）从原始数据重建。

## 重新下载

```bash
cd Data
curl -L -o pkg.zip "https://dataverse.harvard.edu/api/access/dataset/:persistentId/?persistentId=doi:10.7910/DVN/LVS8VX"
unzip -o pkg.zip && unzip -o "Replication Materials.zip"
cd "Replication Materials" && for z in *.zip; do unzip -oq "$z" -d "${z%.zip}"; done
```

（数据集中没有 `.tab` 表格文件，因此不需要 `?format=original`。）

> 本文件夹内容已在 `.gitignore` 中排除，不会提交到 git（仅保留本说明）。作者代码的副本位于 `Program/`。
