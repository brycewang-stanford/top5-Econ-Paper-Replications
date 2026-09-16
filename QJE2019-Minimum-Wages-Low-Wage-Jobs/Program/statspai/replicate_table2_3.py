"""StatsPAI replication of Table 2 (demographic / Card-Krueger groups), Table 3
(industries, 1992-2016) and the group rows of Table 4 (wage effect with/without
spillovers).

Mirrors: Table2_for_QJE.do (cols 1-5 regressions are commented out there and the
shipped Table4aqcewafter_*.ster are loaded instead — we re-estimate them),
CK_groups_regressions_longfigure_QJE.do (cols 6-8), Table3_for_QJE.do,
wage_estimate_demog_groups.do / wage_estimate_ind_groups.do.

Run: /usr/local/bin/python3.13 Program/statspai/replicate_table2_3.py [--only table2|ck|table3] [--reuse]
Outputs: Results/statspai/table2.csv, table3.csv, table4_groups.csv
"""
from __future__ import annotations

import argparse
import json

import numpy as np
import pandas as pd
import pyreadstat

from bunching import (DATA, EST, OUT, Panel, T_AFTER, TREAT_AFTER, TREAT_BEFORE, WINDOW,
                      add_placebo_bins, add_rsums, bunching_stats, constants, fit, load_fit, log,
                      qcew_overall, read_main, tname)

DEMOG = ["HSD", "HSL", "teen", "female", "BH"]
CK = ["first_", "fourth_", "fifth_"]
IND = ["ind_all_overall", "ind_mstrad_overall", "ind_msnontrad_overall", "ind_mscon_overall",
       "ind_msother_overall", "ind_rest_overall", "ind_retail_overall", "ind_manuf_overall"]


def get_fit(tag, reuse, *args, **kw):
    if reuse and (EST / f"{tag}_b.csv").exists():
        log(f"reused {tag}")
        return load_fit(tag)
    return fit(*args, tag=tag, **kw)


