"""StatsPAI replication of all main-text regression tables (Tables 1-6) of
Bai, Jia & Yang (2023, QJE), "Web of Power".

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_tables.py
Output: Results/statspai/table{1..6}.csv, Results/statspai/main_tables_long.csv
"""
from __future__ import annotations

import time

import numpy as np
import pandas as pd

from common import (HUNAN_CTRL, HUNAN_CTRL_GEO, HUNAN_CTRL_POL, NAT_CTRL, OUT, attach_reference, hunan, iv,
                    national, ols, read, status)

T0 = time.time()
ALL = []


def collect(table, col, rows, file, override=None):
    for r in rows:
        r.update(table=table, col=col)
    return rows


# ============================================================================ Table 1
def table1():
    h = hunan()
    va = ("martyr martyrs_tot_hn Zeng_all0_invdist Zeng_all0_invdist_pc lnarea lnpop lnrice lnwheat mainriv "
          "dist2canal lnurbanpop capital lnjinshi lnquotas dist_nanjing route1").split()
    n = read("NationalCntyYr")
    vb = ("martyrs_tot_post Zeng_all0_invdist alloff lncntyarea lncntypop lnrice lnwheat mainriv dist2canal "
          "lnurbanpop prefcap lnjinshi lncntyquota0 dist_nanjing Taiping_route1").split()
    # Panel B as coded (all years 1800-1910, N=182,706) and as labelled in the paper (1820-1910, N=149,786)
    rows = []
    for panel, d, vs in [("A: Hunan 1850-64", h, va), ("B: all counties, code sample (1800-1910)", n, vb),
                         ("B: all counties, 1820-1910 (paper label)", n[n.year >= 1820], vb)]:
        s = d[vs].describe().T[["count", "mean", "std", "min", "max"]]
        s.insert(0, "panel", panel)
        rows.append(s.reset_index().rename(columns={"index": "var"}))
    t = pd.concat(rows)
    # paper (NBER w28667 rev. 2022 = QJE Table I) mean / s.d.
    paper = {
        ("A", "martyr"): (26.21, 145.75), ("A", "martyrs_tot_hn"): (0.37 * 1000, 1.20 * 1000),
        ("A", "Zeng_all0_invdist"): (1.23, 2.53), ("A", "Zeng_all0_invdist_pc"): (4.48, 7.53),
        ("A", "lnarea"): (7.84, 0.48), ("A", "lnpop"): (12.14, 0.62), ("A", "lnurbanpop"): (8.53, 1.48),
        ("B", "martyrs_tot_post"): (0.02, 0.27), ("B", "Zeng_all0_invdist"): (0.68, 2.02),
        ("B", "alloff"): (0.09, 0.54), ("B", "lncntyarea"): (7.40, 0.89), ("B", "lnurbanpop"): (7.70, 2.76),
    }
    t["paper_mean"] = [paper.get((p[0], v), (np.nan, np.nan))[0] if not p.startswith("B: all counties, code") else np.nan
                       for p, v in zip(t.panel, t["var"])]
    t["paper_sd"] = [paper.get((p[0], v), (np.nan, np.nan))[1] if not p.startswith("B: all counties, code") else np.nan
                     for p, v in zip(t.panel, t["var"])]
    t.to_csv(OUT / "table1.csv", index=False)
    print("Table 1 done", round(time.time() - T0, 1))


# ============================================================================ Table 2
def table2():
    h = hunan()
    fe = ["year", "cntyid"]
    full = HUNAN_CTRL
    specs = [
        (1, "Zeng_all0_invdist_Post", []), (2, "Zeng_all0_invdist_Post", HUNAN_CTRL_GEO),
        (3, "Zeng_all0_invdist_Post", HUNAN_CTRL_POL), (4, "Zeng_all0_invdist_Post", full),
        (5, "Zeng_all0_invdist_pc_Post", []), (6, "Zeng_all0_invdist_pc_Post", full),
        (7, "Zeng_all0_Post", []), (8, "Zeng_all0_Post", full),
        (9, "Zeng_all0_pc_Post", []), (10, "Zeng_all0_pc_Post", full),
    ]
    rows = []
    for col, x, c in specs:
        rr, _ = ols("lnmartyr1", c + [x], fe, h, "cntyid", keep=[x])
        rows += collect("Table 2", col, rr, "Table_2.txt")
    df = attach_reference(pd.DataFrame(rows), "Table_2.txt")
    ALL.append(df)
    print("Table 2 done", round(time.time() - T0, 1))


