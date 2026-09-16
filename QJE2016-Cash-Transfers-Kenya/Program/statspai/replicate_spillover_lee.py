"""StatsPAI replication of Table III (spillovers, Lee and Horowitz-Manski bounds) and
Online-Appendix Lee bounds for attrition (UCT_Endline_Regs_Spillover.do, UCT_LeeBounds.do).

Also re-creates the ORIGINAL (pre-erratum) Table III psychological-index column, which the
2017 erratum says was wrongly weighted by household and village weights.

Run: /usr/local/bin/python3.13 Program/statspai/replicate_spillover_lee.py
"""
from __future__ import annotations

import numpy as np
import pandas as pd
import statspai as sp
from scipy import stats

from uct_common import (INDICES, OUT, SPILLOVERCONTROLS, clean_label, fmt, influence_for, load,
                        suest_wald, write_md)


# ------------------------------------------------------------------ exact port of leebounds.ado (no tight(), no weights)
def _pctile(x: np.ndarray, p: float) -> float:
    """Stata _pctile (default definition)."""
    x = np.sort(x)
    n = len(x)
    P = n * p / 100.0
    i = int(np.floor(P))
    if abs(P - round(P)) < 1e-9 and 0 < round(P) < n:
        i = int(round(P))
        return (x[i - 1] + x[i]) / 2.0
    return x[min(int(np.ceil(P)) - 1, n - 1)] if P > 0 else x[0]


def _trimmed_mean(y1: np.ndarray, th: float, q: float, upper: bool):
    """Mean of the top (upper=True) or bottom share (1-q) of y1 with fractional tie weighting."""
    neth = np.sum(y1 == th)
    beyond = y1[y1 > th] if upper else y1[y1 < th]
    if neth == 0:
        keep = y1[y1 >= th] if upper else y1[y1 <= th]
        m = keep.mean()
        return m, keep.var(ddof=1) / len(keep), False, None
    nbth, sbth = len(beyond), beyond.sum()
    stie = (len(y1) * (1 - q) - nbth) / neth
    denom = nbth + stie * neth
    m = (sbth + stie * neth * th) / denom
    vb1 = (((beyond ** 2).sum() + stie * neth * th ** 2) / denom - m ** 2) / denom
    return m, vb1, True, None


def leebounds_port(y: np.ndarray, tr: np.ndarray, reps: int = 0, seed: int = 1):
    """Return dict(lower, upper, se_lower, se_upper, trim, trimmed_group)."""
    ss = ~np.isnan(y)
    t = tr.astype(int).copy()
    q0, q1 = ss[t == 0].mean(), ss[t == 1].mean()
    trimmed = "treatment"
    if q0 > q1:
        t = 1 - t
        trimmed = "control"

    def core(y, ss, t, analytic=True):
        n = len(y)
        q0, q1 = ss[t == 0].mean(), ss[t == 1].mean()
        q = (q1 - q0) / q1
        trim = 100 * q
        y1 = y[ss & (t == 1)]
        y0 = y[ss & (t == 0)]
        uth = _pctile(y1, trim)
        tub, vb1u, _, _ = _trimmed_mean(y1, uth, q, upper=True)
        lth = _pctile(y1, 100 - trim)
        lub, vb1l, _, _ = _trimmed_mean(y1, lth, q, upper=False)
        ub, lb = tub - y0.mean(), lub - y0.mean()
        out = {"lb": lb, "ub": ub, "q": q}
        if analytic:
            est = np.mean(ss & (t == 1)); esnt = np.mean(ss & (t == 0)); et = np.mean(t == 1)
            oddsc = np.mean(~ss & (t == 0)) / esnt; oddst = np.mean(~ss & (t == 1)) / est
            vp = (1 - q) ** 2 * (oddst / et + oddsc / (1 - et))
            vc = y0.var(ddof=1) / esnt
            vub = vb1u + ((uth - tub) ** 2 * q / (est * (1 - q)) + ((uth - tub) / (1 - q)) ** 2 * vp + vc) / n
            vlb = vb1l + ((lth - lub) ** 2 * q / (est * (1 - q)) + ((lth - lub) / (1 - q)) ** 2 * vp + vc) / n
            out.update(vub=vub, vlb=vlb)
        return out

    r = core(y, ss, t)
    if trimmed == "control":
        lower, upper, vl, vu = -r["ub"], -r["lb"], r["vub"], r["vlb"]
    else:
        lower, upper, vl, vu = r["lb"], r["ub"], r["vlb"], r["vub"]
    se_l, se_u = np.sqrt(vl), np.sqrt(vu)
    if reps > 1:  # vce(bootstrap): bsample, strata(treatment group)
        rng = np.random.default_rng(seed)
        draws = []
        idx0, idx1 = np.where(t == 0)[0], np.where(t == 1)[0]
        for _ in range(reps):
            ii = np.concatenate([rng.choice(idx0, len(idx0)), rng.choice(idx1, len(idx1))])
            try:
                rb = core(y[ii], ss[ii], t[ii], analytic=False)
                bl, bu = (-rb["ub"], -rb["lb"]) if trimmed == "control" else (rb["lb"], rb["ub"])
                if np.isfinite(bl) and np.isfinite(bu):
                    draws.append((bl, bu))
            except Exception:
                pass
        dr = np.array(draws)
        se_l, se_u = dr[:, 0].std(ddof=1), dr[:, 1].std(ddof=1)
    return {"lower": lower, "upper": upper, "se_lower": se_l, "se_upper": se_u, "trim": r["q"],
            "trimmed": trimmed}


