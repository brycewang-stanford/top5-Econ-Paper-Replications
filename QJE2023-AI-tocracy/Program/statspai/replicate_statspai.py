"""End-to-end StatsPAI replication of Beraja, Kao, Yang & Yuchtman (2023, QJE) "AI-tocracy".

    /usr/local/bin/python3.13 Program/statspai/replicate_statspai.py [--skip-lasso] [--skip-ext]

Prerequisite: the regression-ready panels in Data/Intermediate/statspai/ (built once by
Program/statspai/run_export.sh, which runs a hooked copy of the author's Analysis.do).
"""
import sys
import time

import build_comparison
import extensions_modern
import figures
import t2_t3_unrest_to_procurement as t23
import t4_t5_ai_and_unrest as t45
import t6_t7_firm_eventstudy as t67
import t8_exports as t8
import t9_spillovers as t9

steps = [
    ("Tables II-III", lambda: t23.main(lasso="--skip-lasso" not in sys.argv)),
    ("Tables IV-V", t45.main),
    ("Tables VI-VII (+Figure V/VI profiles)", t67.main),
    ("Table VIII", t8.main),
    ("Table IX", t9.main),
    ("Figures II and V", figures.main),
]
if "--skip-ext" not in sys.argv:
    steps.append(("Modern extensions", extensions_modern.main))
steps.append(("comparison.md", build_comparison.main))

t_all = time.time()
for name, fn in steps:
    t0 = time.time()
    print(f"\n===== {name} =====", flush=True)
    fn()
    print(f"----- {name}: {time.time() - t0:.1f}s", flush=True)
print(f"\nTotal {time.time() - t_all:.1f}s")
