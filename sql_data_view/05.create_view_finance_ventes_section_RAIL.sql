-- Création de la vue bi.finance_ctrl_statpays pour le calcul des ventes par Section Analytique
-- RAIL : CALCUL VENTES (CHIFFRE) PAR SECTION (AGENCE)

DROP VIEW IF EXISTS bi.finance_ventes_section;

CREATE VIEW bi.finance_ventes_section AS

SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       SUBSTR(f.abrege,1,3) AS section,
       periodecpt,
       SUM(f.chiffre) AS ventes
FROM facture f
WHERE f.etat IS NOT NULL
AND   f.periodecpt >= '202601'
GROUP BY societe,
         section,
         periodecpt;
