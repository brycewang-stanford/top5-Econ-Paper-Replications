# Data — 原始数据

来源：作者（David Dorn）个人网站公开发布的复现文件包 **Autor-Dorn-Hanson-ChinaSyndrome-FileArchive**
（<https://www.ddorn.net/data.htm> → "File Archives for Papers"），论文 DOI [10.1257/aer.103.6.2121](https://doi.org/10.1257/aer.103.6.2121)。

> AEA 官方 openICPSR 副本（项目 **E112670**）需要登录，本机无法访问；ddorn.net 文件包内容与之一致（作者 2013-01-09 发布，含 dta/do/log/gph/tab-fig）。
> 本文件夹内容已在 `.gitignore` 中排除，不上传 GitHub（仅保留本说明与 `.gitkeep`）。

```text
Data/
├── ads.zip          作者文件包原始 zip（2.95 MB，保留以便核对）
├── external/        第三方 shift-share 复现文件（见下文）
├── dta/             文件包 dta/ 子目录（作者原结构，2.9 MB）
│   ├── workfile_china.dta             722 CZ × 2 期（1990–2000, 2000–2007）主分析文件 → 表 3–10、附表 1–5
│   ├── workfile_china_preperiod.dta   722 CZ × 4 期（1970–2007）→ 表 2
│   ├── workfile_china_long.dta        722 CZ，1990–2007 长差分 → 图 2
│   ├── figure1_data.dta               1987–2007 时序 → 图 1
│   ├── import_levels.dta / export_levels.dta  → 表 1
│   └── sic87dd_trade_data.dta         397 个 sic87dd 行业 × 进口国(USA/OTH) × 出口国 × 1991–2007 贸易流
└── companion/       ddorn.net "Data" 页上的配套文件（30 MB），用于 shift-share 现代推断扩展
    ├── cbp_czone_merged.dta          CZ × sic87dd × 年 就业（CBP 插补后，1980–2011）→ 构造 1980/1990/2000 行业份额
    ├── cw_czone_state.dta / cw_czone_division.dta   CZ → 州 / 人口普查大区
    ├── cw_cty_czone.dta / cw_puma1990_czone.dta / cw_puma2000_czone.dta / cw_ctygrp1980_czone_corr.dta  县/PUMA/县组 → CZ 权重
    ├── cw_hs6_sic87dd.dta            HS6 → sic87dd 贸易品映射
    ├── china9114.dta                 1991–2014 更新版贸易流（ADH 后续论文）
    ├── sic87dd_exposure_9114.dta     行业层面进口额（2007 美元，Acemoglu et al. 2016）
    └── README for *.txt              作者对各文件的说明与引用要求
```

## 重新下载（精确命令）

```bash
cd Data
curl -L -o ads.zip https://www.ddorn.net/data/Autor-Dorn-Hanson-ChinaSyndrome-FileArchive.zip
unzip -q ads.zip
mkdir -p dta && cp Autor-Dorn-Hanson-ChinaSyndrome-FileArchive/dta/*.dta dta/

mkdir -p companion && cd companion
for f in cbp_czone_merged cw_czone_state cw_czone_division cw_cty_czone cw_puma1990_czone \
         cw_puma2000_czone cw_ctygrp1980_czone cw_hs6_sic87dd china9114 sic87dd_exposure_9114; do
  curl -L -o $f.zip https://www.ddorn.net/data/$f.zip && unzip -o -j -q $f.zip -x '__MACOSX/*' && rm $f.zip
done
```

## Data/external — 现代 shift-share 推断所需的第三方复现文件（均为公开 GitHub 仓库）

ADH 原始文件包不含 CZ×行业就业份额（作者 CBP 1980/1990/2000 份额未公开，ddorn.net 的 `cbp_czone_merged` 只有 1988/1991/1999/2007/2011 年，无法精确重建工具变量）。以下三份公开复现文件包含 David Dorn 提供给后续研究者的份额矩阵：

| 子目录 | 来源 | 内容 | 用途 |
|---|---|---|---|
| `bhj_shift_share/` | Borusyak-Hull-Jaravel (2022, ReStud) `github.com/borusyak/shift-share` → `ADH.zip`（11 MB） | `Lshares.dta`（722 CZ×2 期×397 行业滞后份额）、`shocks.dta`（行业冲击 g）、`location_level.dta`、`industry_level(_ext).dta`、BHJ 的 Results/ | S·g 复现 ADH 工具变量（误差 5.9e-6）；AKM、BHJ 冲击层面回归、Rotemberg 权重 |
| `gpss_bartik_weight/` | Goldsmith-Pinkham-Sorkin-Swift (2020, AER) `github.com/paulgp/bartik-weight` | `Lshares.dta`、`shocks.dta`、`ADHdata_AKM.csv`、`make_rotemberg_summary_ADH.do`、`rotemberg_summary_adh.tex` | Rotemberg 权重参考值 |
| `akm_ShiftShareSE/` | Adão-Kolesár-Morales (2019, QJE) R 包 `github.com/kolesarm/ShiftShareSE` | `ADH.rda`（1444×770 份额矩阵）、测试脚本 | AKM 标准误参考 |

```bash
mkdir -p Data/external/{bhj_shift_share,gpss_bartik_weight,akm_ShiftShareSE}
cd Data/external/bhj_shift_share && curl -L -o ADH.zip https://github.com/borusyak/shift-share/raw/master/ADH.zip && unzip -q ADH.zip && cd -
cd Data/external/gpss_bartik_weight && for f in data/ADHdata_AKM.csv data/Lshares.dta data/shocks.dta data/sic_code_desc.dta \
  code/make_rotemberg_summary_ADH.do output/rotemberg_summary_adh.tex; do \
  curl -sL -o $(basename $f) https://raw.githubusercontent.com/paulgp/bartik-weight/master/$f; done; cd -
cd Data/external/akm_ShiftShareSE && for f in data/ADH.rda man/ADH.Rd data-raw/data-prep.R tests/testthat/adh.do \
  tests/testthat/test_adh.R; do curl -sL -o $(basename $f) https://raw.githubusercontent.com/kolesarm/ShiftShareSE/master/$f; done
```

文件包中的 do/log/gph/tab-fig/other 子目录分别放在 `Program/do`、`Materials/package/author_logs_2013`、`Materials/package/author_gph_2013`、`Materials/package/tab-fig`、`Program/other`。

## 许可

数据由作者公开发布，引用要求见各 `README for *.txt`（引用 Autor, Dorn and Hanson 2013 AER；CZ 交叉表引用 Autor and Dorn 2013 AER）。原始 CBP、Comtrade、IPUMS、BEA 数据分别受各自机构条款约束。
