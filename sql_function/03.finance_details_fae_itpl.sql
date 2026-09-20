-- Fonction pour les détails des FAE : ITPL : Marges + Sections par code de facturation
DROP FUNCTION IF EXISTS bi.finance_details_fae;

CREATE OR REPLACE FUNCTION bi.finance_details_fae (p_periode TEXT) 
RETURNS TABLE (
       societe TEXT,
       section TEXT,
       ligne TEXT,
       numfact TEXT,
       nomabrege TEXT,
       periodestat TEXT,
       periodecpt TEXT,
       type_fae TEXT,
       ventes NUMERIC)
SECURITY DEFINER
SET search_path = bi, public       
AS $$
SELECT societe,
       COALESCE(section,bureau) AS section,
       ligne,
       numfact,
       nomabrege,
       periodestat,
       periodecpt,
       type_fae,
       SUM(chiffre - debours) AS ventes
FROM ((SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
              p.bureau,
              l.section,
              SUBSTR(f.dossier,1,4) AS ligne,
              f.numfact,
              SUBSTR(f.abrege,4,8) AS nomabrege,
              f.periodestat,
              COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
              'FAE_PLUS' AS type_fae,
              SUM((CASE WHEN f.foua = 1 THEN d.montant ELSE- d.montant END)) AS chiffre,
              0 AS debours
       FROM facture f
         INNER JOIN pays p ON f.code = p.code
         INNER JOIN fadetail d ON d.numfact = f.numfact
         INNER JOIN libfact l ON l.codefact = d.codefact
       WHERE f.etat IS NOT NULL
       AND   l.codefact >= '100'
       AND   l.codefact <> '999'
       AND   f.periodestat = p_periode
       AND   COALESCE(f.periodecpt,'') <> p_periode
       GROUP BY f.pkfacture,
                f.numfact,
                p.bureau,
                l.section
       UNION ALL
       SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
              p.bureau,
              NULL AS section,
              SUBSTR(f.dossier,1,4) AS ligne,
              f.numfact,
              SUBSTR(f.abrege,4,8) AS nomabrege,
              f.periodestat,
              COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
              'FAE_PLUS' AS type_fae,
              0 AS chiffre,
              SUM((CASE WHEN f.foua = 1 THEN f.debgro + f.debdos ELSE- f.debgro - f.debdos END)) AS debours
       FROM facture f
         INNER JOIN pays p ON f.code = p.code
       WHERE f.etat IS NOT NULL
       AND   f.periodestat = p_periode
       AND   COALESCE(f.periodecpt,'') <> p_periode
       GROUP BY f.pkfacture,
                f.numfact,
                p.bureau)
       UNION
       (SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
              p.bureau,
              l.section,
              SUBSTR(f.dossier,1,4) AS ligne,
              f.numfact,
              SUBSTR(f.abrege,4,8) AS nomabrege,
              f.periodestat,
              COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
              'FAE_MOINS' AS type_fae,
              -SUM((CASE WHEN f.foua = 1 THEN d.montant ELSE- d.montant END)) AS chiffre,
              0 AS debours
       FROM facture f
         INNER JOIN pays p ON f.code = p.code
         INNER JOIN fadetail d ON d.numfact = f.numfact
         INNER JOIN libfact l ON l.codefact = d.codefact
       WHERE f.etat IS NOT NULL
       AND   l.codefact >= '100'
       AND   l.codefact <> '999'
       AND   f.periodecpt = p_periode
       AND   COALESCE(f.periodestat,'') <> p_periode
       GROUP BY f.pkfacture,
                f.numfact,
                p.bureau,
                l.section
       UNION ALL
       SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
              p.bureau,
              NULL AS section,
              SUBSTR(f.dossier,1,4) AS ligne,
              f.numfact,
              SUBSTR(f.abrege,4,8) AS nomabrege,
              f.periodestat,
              COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
              'FAE_MOINS' AS type_fae,
              0 AS chiffre,
              -SUM((CASE WHEN f.foua = 1 THEN f.debgro + f.debdos ELSE- f.debgro - f.debdos END)) AS debours
       FROM facture f
         INNER JOIN pays p ON f.code = p.code
       WHERE f.etat IS NOT NULL
       AND   f.periodecpt = p_periode
       AND   COALESCE(f.periodestat,'') <> p_periode
       GROUP BY f.pkfacture,
                f.numfact,
                p.bureau)) R1
GROUP BY societe,
         COALESCE(section,bureau),
         ligne,
         numfact,
         nomabrege,
         periodestat,
         periodecpt,
         type_fae;
$$
LANGUAGE sql;
