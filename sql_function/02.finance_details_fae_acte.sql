-- Fonction pour les détails des FAE : ACTE : Marges + Sections par codes pays
DROP FUNCTION IF EXISTS bi.finance_details_fae;

CREATE OR REPLACE FUNCTION bi.finance_details_fae(p_periode text)
RETURNS TABLE (
    societe text,
    section text,
    ligne text,
    numfact text,
    nomabrege text,
    periodestat text,
    periodecpt text,
    type_fae text,
    ventes numeric
)
SECURITY DEFINER
SET search_path = bi, public
AS $$
SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       p.section AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE_PLUS' AS type_fae,
       (CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END) AS ventes
FROM facture f
 INNER JOIN pays p ON f.code = p.code
WHERE f.etat IS NOT NULL
AND   f.periodestat = p_periode
AND   COALESCE(f.periodecpt,'') <> p_periode
UNION
SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       p.section AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE_MOINS' AS type_fae,
       -(CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END) AS ventes
FROM facture f
 INNER JOIN pays p ON f.code = p.code
WHERE f.etat IS NOT NULL
AND   f.periodecpt = p_periode
AND   COALESCE(f.periodestat) <> p_periode
ORDER BY societe,
         section,
         ligne,
         numfact;
$$
LANGUAGE sql;
