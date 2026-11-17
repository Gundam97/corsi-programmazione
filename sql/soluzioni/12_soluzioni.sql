-- =====================================================================
--  SOLUZIONI - LEZIONE 12: ESERCITAZIONE FINALE
-- =====================================================================
--  Spesso esistono più soluzioni corrette: se la tua è diversa ma dà gli
--  stessi numeri, va benissimo. Confronta i RISULTATI, non il testo.
-- =====================================================================

.print "\n── ★ 1. Ordini da evadere e valore della merce ──"
SELECT COUNT(DISTINCT o.id)                                    AS ordini_aperti,
       ROUND(COALESCE(SUM(r.quantita * r.prezzo_unitario), 0), 2) AS valore_merce
FROM ordini o
LEFT JOIN righe_ordine r ON r.ordine_id = o.id      -- LEFT: l'ordine 31 è vuoto ma va contato
WHERE o.stato IN ('in_attesa', 'spedito');

.print "\n── ★ 2. Prodotti con poca scorta e pezzi venduti ──"
SELECT p.nome,
       COALESCE(c.nome, '-')        AS categoria,
       p.scorta,
       COALESCE(SUM(r.quantita), 0) AS pezzi_venduti
FROM prodotti p
LEFT JOIN categorie c    ON c.id = p.categoria_id
LEFT JOIN righe_ordine r ON r.prodotto_id = p.id
                        AND r.ordine_id IN (SELECT id FROM ordini WHERE stato <> 'annullato')
WHERE p.scorta < 10
GROUP BY p.id, p.nome, c.nome, p.scorta
ORDER BY p.scorta;

.print "\n── ★★ 3. Fatturato 2024 dei venditori, con il loro responsabile ──"
SELECT d.nome || ' ' || d.cognome                    AS venditore,
       resp.nome || ' ' || resp.cognome              AS responsabile,
       COUNT(DISTINCT o.id)                          AS ordini,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2) AS fatturato_2024
FROM dipendenti d
JOIN dipendenti resp ON resp.id = d.responsabile_id
JOIN ordini o        ON o.dipendente_id = d.id
JOIN righe_ordine r  ON r.ordine_id = o.id
WHERE o.stato <> 'annullato'
  AND o.data_ordine BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY d.id, d.nome, d.cognome, resp.nome, resp.cognome
ORDER BY fatturato_2024 DESC;

.print "\n── ★★ 4. Giorno della settimana con più ordini ──"
SELECT CASE strftime('%w', data_ordine)
           WHEN '0' THEN 'Domenica'  WHEN '1' THEN 'Lunedì'  WHEN '2' THEN 'Martedì'
           WHEN '3' THEN 'Mercoledì' WHEN '4' THEN 'Giovedì' WHEN '5' THEN 'Venerdì'
           WHEN '6' THEN 'Sabato'
       END       AS giorno,
       COUNT(*)  AS ordini
FROM ordini
GROUP BY strftime('%w', data_ordine)
ORDER BY ordini DESC;
-- Mostro la classifica completa: se ci fossero pari merito in testa, LIMIT 1
-- ne nasconderebbe uno.

.print "\n── ★★ 5. Clienti dormienti (2024 sì, 2025 no) ──"
SELECT c.nome, c.cognome, c.email, MAX(o.data_ordine) AS ultimo_ordine
FROM clienti c
JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.id, c.nome, c.cognome, c.email
HAVING MAX(o.data_ordine) < '2025-01-01';
-- Trucco: "ha ordinato nel 2024 ma non nel 2025" (con dati che partono
-- dal 2024) equivale a "l'ultimo ordine è prima del 2025".

.print "\n── ★★ 6. Riepilogo per categoria (anche senza vendite) ──"
SELECT c.nome                                                AS categoria,
       COUNT(DISTINCT p.id)                                  AS prodotti_a_catalogo,
       COUNT(DISTINCT v.prodotto_id)                         AS prodotti_venduti,
       ROUND(COALESCE(SUM(v.quantita * v.prezzo_unitario), 0), 2) AS fatturato
FROM categorie c
LEFT JOIN prodotti p ON p.categoria_id = c.id
LEFT JOIN (SELECT r.*
           FROM righe_ordine r
           JOIN ordini o ON o.id = r.ordine_id
           WHERE o.stato <> 'annullato') v ON v.prodotto_id = p.id
GROUP BY c.id, c.nome
ORDER BY fatturato DESC;
-- Le righe d'ordine moltiplicano i prodotti -> COUNT(DISTINCT p.id).

.print "\n── ★★ 7. Scontrino medio per stato vs generale ──"
WITH totali AS (
    SELECT o.id, o.stato, SUM(r.quantita * r.prezzo_unitario) AS totale
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    GROUP BY o.id, o.stato
)
SELECT stato,
       COUNT(*)                                AS ordini,
       ROUND(AVG(totale), 2)                   AS scontrino_medio,
       ROUND((SELECT AVG(totale) FROM totali), 2) AS media_generale
FROM totali
GROUP BY stato
ORDER BY scontrino_medio DESC;
-- L'ordine 31 non ha righe: non ha uno scontrino, quindi è giusto escluderlo
-- (JOIN, non LEFT JOIN). Se lo includessi con totale 0 abbasserebbe la media.

.print "\n── ★★ 8. Prodotti venduti a un prezzo diverso dal listino ──"
SELECT p.nome,
       p.prezzo               AS listino,
       MIN(r.prezzo_unitario) AS prezzo_minimo,
       MAX(r.prezzo_unitario) AS prezzo_massimo,
       COUNT(*)               AS volte_venduto
FROM prodotti p
JOIN righe_ordine r ON r.prodotto_id = p.id
GROUP BY p.id, p.nome, p.prezzo
HAVING SUM(CASE WHEN r.prezzo_unitario <> p.prezzo THEN 1 ELSE 0 END) > 0
ORDER BY p.nome;

