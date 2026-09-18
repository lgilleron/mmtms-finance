-- Création de la vue bi.finance_ctrl_statpays pour le calcul des ventes par Section Analytique
-- ITPL : CALCUL VENTES (MARGE) PAR SECTION (CODEFACT)

DROP VIEW IF EXISTS bi.finance_ventes_section;

CREATE VIEW bi.finance_ventes_section AS

SELECT societe,
       COALESCE(section,bureau) AS section,
       periodecpt,
       SUM(chiffre - debours) AS ventes
FROM (SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
             p.bureau,
             l.section,
             f.periodecpt,
             f.numfact,
             SUM((CASE WHEN d.codefact < '100' THEN 0 ELSE (CASE WHEN f.foua = 1 THEN d.montant ELSE- d.montant END) END)) AS chiffre,
             0 AS debours
      FROM facture f
        INNER JOIN pays p ON p.code = f.code
        INNER JOIN fadetail d ON d.numfact = f.numfact
        INNER JOIN libfact l ON l.codefact = d.codefact
      WHERE f.etat IS NOT NULL
      AND   f.periodecpt = '202608'
      GROUP BY f.pkfacture,
               f.numfact,
               p.bureau,
               l.section
      UNION ALL
      SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
             p.bureau,
             NULL AS section,
             f.periodecpt,
             f.numfact,
             0 AS chiffre,
             SUM((CASE WHEN f.foua = 1 THEN f.debgro + f.debdos ELSE- f.debgro - f.debdos END)) AS debours
      FROM facture f
        INNER JOIN pays p ON p.code = f.code
      WHERE f.etat IS NOT NULL
      AND   f.periodecpt = '202608'
      GROUP BY f.pkfacture,
               f.numfact,
               p.bureau) R1
GROUP BY societe,
         COALESCE(section,bureau),
         periodecpt;