# ============================================================================ Table 3
def table3():
    h = hunan()
    fe = ["year", "cntyid", "prefidXyear"]
    rows = []
    for col, x in [(1, "Zenghu_all_invdist_Post"), (2, "Zeng_BMF_invdist_Post"), (3, "Zeng_Juren_invdist_Post"),
                   (4, "Zeng_exam0_invdist_Post")]:
        rr, _ = ols("lnmartyr1", [x] + HUNAN_CTRL, fe, h, "cntyid", keep=[x])
        rows += collect("Table 3", col, rr, "Table_3.txt")

    d = read("HunanSurname")
    d["Post"] = np.where(d.year < 1854, 0.0, 1.0)
    for v in ("sur_invdis_zeng_all0 capital lnurbanpop lnjinshi lnquotas route1 dist_nanjing mainriv dist2canal "
              "lnwheat lnrice lnarea lnhh").split():
        d[f"{v}_Post"] = d[v] * d.Post
    d["prefXyear"] = d.groupby(["prefid", "year"]).ngroup()
    d["cntyXyear"] = d.cntyid * 100 + (d.year - 1850)
    d["surXyear"] = d.surname_id * 100 + (d.year - 1850)
    d["cntyXsur"] = d.cntyid * 1000 + d.surname_id
    g = d.groupby("cntyXsur")
    d["subsample"] = (g.sur_invdis_zeng_all0.transform("mean") != 0) | (g.martyr_surname.transform("mean") != 0)
    d["sum_sur"] = d.groupby(["cntyid", "year"]).sur_invdis_zeng_all0.transform("sum")
    d["oth_sur_invdis_zeng_all0_Post"] = (d.sum_sur - d.sur_invdis_zeng_all0) * d.Post
    s = d[d.subsample].copy()
    ctrl = ("lnjinshi_Post lnquotas_Post capital_Post lnurbanpop_Post route1_Post dist_nanjing_Post mainriv_Post "
            "lnhh_Post lnarea_Post lnwheat_Post lnrice_Post dist2canal_Post").split()
    cl = ["cntyid", "surname_id"]
    fe5 = ["prefXyear", "surXyear", "cntyXsur", "cntyid", "year"]
    rr, _ = ols("lnmartyr_surname1", ["sur_invdis_zeng_all0_Post"] + ctrl, fe5, s, cl, keep=["sur_invdis_zeng_all0_Post"])
    rows += collect("Table 3", 5, rr, "")
    keep6 = ["sur_invdis_zeng_all0_Post", "oth_sur_invdis_zeng_all0_Post"]
    rr, _ = ols("lnmartyr_surname1", keep6 + ctrl, fe5, s, cl, keep=keep6)
    rows += collect("Table 3", 6, rr, "")
    rr, _ = ols("lnmartyr_surname1", ["sur_invdis_zeng_all0_Post"], ["cntyXyear", "surXyear", "cntyXsur", "cntyid", "year"],
                s, cl)
    rows += collect("Table 3", 7, rr, "")
    # published Table III: N=1,125 in cols 1-4 (reghdfe of the time kept singletons) and col 6 diff-surname 0.057 (0.016)
    ov = {(c, v): (np.nan, np.nan, 1125) for c, v in [(1, "Zenghu_all_invdist_Post"), (2, "Zeng_BMF_invdist_Post"),
                                                   (3, "Zeng_Juren_invdist_Post"), (4, "Zeng_exam0_invdist_Post")]}
    df = attach_reference(pd.DataFrame(rows), "Table_3.txt")
    for (c, v), (_, _, n) in ov.items():
        df.loc[(df.col == c) & (df["var"] == v), "paper_N"] = n
    df.loc[(df.col == 6) & (df["var"] == "oth_sur_invdis_zeng_all0_Post"), ["paper_coef", "paper_se"]] = [0.057, 0.016]
    ALL.append(df)
    print("Table 3 done", round(time.time() - T0, 1))


# ============================================================================ Table 4
def table4():
    h = hunan()
    fe = ["year", "cntyid", "prefidXyear"]
    s = h[h.cntyid != 25]
    keep = ["Zeng_all0_invdist_Post", "Zeng_exam0_invdist_Post", "invdist0_L1_Post", "invdist0_F1_Post"]
    rows = []
    for col, pl in [(1, ["invdist0_L1_Post"]), (2, ["invdist0_F1_Post"]), (3, ["invdist0_L1_Post", "invdist0_F1_Post"])]:
        rr, _ = ols("lnmartyr1", ["Zeng_exam0_invdist_Post"] + pl + HUNAN_CTRL, fe, s, "cntyid", keep=keep)
        rows += collect("Table 4", col, rr, "")
    for col, pl in [(4, ["invdist0_L1_Post"]), (5, ["invdist0_F1_Post"]), (6, ["invdist0_L1_Post", "invdist0_F1_Post"])]:
        rr, _ = iv("lnmartyr1", pl + HUNAN_CTRL, "Zeng_all0_invdist_Post", ["Zeng_exam0_invdist_Post"], fe, s, "cntyid",
                   keep=keep)
        rows += collect("Table 4", col, rr, "")
    # Huai region
    u = read("HuaiYr")
    u["Post"] = np.where(u.year < 1854, 0.0, 1.0)
    for v in ("Zeng_all0_invdist Zeng_exam0_invdist invdist0_L1 invdist0_F1 lncntyarea lncntypop lnrice lnwheat "
              "mainriv dist2canal prefcap lnurbanpop lnjinshi lncntyquota0 dist_nanjing Taiping_route1").split():
        u[f"{v}_Post"] = u[v] * u.Post
    uc = ("prefcap_Post lnurbanpop_Post lnjinshi_Post lncntyquota0_Post Taiping_route1_Post dist_nanjing_Post "
          "mainriv_Post dist2canal_Post lnrice_Post lnwheat_Post lncntypop_Post lncntyarea_Post").split()
    fu = ["year", "samcntyid", "prefidXyear"]
    for col, xs in [(7, ["Zeng_all0_invdist_Post"]), (8, ["Zeng_exam0_invdist_Post"]),
                    (9, ["Zeng_exam0_invdist_Post", "invdist0_L1_Post"]), (10, ["Zeng_exam0_invdist_Post", "invdist0_F1_Post"]),
                    (11, ["Zeng_exam0_invdist_Post", "invdist0_L1_Post", "invdist0_F1_Post"])]:
        rr, _ = ols("lnmartyr_yr", uc + xs, fu, u, "samcntyid", keep=xs)
        rows += collect("Table 4", col, rr, "")
    df = attach_reference(pd.DataFrame(rows), "Table_4.txt")
    ALL.append(df)
    print("Table 4 done", round(time.time() - T0, 1))