.print "\n── ★★★ 9. Mesi del 2024: fatturato, clienti, nuovi clienti ──"
WITH validi AS (
    SELECT * FROM ordini WHERE stato <> 'annullato'
),
primo_ordine AS (
    SELECT cliente_id, MIN(data_ordine) AS data_primo
    FROM validi
    GROUP BY cliente_id
),
fatturato_mese AS (
    SELECT strftime('%Y-%m', v.data_ordine) AS mese,
           SUM(r.quantita * r.prezzo_unitario) AS fatturato
    FROM validi v
    JOIN righe_ordine r ON r.ordine_id = v.id
    GROUP BY mese
)
SELECT strftime('%Y-%m', v.data_ordine)                AS mese,
       ROUND(f.fatturato, 2)                          AS fatturato,
       COUNT(DISTINCT v.cliente_id)                   AS clienti,
       COUNT(DISTINCT CASE WHEN v.data_ordine = p.data_primo THEN v.cliente_id END) AS nuovi
FROM validi v
JOIN primo_ordine p    ON p.cliente_id = v.cliente_id
JOIN fatturato_mese f  ON f.mese = strftime('%Y-%m', v.data_ordine)
WHERE v.data_ordine LIKE '2024%'
GROUP BY strftime('%Y-%m', v.data_ordine), f.fatturato
ORDER BY mese;
-- Il fatturato è calcolato in una CTE separata: se facessi la JOIN con
-- righe_ordine nella query principale, il COUNT(DISTINCT) andrebbe bene ma
-- è più facile sbagliare. Separare i calcoli = meno trappole.

.print "\n── ★★★ 10. Prodotti comprati insieme ──"
SELECT pa.nome AS prodotto_1,
       pb.nome AS prodotto_2,
       COUNT(*) AS ordini_insieme
FROM righe_ordine a
JOIN righe_ordine b ON b.ordine_id = a.ordine_id
                   AND a.prodotto_id < b.prodotto_id      -- ogni coppia una volta, mai con sé stesso
JOIN prodotti pa ON pa.id = a.prodotto_id
JOIN prodotti pb ON pb.id = b.prodotto_id
GROUP BY a.prodotto_id, b.prodotto_id, pa.nome, pb.nome
ORDER BY ordini_insieme DESC, prodotto_1, prodotto_2
LIMIT 10;
-- È la base dei suggerimenti "chi ha comprato X ha comprato anche Y".

.print "\n── ★★★ 11. Tempo medio tra un ordine e il successivo ──"
WITH intervalli AS (
    SELECT cliente_id,
           julianday(data_ordine)
             - julianday(LAG(data_ordine) OVER (PARTITION BY cliente_id ORDER BY data_ordine))
             AS giorni
    FROM ordini
    WHERE stato <> 'annullato'
)
SELECT c.cognome,
       COUNT(i.giorni) + 1        AS ordini,
       ROUND(AVG(i.giorni), 0)    AS giorni_medi_tra_ordini
FROM intervalli i
JOIN clienti c ON c.id = i.cliente_id
GROUP BY c.id, c.cognome
HAVING COUNT(i.giorni) >= 1        -- almeno un intervallo = almeno 2 ordini
ORDER BY giorni_medi_tra_ordini;
-- Il primo ordine di ogni cliente ha LAG = NULL: AVG e COUNT(i.giorni)
-- lo ignorano automaticamente.

.print "\n── ★★★ 12. Il report del direttore ──"
WITH righe AS (                         -- tutte le righe vendute, con anno, cliente e categoria
    SELECT strftime('%Y', o.data_ordine)        AS anno,
           o.id                                 AS ordine_id,
           o.cliente_id,
           COALESCE(cat.nome, '(senza categoria)') AS categoria,
           r.quantita * r.prezzo_unitario       AS importo
    FROM ordini o
    JOIN righe_ordine r     ON r.ordine_id = o.id
    JOIN prodotti p         ON p.id = r.prodotto_id
    LEFT JOIN categorie cat ON cat.id = p.categoria_id
    WHERE o.stato <> 'annullato'
),
per_anno AS (
    SELECT anno,
           SUM(importo)               AS fatturato,
           COUNT(DISTINCT ordine_id)  AS ordini
    FROM righe
    GROUP BY anno
),
miglior_cliente AS (
    SELECT anno, cliente_id
    FROM (SELECT anno, cliente_id,
                 ROW_NUMBER() OVER (PARTITION BY anno ORDER BY SUM(importo) DESC) AS rn
          FROM righe
          GROUP BY anno, cliente_id)
    WHERE rn = 1
),
miglior_categoria AS (
    SELECT anno, categoria
    FROM (SELECT anno, categoria,
                 ROW_NUMBER() OVER (PARTITION BY anno ORDER BY SUM(importo) DESC) AS rn
          FROM righe
          GROUP BY anno, categoria)
    WHERE rn = 1
)
SELECT pa.anno,
       ROUND(pa.fatturato, 2)              AS fatturato,
       pa.ordini,
       ROUND(pa.fatturato / pa.ordini, 2)  AS scontrino_medio,
       c.nome || ' ' || c.cognome          AS cliente_migliore,
       mc.categoria                        AS categoria_migliore
FROM per_anno pa
JOIN miglior_cliente mcl   ON mcl.anno = pa.anno
JOIN clienti c             ON c.id = mcl.cliente_id
JOIN miglior_categoria mc  ON mc.anno = pa.anno
ORDER BY pa.anno;
-- Nota: in una window function si può usare un'aggregazione
-- (ORDER BY SUM(importo)): la window viene calcolata DOPO il GROUP BY.
