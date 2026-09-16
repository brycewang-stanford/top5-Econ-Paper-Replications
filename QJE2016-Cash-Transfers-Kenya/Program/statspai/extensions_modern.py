"""Modern-methods EXTENSIONS (not part of the published paper) for Haushofer & Shapiro (QJE 2016).

1. Randomization inference for Table II col (2) (within-village permutation of `treat`, the
   actual second-stage design) and Table III col (1) (village-level permutation of spillover
   vs pure control); plus sp.ri_test (unstratified / cluster) for comparison.
2. Wild cluster bootstrap (sp.wild_cluster_bootstrap) for the village-clustered spillover
   estimates of Table III col (1).
3. Heterogeneous treatment effects with sp.causal_forest on baseline covariates.
4. Quantile treatment effects (OA Section 14) with sp.qreg, re-creating the OA quantile figure.
5. Baseline covariate balance with sp.balance_diagnostics (standardised mean differences).

Run: /usr/local/bin/python3.13 Program/statspai/extensions_modern.py
"""
from __future__ import annotations

import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statspai as sp

from uct_common import BASELINECONTROLS, INDICES, OUT, clean_label, load, write_md

N_PERM = 2000
SEED = 20160916


def within_village_coef(y, t, ctrl, village):
    """areg-style coefficient on t after absorbing village FE and controls (FWL)."""
    def dm(a):
        return a - pd.Series(a).groupby(village).transform("mean").to_numpy()
    W = np.column_stack([dm(c) for c in ctrl.T]) if ctrl.shape[1] else np.empty((len(y), 0))
    yt, tt = dm(y), dm(t)
    if W.shape[1]:
        P = W @ np.linalg.lstsq(W, np.column_stack([yt, tt]), rcond=None)[0]
        yt, tt = yt - P[:, 0], tt - P[:, 1]
    return (tt @ yt) / (tt @ tt)


def ri_table2(df, labels):
    rng = np.random.default_rng(SEED)
    base = df[(df.purecontrol != 1) & df.endlinedate.notna()]
    rows = []
    for v in INDICES:
        y = v + "1"
        d = base if v == "psy_index_z" else base[base.maleres != 1]
        ctr = [v + "_full0"] + ([v + "_miss0"] if d[v + "_miss0"].sum() > 0 else [])
        d = d.dropna(subset=[y, *ctr]).reset_index(drop=True)
        vil = d.village.to_numpy()
        Y, T, C = d[y].to_numpy(float), d.treat.to_numpy(float), d[ctr].to_numpy(float)
        b0 = within_village_coef(Y, T, C, vil)
        # permute treatment status across HOUSEHOLDS within village (individual rows of the
        # same household move together)
        hh = d.groupby("surveyid").agg(village=("village", "first"), treat=("treat", "first")).reset_index()
        draws = np.empty(N_PERM)
        idx = d.surveyid.map(dict(zip(hh.surveyid, range(len(hh))))).to_numpy()
        groups = [np.where(hh.village.to_numpy() == g)[0] for g in hh.village.unique()]
        th = hh.treat.to_numpy()
        for k in range(N_PERM):
            tp = th.copy()
            for g in groups:
                tp[g] = rng.permutation(th[g])
            draws[k] = within_village_coef(Y, tp[idx], C, vil)
        p_ri = (np.abs(draws) >= abs(b0) - 1e-12).mean()
        spri = sp.ri_test(d, y=y, treat="treat", stat="diff_means", n_perms=N_PERM, seed=SEED)
        rows.append({"outcome": y, "label": clean_label(labels.get(y)), "coef_areg": b0,
                     "p_ri_within_village": p_ri, "sp_ri_test_diffmeans_unstratified_p": spri["p_value"],
                     "sp_ri_test_observed_diffmeans": spri["observed"]})
    return pd.DataFrame(rows)


