"""StatsPAI replication of Table 1 column (7): the "simpler method" on a
state-by-quarter panel (jobs and wage bill per capita below $15), mirroring
Table1_last_column_for_QJE.do.

Needs the constants E, B, EWB, %dMW produced by replicate_table1.py
(Results/statspai/constants_overall.json), exactly as the Stata do-file reuses the
globals left over from Table1_for_QJE.do.

Run: /usr/local/bin/python3.13 Program/statspai/replicate_table1_col7.py
Output: Results/statspai/table1_col7.csv
"""
from __future__ import annotations

import json

import numpy as np
import pandas as pd
import pyreadstat
import statspai as sp

from bunching import DATA, EST, OUT, delta, log, notmiss


def lagop(df, col, k, unit="statenum"):
    """Stata L<k>. (k>0) / F<-k>. (k<0) on a (unit, quarterdate) panel (gaps -> missing)."""
    key = df[[unit, "quarterdate"]]
    src = df[[unit, "quarterdate", col]].copy()
    src["quarterdate"] = src["quarterdate"] + k
    return key.merge(src, on=[unit, "quarterdate"], how="left")[col].to_numpy(dtype=float)


def main():
    K = json.loads((OUT / "constants_overall.json").read_text())

    cpi, _ = pyreadstat.read_dta(str(DATA / "cpiursai1977-2016.dta"))
    cpi = cpi.drop(columns=[c for c in ("v14", "avg") if c in cpi.columns])
    mcols = [c for c in cpi.columns if c.startswith("month")]
    cpi = cpi.melt(id_vars="year", value_vars=mcols, var_name="m", value_name="cpi")
    cpi["month"] = cpi["m"].str.replace("month", "").astype(int)
    cpi = cpi[cpi["year"] >= 1979]
    base = cpi.loc[cpi["year"] == 2016, "cpi"].mean()
    cpi["cpi"] = 100 * cpi["cpi"] / base
    cpi["quarterdate"] = (cpi["year"] - 1960) * 4 + (cpi["month"] - 1) // 3
    cpi = cpi.groupby("quarterdate", as_index=False)["cpi"].mean()

    q, _ = pyreadstat.read_dta(str(DATA / "qcew_multiplier.dta"), usecols=["statenum", "quarterdate", "multiplier"])
    d, _ = pyreadstat.read_dta(str(DATA / "statequarter_counts_maxupperw.dta"))
    d = d.rename(columns={"totalpopulation": "overallpop"})
    d = d.merge(q, on=["statenum", "quarterdate"], how="left", validate="m:1")
    assert d["multiplier"].notna().all()
    d["emp"] = d["emp"] * d["multiplier"]
    d["wage"] = d["wage"] * d["multiplier"]
    d["epop"] = d["emp"] / d["overallpop"]
    d["wagepc"] = d["wage"] / d["overallpop"]
    mw, _ = pyreadstat.read_dta(str(DATA / "VZmw_quarterly_lagsleads_1979_2016.dta"),
                                usecols=["statenum", "quarterdate", "logmw"])
    d = d.merge(mw, on=["statenum", "quarterdate"], how="left", validate="1:1")
    ev, _ = pyreadstat.read_dta(str(DATA / "eventclassification.dta"))
    d = d.merge(ev[["statenum", "quarterdate", "overallcountgroup", "fedincrease", "toosmall"]],
                on=["statenum", "quarterdate"], how="left", validate="1:1")
    d["overallcountgroup"] = d["overallcountgroup"].fillna(0)
    d = d.merge(cpi, on="quarterdate", how="left", validate="m:1")
    d = d.sort_values(["statenum", "quarterdate"]).reset_index(drop=True)

    f32 = lambda x: np.asarray(x, dtype=np.float32).astype(float)
    d["MW"] = f32(np.exp(d["logmw"]))
    d["MW_real"] = f32(np.exp(d["logmw"]) / (d["cpi"] / 100))
    DMW_real = d["MW_real"].to_numpy() - lagop(d, "MW_real", 1)
    DMW = d["MW"].to_numpy() - lagop(d, "MW", 1)
    fed = d["fedincrease"].to_numpy(dtype=float)
    grp = d["overallcountgroup"].to_numpy(dtype=float)

    d["_treat"] = ((grp > 0) & (np.isnan(fed) | (fed != 1))).astype(float)
    d["treat"] = sum(lagop(d, "_treat", k) if k else d["_treat"].to_numpy() for k in range(4))
    # $missedevents = D.MW_real>0 & D.MW_real<. & D.MW>0 & D.MW_real<=0.25 ; toosmall==1
    missed = (DMW_real > 0) & notmiss(DMW_real) & (DMW > 0) & notmiss(DMW) & (DMW_real <= 0.25)
    d["_cont"] = (missed | (d["toosmall"].to_numpy() == 1)).astype(float)
    d["_contf"] = ((fed == 1) & (grp > 0)).astype(float)
    for nm in ("cont", "contf"):
        d[f"temp{nm}"] = sum(lagop(d, f"_{nm}", k) if k else d[f"_{nm}"].to_numpy() for k in range(4))
        post = d[f"_{nm}"].to_numpy().copy()
        for i in range(1, 20):
            post = post + lagop(d, f"_{nm}", i)          # missing propagates, as in Stata
        d[f"post{nm}"] = post
        d[f"pre{nm}"] = lagop(d, f"temp{nm}", -4)
        d[f"early{nm}"] = lagop(d, f"temp{nm}", -12) + lagop(d, f"temp{nm}", -8)
        for c in (f"pre{nm}", f"early{nm}", f"post{nm}"):
            d[c] = d[c].fillna(0)
    for j in (4, 8, 12, 16):
        d[f"F{j}treat"] = np.nan_to_num(lagop(d, "treat", -j))
        d[f"L{j}treat"] = np.nan_to_num(lagop(d, "treat", j))
    d["cleansample"] = ~d["quarterdate"].between(136, 142)
    d["year"] = 1960 + d["quarterdate"] // 4

    keep = ["statenum", "quarterdate", "year", "cleansample", "overallpop", "treat"] + \
        [f"{a}{j}treat" for a in "FL" for j in (4, 8, 12, 16)] + \
        [f"{p}{nm}" for p in ("post", "pre", "early") for nm in ("cont", "contf")]
    e = d[keep + ["epop"]].rename(columns={"epop": "outcome"}).assign(epopoutcome=1)
    wv = d[keep + ["wagepc"]].rename(columns={"wagepc": "outcome"}).assign(epopoutcome=0)
    s = pd.concat([e, wv], ignore_index=True)
    s["treat"] = s["treat"].fillna(0)
    lab = {"treat": "treat", **{f"F{j}treat": f"F{j}treat" for j in (4, 8, 12)},
           **{f"L{j}treat": f"L{j}treat" for j in (4, 8, 12, 16)}}
    xs = []
    for out, flag in (("wage", 0), ("epop", 1)):
        for src in ["F12treat", "F8treat", "F4treat", "treat", "L4treat", "L8treat", "L12treat", "L16treat"]:
            nm = f"{src}{out}"
            s[nm] = s[src] * (s["epopoutcome"] == flag)
            xs.append(nm)
    s["st_o"] = s["statenum"] * 10 + s["epopoutcome"]
    s["q_o"] = s["quarterdate"] * 10 + s["epopoutcome"]
    fes = ["st_o", "q_o"]
    for c in ("postcont", "postcontf", "precont", "precontf", "earlycont", "earlycontf"):
        s[f"{c}_o"] = s[c].round().astype(int) * 10 + s["epopoutcome"]
        fes.append(f"{c}_o")
    s = s[(s["year"] >= 1979) & s["cleansample"]].copy()
    fml = f"outcome ~ {' + '.join(xs)} | {' + '.join(fes)}"
    log(f"simpler method: N={len(s):,}")
    r = sp.hdfe_ols(fml, data=s, weights="overallpop", cluster="statenum")
    b = pd.Series(r.params)
    V = pd.DataFrame(np.asarray(r.vcov), index=b.index, columns=b.index)
    b.to_csv(EST / "table1_col7_b.csv"); V.to_csv(EST / "table1_col7_V.csv")

    names = list(b.index)
    bb, VV = b.to_numpy(), V.to_numpy()
    ix = {n: i for i, n in enumerate(names)}
    post = ["treat", "L4treat", "L8treat", "L12treat", "L16treat"]

    def agg(x, out):
        return sum(x[ix[f"{p}{out}"]] - x[ix[f"F4treat{out}"]] for p in post)

    Bepop = 1 / (K["E"] * K["B"]); Bwage = 1 / K["EWB"]; C = 1 / (K["E"] * K["mwpc"])
    bunch = lambda x: agg(x, "epop") / 5 * Bepop
    elas = lambda x: agg(x, "epop") / 5 * C
    wbE = lambda x: ((agg(x, "wage") / 5 * Bwage) - bunch(x)) / (1 + bunch(x))
    lab_ = lambda x: bunch(x) / wbE(x)
    row = dict(col=7, N=int(r.n_obs))
    for k, f in (("wage", wbE), ("emp", bunch), ("elas_mw", elas), ("elas_wage", lab_)):
        est, se = delta(f, bb, VV)
        row[k] = est; row[k + "_se"] = se
    pd.DataFrame([row]).to_csv(OUT / "table1_col7.csv", index=False)
    log(json.dumps(row))


if __name__ == "__main__":
    main()
