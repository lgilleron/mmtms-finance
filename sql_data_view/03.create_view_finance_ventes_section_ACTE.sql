-- Création de la vue bi.finance_ctrl_statpays pour le calcul des ventes par Section Analytique
-- ACTE : CALCUL VENTES (MARGE) PAR SECTION (PAYS)

DROP VIEW IF EXISTS bi.finance_ventes_section;

CREATE VIEW bi.finance_ventes_section AS

SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       p.section AS section,
       periodecpt,
       SUM((CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END)) AS ventes
FROM facture f
  INNER JOIN pays p ON f.code = p.code
WHERE f.etat IS NOT NULL
AND   f.periodecpt >= '202601'
GROUP BY societe,
         section,
         periodecpt;
