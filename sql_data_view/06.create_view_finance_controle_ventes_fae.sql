-- Création de la vue bi.finance_ctrl_statpays pour le contrôle des factures VS statpays : Chiffre et Débours
DROP VIEW IF EXISTS bi.finance_controle_ventes_fae;

CREATE VIEW bi.finance_controle_ventes_fae 
AS
SELECT societe,
       periodecpt,
       ventes_statpays,
       ventes_compta,
       COALESCE("ventes_fae+",0) AS "ventes_fae+",
       COALESCE("ventes_fae-",0) AS "ventes_fae-",
       COALESCE(ventes_fae,0) AS ventes_fae,
       COALESCE(ventes_statpays - ventes_compta - ventes_fae,0) AS difference
FROM (SELECT *,
             (SELECT SUM(CASE WHEN societecode (code) IN ('MMBE','RAIL') THEN cumht ELSE cumht - cumdebours - cumdebcam - cumdebparc END)
              FROM statpays
              WHERE permens = R1.periodecpt
              AND   societecode(code) = R1.societe) AS ventes_statpays,
             (SELECT SUM(ventes)
              FROM bi.finance_details_fae (R1.periodecpt)
              WHERE societe = R1.societe
              AND   type_fae = 'FAE+') AS "ventes_fae+",
             (SELECT SUM(ventes)
              FROM bi.finance_details_fae (R1.periodecpt)
              WHERE societe = R1.societe
              AND   type_fae = 'FAE-') AS "ventes_fae-",
             (SELECT SUM(ventes)
              FROM bi.finance_details_fae (R1.periodecpt)
              WHERE societe = R1.societe) AS ventes_fae
      FROM (SELECT societe,
                   periodecpt,
                   SUM(ventes) AS ventes_compta
            FROM bi.finance_ventes_section
            GROUP BY societe,
                     periodecpt) R1) R2
ORDER BY societe,
         periodecpt;
