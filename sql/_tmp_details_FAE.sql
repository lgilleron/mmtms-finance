SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       SUBSTR(f.abrege,1,3) AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE_PLUS' AS TYPE,
       (CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END) AS ventes_fae
FROM facture f
WHERE f.etat IS NOT NULL
AND   f.periodestat = '202608'
AND   COALESCE(f.periodecpt,'') <> '202608'
UNION
SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
       SUBSTR(f.abrege,1,3) AS section,
       SUBSTR(f.dossier,1,4) AS ligne,
       f.numfact,
       SUBSTR(f.abrege,4,8) AS nomabrege,
       f.periodestat,
       COALESCE(f.periodecpt,SUBSTR(f.datecpt,1,6)) AS periodecpt,
       'FAE_MOINS' AS TYPE,
       -(CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END) AS ventes_fae
FROM facture f
WHERE f.etat IS NOT NULL
AND   f.periodecpt = '202608'
AND   f.periodestat > '202608'
