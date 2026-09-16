"""StatsPAI replication of Haushofer & Shapiro (QJE 2016), Tables I, II, IV, V, VI and A.1.

Mirrors Program/Do/UCT_Baseline_Balance.do, UCT_Endline_Regs_Main.do,
UCT_Endline_Regs_Ent+Assets_Main.do and UCT_PowerCalcs.do.

Run:  /usr/local/bin/python3.13 Program/statspai/replicate_main_tables.py [--iters 10000]
Outputs: Results/statspai/table{1,2,4,5,6,A1}.{csv,md}, fig_table2_coefplot.png
"""
from __future__ import annotations

import argparse
import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statspai as sp

from uct_common import (ARMS, ARM_LABEL, INDICES, PSYVARS, CONS_FINAL, ASSETS_SHORT, ENT_SHORT,
                        OUT, areg, clean_label, coef, fmt, influence_for, load, stepdown_perm,
                        suest_wald, write_md)


# ------------------------------------------------------------------ generic "maintable" (Main.do)
def maintable(df, labels, varlist, hhcase=True, fwer=False, iters=10000, baseline=False, name=""):
    """baseline=False -> UCT_Endline_Regs_Main.do ; baseline=True -> UCT_Baseline_Balance.do"""
    if baseline:
        use = df[df.baselinedate.notna()].copy()
        suffix = "0"
    else:
        use = df[(df.purecontrol != 1) & df.endlinedate.notna()].copy()
        suffix = "1"
    use["include"] = 1
    if hhcase:
        use.loc[use.maleres == 1, "include"] = 0

    rows = []
    # ---- FWER (stepdown) ------------------------------------------------------------
    fwer_p = {}
    if fwer:
        sd = use.copy()
        ys = []
        ctrl = {}
        for v in varlist:
            y = v + suffix
            if v != "psy_index_z":
                sd.loc[sd.maleres == 1, y] = np.nan
            ys.append(y)
            ctrl[y] = [] if baseline else [v + "_full0", v + "_miss0"]
        for col, x, xs in ARMS:
            t0 = time.time()
            padj, _ = stepdown_perm(sd, ys, x, [z for z in xs if z != x], ctrl, "surveyid", "village",
                                    iters=iters)
            fwer_p[col] = padj
            print(f"  [{name}] stepdown {col}: {time.time()-t0:.1f}s")

    # ---- per-outcome regressions -----------------------------------------------------
    for v in varlist:
        y = v + suffix
        d = use.copy()
        if v == "psy_index_z":
            d["include"] = 1
        if baseline:
            d = d[d[y].notna()]
            cm = d.loc[d.spillover == 1, y]               # `sum y if spillover` (no include)
        else:
            cm = d.loc[(d.spillover == 1) & (d.include == 1), y]
        dd = d[d.include == 1]
        ctr = [] if baseline else [v + "_full0", v + "_miss0"]
        rec = {"outcome": y, "label": clean_label(labels.get(y, y)),
               "control_mean": cm.mean(), "control_sd": cm.std(), "N": int(dd[y].notna().sum())}
        for col, x, xs in ARMS:
            res, est = areg(dd, y, xs, ctr)
            b, se, p = coef(res, x)
            rec[f"{col}_b"], rec[f"{col}_se"], rec[f"{col}_p"] = b, se, p
            if fwer:
                rec[f"{col}_fwer"] = float(fwer_p[col][y])
        rows.append(rec)
    out = pd.DataFrame(rows)

    # ---- joint test row: suest across outcomes ------------------------------------------
    joint = {}
    for col, x, xs in ARMS:
        pieces = []
        d = use.copy()
        for v in varlist:
            y = v + suffix
            if hhcase:
                d.loc[d.maleres == 1, "include"] = 1 if v == "psy_index_z" else 0
            dd = d[d.include == 1]
            ctr = [] if baseline else [c for c in (v + "_full0", v + "_miss0")]
            b, IF = influence_for(dd, y, x, [z for z in xs if z != x] + ctr, "village")
            pieces.append((b, IF))
        chi2, df_, p, _ = suest_wald(use, pieces, "surveyid")
        joint[col] = p
    return out, joint


