# Project-local Stata ado files

`Program/run_original.do` puts this folder first on the adopath (`adopath ++`).

| Package | Version | Source | Why local |
|---|---|---|---|
| `carryforward` | SSC (2016) | `ssc install carryforward` | required by Analysis.do, not installed globally |
| `xtevent` (+ `xteventplot`, `xteventtest`, `_event*.ado`) | **1.0.0 (Aug 24 2021)** | GitHub tag `JMSLab/xtevent@v1.0.0` | Table IX Panel A is reproduced exactly only with v1.0.0; the current SSC release (3.1.0, 2024) and v2.1.1/v2.2.0 change the default endpoint/normalisation conventions and give 8q-after estimates of -8.678 / 3.961 / -5.343 instead of 23.968 / 1.372 / 9.812. |
| `make_index_gr` | V.0.2 (Dec 2017) | https://github.com/cdsamii/make_index (`stata/make_index_gr.do`, saved as .ado) | called by Analysis.do (Tables VI/A.8-A.10 column 2 and 5, Figures 5/6) but **not shipped** in the replication package; without it sections 5, 6 and 11 stop with r(199). |
