# OA Lee bounds for endline attrition (treat vs spillover)

| outcome              | label                          |   lower |   se_lower |   upper |   se_upper |   trim |   sp_lee_lower |   sp_lee_upper |   sp_lee_se_midpoint |
|:---------------------|:-------------------------------|--------:|-----------:|--------:|-----------:|-------:|---------------:|---------------:|---------------------:|
| asset_total_ppp1     | Value of non-land assets (USD) | 283.39  |     38.823 | 302.193 |     32.539 |  0.008 |        282.945 |        302.418 |               33.159 |
| cons_nondurable_ppp1 | Non-durable expenditure (USD)  |  30.577 |      8.64  |  35.008 |      6.722 |  0.008 |         30.467 |         35.058 |                6.371 |
| ent_total_rev_ppp1   | Total revenue, monthly (USD)   |   8.716 |     10.779 |  13.712 |      6.233 |  0.008 |          8.556 |         13.578 |                7.384 |
| fs_hhfoodindexnew1   | Food security index            |   0.228 |      0.075 |   0.283 |      0.09  |  0.008 |          0.228 |          0.283 |                0.071 |
| med_hh_healthindex1  | Health index                   |  -0.048 |      0.077 |   0.001 |      0.085 |  0.008 |         -0.049 |          0.002 |                0.064 |
| ed_index1            | Education index                |  -0.096 |      0.076 |   0.103 |      0.079 |  0.04  |         -0.101 |          0.103 |                0.078 |
| psy_index_z1         | Psychological well-being index |   0.196 |      0.07  |   0.295 |      0.068 |  0.019 |          0.196 |          0.295 |                0.064 |
| ih_overall_index_z1  | Female empowerment index       |  -0.033 |      0.09  |   0.02  |      0.124 |  0.01  |         -0.033 |          0.026 |                0.085 |

lower/upper/se: exact port of leebounds.ado analytic SEs; sp_lee_*: sp.lee_bounds.