def to_paper_md(out, joint, fwer=False):
    lines = []
    for _, r in out.iterrows():
        cells = [r.label, f"{r.control_mean:.2f} ({r.control_sd:.2f})"]
        for col, *_ in ARMS:
            s = f"{fmt(r[f'{col}_b'], r[f'{col}_p'])} ({r[f'{col}_se']:.2f})"
            if fwer:
                s += f" [{fmt(r[f'{col}_fwer'], r[f'{col}_fwer'])}]"
            cells.append(s)
        cells.append(str(r.N))
        lines.append(cells)
    lines.append(["Joint test (p-value)", ""] + [fmt(joint[c], joint[c]) for c, *_ in ARMS] + [""])
    return pd.DataFrame(lines, columns=["Outcome", "Control mean (SD)"] +
                        [ARM_LABEL[c] for c, *_ in ARMS] + ["N"])


# ------------------------------------------------------------------ Table VI (Ent+Assets_Main.do)
def table6(df, labels):
    use = df[(df.maleres != 1) & df.endlinedate.notna() & (df.purecontrol != 1)].copy()
    rows, joints = [], {}
    for panel, group in (("A: Assets", ASSETS_SHORT), ("B: Business activities", ENT_SHORT)):
        for v in group:
            y = v + "1"
            cm = use.loc[use.spillover == 1, y]
            rec = {"panel": panel, "outcome": y, "label": clean_label(labels.get(y, y)),
                   "control_mean": cm.mean(), "control_sd": cm.std(), "N": int(use[y].notna().sum())}
            for col, x, xs in ARMS:
                res, _ = areg(use, y, xs, [v + "_full0", v + "_miss0"])
                rec[f"{col}_b"], rec[f"{col}_se"], rec[f"{col}_p"] = coef(res, x)
            rows.append(rec)
        for col, x, xs in ARMS:
            pieces = [influence_for(use, v + "1", x, [z for z in xs if z != x] + [v + "_full0", v + "_miss0"],
                                    "village") for v in group]
            joints[(panel, col)] = suest_wald(use, pieces, "surveyid")[2]
    return pd.DataFrame(rows), joints


# ------------------------------------------------------------------ Table A.1 (PowerCalcs.do)
def tableA1(df, labels, varlist=INDICES):
    base = df[df.endlinedate.notna() & (df.purecontrol != 1)]
    rows = []
    for v in varlist:
        y = v + "1"
        d = base if v == "psy_index_z" else base[base.maleres != 1]
        cmr = round(d.loc[d.spillover == 1, y].mean(), 2)
        if v == "psy_lncort_mean_clean":
            cmr = 2.46
        rec = {"outcome": y, "label": clean_label(labels.get(y, y)), "control_mean": cmr,
               "control_sd": d.loc[d.spillover == 1, y].std()}
        for col, x, xs in ARMS:
            res, _ = areg(d, y, xs, [v + "_full0", v + "_miss0"])
            mde = 2.8 * float(res.std_errors[x])
            rec[f"{col}_mde"] = mde
            rec[f"{col}_pct"] = abs(mde / cmr) if abs(cmr) > 0 else np.nan
        rows.append(rec)
    return pd.DataFrame(rows)


