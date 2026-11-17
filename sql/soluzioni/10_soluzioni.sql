-- =====================================================================
--  SOLUZIONI - LEZIONE 10: INSERT, UPDATE, DELETE
-- =====================================================================

BEGIN TRANSACTION;

.print "\n── Esercizio 1: nuovo cliente con RETURNING ──"
INSERT INTO clienti (nome, cognome, email, citta, data_registrazione)
VALUES ('Ada', 'Studente', 'ada.studente@example.com', 'Pisa', '2025-07-01')
RETURNING id;

.print "\n── Esercizio 2: ordine con due prodotti al prezzo di listino ──"
INSERT INTO ordini (cliente_id, data_ordine, stato)
VALUES ((SELECT id FROM clienti WHERE email = 'ada.studente@example.com'), '2025-07-02', 'in_attesa')
RETURNING id;

-- Recupero l'id dell'ordine appena creato con una subquery.
-- (Tentazione: usare last_insert_rowid(). Ma dentro un INSERT ... SELECT
--  viene ricalcolato a OGNI riga inserita: dalla seconda riga in poi
--  restituirebbe l'id della riga d'ordine appena inserita, non dell'ordine!
--  In Java/JDBC si legge l'id con getGeneratedKeys e lo si passa come parametro.)
INSERT INTO righe_ordine (ordine_id, prodotto_id, quantita, prezzo_unitario)
SELECT (SELECT o.id FROM ordini o
        JOIN clienti c ON c.id = o.cliente_id
        WHERE c.email = 'ada.studente@example.com'),
       id, 1, prezzo
FROM prodotti
WHERE id IN (7, 8);

SELECT o.id, c.nome, p.nome AS prodotto, r.prezzo_unitario
FROM ordini o
JOIN clienti c      ON c.id = o.cliente_id
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
WHERE c.email = 'ada.studente@example.com';

.print "\n── Esercizio 3: +5% ai prodotti venduti in almeno 3 ordini ──"
SELECT id, nome, prezzo FROM prodotti
WHERE id IN (SELECT prodotto_id FROM righe_ordine GROUP BY prodotto_id HAVING COUNT(*) >= 3);

UPDATE prodotti
SET prezzo = ROUND(prezzo * 1.05, 2)
WHERE id IN (SELECT prodotto_id FROM righe_ordine GROUP BY prodotto_id HAVING COUNT(*) >= 3);

SELECT id, nome, prezzo FROM prodotti
WHERE id IN (SELECT prodotto_id FROM righe_ordine GROUP BY prodotto_id HAVING COUNT(*) >= 3);

.print "\n── Esercizio 4: 'spedito' prima di aprile 2025 -> 'consegnato' ──"
SELECT id, data_ordine, stato FROM ordini
WHERE stato = 'spedito' AND data_ordine < '2025-04-01';     -- controllo: solo l'ordine 24

UPDATE ordini
SET stato = 'consegnato'
WHERE stato = 'spedito' AND data_ordine < '2025-04-01';

SELECT id, stato FROM ordini WHERE id IN (24, 25);

.print "\n── Esercizio 5: elimina recensioni senza commento e senza acquisto ──"
DELETE FROM recensioni
WHERE commento IS NULL
  AND NOT EXISTS (SELECT 1
                  FROM ordini o
                  JOIN righe_ordine r ON r.ordine_id = o.id
                  WHERE o.cliente_id = recensioni.cliente_id
                    AND r.prodotto_id = recensioni.prodotto_id)
RETURNING id, cliente_id, prodotto_id;
-- La recensione 10 (Webcam) non è stata cancellata: ha un commento.

.print "\n── Esercizio 6: scala le scorte con gli ordini in attesa ──"
UPDATE prodotti
SET scorta = MAX(0, scorta - (SELECT COALESCE(SUM(r.quantita), 0)
                              FROM righe_ordine r
                              JOIN ordini o ON o.id = r.ordine_id
                              WHERE o.stato = 'in_attesa'
                                AND r.prodotto_id = prodotti.id))
WHERE id IN (SELECT r.prodotto_id
             FROM righe_ordine r
             JOIN ordini o ON o.id = r.ordine_id
             WHERE o.stato = 'in_attesa');
-- PERCHÉ MAX(0, ...)? Senza, l'UPDATE fallisce con
--   "CHECK constraint failed: scorta >= 0"
-- Nell'esercizio 2 abbiamo ordinato il "Manuale di SQL", che ha scorta 0:
-- il vincolo ha scoperto un ordine di un prodotto esaurito! Qui ci
-- limitiamo a non scendere sotto zero (MAX con due argomenti è di SQLite;
-- altrove si usa GREATEST); in un'applicazione vera l'ordine andrebbe
-- bloccato PRIMA, al momento dell'inserimento.
-- Il WHERE evita di "toccare" i prodotti che non c'entrano.
-- Il COALESCE serve per sicurezza: SUM di zero righe è NULL, e
-- scorta - NULL = NULL violerebbe il NOT NULL.
SELECT id, nome, scorta FROM prodotti WHERE id IN (2, 5, 7, 8, 10, 12, 13, 16);

.print "\n── Esercizio 7: eliminare la categoria Informatica ──"
-- DELETE FROM categorie WHERE nome = 'Informatica';
--   -> FOREIGN KEY constraint failed
-- Ci sono prodotti che puntano a quella categoria. Le scelte possibili:
--  a) eliminare (o spostare) prima i prodotti, b) definire la FK con
--  ON DELETE SET NULL / CASCADE. Mai disattivare i vincoli per "far passare"
--  la DELETE!
.print "   (istruzione commentata: vedi il file)"

ROLLBACK;
