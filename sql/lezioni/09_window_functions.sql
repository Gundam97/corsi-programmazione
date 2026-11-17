-- =====================================================================
--  SQL - LEZIONE 9: LE WINDOW FUNCTION (funzioni finestra)
-- =====================================================================
--
--  IL PROBLEMA
--  Con GROUP BY ottengo lo stipendio medio per reparto, ma PERDO il
--  dettaglio: una riga per reparto. E se volessi vedere OGNI dipendente
--  E ACCANTO la media del suo reparto? Con GROUP BY non si può.
--
--  LA SOLUZIONE: OVER (...)
--  Una window function calcola un valore su un gruppo di righe (la
--  "finestra") ma SENZA COLLASSARLE: ogni riga resta al suo posto.
--
--      funzione(...) OVER (
--          PARTITION BY ...   -- come GROUP BY: divide in gruppi (facoltativo)
--          ORDER BY ...       -- ordine dentro ogni gruppo (facoltativo)
--          ROWS BETWEEN ...   -- quali righe considerare (facoltativo)
--      )
--
--      GROUP BY reparto             ...OVER (PARTITION BY reparto)
--      ┌───────────┬───────┐        ┌───────┬───────────┬───────┬───────┐
--      │ Vendite   │ 2440  │        │ Andrea│ Vendite   │ 2400  │ 2440  │
--      │ Logistica │ 2600  │        │ Matteo│ Vendite   │ 2200  │ 2440  │
--      └───────────┴───────┘        │ Irene │ Logistica │ 1900  │ 2600  │
--       1 riga per gruppo           └───────┴───────────┴───────┴───────┘
--                                    tutte le righe + il valore del gruppo
--
--  Le window function vengono calcolate DOPO WHERE, GROUP BY e HAVING
--  (insieme alla SELECT). Quindi NON si possono usare nel WHERE: per
--  filtrarle serve una CTE o una subquery (lo vediamo in 9.6).
-- =====================================================================

.print "\n── 9.1 Ogni dipendente con la media generale e quella del suo reparto ──"
SELECT nome, reparto, stipendio,
       ROUND(AVG(stipendio) OVER (), 0)                     AS media_aziendale,
       ROUND(AVG(stipendio) OVER (PARTITION BY reparto), 0) AS media_reparto,
       stipendio - ROUND(AVG(stipendio) OVER (PARTITION BY reparto), 0) AS scarto
FROM dipendenti
ORDER BY reparto, stipendio DESC;
-- OVER () vuoto = la finestra è TUTTA la tabella.

.print "\n── 9.2 Peso percentuale di ogni stipendio sul totale del reparto ──"
SELECT nome, reparto, stipendio,
       ROUND(100.0 * stipendio / SUM(stipendio) OVER (PARTITION BY reparto), 1) AS perc_reparto,
       COUNT(*) OVER (PARTITION BY reparto) AS colleghi_nel_reparto
FROM dipendenti
ORDER BY reparto, stipendio DESC;

-- =====================================================================
--  FUNZIONI DI RANKING: ROW_NUMBER, RANK, DENSE_RANK
-- =====================================================================
--  Numerano le righe secondo l'ORDER BY della finestra.
--  La differenza si vede solo con i PARI MERITO:
--     ROW_NUMBER  1, 2, 3, 4   (sempre diversi: i pari merito in ordine casuale)
--     RANK        1, 2, 2, 4   (pari merito stessa posizione, poi SALTA)
--     DENSE_RANK  1, 2, 2, 3   (pari merito stessa posizione, NON salta)
-- =====================================================================

.print "\n── 9.3 Classifica stipendi: le tre funzioni a confronto ──"
-- Irene e Simone guadagnano entrambi 1900: guarda le ultime righe.
SELECT nome, stipendio,
       ROW_NUMBER() OVER (ORDER BY stipendio DESC) AS row_number,
       RANK()       OVER (ORDER BY stipendio DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY stipendio DESC) AS dense_rank
FROM dipendenti
ORDER BY stipendio DESC;

.print "\n── 9.4 Classifica DENTRO ogni gruppo: PARTITION BY + ORDER BY ──"
-- La numerazione riparte da 1 per ogni reparto.
SELECT reparto, nome, stipendio,
       RANK() OVER (PARTITION BY reparto ORDER BY stipendio DESC) AS pos_nel_reparto
FROM dipendenti
ORDER BY reparto, pos_nel_reparto;

