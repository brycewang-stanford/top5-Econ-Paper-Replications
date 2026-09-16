# Data — 原始数据

来源：Harvard Dataverse **doi:10.7910/DVN/JX1OIU** — *Replication Data for: "Kinship, Cooperation, and the Evolution of Moral Systems"* (Enke 2019, QJE)，发布于 2018-12-26，许可 **CC0 1.0**。

数据集只有一个文件 `data_programs.zip`（Dataverse file id 3335940，2,906,863 bytes，MD5 `e6cbc18b5c4def390b5691177be2f45c`，解压后约 25 MB）。压缩包内结构为 `data_programs/Data/*.dta` + `data_programs/do-files/`；本项目把 `.dta` 放在本文件夹，do-files 放在 [`Program/do-files/`](../Program/do-files)（未改动）。解压并核对完整后删除了 zip。

| 文件 | 大小 | 观测单位 | 用于 |
|---|---|---|---|
| `EAShort.dta` | 0.8 MB | 1,246 个 Ethnographic Atlas 民族（kinship index、道德/宗教/制度变量、病原体生态） | Table III, IV, XI；Figure I–IV |
| `EA_contiguous.dta` | 1.6 MB | 11,058 个同国民族配对（`match` = 配对 FE，`geodist` = 质心距离） | Table V |
| `CountryData.dta` | 0.5 MB | 216 个国家（按祖先人口迁移矩阵加权的 kinship、WVS/GPS/MFQ/ISEAR 国家均值、HYDE 人口密度与城市化 1500–1950） | Table VI–VII（1–4 列）、IX、X（1–3 列）；Figure V, VI, VIII, IX |
| `WVS_EA_Ind.dta` | 10 MB | 35,363 名 WVS 受访者（按民族匹配 EA kinship） | Table VI–VII（5–8 列） |
| `MFQ_Ind.dta` | 10.6 MB | 28,433 名 MFQ 移民（原籍国 kinship） | Table VIII；Figure VII |
| `ISEAR_ind.dta` | 0.8 MB | 2,626 名 ISEAR 受访者 | Table IX（1–6 列） |
| `GTrends.dta` | 0.4 MB | 85 个国家×语言 Google Trends 观测 | Table IX（7–8 列） |

**不包含的数据**：Table X 第 4–6 列需要个人层面 GPS 数据中的出生国信息，受 Gallup World Poll 许可限制不能公开（见 `Program/do-files/Country/Tables_6_7_9_10.do` 注释）。

## 重新下载

```bash
cd Data
curl -L -o data_programs.zip "https://dataverse.harvard.edu/api/access/datafile/3335940"
md5 data_programs.zip        # e6cbc18b5c4def390b5691177be2f45c
unzip -q data_programs.zip
mv data_programs/Data/*.dta .
# do-files are already tracked in Program/do-files/ (identical to data_programs/do-files/)
rm -rf data_programs data_programs.zip
```

> 本文件夹内容已在 `.gitignore` 中排除（仅保留本说明和 `.gitkeep`）。
