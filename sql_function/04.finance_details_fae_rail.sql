-- Fonction pour les détails des FAE : RAIL : Chiffre + Section par agence
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
       SUBSTR(f.abrege,1,3) AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE+' AS type_fae,
       f.chiffre AS ventes
FROM facture f
WHERE f.etat IS NOT NULL
AND   f.periodestat = p_periode
AND   COALESCE(f.periodecpt,'') <> p_periode
AND   f.chiffre <> 0
UNION
SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       SUBSTR(f.abrege,1,3) AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE-' AS type_fae,
       -f.chiffre AS ventes
FROM facture f
WHERE f.etat IS NOT NULL
AND   f.periodecpt = p_periode
AND   coalesce(f.periodestat,'') <> p_periode
AND   f.chiffre <> 0
ORDER BY societe,
         section,
         ligne,
         numfact;
$$
LANGUAGE sql;