def zstar(b, se):
    return stats.norm.sf(abs(b / se)) * 2


# ------------------------------------------------------------------ Table III
def table3(df, labels, weighted_psych=False, reps=100):
    use = df[(df.treat != 1) & df.endlinedate.notna()].copy()
    use["include"] = 1
    use.loc[use.maleres == 1, "include"] = 0
    roof = use.asset_niceroof1 == 1
    use.loc[roof, "asset_total_ppp1"] = use.loc[roof, "asset_total_ppp1"] - use.loc[roof, "asset_valroof_ppp1"]

    rows = []
    for v in INDICES:
        y = v + "1"
        d = use.copy()
        if v == "psy_index_z":
            d.loc[d.maleres == 1, "include"] = 1
        w = None
        if weighted_psych and v == "psy_index_z":   # pre-erratum: [aw=weight2]
            inc = d[(d.include == 1)]
            cnt_hh = inc.groupby("surveyid")[y].transform("count")
            cnt_v = inc.groupby("village")[y].transform("count")
            d["w2"] = np.nan
            d.loc[inc.index, "w2"] = 1 / cnt_v / cnt_hh
            w = "w2"
        rec = {"outcome": y, "label": clean_label(labels.get(y, y))}
        specs = {}
        for c, excl_roof, ctr in ((1, False, []), (2, False, SPILLOVERCONTROLS),
                                  (3, True, []), (4, True, SPILLOVERCONTROLS)):
            dd = d[(d.include == 1) & ~((d.asset_niceroof1 == 1) & excl_roof)]
            dd = dd.dropna(subset=[y, "spillover", *ctr] + ([w] if w else []))
            fml = f"{y} ~ spillover" + ("".join(f" + {z}" for z in ctr))
            kw = {"weights": w} if w else {}
            res = sp.feols(fml, dd, vcov={"CRV1": "village"}, **kw)
            rec[f"c{c}_b"] = float(res.params["spillover"])
            rec[f"c{c}_se"] = float(res.std_errors["spillover"])
            rec[f"c{c}_p"] = float(res.pvalues["spillover"])
            # influence function of the spillover coefficient for the suest-type tests
            # (unweighted; the weighted pre-erratum run only reports point estimates / SEs)
            specs[c] = influence_for(dd, y, "spillover", list(ctr), None)
        # columns 5-6: SUR equality tests, cluster(village)
        R = np.array([[1.0, -1.0]])
        rec["c5_p"] = suest_wald(use, [specs[1], specs[3]], "village", R)[2]
        rec["c6_p"] = suest_wald(use, [specs[2], specs[4]], "village", R)[2]

        # columns 7-10: Lee and Horowitz-Manski bounds with 5 (10) pseudo-attriters
        lb = d.copy()
        nfake = 10 if v == "psy_index_z" else 5
        if v != "psy_index_z":
            lb = lb[lb.maleres != 1]
        fake = pd.DataFrame({y: [np.nan] * nfake, "spillover": 1.0, "purecontrol": 0.0, "treat": 0.0})
        lb = pd.concat([lb[[y, "spillover"]].assign(select=0), fake[[y, "spillover"]].assign(select=1)],
                       ignore_index=True)
        L = leebounds_port(lb[y].to_numpy(float), lb.spillover.to_numpy(float), reps=reps, seed=2016)
        rec.update(c7_b=L["lower"], c7_se=L["se_lower"], c8_b=L["upper"], c8_se=L["se_upper"], lee_trim=L["trim"])
        rec["c7_p"], rec["c8_p"] = zstar(L["lower"], L["se_lower"]), zstar(L["upper"], L["se_upper"])
        # sp.lee_bounds on the same data for comparison
        lb["sel"] = lb[y].notna().astype(int)
        try:
            spl = sp.lee_bounds(lb, y=y, treat="spillover", selection="sel", n_bootstrap=reps, random_state=2016)
            rec["sp_lee_lower"] = spl.model_info["lower_bound"]
            rec["sp_lee_upper"] = spl.model_info["upper_bound"]
        except Exception as e:  # noqa
            rec["sp_lee_lower"] = rec["sp_lee_upper"] = np.nan
            rec["sp_lee_error"] = repr(e)
        obs = lb.loc[lb.select == 0, y].dropna()
        p5, p95 = _stata_pct(obs.to_numpy(), 5), _stata_pct(obs.to_numpy(), 95)
        for c, val in ((9, p5), (10, p95)):
            hm = lb.copy()
            hm.loc[hm.select == 1, y] = val
            hm = hm.dropna(subset=[y])
            r = sp.regress(f"{y} ~ spillover", hm, robust="hc1")
            rec[f"c{c}_b"], rec[f"c{c}_se"], rec[f"c{c}_p"] = (float(r.params["spillover"]),
                                                              float(r.std_errors["spillover"]),
                                                              float(r.pvalues["spillover"]))
        rows.append(rec)
    out = pd.DataFrame(rows)

    # joint row: suest over the 8 outcomes for each of columns 1-4
    joint = {}
    for c, excl_roof, ctr in ((1, False, []), (2, False, SPILLOVERCONTROLS), (3, True, []), (4, True, SPILLOVERCONTROLS)):
        d = use.copy()
        pieces = []
        for v in INDICES:
            y = v + "1"
            d.loc[d.maleres == 1, "include"] = 1 if v == "psy_index_z" else 0
            dd = d[(d.include == 1) & ~((d.asset_niceroof1 == 1) & excl_roof)]
            pieces.append(influence_for(dd, y, "spillover", list(ctr), None))
        joint[c] = suest_wald(use, pieces, "village")[2]
    return out, joint


