-- =====================================================================
--  SOLUZIONI - LEZIONE 9: WINDOW FUNCTION
-- =====================================================================

.print "\n── Esercizio 1: prezzo vs media della categoria ──"
SELECT nome, categoria_id, prezzo,
       ROUND(AVG(prezzo) OVER (PARTITION BY categoria_id), 2)          AS media_categoria,
       ROUND(prezzo - AVG(prezzo) OVER (PARTITION BY categoria_id), 2) AS differenza
FROM prodotti
ORDER BY categoria_id, prezzo DESC;

.print "\n── Esercizio 2: DENSE_RANK per prezzo nella categoria ──"
SELECT c.nome AS categoria, p.nome, p.prezzo,
       DENSE_RANK() OVER (PARTITION BY p.categoria_id ORDER BY p.prezzo DESC) AS posizione
FROM prodotti p
LEFT JOIN categorie c ON c.id = p.categoria_id
ORDER BY categoria, posizione;

.print "\n── Esercizio 3: il più caro di ogni categoria (top-1) ──"
WITH classifica AS (
    SELECT categoria_id, nome, prezzo,
           ROW_NUMBER() OVER (PARTITION BY categoria_id ORDER BY prezzo DESC) AS rn
    FROM prodotti
)
SELECT c.nome AS categoria, cl.nome, cl.prezzo
FROM classifica cl
JOIN categorie c ON c.id = cl.categoria_id
WHERE cl.rn = 1
ORDER BY c.nome;
-- Con RANK() al posto di ROW_NUMBER() i pari merito uscirebbero entrambi.

.print "\n── Esercizio 4: il primo ordine di ogni cliente ──"
WITH numerati AS (
    SELECT cliente_id, id, data_ordine,
           ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY data_ordine, id) AS rn
    FROM ordini
)
SELECT cliente_id, id AS primo_ordine, data_ordine
FROM numerati
WHERE rn = 1
ORDER BY cliente_id;

.print "\n── Esercizio 5: totale progressivo del cliente 4 ──"
WITH totali AS (
    SELECT o.id, o.data_ordine, SUM(r.quantita * r.prezzo_unitario) AS totale
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.cliente_id = 4
    GROUP BY o.id, o.data_ordine
)
SELECT id, data_ordine, totale,
       SUM(totale) OVER (ORDER BY data_ordine) AS speso_fin_qui
FROM totali
ORDER BY data_ordine;

.print "\n── Esercizio 6: media voti cumulativa per prodotto ──"
SELECT prodotto_id, data, voto,
       ROUND(AVG(voto) OVER (PARTITION BY prodotto_id ORDER BY data), 2) AS media_fino_a_qui
FROM recensioni
ORDER BY prodotto_id, data;

.print "\n── Esercizio 7: fatturato annuo e variazione % ──"
WITH annuale AS (
    SELECT strftime('%Y', o.data_ordine) AS anno,
           SUM(r.quantita * r.prezzo_unitario) AS fatturato
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.stato <> 'annullato'
    GROUP BY anno
)
SELECT anno,
       ROUND(fatturato, 2) AS fatturato,
       ROUND(100.0 * (fatturato - LAG(fatturato) OVER (ORDER BY anno))
             / LAG(fatturato) OVER (ORDER BY anno), 1) AS variazione_perc
FROM annuale;
-- (Il 2025 nel dataset contiene solo 6 mesi: il confronto va preso con le pinze!)

.print "\n── Esercizio 8: clienti divisi in 3 fasce di spesa ──"
WITH spesa AS (
    SELECT o.cliente_id, SUM(r.quantita * r.prezzo_unitario) AS speso
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.stato <> 'annullato'
    GROUP BY o.cliente_id
),
fasce AS (
    SELECT cliente_id, speso, NTILE(3) OVER (ORDER BY speso DESC) AS fascia
    FROM spesa
)
SELECT fascia, COUNT(*) AS clienti, ROUND(AVG(speso), 2) AS spesa_media
FROM fasce
GROUP BY fascia
ORDER BY fascia;