.print "\n── 9.5 ERRORE: una window function non può stare nel WHERE ──"
-- SELECT nome FROM dipendenti
-- WHERE RANK() OVER (ORDER BY stipendio DESC) <= 3;
--   -> Error: misuse of window function RANK()
-- Motivo: WHERE viene eseguito PRIMA che le window function siano calcolate.
.print "   (query commentata: vedi il file)"

.print "\n── 9.6 TOP-N PER GRUPPO: i 2 prodotti più venduti di ogni categoria ──"
-- Lo schema classico (da imparare a memoria!):
--   1) CTE che calcola il ranking
--   2) query esterna che filtra sul ranking
WITH vendite AS (
    SELECT cat.nome                     AS categoria,
           p.nome                       AS prodotto,
           SUM(r.quantita * r.prezzo_unitario) AS fatturato
    FROM righe_ordine r
    JOIN ordini o      ON o.id = r.ordine_id AND o.stato <> 'annullato'
    JOIN prodotti p    ON p.id = r.prodotto_id
    JOIN categorie cat ON cat.id = p.categoria_id
    GROUP BY cat.nome, p.id, p.nome
),
classifica AS (
    SELECT categoria, prodotto, fatturato,
           ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY fatturato DESC) AS pos
    FROM vendite
)
SELECT categoria, pos, prodotto, ROUND(fatturato, 2) AS fatturato
FROM classifica
WHERE pos <= 2
ORDER BY categoria, pos;

.print "\n── 9.7 Deduplicare: l'ULTIMO ordine di ogni cliente ──"
-- Altro uso classicissimo di ROW_NUMBER: tenere una sola riga per gruppo.
WITH numerati AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY data_ordine DESC) AS rn
    FROM ordini o
)
SELECT cliente_id, id AS ultimo_ordine, data_ordine, stato
FROM numerati
WHERE rn = 1
ORDER BY cliente_id;

-- =====================================================================
--  TOTALI PROGRESSIVI e MEDIE MOBILI
-- =====================================================================
--  Con ORDER BY dentro OVER, le funzioni di aggregazione diventano
--  "cumulative": per ogni riga considerano le righe dall'inizio fino a lei.
-- =====================================================================

.print "\n── 9.8 Fatturato mensile e totale progressivo (running total) ──"
WITH mensile AS (
    SELECT strftime('%Y-%m', o.data_ordine)    AS mese,
           SUM(r.quantita * r.prezzo_unitario) AS fatturato
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.stato <> 'annullato'
    GROUP BY mese
)
SELECT mese,
       ROUND(fatturato, 2)                                   AS fatturato,
       ROUND(SUM(fatturato) OVER (ORDER BY mese), 2)         AS progressivo,
       ROUND(SUM(fatturato) OVER (PARTITION BY substr(mese, 1, 4)
                                  ORDER BY mese), 2)         AS progressivo_anno
FROM mensile
ORDER BY mese;
-- Manca 2024-04: quel mese c'è solo un ordine annullato. Se il mese deve
-- comparire con 0, si usa il calendario generato della lezione 7.18.

