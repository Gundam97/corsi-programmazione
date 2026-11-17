-- =====================================================================
--  SOLUZIONI - LEZIONE 7: SUBQUERY e CTE
-- =====================================================================

.print "\n── Esercizio 1: più economici del più economico di Informatica ──"
SELECT nome, prezzo
FROM prodotti
WHERE prezzo < (SELECT MIN(p.prezzo)
                FROM prodotti p
                JOIN categorie c ON c.id = p.categoria_id
                WHERE c.nome = 'Informatica')
ORDER BY prezzo;

.print "\n── Esercizio 2a: clienti senza recensioni (NOT IN) ──"
SELECT id, nome, cognome
FROM clienti
WHERE id NOT IN (SELECT cliente_id FROM recensioni);
-- Funziona perché recensioni.cliente_id è NOT NULL. Se potesse essere
-- NULL, il NOT IN restituirebbe 0 righe (vedi 7.6).

.print "\n── Esercizio 2b: clienti senza recensioni (NOT EXISTS) ──"
SELECT c.id, c.nome, c.cognome
FROM clienti c
WHERE NOT EXISTS (SELECT 1 FROM recensioni r WHERE r.cliente_id = c.id);

.print "\n── Esercizio 3: prodotti mai venduti (NOT EXISTS) ──"
SELECT p.id, p.nome
FROM prodotti p
WHERE NOT EXISTS (SELECT 1 FROM righe_ordine r WHERE r.prodotto_id = p.id);

.print "\n── Esercizio 4: primo e ultimo ordine di ogni cliente ──"
SELECT c.cognome, t.primo, t.ultimo,
       CAST(julianday(t.ultimo) - julianday(t.primo) AS INTEGER) AS giorni
FROM clienti c
JOIN (SELECT cliente_id, MIN(data_ordine) AS primo, MAX(data_ordine) AS ultimo
      FROM ordini
      GROUP BY cliente_id) t ON t.cliente_id = c.id
ORDER BY giorni DESC;

.print "\n── Esercizio 5: ordini con merce > 500 € ──"
WITH totali AS (
    SELECT ordine_id, SUM(quantita * prezzo_unitario) AS totale
    FROM righe_ordine
    GROUP BY ordine_id
)
SELECT t.ordine_id, c.nome || ' ' || c.cognome AS cliente, o.stato, t.totale
FROM totali t
JOIN ordini o  ON o.id = t.ordine_id
JOIN clienti c ON c.id = o.cliente_id
WHERE t.totale > 500
ORDER BY t.totale DESC;

.print "\n── Esercizio 6: il prodotto più caro di ogni categoria ──"
SELECT c.nome AS categoria, p.nome, p.prezzo
FROM prodotti p
JOIN categorie c ON c.id = p.categoria_id
WHERE p.prezzo = (SELECT MAX(p2.prezzo)
                  FROM prodotti p2
                  WHERE p2.categoria_id = p.categoria_id)
ORDER BY c.nome;

.print "\n── Esercizio 7: il cliente che ha speso di più in ogni città ──"
WITH spesa AS (
    SELECT c.id, c.cognome, c.citta, SUM(r.quantita * r.prezzo_unitario) AS speso
    FROM clienti c
    JOIN ordini o       ON o.cliente_id = c.id AND o.stato <> 'annullato'
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE c.citta IS NOT NULL
    GROUP BY c.id, c.cognome, c.citta
),
massimi AS (
    SELECT citta, MAX(speso) AS max_speso
    FROM spesa
    GROUP BY citta
)
SELECT s.citta, s.cognome, ROUND(s.speso, 2) AS speso
FROM spesa s
JOIN massimi m ON m.citta = s.citta AND m.max_speso = s.speso
ORDER BY s.speso DESC;
-- (Con le window function della lezione 9 si scrive in modo più diretto.)

.print "\n── Esercizio 8: tutti i 'sottoposti' di Giorgio Moretti ──"
WITH RECURSIVE sotto(id, nome, cognome, ruolo, livello) AS (
    SELECT id, nome, cognome, ruolo, 1
    FROM dipendenti
    WHERE responsabile_id = (SELECT id FROM dipendenti WHERE cognome = 'Moretti')
    UNION ALL
    SELECT d.id, d.nome, d.cognome, d.ruolo, s.livello + 1
    FROM dipendenti d
    JOIN sotto s ON d.responsabile_id = s.id
)
SELECT nome, cognome, ruolo, livello FROM sotto ORDER BY livello, cognome;

.print "\n── Esercizio 9: NOT IN con dipendente_id che contiene NULL ──"
-- ordini.dipendente_id è NULL per gli ordini online: la lista contiene
-- NULL, quindi ogni "id NOT IN (...)" è sconosciuto -> nessuna riga.
SELECT nome, cognome
FROM dipendenti
WHERE id NOT IN (SELECT dipendente_id FROM ordini WHERE dipendente_id IS NOT NULL);
-- oppure, meglio:
SELECT d.nome, d.cognome
FROM dipendenti d
WHERE NOT EXISTS (SELECT 1 FROM ordini o WHERE o.dipendente_id = d.id);
