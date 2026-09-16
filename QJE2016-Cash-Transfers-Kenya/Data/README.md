# Data — 原始数据

来源：Harvard Dataverse 复现包 **doi:10.7910/DVN/M2GAZN**（Haushofer & Shapiro 2016, QJE 131(4)），
下载日期 2026-09-15，版本 = Dataverse latestVersion。数据许可见 Dataverse 页面（CC0 / Dataverse 默认条款）。

```text
Data/
├── UCT_FINAL_CLEAN.dta         9.8 MB  主分析文件（2,880 行 = 1,440 户 × 男/女受访者；123 个村）
├── UCT_MetalRoofHHs.dta        0.5 MB  铁皮屋顶户（OA §6.2, §12）
├── UCT_UNMATCHED.dta           9.8 MB  普查未匹配户（OA §5.3）
├── UCT_Village_Collapsed.dta   0.07 MB 村级价格/工资/犯罪（OA §19）
└── raw_download/               10 MB   Dataverse 原始 tar：Ado, Do, Erratum, Figs, Online Appendix, Paper, Tables
```

- 四个 `.dta` 在 Dataverse 上被转成了 `.tab`；这里下载的是 **原始 Stata 13 (release 117) 格式**（`?format=original`），
  作者的 `MASTER.do` 用 `datasignature confirm, strict` 校验，四个文件均通过（rc=0）。
- tar 包已解压到：`Program/Do`、`Program/Ado`（代码）、`Materials/Paper`、`Materials/Online Appendix`、
  `Materials/Erratum`、`Materials/package_outputs/{Tables,Figs}`（作者随包附带的输出，用作对照基准）。
- 本文件夹除本说明外均在 `.gitignore` 中排除。

## 重新下载（curl；Python urllib 在本机代理下有证书问题）

```bash
cd Data && mkdir -p raw_download && cd raw_download
# 非表格文件（tar）
for id in 3346775 3346783 3346780 3346776 3346779 3346778 3346782; do
  curl -sL -OJ "https://dataverse.harvard.edu/api/access/datafile/$id"; done
# 表格文件：必须取 original（.dta），否则得到 .tab
for id in 3346777 3346774 3346784 3346781; do
  curl -sL -OJ "https://dataverse.harvard.edu/api/access/datafile/$id?format=original"; done
mv UCT_*.dta ..
```

文件 id 对照（`https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/M2GAZN`）：

| id | file | bytes |
|---|---|---|
| 3346775 | Ado.tar | 732,672 |
| 3346783 | Do.tar | 189,440 |
| 3346780 | Erratum.tar | 1,045,504 |
| 3346776 | Figs.tar | 2,872,320 |
| 3346779 | Online Appendix.tar | 3,402,240 |
| 3346778 | Paper.tar | 1,799,680 |
| 3346782 | Tables.tar | 799,744 |
| 3346777 | UCT_FINAL_CLEAN.dta | 9,768,958 |
| 3346774 | UCT_MetalRoofHHs.dta | 489,561 |
| 3346784 | UCT_UNMATCHED.dta | 9,843,330 |
| 3346781 | UCT_Village_Collapsed.dta | 74,534 |

SHA-256 前缀：FINAL_CLEAN `a48302f11d3376e7`，MetalRoofHHs `b0ad2b8252f1b790`，UNMATCHED `9912b45b2c6e58b5`，
Village_Collapsed `4686c458aef3f821`。