def run_demog(reuse: bool) -> list[dict]:
    extra = []
    for c in ("teen", "HSL", "HSD", "gender", "black", "hispanic"):
        extra += [f"{c}count", f"{c}countall"]
    extra += [f"{g}pop" for g in ("teen", "HSL", "HSD", "female", "BH")]
    extra += [f"{g}countpcall" for g in DEMOG] + [f"wt{g}1979" for g in DEMOG]
    df = read_main(extra=extra)
    df = df.merge(qcew_overall(), on=["statenum", "quarterdate"], how="left", validate="m:1")
    assert df["emp"].notna().all()
    df["femalecount"] = df["count"] - df["gendercount"]
    df["femalecountall"] = df["countall"] - df["gendercountall"]
    df["BHcount"] = df["blackcount"] + df["hispaniccount"]
    df["BHcountall"] = df["blackcountall"] + df["hispaniccountall"]
    m = df["emp"].to_numpy() != 0
    ratio = np.where(m, df["emp"] / df["countall"], np.nan)
    for Y in DEMOG:
        c = df[f"{Y}count"].to_numpy(dtype=float)
        df[f"{Y}count"] = np.where(m, c * ratio, c)
        df[f"{Y}countpc"] = df[f"{Y}count"] / df[f"{Y}pop"]
        df[f"{Y}countpcall"] = np.where(m, df[f"{Y}countall"] * ratio / df[f"{Y}pop"], np.nan)
    df = df.sort_values(["statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    P = Panel(df)
    rows = []
    for Y in ["HSD", "teen", "HSL", "female", "BH"]:
        add_rsums(df, Y, f"{Y}count", f"{Y}pop", f"{Y}countpc")
        K = constants(df, P, Y, f"wt{Y}1979", f"{Y}countpcall")
        log(f"{Y} constants {json.dumps(K)}")
        d = df[(df["year"] >= 1979) & (df["cleansample"] == 1) & (df[f"wt{Y}1979"] > 0)]
        params, V, N = get_fit(f"table2_{Y}", reuse, d, f"{Y}countpc", TREAT_AFTER,
                               TREAT_BEFORE + WINDOW, f"wt{Y}1979", spec=1)
        st = bunching_stats(params, V, K, with_alt=True)
        rows.append(dict(table="2", group=Y, N=N, b_minus1=K["B"], mwpc=K["mwpc"],
                         n_events=K["n_events"], **st))
        pd.DataFrame(rows).to_csv(OUT / "table2_demog.csv", index=False)
    return rows


def run_ck(reuse: bool) -> list[dict]:
    ck, _ = pyreadstat.read_dta(str(DATA / "CK_groups.dta"))
    df = read_main()
    df = ck.merge(df, on=["statenum", "quarterdate", "wagebins"], how="right", validate="1:1")
    for v in CK:
        df[f"{v}count"] = df[f"{v}count"].fillna(0)
        df[f"{v}pop"] = df[f"{v}pop"].fillna(df.groupby(["statenum", "quarterdate"])[f"{v}pop"].transform("max"))
    df = df.merge(qcew_overall(), on=["statenum", "quarterdate"], how="left", validate="m:1")
    m = df["emp"].to_numpy() != 0
    for Y in CK:
        c = df[f"{Y}count"].to_numpy(dtype=float)
        df[f"{Y}count"] = np.where(m, c * df["emp"] / df["countall"], c)
        df[f"{Y}countpc"] = df[f"{Y}count"] / df[f"{Y}pop"]
        g = df.groupby(["statenum", "quarterdate"])
        df[f"{Y}countall"] = g[f"{Y}count"].transform("sum")
        df[f"{Y}countpcall"] = g[f"{Y}countpc"].transform("sum")
    df = df.sort_values(["statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    P = Panel(df)
    add_placebo_bins(df, P, kmax=16)
    pbins = [f"p{k}" for k in range(5, 18)]
    x_after = TREAT_AFTER + [tname(t, b) for t in T_AFTER for b in pbins]
    lin = TREAT_BEFORE + WINDOW + [tname(t, b, True) for t in (12, 8) for b in pbins] \
        + [f"window_p{k}" for k in range(5, 18)]
    rows = []
    for Y in CK:
        add_rsums(df, Y, f"{Y}count", f"{Y}pop", f"{Y}countpc")
        K = constants(df, P, Y, f"{Y}pop", f"{Y}countpcall", mw_denominator_needs_nonmissing=True)
        log(f"{Y} constants {json.dumps(K)}")
        d = df[(df["year"] >= 1979) & (df["cleansample"] == 1)]
        params, V, N = get_fit(f"table2_ck_{Y}", reuse, d, f"{Y}countpc", x_after, lin, f"{Y}pop", spec=1)
        st = bunching_stats(params, V, K, with_alt=True)
        rows.append(dict(table="2", group=Y, N=N, b_minus1=K["B"], mwpc=K["mwpc"],
                         n_events=K["n_events"], **st))
        pd.DataFrame(rows).to_csv(OUT / "table2_ck.csv", index=False)
    return rows


def run_ind(reuse: bool) -> list[dict]:
    path = "state_panels_with3quant_ind_1992_2016.dta"
    extra = [f"{Y}{s}" for Y in IND for s in ("count", "countall", "samplesize")] + ["overallpop"]
    df = read_main(extra=extra, path=path)
    q, _ = pyreadstat.read_dta(str(DATA / "qcew_state_sector_counts_2016.dta"))
    q = q.rename(columns={"statefips": "statenum"})
    q["quarterdate"] = ((q["year"] - 1960) * 4 + q["quarter"] - 1).astype(int)
    q = q.rename(columns={c: f"emp_{c}_overall" for c in q.columns if c.startswith("ind_")})
    q = q[["statenum", "quarterdate"] + [c for c in q.columns if c.startswith("emp_")]]
    df = df.merge(q, on=["statenum", "quarterdate"], how="inner", validate="m:1")
    for Y in IND:
        df[f"{Y}count"] = df[f"{Y}count"] * df[f"emp_{Y}"] / df["countall"]
        df[f"{Y}countpc"] = df[f"{Y}count"] / df["population"]
        df[f"{Y}countpcall"] = df[f"{Y}countall"] * (df[f"emp_{Y}"] / df["countall"]) / df["population"]
    sel = (df["year"] >= 1992) & (df["cleansample"] == 1)
    df["wtoverall1992"] = np.where(sel, df.groupby(["statenum", "quarterdate"])["overallpop"].transform("mean"), np.nan)
    df = df.sort_values(["statenum", "quarterdate", "wagebins"]).reset_index(drop=True)
    P = Panel(df)
    rows = []
    for Y in IND:
        add_rsums(df, Y, f"{Y}count", "population", f"{Y}countpc")
        K = constants(df, P, Y, "wtoverall1992", f"{Y}countpcall", b=1992)
        log(f"{Y} constants {json.dumps(K)}")
        d = df[(df["year"] >= 1992) & (df["cleansample"] == 1)]
        params, V, N = get_fit(f"table3_{Y}", reuse, d, f"{Y}countpc", TREAT_AFTER,
                               TREAT_BEFORE + WINDOW, "wtoverall1992", spec=1)
        st = bunching_stats(params, V, K, with_alt=True)
        workers = float(df.loc[sel, f"{Y}samplesize"].sum()) if f"{Y}samplesize" in df else np.nan
        rows.append(dict(table="3", group=Y, N=N, workers=workers, b_minus1=K["B"], mwpc=K["mwpc"],
                         n_events=K["n_events"], **st))
        pd.DataFrame(rows).to_csv(OUT / "table3.csv", index=False)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="table2,ck,table3")
    ap.add_argument("--reuse", action="store_true")
    a = ap.parse_args()
    todo = a.only.split(",")
    if "table2" in todo:
        run_demog(a.reuse)
    if "ck" in todo:
        run_ck(a.reuse)
    if "table3" in todo:
        run_ind(a.reuse)
    log("done")


if __name__ == "__main__":
    main()
