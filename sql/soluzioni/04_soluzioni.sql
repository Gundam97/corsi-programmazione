-- =====================================================================
--  SOLUZIONI - LEZIONE 4: GROUP BY e HAVING
-- =====================================================================

.print "\n── Esercizio 1: prodotti per categoria_id (anche NULL) ──"
SELECT categoria_id, COUNT(*) AS num_prodotti
FROM prodotti
GROUP BY categoria_id
ORDER BY categoria_id;
-- La categoria 5 (Giochi) non compare: senza prodotti non ha righe in
-- prodotti. Per vederla serve una LEFT JOIN da categorie (lezione 6.6).

.print "\n── Esercizio 2: statistiche stipendi per reparto ──"
SELECT reparto,
       SUM(stipendio)           AS totale,
       ROUND(AVG(stipendio), 2) AS media,
       MIN(stipendio)           AS minimo,
       MAX(stipendio)           AS massimo
FROM dipendenti
GROUP BY reparto;

.print "\n── Esercizio 3: clienti registrati per anno ──"
SELECT strftime('%Y', data_registrazione) AS anno, COUNT(*) AS nuovi_clienti
FROM clienti
GROUP BY anno
ORDER BY anno;

.print "\n── Esercizio 4: pezzi e incasso per prodotto ──"
SELECT prodotto_id,
       SUM(quantita)                             AS pezzi,
       ROUND(SUM(quantita * prezzo_unitario), 2) AS incasso
FROM righe_ordine
GROUP BY prodotto_id
ORDER BY pezzi DESC, incasso DESC;
-- (Qui sono inclusi anche gli ordini annullati: per escluderli serve la
--  JOIN con ordini, lezione 6.)

.print "\n── Esercizio 5: prodotti presenti in almeno 4 ordini diversi ──"
SELECT prodotto_id, COUNT(DISTINCT ordine_id) AS ordini
FROM righe_ordine
GROUP BY prodotto_id
HAVING COUNT(DISTINCT ordine_id) >= 4
ORDER BY ordini DESC, prodotto_id;
-- In righe_ordine la coppia (ordine, prodotto) è unica, quindi qui
-- COUNT(*) darebbe lo stesso risultato. DISTINCT rende esplicita l'intenzione.

.print "\n── Esercizio 6: voto medio dei prodotti con almeno 2 recensioni ──"
SELECT prodotto_id,
       COUNT(*)             AS recensioni,
       ROUND(AVG(voto), 1)  AS voto_medio
FROM recensioni
GROUP BY prodotto_id
HAVING COUNT(*) >= 2
ORDER BY voto_medio DESC;

.print "\n── Esercizio 7: ordini e spese di spedizione per mese nel 2024 ──"
SELECT strftime('%Y-%m', data_ordine) AS mese,
       COUNT(*)                        AS ordini,
       ROUND(SUM(spese_spedizione), 2) AS spedizioni
FROM ordini
WHERE data_ordine LIKE '2024%'          -- filtro sulle RIGHE: WHERE
GROUP BY mese
HAVING SUM(spese_spedizione) > 0        -- filtro sui GRUPPI: HAVING
ORDER BY mese;

.print "\n── Esercizio 8: ordini gestiti per dipendente (più di 4) ──"
SELECT dipendente_id, COUNT(*) AS ordini_gestiti
FROM ordini
GROUP BY dipendente_id
HAVING COUNT(*) > 4
ORDER BY ordini_gestiti DESC, dipendente_id;
-- Il gruppo NULL sono gli ordini online (9).

.print "\n── Esercizio 9: prodotti per fascia di prezzo (aggregazione condizionale) ──"
SELECT SUM(CASE WHEN prezzo < 30                 THEN 1 ELSE 0 END) AS sotto_30,
       SUM(CASE WHEN prezzo BETWEEN 30 AND 100   THEN 1 ELSE 0 END) AS da_30_a_100,
       SUM(CASE WHEN prezzo > 100                THEN 1 ELSE 0 END) AS sopra_100
FROM prodotti;
-- Alternativa: COUNT(CASE WHEN prezzo < 30 THEN 1 END) - senza ELSE il CASE
-- dà NULL, e COUNT ignora i NULL.

.print "\n── Esercizio 10: la query che PostgreSQL rifiuta ──"
-- "nome" non è nel GROUP BY e non è aggregato: in ogni città ci sono più
-- clienti, quale nome dovrebbe mostrare? Correzioni possibili:
SELECT citta, COUNT(*) AS clienti, GROUP_CONCAT(nome, ', ') AS nomi
FROM clienti
GROUP BY citta;
-- oppure togliere "nome", oppure aggiungerlo al GROUP BY (ma allora i
-- gruppi diventano città+nome e il conteggio cambia significato).
