-- =====================================================================
--  SQL - LEZIONE 5: LE JOIN (collegare le tabelle)
-- =====================================================================
--
--  PERCHÉ I DATI SONO DIVISI IN PIÙ TABELLE?
--  Nella tabella ordini non c'è il nome del cliente, solo cliente_id.
--  Se scrivessimo nome, email e città del cliente in OGNI ordine:
--    - ripeteremmo gli stessi dati decine di volte
--    - se il cliente cambia email, dovremmo aggiornarla ovunque
--      (e prima o poi ne dimenticheremmo una: dati incoerenti!)
--  Quindi ogni informazione sta in UN posto solo, e le tabelle si
--  collegano tramite le CHIAVI:
--    - CHIAVE PRIMARIA (PK): identifica una riga (clienti.id)
--    - CHIAVE ESTERNA  (FK): "punta" alla PK di un'altra tabella
--                            (ordini.cliente_id -> clienti.id)
--
--  La JOIN rimette insieme i pezzi:
--
--      SELECT ...
--      FROM ordini o
--      JOIN clienti c ON c.id = o.cliente_id     -- condizione di collegamento
--
--  COME RAGIONA UNA JOIN (modello mentale)
--   1. Prende OGNI riga della prima tabella e la abbina a OGNI riga della
--      seconda (prodotto cartesiano: 31 ordini x 16 clienti = 496 coppie)
--   2. Tiene solo le coppie per cui la condizione ON è vera
--  (Il database in realtà è molto più furbo, ma il RISULTATO è questo.)
--
--  I TIPI DI JOIN
--
--     INNER JOIN   solo le righe che hanno una corrispondenza in ENTRAMBE
--     LEFT JOIN    TUTTE le righe della tabella di sinistra; se non c'è
--                  corrispondenza a destra, le colonne di destra sono NULL
--     RIGHT JOIN   il contrario (poco usata: basta invertire le tabelle)
--     FULL JOIN    tutte le righe di entrambe, con NULL dove manca l'abbinamento
--     CROSS JOIN   tutte le combinazioni possibili (prodotto cartesiano)
--
--          A        B             INNER: ▓ (solo l'intersezione)
--        ┌───┬───┬───┐            LEFT:  A completa + ▓
--        │ A │ ▓ │ B │            RIGHT: ▓ + B completa
--        └───┴───┴───┘            FULL:  tutto
-- =====================================================================

.print "\n── 5.1 Il prodotto cartesiano (CROSS JOIN) ──"
-- Ogni categoria abbinata a ogni stato possibile: 5 x 2 = 10 righe.
-- È il "punto di partenza" di ogni JOIN.
SELECT c.nome AS categoria, s.stato
FROM categorie c
CROSS JOIN (SELECT 'disponibile' AS stato UNION ALL SELECT 'esaurito') s;

.print "\n── 5.2 INNER JOIN: ogni prodotto con il nome della sua categoria ──"
-- p e c sono ALIAS delle tabelle: abbreviano e servono a distinguere
-- colonne con lo stesso nome (sia prodotti che categorie hanno "id" e "nome").
SELECT p.nome   AS prodotto,
       c.nome   AS categoria,
       p.prezzo
FROM prodotti p
INNER JOIN categorie c ON c.id = p.categoria_id
ORDER BY c.nome, p.nome;
-- CONTA LE RIGHE: sono 17, non 18. Manca "Gift card 50€" perché ha
-- categoria_id NULL e NULL = qualcosa non è mai vero.
-- Manca anche la categoria "Giochi", che non ha prodotti.
-- (INNER JOIN e JOIN sono la stessa cosa: INNER è facoltativo.)

.print "\n── 5.3 ERRORE: colonna ambigua ──"
-- SELECT nome FROM prodotti p JOIN categorie c ON c.id = p.categoria_id;
--   -> Error: ambiguous column name: nome
-- Quale "nome"? Del prodotto o della categoria? Va sempre qualificato: p.nome
.print "   (query commentata: vedi il file)"

.print "\n── 5.4 LEFT JOIN: TUTTI i prodotti, anche senza categoria ──"
SELECT p.nome AS prodotto,
       c.nome AS categoria
FROM prodotti p
LEFT JOIN categorie c ON c.id = p.categoria_id
WHERE p.id >= 14;
-- La Gift card ora c'è, con categoria NULL.

.print "\n── 5.5 LEFT JOIN dall'altra parte: TUTTE le categorie ──"
-- L'ordine delle tabelle conta! "Sinistra" = quella scritta prima.
SELECT c.nome AS categoria,
       p.nome AS prodotto
FROM categorie c
LEFT JOIN prodotti p ON p.categoria_id = c.id
ORDER BY c.nome, p.nome;
-- "Giochi" compare una volta con prodotto NULL.

.print "\n── 5.6 RIGHT JOIN: equivale alla 5.5 con le tabelle invertite ──"
SELECT c.nome AS categoria, p.nome AS prodotto
FROM prodotti p
RIGHT JOIN categorie c ON p.categoria_id = c.id
WHERE p.id IS NULL;

.print "\n── 5.7 FULL OUTER JOIN: tutto, da entrambe le parti ──"
-- Mostriamo solo le righe "spaiate" per vederle bene:
-- la categoria senza prodotti E il prodotto senza categoria.
-- (MySQL non supporta FULL JOIN: si simula con LEFT JOIN UNION RIGHT JOIN)
SELECT c.nome AS categoria, p.nome AS prodotto
FROM categorie c
FULL OUTER JOIN prodotti p ON p.categoria_id = c.id
WHERE c.id IS NULL OR p.id IS NULL;

.print "\n── 5.8 Elenco ordini con il nome del cliente ──"
SELECT o.id, o.data_ordine, o.stato,
       c.nome || ' ' || c.cognome AS cliente,
       c.citta
FROM ordini o
JOIN clienti c ON c.id = o.cliente_id
WHERE o.data_ordine >= '2025-01-01'
ORDER BY o.data_ordine;

.print "\n── 5.9 Più JOIN in fila: il dettaglio completo di un ordine ──"
-- ordini -> clienti        (chi ha comprato)
-- ordini -> righe_ordine   (cosa c'è nell'ordine)
-- righe  -> prodotti       (come si chiama il prodotto)
-- prodotti -> categorie    (di che categoria è)
SELECT o.id                         AS ordine,
       c.nome || ' ' || c.cognome   AS cliente,
       p.nome                       AS prodotto,
       cat.nome                     AS categoria,
       r.quantita,
       r.prezzo_unitario,
       r.quantita * r.prezzo_unitario AS subtotale
FROM ordini o
JOIN clienti      c   ON c.id = o.cliente_id
JOIN righe_ordine r   ON r.ordine_id = o.id
JOIN prodotti     p   ON p.id = r.prodotto_id
LEFT JOIN categorie cat ON cat.id = p.categoria_id   -- LEFT: la gift card non ha categoria
WHERE o.id IN (11, 15, 16)
ORDER BY o.id, p.nome;

.print "\n── 5.10 Chi ha gestito l'ordine? (LEFT JOIN: gli ordini online restano) ──"
SELECT o.id,
       o.data_ordine,
       COALESCE(d.nome || ' ' || d.cognome, '(online)') AS gestito_da
FROM ordini o
LEFT JOIN dipendenti d ON d.id = o.dipendente_id
WHERE o.id <= 8
ORDER BY o.id;

.print "\n── 5.11 Condizioni multiple nell'ON: prezzo pagato vs listino ──"
-- Righe d'ordine pagate MENO del prezzo di listino attuale (sconti)
SELECT r.ordine_id, p.nome, p.prezzo AS listino, r.prezzo_unitario AS pagato,
       ROUND(100.0 * (p.prezzo - r.prezzo_unitario) / p.prezzo, 1) AS sconto_perc
FROM righe_ordine r
JOIN prodotti p ON p.id = r.prodotto_id AND r.prezzo_unitario < p.prezzo
ORDER BY sconto_perc DESC;

.print "\n── 5.12 Sintassi 'vecchia' (implicita): da riconoscere, non da usare ──"
-- Le tabelle separate da virgola + condizione nel WHERE. Funziona come
-- una INNER JOIN, ma se dimentichi la condizione ottieni il prodotto
-- cartesiano senza accorgertene. Usa sempre JOIN ... ON.
SELECT o.id, c.cognome
FROM ordini o, clienti c
WHERE c.id = o.cliente_id AND o.id <= 3;

.print "\n── 5.13 JOIN ... USING: scorciatoia quando le colonne hanno lo stesso nome ──"
-- Qui non si applica bene (le nostre FK si chiamano cliente_id, le PK id),
-- quindi lo mostriamo con due sottoquery che hanno entrambe "ordine_id".
SELECT ordine_id, num_righe, stato
FROM (SELECT ordine_id, COUNT(*) AS num_righe FROM righe_ordine GROUP BY ordine_id)
JOIN (SELECT id AS ordine_id, stato FROM ordini) USING (ordine_id)
WHERE ordine_id <= 4;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/05_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Elenca tutte le recensioni con: nome del prodotto, nome e cognome
      del cliente, voto e commento.
   2. Elenca gli ordini del 2024 consegnati con cognome del cliente e
      cognome del dipendente che li ha gestiti (solo ordini con dipendente).
   3. Rifai l'esercizio 2 includendo anche gli ordini online, mostrando
      'online' al posto del dipendente.
   4. Elenca tutte le categorie con i loro prodotti, incluse le categorie
      vuote. Ordina per categoria e prezzo decrescente.
   5. Tutti i prodotti acquistati da clienti di Milano: nome cliente,
      nome prodotto, data ordine.
   6. Per l'ordine 16 mostra prodotto, quantità, prezzo pagato, prezzo di
      listino e quanto ha risparmiato il cliente su ogni riga.
   7. Elenca i libri (categoria 'Libri', usa il NOME, non l'id!) che sono
      stati venduti, con le date degli ordini.
   8. Quanti abbinamenti produce  clienti CROSS JOIN prodotti? Calcolalo
      con COUNT(*) e verifica che sia 16 x 18.
   --------------------------------------------------------------------- */
