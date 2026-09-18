-- Création de la vue bi.finance_ctrl_statpays pour le contrôle des factures VS statpays : Chiffre et Débours
DROP VIEW IF EXISTS bi.finance_ctrl_statpays;

CREATE VIEW bi.finance_ctrl_statpays AS

SELECT fc.*,
       fc.chiffre - fc.debours AS marge,
       COALESCE(sp.chiffre_statpays, 0) AS chiffre_statpays,
       COALESCE(sp.debours_statpays, 0) AS debours_statpays,
       COALESCE(sp.chiffre_statpays, 0)
           - COALESCE(sp.debours_statpays, 0) AS marge_statpays

FROM (
    SELECT societeagence(SUBSTR(f.abrege, 1, 3)) AS societe,
           f.periodestat,
           SUBSTR(f.abrege, 1, 3) AS agence,
           SUBSTR(f.dossier, 1, 4) AS ligne,
           SUM(f.chiffre) AS chiffre,
           SUM(
               CASE
                   WHEN f.foua = 1
                   THEN f.debgro + f.debdos
                   ELSE -f.debgro - f.debdos
               END
           ) AS debours
    FROM facture f
    WHERE f.etat IS NOT NULL
      AND f.periodestat >= '202601'
    GROUP BY societe,
             periodestat,
             SUBSTR(f.abrege, 1, 3),
             SUBSTR(f.dossier, 1, 4)
) fc

LEFT JOIN (
    SELECT agencecode(code) AS agence,
           code,
           permens,
           SUM(cumht) AS chiffre_statpays,
           SUM(cumdebours + cumdebcam + cumdebparc) AS debours_statpays
    FROM statpays
    GROUP BY agencecode(code),
             code,
             permens
) sp
    ON sp.agence = fc.agence
   AND sp.code = fc.ligne
   AND sp.permens = fc.periodestat

WHERE fc.chiffre <> COALESCE(sp.chiffre_statpays, 0)
   OR fc.debours <> COALESCE(sp.debours_statpays, 0);