.print "\n── 9.9 Media mobile a 3 mesi (il FRAME: ROWS BETWEEN) ──"
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = questa riga e le 2 precedenti.
-- Utile per "lisciare" un andamento irregolare.
WITH mensile AS (
    SELECT strftime('%Y-%m', o.data_ordine)    AS mese,
           SUM(r.quantita * r.prezzo_unitario) AS fatturato
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.stato <> 'annullato'
    GROUP BY mese
)
SELECT mese,
       ROUND(fatturato, 2) AS fatturato,
       ROUND(AVG(fatturato) OVER (ORDER BY mese
                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_mobile_3m
FROM mensile
ORDER BY mese
LIMIT 8;

-- =====================================================================
--  LAG e LEAD: guardare la riga PRECEDENTE o SUCCESSIVA
-- =====================================================================
--     LAG(colonna, n, default)   valore di n righe PRIMA  (default n = 1)
--     LEAD(colonna, n, default)  valore di n righe DOPO
-- =====================================================================

.print "\n── 9.10 Variazione rispetto al mese precedente ──"
WITH mensile AS (
    SELECT strftime('%Y-%m', o.data_ordine) AS mese, COUNT(*) AS ordini
    FROM ordini o
    GROUP BY mese
)
SELECT mese, ordini,
       LAG(ordini) OVER (ORDER BY mese)          AS mese_prima,
       ordini - LAG(ordini) OVER (ORDER BY mese) AS variazione
FROM mensile
ORDER BY mese
LIMIT 8;
-- La prima riga ha NULL: non esiste un mese precedente.

.print "\n── 9.11 Ogni quanti giorni riordina un cliente? ──"
SELECT cliente_id, id AS ordine, data_ordine,
       LAG(data_ordine) OVER w AS ordine_precedente,
       CAST(julianday(data_ordine) - julianday(LAG(data_ordine) OVER w) AS INTEGER) AS giorni_dopo,
       LEAD(data_ordine) OVER w AS ordine_successivo
FROM ordini
WHERE cliente_id IN (1, 2)
WINDOW w AS (PARTITION BY cliente_id ORDER BY data_ordine)   -- finestra con nome, riusata
ORDER BY cliente_id, data_ordine;

.print "\n── 9.12 FIRST_VALUE e la trappola di LAST_VALUE ──"
-- Il frame di DEFAULT (quando c'è ORDER BY) va dall'inizio alla riga
-- CORRENTE. Quindi LAST_VALUE restituisce... la riga corrente!
-- Per avere davvero l'ultima serve allargare il frame fino alla fine.
SELECT nome, reparto, stipendio,
       FIRST_VALUE(nome) OVER (PARTITION BY reparto ORDER BY stipendio DESC) AS piu_pagato,
       LAST_VALUE(nome)  OVER (PARTITION BY reparto ORDER BY stipendio DESC) AS last_SBAGLIATO,
       LAST_VALUE(nome)  OVER (PARTITION BY reparto ORDER BY stipendio DESC
                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                                              AS meno_pagato
FROM dipendenti
WHERE reparto <> 'Direzione'
ORDER BY reparto, stipendio DESC;
-- Dettaglio sottile: sulla riga di Irene, last_SBAGLIATO vale "Simone" e non
-- "Irene". Il frame di default è RANGE (non ROWS): include anche le righe
-- "pari merito" con lo stesso valore di ORDER BY (stesso stipendio 1900).

.print "\n── 9.13 NTILE: dividere in fasce di uguale numerosità ──"
-- NTILE(4) divide le righe ordinate in 4 gruppi (quartili).
SELECT nome, prezzo,
       NTILE(4) OVER (ORDER BY prezzo) AS quartile_prezzo
FROM prodotti
ORDER BY prezzo;

.print "\n── 9.14 Mettere tutto insieme: scheda cliente ──"
WITH spesa AS (
    SELECT c.id, c.cognome, c.citta,
           SUM(r.quantita * r.prezzo_unitario) AS speso
    FROM clienti c
    JOIN ordini o       ON o.cliente_id = c.id AND o.stato <> 'annullato'
    JOIN righe_ordine r ON r.ordine_id = o.id
    GROUP BY c.id, c.cognome, c.citta
)
SELECT cognome, citta,
       ROUND(speso, 2)                                                    AS speso,
       RANK() OVER (ORDER BY speso DESC)                                  AS classifica,
       RANK() OVER (PARTITION BY citta ORDER BY speso DESC)               AS in_citta,
       ROUND(100.0 * speso / SUM(speso) OVER (), 1)                       AS perc_fatturato,
       ROUND(100.0 * SUM(speso) OVER (ORDER BY speso DESC) / SUM(speso) OVER (), 1) AS perc_cumulata
FROM spesa
ORDER BY classifica;
-- perc_cumulata risponde a domande tipo "quanti clienti fanno l'80% del
-- fatturato?" (principio di Pareto).

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/09_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Per ogni prodotto: nome, prezzo, prezzo medio della sua categoria
      e differenza (window function, NON subquery correlata).
   2. Classifica dei prodotti per prezzo dentro ogni categoria con
      DENSE_RANK.
   3. Il prodotto più caro di ogni categoria (top-1 per gruppo).
   4. Il PRIMO ordine di ogni cliente (data e id).
   5. Per ogni ordine del cliente 4: totale dell'ordine e totale
      progressivo speso dal cliente fino a quel momento.
   6. Per ogni recensione: voto, e voto medio del prodotto calcolato sulle
      recensioni fino a quella data inclusa (media cumulativa).
   7. Fatturato per anno e variazione percentuale rispetto all'anno prima
      (LAG).
   8. Dividi i clienti che hanno ordinato in 3 fasce di spesa con NTILE(3)
      e mostra per ogni fascia il numero di clienti e la spesa media.
   --------------------------------------------------------------------- */
