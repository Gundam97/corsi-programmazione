-- =====================================================================
--  SQL - LEZIONE 8: UNION, INTERSECT, EXCEPT
-- =====================================================================
--
--  Le JOIN affiancano le colonne di due tabelle (crescono "in larghezza").
--  Gli operatori insiemistici impilano i RISULTATI di due query
--  (crescono "in altezza"):
--
--     query A  UNION      query B   -> righe di A + righe di B, senza duplicati
--     query A  UNION ALL  query B   -> righe di A + righe di B, CON duplicati
--     query A  INTERSECT  query B   -> righe presenti in ENTRAMBE
--     query A  EXCEPT     query B   -> righe di A che NON sono in B
--                                      (in Oracle si chiama MINUS)
--
--  REGOLE
--   - le due query devono avere lo STESSO NUMERO di colonne, con tipi
--     compatibili, nello stesso ordine
--   - i nomi delle colonne del risultato sono quelli della PRIMA query
--   - ORDER BY si scrive una volta sola, in fondo, e vale per tutto
-- =====================================================================

.print "\n── 8.1 UNION: una rubrica unica di clienti e dipendenti ──"
SELECT nome, cognome, 'cliente'    AS tipo FROM clienti    WHERE id <= 3
UNION
SELECT nome, cognome, 'dipendente' AS tipo FROM dipendenti WHERE id <= 3
ORDER BY cognome;

.print "\n── 8.2 UNION vs UNION ALL ──"
-- Le città in cui abbiamo clienti, per due anni di registrazione diversi.
-- UNION toglie i duplicati (e per farlo deve ordinare/confrontare: è più lenta)
SELECT citta FROM clienti WHERE data_registrazione LIKE '2023%'
UNION
SELECT citta FROM clienti WHERE data_registrazione LIKE '2024%';

.print "\n   ...con UNION ALL (tutti i valori, anche ripetuti):"
SELECT citta FROM clienti WHERE data_registrazione LIKE '2023%'
UNION ALL
SELECT citta FROM clienti WHERE data_registrazione LIKE '2024%';
-- Regola pratica: usa UNION ALL quando sai che non ci sono duplicati
-- (o quando li vuoi): è più veloce.

.print "\n── 8.3 INTERSECT: città in cui c'erano clienti sia nel 2023 sia nel 2024 ──"
SELECT citta FROM clienti WHERE data_registrazione LIKE '2023%'
INTERSECT
SELECT citta FROM clienti WHERE data_registrazione LIKE '2024%';
-- NB: per INTERSECT/EXCEPT/UNION due NULL sono considerati "uguali"
-- (diversamente da = nel WHERE!)

.print "\n── 8.4 EXCEPT: clienti che hanno ordinato nel 2024 ma NON nel 2025 ──"
SELECT cliente_id FROM ordini WHERE data_ordine LIKE '2024%'
EXCEPT
SELECT cliente_id FROM ordini WHERE data_ordine LIKE '2025%';

.print "\n── 8.5 EXCEPT come anti-join: prodotti mai venduti ──"
SELECT id FROM prodotti
EXCEPT
SELECT prodotto_id FROM righe_ordine;

.print "\n── 8.6 UNION ALL per costruire un report con riga di TOTALE ──"
SELECT stato, COUNT(*) AS ordini
FROM ordini
GROUP BY stato
UNION ALL
SELECT 'TOTALE', COUNT(*)
FROM ordini;

.print "\n── 8.7 UNION ALL per unire 'eventi' diversi in una timeline ──"
-- Tutto ciò che ha fatto il cliente 1, in ordine di data.
SELECT data_registrazione AS data, 'Registrazione' AS evento, NULL AS dettaglio
FROM clienti WHERE id = 1
UNION ALL
SELECT data_ordine, 'Ordine #' || id, stato
FROM ordini WHERE cliente_id = 1
UNION ALL
SELECT r.data, 'Recensione', p.nome || ' (' || r.voto || '/5)'
FROM recensioni r JOIN prodotti p ON p.id = r.prodotto_id
WHERE r.cliente_id = 1
ORDER BY data;

.print "\n── 8.8 Simulare un FULL JOIN con LEFT JOIN + UNION (utile in MySQL) ──"
SELECT c.nome AS categoria, p.nome AS prodotto
FROM categorie c LEFT JOIN prodotti p ON p.categoria_id = c.id
WHERE p.id IS NULL
UNION
SELECT c.nome, p.nome
FROM prodotti p LEFT JOIN categorie c ON c.id = p.categoria_id
WHERE c.id IS NULL;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/08_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Elenco unico di tutte le persone (clienti e dipendenti) con nome,
      cognome e tipo, ordinato per cognome.
   2. Prodotti che sono stati sia ordinati sia recensiti (INTERSECT).
   3. Prodotti recensiti ma mai venduti (EXCEPT).
   4. Clienti che hanno ordinato nel 2025 ma non nel 2024 (nuovi clienti),
      con il loro nome (suggerimento: usa l'EXCEPT in una subquery con IN).
   5. Report con il fatturato per anno e una riga finale 'TOTALE'.
   6. Perché questa query dà errore?
        SELECT nome, cognome FROM clienti UNION SELECT nome FROM dipendenti;
   --------------------------------------------------------------------- */
