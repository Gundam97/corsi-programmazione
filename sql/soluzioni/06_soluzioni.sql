-- =====================================================================
--  SOLUZIONI - LEZIONE 6: JOIN + GROUP BY, trappole e tecniche
-- =====================================================================

.print "\n── Esercizio 1: ordini e fatturato per dipendente (tutti) ──"
-- Trappole: 1) LEFT JOIN per tenere chi ha 0 ordini, con il filtro sullo
-- stato nell'ON; 2) COUNT(o.id) e non COUNT(*); 3) le righe d'ordine
-- moltiplicano gli ordini -> COUNT(DISTINCT o.id).
SELECT d.nome || ' ' || d.cognome                              AS dipendente,
       COUNT(DISTINCT o.id)                                    AS ordini,
       ROUND(COALESCE(SUM(r.quantita * r.prezzo_unitario), 0), 2) AS fatturato
FROM dipendenti d
LEFT JOIN ordini o       ON o.dipendente_id = d.id AND o.stato <> 'annullato'
LEFT JOIN righe_ordine r ON r.ordine_id = o.id
GROUP BY d.id, d.nome, d.cognome
ORDER BY fatturato DESC, d.id;

.print "\n── Esercizio 2: categorie che non hanno mai venduto ──"
SELECT cat.nome
FROM categorie cat
LEFT JOIN prodotti p     ON p.categoria_id = cat.id
LEFT JOIN righe_ordine r ON r.prodotto_id = p.id
GROUP BY cat.id, cat.nome
HAVING COUNT(r.ordine_id) = 0;
-- Non basta "WHERE r.ordine_id IS NULL": la categoria Informatica ha la
-- Webcam mai venduta, quindi avrebbe UNA riga con r NULL e comparirebbe.
-- Con GROUP BY + HAVING ragioniamo sull'intera categoria.

.print "\n── Esercizio 3: clienti e ordini per città ──"
SELECT c.citta,
       COUNT(DISTINCT c.id) AS clienti,
       COUNT(o.id)          AS ordini
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.citta
ORDER BY ordini DESC, c.citta;
-- Qui COUNT(o.id) è corretto senza DISTINCT: la JOIN clienti-ordini non
-- duplica gli ordini (ogni ordine ha un solo cliente).

.print "\n── Esercizio 4: clienti che hanno ordinato sia nel 2024 sia nel 2025 ──"
-- Soluzione A: aggregazione condizionale
SELECT c.id, c.cognome
FROM clienti c
JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.id, c.cognome
HAVING SUM(CASE WHEN o.data_ordine LIKE '2024%' THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN o.data_ordine LIKE '2025%' THEN 1 ELSE 0 END) > 0
ORDER BY c.id;

.print "   Soluzione B: self join su ordini"
SELECT DISTINCT o1.cliente_id
FROM ordini o1
JOIN ordini o2 ON o2.cliente_id = o1.cliente_id
WHERE o1.data_ordine LIKE '2024%' AND o2.data_ordine LIKE '2025%'
ORDER BY o1.cliente_id;

.print "\n── Esercizio 5: recensioni e voto medio per prodotto (tutti) ──"
SELECT p.nome,
       COUNT(r.id)          AS recensioni,
       ROUND(AVG(r.voto), 1) AS voto_medio      -- NULL se non ci sono recensioni
FROM prodotti p
LEFT JOIN recensioni r ON r.prodotto_id = p.id
GROUP BY p.id, p.nome
ORDER BY recensioni DESC, voto_medio DESC;

.print "\n── Esercizio 6: recensioni senza acquisto ──"
SELECT c.cognome, p.nome AS prodotto, rec.voto
FROM recensioni rec
JOIN clienti c  ON c.id = rec.cliente_id
JOIN prodotti p ON p.id = rec.prodotto_id
LEFT JOIN (SELECT o.cliente_id, r.prodotto_id
           FROM ordini o
           JOIN righe_ordine r ON r.ordine_id = o.id) acquisti
       ON acquisti.cliente_id = rec.cliente_id
      AND acquisti.prodotto_id = rec.prodotto_id
WHERE acquisti.cliente_id IS NULL;

.print "\n── Esercizio 7: trova l'errore (pezzi venduti nel 2025 per prodotto) ──"
-- Il WHERE su o.data_ordine scarta i prodotti senza vendite 2025
-- (o.data_ordine è NULL) e trasforma le LEFT JOIN in INNER.
-- Il filtro va spostato nella JOIN. Ma attenzione: deve agire sulle righe
-- d'ordine, quindi va "dentro" il collegamento prodotti -> righe -> ordini.
SELECT p.nome, COALESCE(SUM(v.quantita), 0) AS venduti_2025
FROM prodotti p
LEFT JOIN (SELECT r.prodotto_id, r.quantita
           FROM righe_ordine r
           JOIN ordini o ON o.id = r.ordine_id
           WHERE o.data_ordine >= '2025-01-01') v ON v.prodotto_id = p.id
GROUP BY p.id, p.nome
ORDER BY venduti_2025 DESC, p.nome;
-- Con la versione originale e il filtro spostato nell'ON di ordini, le
-- righe del 2024 resterebbero comunque (con o NULL) e verrebbero sommate:
-- per questo è più sicuro filtrare prima, nella sottoquery.

.print "\n── Esercizio 8: il 'nonno' nella gerarchia ──"
SELECT d.nome      AS dipendente,
       r.nome      AS responsabile,
       rr.nome     AS responsabile_del_responsabile
FROM dipendenti d
LEFT JOIN dipendenti r  ON r.id  = d.responsabile_id
LEFT JOIN dipendenti rr ON rr.id = r.responsabile_id
ORDER BY d.id;
