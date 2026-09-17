
## Original-code runs: what was run and how

* Wrapper `Program/run_original.do` (globals only; **no edits to author do-files**). One Stata batch per step via
  `Program/run_steps_sequential.sh` (Stata `-b` names its log after the whole argument string; long step lists exceed
  the 255-character filename limit and Stata exits silently — found the hard way).
* Started from the shipped intermediate datasets. The data-construction steps need CPS-MORG microdata, BLS QCEW
  extracts and state administrative records that are **not** in the package → not run.
* The authors' `.ster` files were copied into `Results/estimates/` first (`cp -n`) because several shipped do-files
  `est use` estimates whose regressions are commented out (Table 2 cols 1–5, Table 4, appendix tables).
* **Est-use copies** (`Program/dofiles_estuse/*_estuse.do`, auto-generated, only `reghdfe`/`est save` lines prefixed with
  `*ESTUSE*`): Figure 2, Figure 4, Table 2 (CK columns), Appendix Figure A8 (group-level analysis). These do-files absorb
  ~180 `i.one#c.x` slopes; reghdfe treats each as a separate absorbed dimension and a single regression did not finish in
  2.5 h on the shared 8-core machine (load average 60–230 from parallel agents). Their regressions are instead
  re-estimated independently in StatsPAI and matched to the shipped `.ster` to 1e-9.
* **Patched copy** `Program/dofiles_patched/Appendix_TableG2_col1_patched.do`: the shipped file merges on a tempfile
  `qcew` that it never creates (r(198)); we prepend the 5-line block that creates it, copied verbatim from
  `Appendix_TableG2_cols_2_3_4.do`.

## Failures and gaps (original code)

{{STEPS_TABLE}}

## Extensions (not replication)

See `Results/statspai/ext_summary.csv`, `ext_eventstudy_paths.csv`, `ext_honest_did_sunabraham_e0.csv` and
`ext_eventstudy_compare.png`. Outcome = (missing + excess jobs)/EPOP₋₁ on the authors' stacked event × state × quarter
file with clean controls; 5-year post average:

| Estimator | Estimate (s.e.) |
|---|---|
{{EXT_ROWS}}
