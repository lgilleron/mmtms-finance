SELECT y_section AS section,
       y_periode AS periodecpt,
       SUM(y_credit - y_debit) AS ventes
FROM analytiq
WHERE y_general LIKE '7%'
AND   y_periode >= '202601'
AND   y_journal = 'VEN'
GROUP BY y_section,
         y_periode
ORDER BY y_periode,
         y_section;