def _wif(dd, y, ctr, w):
    return influence_for(dd.dropna(subset=[y, *ctr, w]), y, "spillover", list(ctr), None,
                         weights=None)  # weights only change point estimates in the pre-erratum check


def _stata_pct(x, p):
    """`summarize, detail` percentiles (same definition as _pctile)."""
    return _pctile(x, p)


# ------------------------------------------------------------------ OA: Lee bounds for attrition (UCT_LeeBounds.do)
def lee_attrition(df, labels):
    use = df[(df.purecontrol != 1) & df.baselinedate.notna()]
    rows = []
    for v in INDICES:
        d = use if v == "psy_index_z" else use[use.maleres != 1]
        d = d.copy()
        y1 = d[v + "1"].where(d.endlinedate.notna())
        y0 = d[v + "0"].where(d.baselinedate.notna())
        attr = y1.isna() & y0.notna()
        d["sel"] = (~attr).astype(int)
        d["ysel"] = y1
        # leebounds with select(): selection indicator given; obs with sel==1 but y missing are dropped from esample
        es = (d.ysel.notna() | (d.sel == 0))
        dd = d[es]
        yy = dd.ysel.where(dd.sel == 1).to_numpy(float)
        L = leebounds_port(yy, dd.treat.to_numpy(float))
        spl = sp.lee_bounds(dd.assign(ysp=yy), y="ysp", treat="treat", selection="sel", n_bootstrap=200)
        rows.append({"outcome": v + "1", "label": clean_label(labels.get(v + "1")),
                     "lower": L["lower"], "se_lower": L["se_lower"], "upper": L["upper"], "se_upper": L["se_upper"],
                     "trim": L["trim"], "sp_lee_lower": spl.model_info["lower_bound"],
                     "sp_lee_upper": spl.model_info["upper_bound"], "sp_lee_se_midpoint": float(spl.se)})
    return pd.DataFrame(rows)


