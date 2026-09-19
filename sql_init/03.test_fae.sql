--select * from facture where periodestat='202608' and coalesce(periodecpt,'')<>'202608';

SELECT *,
       (SELECT ventes
        FROM bi.finance_ventes_section
        WHERE section = R1.section
        AND   periodecpt = R1.periodestat) as ventes_cpt,
       (SELECT SUM(cumht - cumdebours - cumdebcam - cumdebparc)
        FROM statpays
        WHERE agencecode(statpays.code) = R1.section
        AND   statpays.permens = R1.periodestat) as ventes_sta
FROM (SELECT societeagence(SUBSTR(f.abrege,1,3)) AS societe,
             SUBSTR(f.abrege,1,3) AS section,
             f.periodestat,
             SUM((CASE WHEN f.foua = 1 THEN f.chiffre -(f.debgro + f.debdos) ELSE f.chiffre + f.debgro + f.debdos END)) AS ventes_fae
      FROM facture f
      WHERE f.etat IS NOT NULL
      AND   f.periodestat = '202608'
      AND   COALESCE(f.periodecpt,'') <> '202608'
      --AND   (f.datecpt > '20260831' or f.datecpt < '20260801')
      AND   SUBSTR(f.abrege,1,3) <> 'BEL'
      GROUP BY societe,
               section,
               periodestat) R1
ORDER BY section

