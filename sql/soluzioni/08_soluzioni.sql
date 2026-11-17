-- =====================================================================
--  SOLUZIONI - LEZIONE 8: UNION, INTERSECT, EXCEPT
-- =====================================================================

.print "\n── Esercizio 1: tutte le persone ──"
SELECT nome, cognome, 'cliente' AS tipo FROM clienti
UNION ALL                                   -- un cliente e un dipendente omonimi restano due righe
SELECT nome, cognome, 'dipendente' FROM dipendenti
ORDER BY cognome, nome;

.print "\n── Esercizio 2: prodotti ordinati E recensiti ──"
SELECT prodotto_id FROM righe_ordine
INTERSECT
SELECT prodotto_id FROM recensioni;

.print "\n── Esercizio 3: prodotti recensiti ma mai venduti ──"
SELECT prodotto_id FROM recensioni
EXCEPT
SELECT prodotto_id FROM righe_ordine;

.print "\n── Esercizio 4: nuovi clienti del 2025 ──"
SELECT id, nome, cognome
FROM clienti
WHERE id IN (SELECT cliente_id FROM ordini WHERE data_ordine LIKE '2025%'
             EXCEPT
             SELECT cliente_id FROM ordini WHERE data_ordine LIKE '2024%');

.print "\n── Esercizio 5: fatturato per anno con riga TOTALE ──"
SELECT strftime('%Y', o.data_ordine) AS anno,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2) AS fatturato
FROM ordini o
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.stato <> 'annullato'
GROUP BY anno
UNION ALL
SELECT 'TOTALE', ROUND(SUM(r.quantita * r.prezzo_unitario), 2)
FROM ordini o
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.stato <> 'annullato';

.print "\n── Esercizio 6: perché la UNION dà errore ──"
-- La prima query ha 2 colonne, la seconda 1: le query di una UNION devono
-- avere lo stesso numero di colonne. Versione corretta:
SELECT nome, cognome FROM clienti WHERE id <= 2
UNION
SELECT nome, cognome FROM dipendenti WHERE id <= 2;
