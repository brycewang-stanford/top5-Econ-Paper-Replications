"""Table IX: spillovers to never-contracted firms (Analysis.do section 14).

Panel A : xtevent n_software_cum if n_contracts==0, policyvar(event) panelvar(sub_fe) timevar(qofd) w(-8 8) cl(place)
          -- xtevent **1.0.0** (Aug 2021).  With a non-binary policy variable v1.0.0 builds
             _k_eq_m{k} = F^k z - F^(k-1) z (k=1..8), _k_eq_p{k} = L^k z - L^(k+1) z (k=0..8),
             endpoints _k_eq_m9 = 1 - F^8 z and _k_eq_p9 = L^9 z (missing kept missing),
             omits _k_eq_m1, and runs  areg y _k* i.qofd, absorb(sub_fe) vce(cluster place).
          StatsPAI has no xtevent-style continuous-policy event study (sp.event_study needs a
          binary treatment date), so the design matrix is generated in Python and estimated with
          sp.feols (firm + quarter FE).  Reported coefficient: _k_eq_p8.
Panels B/C: reghdfe n_software b(23).quarter_to_first if n_contracts==0, absorb(firm_contract qofd) cl(place)
          -> 32.quarter_to_first, with Stata's sequential collinearity omission (common.stata_keep_order).
"""
from common import *

TYPES = ["ALL", "GOVERNMENT", "BUSINESS"]


def xtevent_v1_design(d, y, z, i, t, lw=8, rw=8):
    d = d.sort_values([i, t]).copy()
    full = d.set_index([i, t])[z]

    def shift(k):  # value of z at t+k within panel, respecting gaps (time-series operators)
        idx = pd.MultiIndex.from_arrays([d[i].values, d[t].values + k])
        return pd.Series(full.reindex(idx).values, index=d.index)

    cols = []
    for k in range(lw, 0, -1):
        c = f"_k_eq_m{k}"
        d[c] = (shift(k) - shift(k - 1)).fillna(0.0)
        cols.append(c)
    for k in range(0, rw + 1):
        c = f"_k_eq_p{k}"
        d[c] = (shift(-k) - shift(-(k + 1))).fillna(0.0)
        cols.append(c)
    d[f"_k_eq_m{lw+1}"] = 1 - shift(lw)          # v1.0.0 formula (sic) for non-binary policy
    d[f"_k_eq_p{rw+1}"] = shift(-(rw + 1))
    cols = [f"_k_eq_m{lw+1}"] + cols + [f"_k_eq_p{rw+1}"]
    cols = [c for c in cols if c != "_k_eq_m1"]
    return d, cols


def panel_a():
    rows = []
    for t in TYPES:
        d = read_dta(XDATA / f"s14_A_{t}.dta")
        d = d[d.n_contracts == 0]
        d, cols = xtevent_v1_design(d, "n_software_cum", "event", "sub_fe", "qofd")
        d = d.dropna(subset=["n_software_cum", "place"] + cols)
        keep = stata_keep_order(d, cols, ["sub_fe", "qofd"])
        # areg: absorbed firm dummies count in K (no nesting adjustment); i.qofd are regular regressors (+ constant)
        b, se, info, res = hdfe("n_software_cum ~ " + " + ".join(keep), d, ["sub_fe", "qofd"], cluster="place",
                                singletons=False, stata="reghdfe")
        N, G = info["N"], info["G"]
        # areg K = rank(regressors incl. i.qofd dummies) + constant + (firms - 1); rank computed after firm demeaning
        tq = []
        for lev in sorted(d.qofd.unique())[1:]:
            c = f"t_{int(lev)}"; d[c] = (d.qofd == lev).astype(float); tq.append(c)
        rank = len(stata_keep_order(d, keep + tq, ["sub_fe"]))
        k_areg = rank + 1 + d.sub_fe.nunique() - 1
        raw_se = se / np.sqrt(info["factor"])
        fac_areg = (N - 1) / (N - k_areg) * G / (G - 1)
        rows.append(dict(table="IX", panel="A", column=TYPES.index(t) + 1, outcome=t, term="8 quarters after unrest (_k_eq_p8)",
                         coef=b["_k_eq_p8"], se=raw_se["_k_eq_p8"] * np.sqrt(fac_areg), se_reghdfe_small=se["_k_eq_p8"],
                         N=N, clusters=G, estimator="Python xtevent-1.0.0 design + sp.feols (firm+quarter FE), areg-style CRV1"))
    return rows


def panel_bc(panel):
    rows = []
    for t in TYPES:
        d = read_dta(XDATA / f"s14_{panel}_{t}.dta")
        d = d[d.n_contracts == 0].dropna(subset=["n_software", "quarter_to_first", "place"])
        cols = []
        for lev in sorted(d.quarter_to_first.unique()):
            if int(lev) == 23:
                continue
            c = f"q_{int(lev)}"
            d[c] = (d.quarter_to_first == lev).astype(float)
            cols.append(c)
        d = drop_singletons(d, ["firm_contract", "qofd"])
        keep = stata_keep_order(d, cols, ["firm_contract", "qofd"])
        b, se, info, _ = hdfe("n_software ~ " + " + ".join(keep), d, ["firm_contract", "qofd"], cluster="place",
                              singletons=False, stata="reghdfe")
        rows.append(dict(table="IX", panel=panel, column=TYPES.index(t) + 1, outcome=t, term="8 quarters after contract (32.quarter_to_first)",
                         coef=b.get("q_32", np.nan), se=se.get("q_32", np.nan), N=info["N"], clusters=info["G"],
                         omitted=";".join(c for c in cols if c not in keep),
                         estimator="sp.feols (firm-contract + quarter FE, CRV1 place, reghdfe small)"))
    return rows


def main():
    rows = panel_a() + panel_bc("B") + panel_bc("C")
    out = save_rows(rows, "table9")
    print(out[["panel", "column", "coef", "se", "N", "clusters"]].round(3).to_string())
    return out


if __name__ == "__main__":
    main()
