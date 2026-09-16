"""Quick check of a StatsPAI csv against published values: python3.13 check_vs_paper.py table_VIII"""
import sys, pandas as pd
from paper_values import paper_long
from common import OUT
s = pd.read_csv(OUT / f"{sys.argv[1]}.csv"); s["col"] = s["col"].astype(int)
m = paper_long().merge(s, on=["table", "col", "var"], how="inner")
m["ok"] = ((m.coef - m.paper_coef).abs() <= 0.0005 + 1e-9) & ((m.se - m.paper_se).abs() <= 0.0005 + 1e-9) & (m.N == m.paper_N)
print(len(m), "cells, matched to 3 d.p.:", int(m.ok.sum()))
print(m[~m.ok][["table", "col", "var", "paper_coef", "coef", "paper_se", "se", "paper_N", "N"]].round(4).to_string())
