# Data — 原始数据

来源：Harvard Dataverse 复现包 **doi:10.7910/DVN/TJCTC7**（Cengiz, Dube, Lindner & Zipperer 2019, *QJE* 134(3): 1405–1454，作者 Doruk Cengiz 上传）。

| 文件 | Dataverse file id | 大小 (bytes) | MD5 | 去向 |
|---|---|---|---|---|
| data1.zip | 3588720 | 2,034,430,385 | 1394ae60b51570f21ffe0fc47ff9a75b | 解压到 `Data/data/` |
| data2.zip | 3588721 | 2,055,295,418 | 12f800df4eab71e5888fce05bbe07511 | 解压到 `Data/data/` |
| data3.zip | 3588738 | 1,452,920,351 | a3aff23b9fdd19d6620590316df0cffc | 解压到 `Data/data/` |
| dofiles.zip | 3588739 | 276,272 | b3a55d08bc05c1bb2fafea9169237790 | 解压到 `Program/dofiles/` |
| estimates.zip | 3588740 | 1,141,159 | 2143a62e154d0947f6b7da8cbc211c71 | 解压到 `Materials/author_outputs/estimates/` |
| figures.zip | 3588725 | 383,722 | a5ce5accc9ea0111dff551aa1f2fd066 | 解压到 `Materials/author_outputs/figures/` |
| tables.zip | 3588727 | 9,736 | c74646b65fc5a09eafeb133dd8817395 | 解压到 `Materials/author_outputs/tables/` |
| Readme.txt | 3588726 | 3,390 | 69170738d3ca457d81d7c321f14ea28a | 保留在 `Data/` |
| zipfordataverse.sh | 3588722 | 853 | c450ee9699cadee53f5b535a670edc32 | 保留在 `Data/` |

合计约 5.5 GB（压缩）。作者代码通过 `master_QJE.do` 顶部的全局宏 `${data}` 读取数据；我们的包装脚本 `Program/run_original.do` 把 `${data}` 指向 `Data/data/`。

## 重新下载

逐文件 API（会 303 重定向到 S3，支持 Range），单文件示例：

```bash
curl -L -C - -o data1.zip "https://dataverse.harvard.edu/api/access/datafile/3588720"
md5 -q data1.zip   # 应为 1394ae60b51570f21ffe0fc47ff9a75b
```

本机实际使用的是并行分段下载脚本 [`download.sh`](download.sh)（每个 zip 分 6 段 Range 请求，可断点续传，结束时校验大小和 MD5）：

```bash
bash Data/download.sh
mkdir -p Data/data && for z in data1 data2 data3; do unzip -o Data/$z.zip -d Data/; done   # zip 内路径即 data/…
```

## 许可

数据由作者公开发布于 Harvard Dataverse（按 Dataverse 条款使用）；底层来源为 NBER CPS-MORG、BLS QCEW、Vaghul & Zipperer (2016) 州最低工资序列，以及俄勒冈/明尼苏达/华盛顿州行政工资记录的汇总数据。

> 本文件夹内容已在 `.gitignore` 中排除，**不会上传到 GitHub**（仅保留本说明和 `download.sh`）。
