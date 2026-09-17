SELECT *,
       ABS(v.chiffre - v.chiffre_statpays) + ABS(v.debours - v.debours_statpays) AS total_diff
FROM bi.finance_ctrl_statpays v
ORDER BY periodestat,
         societe,
         agence,
         ligne;
