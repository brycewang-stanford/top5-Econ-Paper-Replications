# Data — 原始数据

来源：Harvard Dataverse 复现包 **doi:10.7910/DVN/0H4HG2**（Bai, Jia & Yang 2023, *QJE* 138(2): 1067–1108, "Web of Power"），许可 **CC0 1.0**。
复现包原始目录为 `Replication/Data/`；本文件夹即该目录（9 个 Stata 数据集，原始 `.dta`，Stata 14 格式，合计约 94 MB）。

| 文件 | 大小 | 层级 | 用于 |
|---|---:|---|---|
| `HunanCntyYr.dta` | 0.28 MB | 湖南 75 县 × 1850–1864 | Table 1A–4, Figure 3–4, 附录 B |
| `HunanSurname.dta` | 32 MB | 湖南 县×姓氏×年（405,000 行） | Table 3 (5)–(7) |
| `HunanBattleField.dta` | 5.5 MB | 县×战役 | 附录 Table B6.I (4)–(5) |
| `ThreeRivers.dta` | 0.03 MB | 1858 三河之役 | 附录 Table B6.II |
| `HuaiYr.dta` | 0.25 MB | 淮军地区 县×年 | Table 4 (7)–(11) |
| `NationalCntyYr.dta` | 53 MB | 全国 1,646 县 × 1800–1910 | Table 1B, 5, 6, Figure 5–6, 附录 C |
| `EG_Index.dta` | 6.8 MB | 省×年 | Figure 7, Table C7 |
| `OfficialYear.dta` | 0.01 MB | 年度时间序列 | Figure A5 |
| `ProvGovernors.dta` | 0.02 MB | 省级 | Figure 8 |

> 本文件夹内容已在 `.gitignore` 中排除（仅保留本说明），换机器时需重新下载。

## 重新下载（必须取 ORIGINAL .dta，Dataverse 默认给的是 .tab 归档格式）

```bash
cd Data
# 文件 id 来自 https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/0H4HG2
for pair in 6573760:EG_Index 6573677:HuaiYr 6573637:HunanBattleField 6573718:HunanCntyYr \
            6573748:HunanSurname 6573737:NationalCntyYr 6573696:OfficialYear 6573759:ProvGovernors \
            6573667:ThreeRivers; do
  id=${pair%%:*}; name=${pair#*:}
  curl -L -o "$name.dta" "https://dataverse.harvard.edu/api/access/datafile/$id?format=original"
done
```

整个复现包（134 个文件，含作者代码与输出）：

```bash
curl -L -o pkg.zip "https://dataverse.harvard.edu/api/access/dataset/:persistentId/?persistentId=doi:10.7910/DVN/0H4HG2"
```

作者输出（`.txt/.doc/.gph/.png`、parmest `.dta`、`All_in_One.log`）放在 `Results/author_outputs/`；作者代码放在 `Program/`；包内 README（PDF/DOCX，含变量字典）放在 `Materials/`。