def coefplot(t2: pd.DataFrame, path):
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.6), gridspec_kw={"width_ratios": [1, 1.4]})
    usd = t2[t2.outcome.isin(["asset_total_ppp1", "cons_nondurable_ppp1", "ent_total_rev_ppp1"])]
    z = t2[~t2.outcome.isin(usd.outcome)]
    for ax, sub, xl in ((axes[0], usd, "PPP USD"), (axes[1], z, "SD units")):
        ypos = np.arange(len(sub))[::-1]
        for k, (col, *_rest) in enumerate(ARMS):
            off = (k - 1.5) * 0.18
            ax.errorbar(sub[f"{col}_b"], ypos + off, xerr=1.96 * sub[f"{col}_se"], fmt="o", ms=4,
                        capsize=2, label=ARM_LABEL[col])
        ax.axvline(0, color="grey", lw=0.8)
        ax.set_yticks(ypos)
        ax.set_yticklabels(sub.label)
        ax.set_xlabel(xl)
    axes[1].legend(fontsize=8, loc="lower right")
    fig.suptitle("Table II replicated with StatsPAI: treatment and arm effects on index outcomes (95% CI)")
    fig.tight_layout()
    fig.savefig(path, dpi=160)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iters", type=int, default=10000)
    args = ap.parse_args()
    df, labels = load()
    t_start = time.time()

    print("Table I (baseline balance)")
    t1, j1 = maintable(df, labels, INDICES, fwer=True, iters=args.iters, baseline=True, name="T1")
    print("Table II (index outcomes)")
    t2, j2 = maintable(df, labels, INDICES, fwer=True, iters=args.iters, name="T2")
    print("Table IV (psych)")
    t4, j4 = maintable(df, labels, PSYVARS, hhcase=False, name="T4")
    print("Table V (consumption)")
    t5, j5 = maintable(df, labels, CONS_FINAL, name="T5")
    print("Table VI (assets & enterprise)")
    t6, j6 = table6(df, labels)
    print("Table A.1 (MDEs)")
    ta1 = tableA1(df, labels)

    for tag, t, j, fw in (("table1", t1, j1, True), ("table2", t2, j2, True), ("table4", t4, j4, False),
                          ("table5", t5, j5, False)):
        tt = t.copy()
        for c, p in j.items():
            tt[f"{c}_joint_p"] = p
        tt.to_csv(OUT / f"{tag}.csv", index=False)
        write_md(to_paper_md(t, j, fwer=fw), OUT / f"{tag}.md", f"{tag} (StatsPAI)",
                 "coef (SE) [FWER p, author's stepdown ported, 10,000 permutations]; stars from "
                 "cluster(surveyid) t(G-1) p-values; joint test = suest-equivalent Wald chi2.")
    t6c = t6.copy()
    for (panel, c), p in j6.items():
        t6c.loc[t6c.panel == panel, f"{c}_joint_p"] = p
    t6c.to_csv(OUT / "table6.csv", index=False)
    md6 = []
    for panel in t6.panel.unique():
        sub = t6[t6.panel == panel]
        jj = {c: j6[(panel, c)] for c, *_ in ARMS}
        md = to_paper_md(sub, jj)
        md.insert(0, "Panel", panel)
        md6.append(md)
    write_md(pd.concat(md6), OUT / "table6.md", "table6 (StatsPAI)")
    ta1.to_csv(OUT / "tableA1.csv", index=False)
    write_md(ta1.round(2), OUT / "tableA1.md", "Table A.1 MDEs (StatsPAI)")

    # ---- StatsPAI's built-in multiple-testing tools on Table II (comparison with stepdown)
    mt = []
    for col, *_ in ARMS:
        p = t2[f"{col}_p"].to_numpy()
        mt.append(pd.DataFrame({"arm": col, "outcome": t2.outcome, "p_naive": p,
                                "p_bonferroni": sp.bonferroni(p), "p_holm": sp.holm(p),
                                "p_bh": sp.benjamini_hochberg(p),
                                "p_fwer_author_stepdown_port": t2[f"{col}_fwer"]}))
    mt = pd.concat(mt)
    # sp.romano_wolf needs one common sample and common controls: use the 6 household-level
    # indices (female-respondent rows, complete cases) + village dummies + all baseline controls
    use = df[(df.purecontrol != 1) & df.endlinedate.notna() & (df.maleres != 1)].copy()
    hh = INDICES[:6]
    vd = pd.get_dummies(use.village.astype(int), prefix="v", drop_first=True, dtype=float)
    use = pd.concat([use, vd], axis=1)
    ctrls = [f"{v}_full0" for v in hh] + [f"{v}_miss0" for v in hh if use[f"{v}_miss0"].sum() > 0] + list(vd.columns)
    t0 = time.time()
    rw = sp.romano_wolf(use, y=[v + "1" for v in hh], x="treat", controls=ctrls, cluster="surveyid",
                        n_boot=2000, seed=20160916)
    rwt = rw.table.copy()
    rwt["note"] = f"sp.romano_wolf, complete cases N={rw.n_obs}, common controls, cluster bootstrap 2000 ({time.time()-t0:.0f}s)"
    rwt.to_csv(OUT / "table2_romano_wolf_extension.csv", index=False)
    mt.to_csv(OUT / "table2_multiple_testing.csv", index=False)
    write_md(mt.round(4), OUT / "table2_multiple_testing.md", "Table II: multiple-testing adjustments",
             "Bonferroni/Holm/BH via sp.bonferroni/sp.holm/sp.benjamini_hochberg on the naive p-values; "
             "last column = port of the authors' permutation stepdown (Westfall-Young style).\n\n"
             "## sp.romano_wolf (extension, common sample)\n\n" + rwt.round(4).to_markdown(index=False))

    coefplot(t2, OUT / "fig_table2_coefplot.png")
    print(f"done in {time.time()-t_start:.0f}s")


if __name__ == "__main__":
    main()
