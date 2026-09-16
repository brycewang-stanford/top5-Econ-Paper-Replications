# Data — 原始数据

来源：Harvard Dataverse，**Chen, Ting; Kung, James Kai-sing, 2018, "Replication Data for: 'Busting the "Princelings": The Campaign against Corruption in China's Primary Land Market'"**，doi:[10.7910/DVN/XW6OJT](https://doi.org/10.7910/DVN/XW6OJT)，*The Quarterly Journal of Economics* Dataverse。许可：**CC0 1.0**。

Dataverse 把 Stata 文件存成归档格式 `.tab`；作者代码读取 `.dta`，因此这里下载的是每个文件的 **original 格式**（Stata 14 `.dta`）。

| 文件 | Dataverse file id | 大小 (original) | 用途 |
|---|---|---|---|
| `price.dta` | 3239602 | 134.2 MB | 1,208,621 笔土地交易（Tables III, V, X；Figure V） |
| `firm_panel.dta` | 3239599 | 227.7 MB | 企业×年 面板，5,690,984 obs（Table VI；Figure VI） |
| `firm_prov_panel.dta` | 3239603 | 702.5 MB | 企业×省×年 面板，11,516,622 obs（Table XI） |
| `province_panel.dta` | 3239605 | 0.1 MB | 省级书记/省长×年（Tables VII, VIII, XII） |
| `prefecture_panel.dta` | 3239601 | 1.0 MB | 地级市书记/市长×年（Tables VII, IX, XII） |
| `figure4.dta` | 3239600 | 0.5 MB | Figure IV（500 米内价格散点） |
| `figure7.dta` | 3239598 | 0.01 MB | Figure VII（2013-10 至 2014-01 日度价格/数量） |

合计约 **1.07 GB**。代码 `Tables&Figures.do`（file id 3239604）放在 `Program/`。

## 重新下载

```bash
cd Data
for pair in 3239602:price 3239599:firm_panel 3239603:firm_prov_panel 3239605:province_panel \
            3239601:prefecture_panel 3239600:figure4 3239598:figure7; do
  id=${pair%%:*}; n=${pair##*:}
  curl -L -C - --retry 5 -o $n.dta "https://dataverse.harvard.edu/api/access/datafile/$id?format=original"
done
curl -L -o "../Program/Tables&Figures.do" "https://dataverse.harvard.edu/api/access/datafile/3239604"
```

（`-C -` 可断点续传；大文件下载速度约 0.3–1 MB/s。）

> 本文件夹除本说明外均在 `.gitignore` 中排除，**不会提交到 git**（数据量大，且 `firm_prov_panel.dta` 超过 GitHub 单文件 100 MB 上限）。