def main():
    df, labels = load()
    t3, j3 = table3(df, labels)
    t3c = t3.copy()
    for c, p in j3.items():
        t3c[f"c{c}_joint_p"] = p
    t3c.to_csv(OUT / "table3.csv", index=False)
    md = []
    for _, r in t3.iterrows():
        cells = [r.label]
        for c in (1, 2, 3, 4):
            cells.append(f"{fmt(r[f'c{c}_b'], r[f'c{c}_p'])} ({r[f'c{c}_se']:.2f})")
        cells += [fmt(r.c5_p, r.c5_p), fmt(r.c6_p, r.c6_p)]
        for c in (7, 8, 9, 10):
            cells.append(f"{fmt(r[f'c{c}_b'], r[f'c{c}_p'])} ({r[f'c{c}_se']:.2f})")
        md.append(cells)
    md.append(["Joint test (p-value)"] + [fmt(j3[c], j3[c]) for c in (1, 2, 3, 4)] + [""] * 6)
    cols = ["Outcome", "(1) All HH", "(2) All HH +ctrl", "(3) Thatched", "(4) Thatched +ctrl",
            "(5) p (1)=(3)", "(6) p (2)=(4)", "(7) Lee lower", "(8) Lee upper", "(9) HM lower", "(10) HM upper"]
    write_md(pd.DataFrame(md, columns=cols), OUT / "table3.md", "Table III (StatsPAI)",
             "Cols 1-4 sp.feols cluster(village); 5-6 suest-equivalent Wald; 7-8 exact Python port of "
             "leebounds.ado with 100 stratified bootstrap reps (SEs are Monte-Carlo); 9-10 sp.regress HC1.\n\n"
             "sp.lee_bounds on the same samples (lower, upper):\n\n" +
             t3[["label", "c7_b", "c8_b", "sp_lee_lower", "sp_lee_upper"]].round(3).to_markdown(index=False))

    # pre-erratum psych index (weighted) check
    t3w, _ = table3(df, labels, weighted_psych=True, reps=2)
    pr = t3w[t3w.outcome == "psy_index_z1"][["c1_b", "c1_se", "c2_b", "c2_se", "c3_b", "c3_se", "c4_b", "c4_se"]]
    pr.to_csv(OUT / "table3_psych_preerratum_weighted.csv", index=False)

    la = lee_attrition(df, labels)
    la.to_csv(OUT / "oa_leebounds_attrition.csv", index=False)
    write_md(la.round(3), OUT / "oa_leebounds_attrition.md", "OA Lee bounds for endline attrition (treat vs spillover)",
             "lower/upper/se: exact port of leebounds.ado analytic SEs; sp_lee_*: sp.lee_bounds.")
    print(t3.round(3).T.to_string())
    print(pr)
    print(la.round(3).to_string())


if __name__ == "__main__":
    main()
