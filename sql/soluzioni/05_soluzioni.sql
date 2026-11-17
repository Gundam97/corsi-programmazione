-- =====================================================================
--  SOLUZIONI - LEZIONE 5: JOIN
-- =====================================================================

.print "\n── Esercizio 1: recensioni con prodotto e cliente ──"
SELECT p.nome AS prodotto,
       c.nome || ' ' || c.cognome AS cliente,
       r.voto, r.commento
FROM recensioni r
JOIN prodotti p ON p.id = r.prodotto_id
JOIN clienti  c ON c.id = r.cliente_id
ORDER BY p.nome;

.print "\n── Esercizio 2: ordini consegnati 2024 con cliente e dipendente ──"
SELECT o.id, o.data_ordine, c.cognome AS cliente, d.cognome AS dipendente
FROM ordini o
JOIN clienti c    ON c.id = o.cliente_id
JOIN dipendenti d ON d.id = o.dipendente_id     -- INNER: esclude gli ordini online
WHERE o.stato = 'consegnato' AND o.data_ordine LIKE '2024%'
ORDER BY o.data_ordine;

.print "\n── Esercizio 3: come il 2, con gli ordini online ──"
SELECT o.id, o.data_ordine, c.cognome AS cliente,
       COALESCE(d.cognome, 'online') AS dipendente
FROM ordini o
JOIN clienti c         ON c.id = o.cliente_id
LEFT JOIN dipendenti d ON d.id = o.dipendente_id
WHERE o.stato = 'consegnato' AND o.data_ordine LIKE '2024%'
ORDER BY o.data_ordine;

.print "\n── Esercizio 4: categorie con i loro prodotti, anche vuote ──"
SELECT c.nome AS categoria, p.nome AS prodotto, p.prezzo
FROM categorie c
LEFT JOIN prodotti p ON p.categoria_id = c.id
ORDER BY c.nome, p.prezzo DESC;

.print "\n── Esercizio 5: prodotti acquistati da clienti di Milano ──"
SELECT c.nome || ' ' || c.cognome AS cliente, p.nome AS prodotto, o.data_ordine
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
WHERE c.citta = 'Milano'
ORDER BY c.cognome, o.data_ordine;

.print "\n── Esercizio 6: risparmio sulle righe dell'ordine 16 ──"
SELECT p.nome, r.quantita, r.prezzo_unitario AS pagato, p.prezzo AS listino,
       (p.prezzo - r.prezzo_unitario) * r.quantita AS risparmio
FROM righe_ordine r
JOIN prodotti p ON p.id = r.prodotto_id
WHERE r.ordine_id = 16;

.print "\n── Esercizio 7: libri venduti, cercando la categoria per NOME ──"
SELECT p.nome AS libro, o.data_ordine, o.stato
FROM categorie cat
JOIN prodotti p     ON p.categoria_id = cat.id
JOIN righe_ordine r ON r.prodotto_id = p.id
JOIN ordini o       ON o.id = r.ordine_id
WHERE cat.nome = 'Libri'
ORDER BY p.nome, o.data_ordine;

.print "\n── Esercizio 8: dimensione del prodotto cartesiano ──"
SELECT COUNT(*) AS abbinamenti, 16 * 18 AS atteso
FROM clienti
CROSS JOIN prodotti;
