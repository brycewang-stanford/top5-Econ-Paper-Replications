# Data — 原始数据

**Source.** Beraja, Kao, Yang & Yuchtman (2023), "AI-tocracy", *QJE* 138(3). Replication package on Harvard Dataverse:
**doi:[10.7910/DVN/GCOVGX](https://doi.org/10.7910/DVN/GCOVGX)** (version 1, license **CC0 1.0**).
The package ships two files: `README.pdf` (185 KB, copied to `Materials/package/README.pdf`) and `Replication.zip` (610,174,932 bytes; 5.2 GB unzipped).
All data are included in de-identified form (see the package README for the underlying commercial sources: MIIT software registry via qcc.com, Tianyancha, Pitchbook, CEIC, Chinese Government Procurement Database, GDELT, NOAA/WMO GSOD, OffCN).

This folder is git-ignored (size). Layout = the package's `Replication/Data/` folder, unchanged:

```text
Data/
├── GDELT_China_contemp_distance_111820.dta   3.1 GB  prefecture-pair x quarter unrest/weather panel (Tables IV-V)
├── firm_data.dta                              917 MB  software x firm x quarter (Tables VI-VII, IX, Figures V-VI)
├── baseline_data_04292020.dta                 629 MB  software-level baseline (Table I)
├── china_weather_panel.dta                    257 MB  station x day weather (Tables II-III, Figures II-III)
├── GDELT_China_072920.dta                     147 MB  unrest events (Tables I-III)
├── ... 23 further .dta files (contracts, crosswalks, police hires, exports, LSTM predictions, ...)
├── map_prefecture_2015/                       prefecture shapefile (Figure I, A.5)
├── Intermediate/                              written by Analysis.do (Fig*.dta, China_map_*.csv)
├── Intermediate_shipped/                      APFS clone of the package's Intermediate/ before any re-run (reference copy)
└── Intermediate/statspai/                     regression-ready panels exported by Program/statspai/run_export.sh
```

## Re-download

```bash
cd Data
# whole Replication.zip (file id 7092390) — Dataverse redirects to S3; resume with -C - if the connection drops
curl -L -C - --retry 5 -o Replication.zip "https://dataverse.harvard.edu/api/access/datafile/7092390"
curl -L -o ../Materials/package/README.pdf "https://dataverse.harvard.edu/api/access/datafile/7092389"
unzip -q Replication.zip
mv Replication/Data/* . && mkdir -p ../Program/Analysis && cp Replication/Analysis/* ../Program/Analysis/
mv Replication/Output ../Materials/package/Output_shipped && rm -rf Replication Replication.zip
cp -cR Intermediate Intermediate_shipped
```

Note: `Program/Analysis/Analysis.do` in this repo carries two documented one-line edits (root path, section argument); re-copying the original file will overwrite them.
