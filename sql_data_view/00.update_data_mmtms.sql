-- Correction CHIFFRE avec arrondi à 2 décimales
UPDATE facture SET chiffre = ROUND(chiffre,2) WHERE ROUND(chiffre,2) <> chiffre;

-- Initialisation PERIODECPT 2026/08 : HORS ACTE
UPDATE facture
   SET periodecpt = '202608'
WHERE COALESCE(periodecpt,'') <> '202608'
AND   agencecode(dossier) <> 'ACT'
AND   ((datefact BETWEEN '20260801' AND '20260831' AND datecr BETWEEN '20260801' AND '20260831') OR (datefact BETWEEN '20260801' AND '20260831' AND datecr < '20260801') OR (datecr BETWEEN '20260828' AND '20260831'));

-- Initialisation PERIODECPT 2026/08 : ACTE
UPDATE facture
   SET periodecpt = '202608'
WHERE COALESCE(periodecpt,'') <> '202608'
AND   agencecode(dossier) = 'ACT'
AND   ((datefact BETWEEN '20260801' AND '20260831' AND datecr BETWEEN '20260801' AND '20260831') OR (datefact BETWEEN '20260801' AND '20260831' AND datecr < '20260801') OR (datecr BETWEEN '20260828' AND '20260831') OR (datecr = '20260727'));

-- Initialisation PERIODESTAT
UPDATE facture
   SET periodestat = substr(datefact,1,6)
WHERE COALESCE(periodestat,'') <> substr(datefact,1,6)
AND   datefact>='20260101'
AND   etat is not null;

-- Initialisation PERIODECPT (Après changement)
UPDATE facture
   SET periodecpt = SUBSTR(datecr,1,6)
WHERE datecr >= '20260828'
AND   etat IS NOT NULL
AND   COALESCE(periodecpt,'') <> SUBSTR(datecr,1,6);

-- Initialisation PERIODECPT (Avant changement)
UPDATE facture
   SET periodecpt = SUBSTR(datefact,1,6)
WHERE datecr < '20260828'
AND   datefact >= '20260101'
AND   etat IS NOT NULL
AND   periodecpt IS NULL;
