# Reference AKM (Adao-Kolesar-Morales 2019) standard errors from the authors'
# R package ShiftShareSE (CRAN 1.1.0), used to validate the StatsPAI shift-share
# functions and the Python AKM port in modern_extensions.py.
# Run: /usr/local/bin/Rscript Program/statspai/akm_reference.R
suppressMessages(library(ShiftShareSE))
root <- normalizePath(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE))), "..", ".."))
bhj <- file.path(root, "Data/external/bhj_shift_share/ADH/Data")
loc <- read.csv(file.path(bhj, "location_level.csv"))
W <- as.matrix(read.csv(file.path(bhj, "Lshares_superwide.csv")))   # collinear shares dropped by BHJ
sic3 <- as.matrix(read.csv(file.path(bhj, "sic3.csv")))[, 1]
ctrl <- c("t2", "reg_midatl", "reg_encen", "reg_wncen", "reg_satl", "reg_escen", "reg_wscen", "reg_mount",
          "reg_pacif", "l_sh_popedu_c", "l_sh_popfborn", "l_sh_empl_f", "l_sh_routine33", "l_task_outsource",
          "l_shind_manuf_cbp")
Zc <- cbind(1, as.matrix(loc[, ctrl]))
out <- list()
run <- function(tag, w, scv) {
  r <- ivreg_ss.fit(y1 = loc$y, y2 = loc$x, X = loc$z, W = W, Z = Zc, w = w,
                    method = c("ehw", "akm", "akm0"), sector_cvar = scv)
  data.frame(case = tag, beta = r$beta, se_ehw = r$se["EHW"], se_akm = r$se["AKM"],
             akm0_lo = r$ci.l["AKM0"], akm0_hi = r$ci.r["AKM0"])
}
out[[1]] <- run("BHJshares_weighted_sic3", loc$wei, sic3)          # = BHJ (2022) Table C2 col 1
out[[2]] <- run("BHJshares_weighted_nocluster", loc$wei, NULL)
out[[3]] <- run("BHJshares_unweighted_nocluster", NULL, NULL)
res <- do.call(rbind, out)
print(res, digits = 10)
write.csv(res, file.path(root, "Results/statspai/akm_reference_R.csv"), row.names = FALSE)
