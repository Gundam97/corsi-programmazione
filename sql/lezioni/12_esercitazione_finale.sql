-- =====================================================================
--  SQL - LEZIONE 12: ESERCITAZIONE FINALE
--  "Il direttore vuole dei numeri"
-- =====================================================================
--
--  Nel lavoro vero nessuno ti dice "fai una LEFT JOIN con GROUP BY".
--  Ti fanno una DOMANDA in italiano, e sta a te tradurla in SQL.
--
--  METODO IN 5 PASSI (usalo sempre!)
--   1. CAPISCI la domanda: cosa deve contenere OGNI RIGA del risultato?
--      ("una riga per cliente", "una riga per mese e categoria"...)
--   2. TROVA le tabelle: dove sono i dati che servono? Come si collegano?
--   3. COSTRUISCI a pezzi: prima FROM + JOIN, guarda le righe grezze.
--   4. FILTRA e AGGREGA: WHERE, GROUP BY, HAVING. Controlla i NULL e
--      la moltiplicazione delle righe (fan-out).
--   5. VERIFICA: i numeri tornano? Prova su un caso che sai calcolare a
--      mano (un cliente, un ordine).
--
--  Prima un esempio risolto passo per passo, poi tocca a te.
-- =====================================================================

-- =====================================================================
--  ESEMPIO GUIDATO
--  "Per ogni città, quanti clienti hanno ordinato, quanto hanno speso in
--   totale e qual è il prodotto più venduto (per pezzi) in quella città?
--   Considera solo gli ordini non annullati."
-- =====================================================================
--  PASSO 1: una riga per CITTÀ, con 3 informazioni.
--  PASSO 2: clienti (città) -> ordini (stato) -> righe_ordine (pezzi,
--           importi) -> prodotti (nome).
--  La terza informazione è un "top-1 per gruppo": servirà ROW_NUMBER.
-- =====================================================================

.print "\n── Passo 3: le righe grezze (una per riga d'ordine) ──"
SELECT c.citta, c.id AS cliente, o.id AS ordine, p.nome AS prodotto,
       r.quantita, r.quantita * r.prezzo_unitario AS importo
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
WHERE o.stato <> 'annullato' AND c.citta = 'Bologna';   -- guardo una città sola per controllare

.print "\n── Passo 4a: clienti e spesa per città ──"
-- ATTENZIONE: dopo la JOIN un cliente compare più volte -> COUNT(DISTINCT)
SELECT c.citta,
       COUNT(DISTINCT c.id)                           AS clienti,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2)  AS speso
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.stato <> 'annullato'
GROUP BY c.citta;

.print "\n── Passo 4b: il prodotto più venduto per città ──"
WITH pezzi AS (
    SELECT c.citta, p.nome AS prodotto, SUM(r.quantita) AS pezzi
    FROM clienti c
    JOIN ordini o       ON o.cliente_id = c.id
    JOIN righe_ordine r ON r.ordine_id = o.id
    JOIN prodotti p     ON p.id = r.prodotto_id
    WHERE o.stato <> 'annullato'
    GROUP BY c.citta, p.id, p.nome
)
SELECT *
FROM (SELECT citta, prodotto, pezzi,
             ROW_NUMBER() OVER (PARTITION BY citta ORDER BY pezzi DESC, prodotto) AS pos
      FROM pezzi)
WHERE pos <= 2            -- mostro i primi 2 per città, per controllare i pari merito
ORDER BY citta, pos;
-- A parità di pezzi decido io la regola (qui: ordine alfabetico), così il
-- risultato è stabile. Senza, il database sceglierebbe a caso.

.print "\n── Passo 5: metto insieme i pezzi con le CTE ──"
WITH base AS (
    SELECT c.citta, c.id AS cliente_id, p.nome AS prodotto,
           r.quantita, r.quantita * r.prezzo_unitario AS importo
    FROM clienti c
    JOIN ordini o       ON o.cliente_id = c.id
    JOIN righe_ordine r ON r.ordine_id = o.id
    JOIN prodotti p     ON p.id = r.prodotto_id
    WHERE o.stato <> 'annullato'
),
per_citta AS (
    SELECT citta, COUNT(DISTINCT cliente_id) AS clienti, SUM(importo) AS speso
    FROM base
    GROUP BY citta
),
top_prodotto AS (
    SELECT citta, prodotto, pezzi
    FROM (SELECT citta, prodotto, SUM(quantita) AS pezzi,
                 ROW_NUMBER() OVER (PARTITION BY citta ORDER BY SUM(quantita) DESC, prodotto) AS pos
          FROM base
          GROUP BY citta, prodotto)
    WHERE pos = 1
)
SELECT COALESCE(pc.citta, '(non indicata)') AS citta,
       pc.clienti,
       ROUND(pc.speso, 2)                   AS speso,
       tp.prodotto || ' (' || tp.pezzi || ' pz)' AS piu_venduto
FROM per_citta pc
JOIN top_prodotto tp ON tp.citta IS pc.citta     -- IS: confronto che considera uguali due NULL
ORDER BY pc.speso DESC;
-- Nota finale: la città NULL (cliente Marino) è un gruppo a sé. Con "="
-- la JOIN l'avrebbe persa (NULL = NULL non è vero): per questo ho usato
-- IS, che in SQLite confronta anche i NULL (nello standard: IS NOT DISTINCT FROM).
-- Verifica: Bologna ha 2 clienti (Ricci, Costa) e 135 + 1548 = 1683 €. ✔

/* =====================================================================
   ADESSO TOCCA A TE
   (soluzioni in: soluzioni/12_soluzioni.sql - prova davvero prima di guardarle!)
   =====================================================================

   ★ = facile    ★★ = medio    ★★★ = difficile

   ★   1. Quanti ordini sono ancora da evadere ('in_attesa' o 'spedito') e
          per quale valore totale di merce?

   ★   2. Elenco dei prodotti con scorta inferiore a 10, con il nome della
          categoria e quanti pezzi ne abbiamo venduti in tutto.

   ★★  3. Il fatturato (merce, ordini non annullati) di ogni venditore nel
          2024, con il nome del suo responsabile. Ordina dal migliore.

   ★★  4. Qual è il giorno della settimana in cui riceviamo più ordini?

   ★★  5. Clienti "dormienti": hanno ordinato nel 2024 ma non nel 2025.
          Mostra nome, email e data dell'ultimo ordine.

   ★★  6. Per ogni categoria (anche quelle senza vendite): numero di
          prodotti a catalogo, prodotti venduti almeno una volta, fatturato.

   ★★  7. Lo scontrino medio (totale merce per ordine) per stato dell'ordine,
          confrontato con lo scontrino medio generale.

   ★★  8. I prodotti che sono stati venduti a un prezzo DIVERSO dal listino,
          con il prezzo minimo e massimo a cui sono stati venduti.

   ★★★ 9. Per ogni mese del 2024: fatturato, numero di clienti DIVERSI che
          hanno ordinato, e quanti di questi erano al loro PRIMO ordine
          in assoluto.

   ★★★ 10. Prodotti comprati INSIEME: le coppie di prodotti che compaiono
           nello stesso ordine, con il numero di ordini in cui compaiono
           insieme (ogni coppia una volta sola).

   ★★★ 11. Per ogni cliente con almeno 2 ordini non annullati: tempo medio
           (in giorni) tra un ordine e il successivo.

   ★★★ 12. Il "report del direttore": per ogni anno, fatturato, numero
           ordini, scontrino medio, cliente migliore (nome) e categoria
           migliore (nome), in UNA sola query.
   ===================================================================== */