def spill_ri_wild(df, labels):
    use = df[(df.treat != 1) & df.endlinedate.notna()].copy()
    roof = use.asset_niceroof1 == 1
    use.loc[roof, "asset_total_ppp1"] -= use.loc[roof, "asset_valroof_ppp1"]
    rows = []
    for v in INDICES:
        y = v + "1"
        d = use if v == "psy_index_z" else use[use.maleres != 1]
        d = d.dropna(subset=[y])
        w = sp.wild_cluster_bootstrap(d, y=y, x=["spillover"], cluster="village", n_boot=1999, seed=SEED)
        ri = sp.ri_test(d, y=y, treat="spillover", stat="diff_means", n_perms=N_PERM, cluster="village", seed=SEED)
        rows.append({"outcome": y, "label": clean_label(labels.get(y)), "beta": w["beta_hat"],
                     "se_cluster_village": w["se_cluster"], "p_cluster": w["p_cluster"],
                     "p_wild_rademacher": w["p_boot"], "ci_wild_lo": w["ci_boot"][0], "ci_wild_hi": w["ci_boot"][1],
                     "p_ri_village_level": ri["p_value"], "n_villages": w["n_clusters"]})
    return pd.DataFrame(rows)


def forest(df, labels):
    use = df[(df.purecontrol != 1) & df.endlinedate.notna()]
    X = ["b_age", "b_married", "b_edu", "b_children", "b_hhsize", "asset_total_ppp0", "cons_total_ppp0",
         "ent_wagelabor0", "ent_ownfarm0", "ent_nonagbusiness0", "femaleres"]
    rows, imp = [], []
    for v in ["asset_total_ppp", "cons_nondurable_ppp", "fs_hhfoodindexnew", "psy_index_z"]:
        y = v + "1"
        d = use if v == "psy_index_z" else use[use.maleres != 1]
        d = d.dropna(subset=[y, *X]).reset_index(drop=True)
        cf = sp.causal_forest(data=d, y=y, d="treat", x=X, n_estimators=1000, min_samples_leaf=10,
                              random_state=SEED)
        tau = np.asarray(cf.effect(d[X].to_numpy(float))).ravel()
        ate = cf.ate() if callable(getattr(cf, "ate", None)) else cf.ate
        q = pd.qcut(d.asset_total_ppp0.rank(method="first"), 4, labels=["Q1", "Q2", "Q3", "Q4"])
        by_q = pd.Series(tau).groupby(q.to_numpy()).mean()
        vi = cf.variable_importance() if callable(getattr(cf, "variable_importance", None)) else cf.variable_importance
        vi = np.asarray(vi).ravel()
        rows.append({"outcome": y, "label": clean_label(labels.get(y)), "N": len(d),
                     "forest_ate": float(np.asarray(ate).ravel()[0]) if np.size(ate) else np.nan,
                     "cate_mean": tau.mean(), "cate_sd": tau.std(),
                     **{f"cate_baseline_asset_{k}": val for k, val in by_q.items()}})
        imp.append(pd.Series(vi[:len(X)], index=X, name=y))
    return pd.DataFrame(rows), pd.concat(imp, axis=1)


def quantiles(df, labels):
    base = df[(df.purecontrol != 1) & df.endlinedate.notna()]
    qs = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    rows = []
    for v in INDICES:
        y = v + "1"
        d = base if v == "psy_index_z" else base[base.maleres != 1]
        ctr = [v + "_full0"] + ([v + "_miss0"] if d[v + "_miss0"].sum() > 0 else [])
        d = d.dropna(subset=[y, *ctr])
        for q in qs:
            r = sp.qreg(d, formula=f"{y} ~ treat + " + " + ".join(ctr), quantile=q)
            # sp.qreg returns a CausalResult whose params hold only the FIRST regressor, labelled
            # "Q(<q>) treat" (API friction, see note)
            key = [k for k in r.params.index if k.endswith("treat")][0]
            rows.append({"outcome": y, "label": clean_label(labels.get(y)), "q": q,
                         "b": float(r.params[key]), "se": float(r.std_errors[key])})
    out = pd.DataFrame(rows)
    fig, axes = plt.subplots(2, 4, figsize=(14, 6.5))
    for ax, (y, g) in zip(axes.ravel(), out.groupby("outcome", sort=False)):
        ax.fill_between(g.q, g.b - 1.96 * g.se, g.b + 1.96 * g.se, alpha=0.25)
        ax.plot(g.q, g.b, "o-", ms=3)
        ax.axhline(0, color="grey", lw=0.8)
        ax.set_title(g.label.iloc[0], fontsize=9)
        ax.set_xlabel("quantile", fontsize=8)
    fig.suptitle("Quantile treatment effects (OA Section 14) re-estimated with sp.qreg (95% CI, analytic SE)")
    fig.tight_layout()
    fig.savefig(OUT / "fig_oa_quantile_effects.png", dpi=150)
    plt.close(fig)
    return out