# ============================================================================ Table 5
def table5():
    n = national()
    fe = ["year", "samcntyid"]
    keep = ["hXZeng_all0_invdistXperiod", "Zeng_all0_invdistXperiod", "hunanXperiod"]
    rows = []
    for col, sub, c in [(1, n[n.hunan == 1], []), (2, n[n.hunan == 1], NAT_CTRL),
                        (3, n[n.hunan == 0], []), (4, n[n.hunan == 0], NAT_CTRL)]:
        rr, _ = ols("alloff", c + ["Zeng_all0_invdistXperiod"], fe, sub, "prefid", keep=keep)
        rows += collect("Table 5", col, rr, "")
    for col, c in [(5, []), (6, NAT_CTRL)]:
        rr, _ = ols("alloff", c + keep, fe, n, "prefid", keep=keep)
        rows += collect("Table 5", col, rr, "")
    df = attach_reference(pd.DataFrame(rows), "Table_5.txt")
    ALL.append(df)
    print("Table 5 done", round(time.time() - T0, 1))


# ============================================================================ Table 6
def table6():
    n = national()
    fe = ["year", "samcntyid"]
    keep = ["hXZeng_all0_invdistXperiod", "Zeng_all0_invdistXperiod", "hunanXperiod", "martyrs_tot_postXperiod",
            "Zeng_exam0_invdistXperiod", "Zeng_Extraexam_invdistXperiod", "hXZeng_exam0_invdistXperiod",
            "hXZeng_Extraexam_invdistXperiod"]
    rows = []
    rr, _ = ols("alloff", NAT_CTRL + ["hXZeng_all0_invdistXperiod", "Zeng_all0_invdistXperiod", "hunanXperiod"], fe, n,
                "prefid", keep=keep)
    rows += collect("Table 6", 1, rr, "")
    rr, _ = ols("alloff", NAT_CTRL + ["martyrs_tot_postXperiod", "Zeng_all0_invdistXperiod", "hunanXperiod"], fe, n,
                "prefid", keep=keep)
    rows += collect("Table 6", 2, rr, "")
    rr, _ = ols("alloff", NAT_CTRL + ["martyrs_tot_postXperiod", "hXZeng_all0_invdistXperiod", "Zeng_all0_invdistXperiod",
                                      "hunanXperiod"], fe, n, "prefid", keep=keep)
    rows += collect("Table 6", 3, rr, "")
    base = ["Zeng_exam0_invdistXperiod", "Zeng_Extraexam_invdistXperiod"] + NAT_CTRL + ["hunanXperiod"]
    specs = [(4, base, ["hXZeng_Extraexam_invdistXperiod", "hXZeng_exam0_invdistXperiod"]),
             (5, ["hXZeng_exam0_invdistXperiod"] + base, ["hXZeng_Extraexam_invdistXperiod"]),
             (6, ["hXZeng_Extraexam_invdistXperiod"] + base, ["hXZeng_exam0_invdistXperiod"])]
    for col, ex, z in specs:
        rr, _ = iv("alloff", ex, "martyrs_tot_postXperiod", z, fe, n, "prefid", keep=keep)
        rows += collect("Table 6", col, rr, "")
    df = attach_reference(pd.DataFrame(rows), "Table_6.txt")
    ALL.append(df)
    print("Table 6 done", round(time.time() - T0, 1))


if __name__ == "__main__":
    table1()
    table2()
    table3()
    table4()
    table5()
    table6()
    out = pd.concat(ALL, ignore_index=True)
    out["status"] = out.apply(status, axis=1)
    cols = ["table", "col", "var", "paper_coef", "paper_se", "paper_N", "stata_coef", "stata_se", "stata_N", "coef", "se",
            "N", "abs_diff_coef_vs_stata", "abs_diff_se_vs_stata", "status"]
    out[cols].to_csv(OUT / "main_tables_long.csv", index=False)
    for t, g in out.groupby("table"):
        g[cols].to_csv(OUT / f"{t.lower().replace(' ', '')}.csv", index=False)
    print(out.status.value_counts())
    print("total seconds", round(time.time() - T0, 1))
