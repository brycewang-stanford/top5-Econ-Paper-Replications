# Project-local Stata ado files

`reg2hdfespatial.ado` + `ols_spatial_HAC.ado` — Thiemo Fetzer's (2015) wrapper around Sol Hsiang's (2010)
Conley spatial/serial HAC code. Not on SSC.

* Version used here: the original 2015 release (568-line `ols_spatial_HAC.ado`; `reg2hdfespatial` passes
  `bartlett` to `ols_spatial_HAC` unconditionally), copied from
  https://github.com/surajrn/economic-conflict-africa/tree/main/adofiles .
  This is the version the authors used: their `All_in_One.log` prints
  "(NOTE: LINEAR BARTLETT WINDOW USED FOR SPATIAL KERNAL)", and with it Appendix Table B.1.III reproduces exactly.
* A later release (https://github.com/Ramin001/reg2hdfespatial, weights support, 682-line `ols_spatial_HAC`)
  uses a *uniform* spatial kernel by default and gives SEs ~7% larger (e.g. 0.059 vs the published 0.055),
  and its `bartlett` option crashes ("weights not allowed", r(101)). Do not use it for this package.

Other dependencies (SSC): reghdfe, ftools, ivreghdfe, ivreg2, ranktest, outreg2, parmest, tabout, reg2hdfe, hdfe, tmpdir.