def balance(df):
    d = df[(df.purecontrol != 1) & df.baselinedate.notna() & (df.maleres != 1)]
    d = d.dropna(subset=BASELINECONTROLS)
    res = sp.balance_diagnostics(d, treatment="treat", covariates=BASELINECONTROLS)
    for attr in ("table", "balance_table", "summary_table"):
        if isinstance(getattr(res, attr, None), pd.DataFrame):
            return getattr(res, attr)
    s = res.summary() if callable(getattr(res, "summary", None)) else str(res)
    return pd.DataFrame({"summary": [str(s)]})


def main():
    df, labels = load()
    t0 = time.time()
    ri2 = ri_table2(df, labels); print("RI table 2", time.time() - t0)
    sw = spill_ri_wild(df, labels); print("spillover RI/wild", time.time() - t0)
    cf, imp = forest(df, labels); print("forest", time.time() - t0)
    qr = quantiles(df, labels); print("qreg", time.time() - t0)
    bal = balance(df); print("balance", time.time() - t0)
    ri2.to_csv(OUT / "ext_ri_table2.csv", index=False)
    sw.to_csv(OUT / "ext_spillover_ri_wild.csv", index=False)
    cf.to_csv(OUT / "ext_causal_forest.csv", index=False)
    imp.to_csv(OUT / "ext_causal_forest_importance.csv")
    qr.to_csv(OUT / "ext_quantile_effects.csv", index=False)
    bal.to_csv(OUT / "ext_balance_diagnostics.csv")
    with open(OUT / "extensions.md", "w") as f:
        f.write("# Modern-methods extensions (NOT replication)\n\n")
        f.write(f"## 1. Randomization inference, Table II col (2) ({N_PERM} permutations)\n\n")
        f.write("`p_ri_within_village`: households re-randomised to treatment within village (the actual design), "
                "statistic = areg coefficient with baseline-outcome controls. `sp.ri_test` can only permute the whole "
                "vector (no strata), so its diff-in-means p is shown for contrast.\n\n")
        f.write(ri2.round(4).to_markdown(index=False))
        f.write("\n\n## 2. Table III col (1): village-clustered SE, wild cluster bootstrap, village-level RI\n\n")
        f.write(sw.round(4).to_markdown(index=False))
        f.write("\n\n## 3. Causal forest CATEs (sp.causal_forest, 1000 trees)\n\n")
        f.write(cf.round(3).to_markdown(index=False))
        f.write("\n\nVariable importance:\n\n" + imp.round(3).to_markdown())
        f.write("\n\n## 4. Quantile treatment effects (sp.qreg) -> fig_oa_quantile_effects.png\n\n")
        f.write(qr.pivot(index="label", columns="q", values="b").round(2).to_markdown())
        f.write("\n\n## 5. Baseline balance (sp.balance_diagnostics, treat vs spillover, female-respondent rows)\n\n")
        f.write(bal.round(3).to_markdown())
        f.write("\n")
    print(f"done {time.time()-t0:.0f}s")


if __name__ == "__main__":
    main()
