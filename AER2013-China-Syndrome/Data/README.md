# Data — 原始数据

来源：作者（David Dorn）个人网站公开发布的复现文件包 **Autor-Dorn-Hanson-ChinaSyndrome-FileArchive**
（<https://www.ddorn.net/data.htm> → "File Archives for Papers"），论文 DOI [10.1257/aer.103.6.2121](https://doi.org/10.1257/aer.103.6.2121)。

> AEA 官方 openICPSR 副本（项目 **E112670**）需要登录，本机无法访问；ddorn.net 文件包内容与之一致（作者 2013-01-09 发布，含 dta/do/log/gph/tab-fig）。
> 本文件夹内容已在 `.gitignore` 中排除，不上传 GitHub（仅保留本说明与 `.gitkeep`）。

```text
Data/
├── ads.zip          作者文件包原始 zip（2.95 MB，保留以便核对）
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

文件包中的 do/log/gph/tab-fig/other 子目录分别放在 `Program/do`、`Materials/package/author_logs_2013`、`Materials/package/author_gph_2013`、`Materials/package/tab-fig`、`Program/other`。

## 许可

数据由作者公开发布，引用要求见各 `README for *.txt`（引用 Autor, Dorn and Hanson 2013 AER；CZ 交叉表引用 Autor and Dorn 2013 AER）。原始 CBP、Comtrade、IPUMS、BEA 数据分别受各自机构条款约束。
