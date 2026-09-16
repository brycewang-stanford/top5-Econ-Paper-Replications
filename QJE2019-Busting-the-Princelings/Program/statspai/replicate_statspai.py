"""End-to-end StatsPAI replication of Chen & Kung (2019, QJE).

    cd Program/statspai && python3.13 replicate_statspai.py            # everything
    python3.13 replicate_statspai.py price firm                         # a subset

Steps (outputs in Results/statspai/):
  descriptive  Table VII, Figures IV & VII                  (seconds)
  price        Tables III, V, X; Figure V                   (~12 min, sp.feols / pyfixest)
  firm         Table VI + Figure VI (sp.feols), Table XI (sp.hdfe_ols)   (~5-15 min, 12 GB RAM peak)
  promotion    Tables VIII, IX, XII (sp.oprobit, sp.feols)  (VIII ~2 min; IX+XII several hours,
                                                             sp.oprobit is slow with ~300 dummies)
  modern       extensions: staggered DID (TWFE/Bacon/CS/SA/BJS), HonestDiD, pre-trend power
  compare      builds Results/comparison.md
"""
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
PY = sys.executable
STEPS = {
    "descriptive": [["rep_descriptive.py"]],
    "price": [["rep_price.py"]],
    "firm": [["rep_firm.py", "VI", "XI"]],
    "promotion": [["rep_promotion.py", "VIII", "IX", "XII"]],
    "modern": [["modern_did.py"]],
    "compare": [["make_comparison.py"]],
}

if __name__ == "__main__":
    which = sys.argv[1:] or list(STEPS)
    log = []
    for step in which:
        for cmd in STEPS[step]:
            t0 = time.time()
            rc = subprocess.call([PY] + cmd, cwd=HERE)
            log.append((step, " ".join(cmd), rc, round(time.time() - t0, 1)))
            print(f"== {step}: {' '.join(cmd)} rc={rc} {log[-1][3]}s", flush=True)
    out = HERE.parents[1] / "Results" / "statspai" / "run_statspai_steps.csv"
    with open(out, "a") as f:
        for row in log:
            f.write(",".join(map(str, row)) + "\n")
