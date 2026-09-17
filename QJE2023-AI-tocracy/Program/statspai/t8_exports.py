"""Table VIII: public-security first contract -> newly exporting firm (Analysis.do section 13).

ivreghdfe export_diff police_data scale [software] [year_founded] if ever_contract==1
          [aweight=sub_weight], robust [absorb(contract_ym place)]
ivreghdfe defaults to `small`: robust V * N/(N-K), singletons dropped when FE are absorbed.
"""
from common import *


def main():
    d = read_dta(DATA / "export_regression.dta")
    d = d[d.ever_contract == 1].copy()
    specs = {
        1: ("export_diff ~ police_data + scale", []),
        2: ("export_diff ~ police_data + scale", ["contract_ym", "place"]),
        3: ("export_diff ~ police_data + scale + software", ["contract_ym", "place"]),
        4: ("export_diff ~ police_data + scale + software + year_founded", ["contract_ym", "place"]),
    }
    rows = []
    for col, (fml, fes) in specs.items():
        b, se, info, _ = hdfe(fml, d, fes, robust=True, weights="sub_weight")
        rows.append(dict(table="VIII", panel="", column=col, term="Public security", coef=b["police_data"],
                         se=se["police_data"], N=info["N"], clusters=None,
                         estimator="sp.feols WLS (aweight), HC x ivreghdfe small, singletons dropped"))
    out = save_rows(rows, "table8")
    print(out[["column", "coef", "se", "N"]].round(4))
    return out


if __name__ == "__main__":
    main()
