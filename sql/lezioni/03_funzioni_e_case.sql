-- =====================================================================
--  SQL - LEZIONE 3: FUNZIONI, DATE, COALESCE e CASE
-- =====================================================================
--
--  Le funzioni trasformano i valori di OGNI SINGOLA RIGA (sono funzioni
--  "scalari": una riga in ingresso, un valore in uscita).
--  Da non confondere con le funzioni di AGGREGAZIONE (COUNT, SUM...)
--  della lezione 4, che riassumono MOLTE righe in un solo valore.
--
--  ATTENZIONE AI "DIALETTI": il cuore di SQL è standard, ma le funzioni
--  cambiano un po' da un database all'altro. Qui usiamo SQLite; nei
--  commenti trovi l'equivalente per MySQL / PostgreSQL quando è diverso.
-- =====================================================================

.print "\n── 3.1 Funzioni sul testo ──"
SELECT nome,
       UPPER(nome)             AS maiuscolo,
       LOWER(nome)             AS minuscolo,
       LENGTH(nome)            AS lunghezza,
       SUBSTR(nome, 1, 3)      AS prime_3,        -- da posizione 1, 3 caratteri
       REPLACE(nome, ' ', '_') AS senza_spazi
FROM prodotti
LIMIT 5;

.print "\n── 3.2 Estrarre il dominio dall'email ──"
-- INSTR trova la posizione di un carattere (in MySQL: LOCATE, in PostgreSQL: POSITION)
SELECT email,
       INSTR(email, '@')                      AS posizione_chiocciola,
       SUBSTR(email, 1, INSTR(email, '@') - 1) AS utente,
       SUBSTR(email, INSTR(email, '@') + 1)    AS dominio
FROM clienti
ORDER BY id
LIMIT 4;

.print "\n── 3.3 Funzioni numeriche ──"
SELECT prezzo,
       ROUND(prezzo)           AS arrotondato,
       ROUND(prezzo * 0.85, 2) AS scontato_15,
       CAST(prezzo AS INTEGER) AS troncato,   -- toglie i decimali
       ABS(prezzo - 50)        AS distanza_da_50
FROM prodotti
LIMIT 5;

.print "\n── 3.4 TRAPPOLA: divisione tra interi ──"
-- Proprio come in Java: intero / intero = intero!
SELECT 7 / 2       AS intera,
       7 / 2.0     AS decimale,
       CAST(7 AS REAL) / 2 AS con_cast;

.print "\n── 3.5 Date: estrarre parti con strftime ──"
-- SQLite salva le date come testo. strftime(formato, data):
--   %Y anno   %m mese   %d giorno   %w giorno settimana (0 = domenica)
-- MySQL: YEAR(d), MONTH(d)      PostgreSQL: EXTRACT(YEAR FROM d)
SELECT id,
       data_ordine,
       strftime('%Y', data_ordine)    AS anno,
       strftime('%m', data_ordine)    AS mese,
       strftime('%Y-%m', data_ordine) AS anno_mese
FROM ordini
LIMIT 5;

.print "\n── 3.6 Date: calcoli ──"
-- date(d, '+N days') aggiunge giorni; julianday() trasforma una data in un
-- numero di giorni, così la differenza tra due date è una sottrazione.
-- MySQL: DATE_ADD / DATEDIFF      PostgreSQL: d + INTERVAL '7 days' / d1 - d2
SELECT id,
       data_ordine,
       date(data_ordine, '+7 days')                         AS consegna_prevista,
       CAST(julianday('2025-12-31') - julianday(data_ordine) AS INTEGER) AS giorni_a_fine_2025
FROM ordini
LIMIT 5;

.print "\n── 3.7 Anzianità dei dipendenti (in anni) ──"
SELECT nome, cognome, data_assunzione,
       CAST((julianday('2025-12-31') - julianday(data_assunzione)) / 365.25 AS INTEGER)
           AS anni_servizio
FROM dipendenti
ORDER BY anni_servizio DESC;
-- NB: usiamo una data fissa invece di date('now') così i risultati
-- non cambiano a seconda di quando esegui il file.

.print "\n── 3.8 COALESCE: sostituire i NULL ──"
-- COALESCE(a, b, c, ...) restituisce il PRIMO valore non NULL.
-- (IFNULL(a, b) in SQLite/MySQL, ISNULL in SQL Server, NVL in Oracle)
SELECT nome, cognome,
       citta,
       COALESCE(citta, 'Non indicata') AS citta_mostrata
FROM clienti
WHERE id IN (1, 9, 14);

.print "\n── 3.9 NULLIF: l'opposto (trasforma un valore in NULL) ──"
-- NULLIF(a, b) restituisce NULL se a = b, altrimenti a.
-- Uso classico: evitare la divisione per zero.
-- Esempio: un budget promozionale di 100 € da dividere tra i pezzi in magazzino.
-- Con scorta 0, 100 / 0 darebbe errore in molti database; con NULLIF dà NULL.
SELECT nome, scorta,
       ROUND(100.0 / NULLIF(scorta, 0), 2) AS sconto_per_pezzo
FROM prodotti
WHERE id IN (7, 8);

-- =====================================================================
--  CASE: l'if/else di SQL
-- =====================================================================
--     CASE
--         WHEN condizione1 THEN valore1
--         WHEN condizione2 THEN valore2
--         ELSE valore_default        -- se manca l'ELSE: NULL
--     END
--  Come l'if/else if di Java: si ferma alla PRIMA condizione vera.
-- =====================================================================

.print "\n── 3.10 CASE 'cercato': fasce di prezzo ──"
SELECT nome, prezzo,
       CASE
           WHEN prezzo < 30  THEN 'Economico'
           WHEN prezzo < 100 THEN 'Medio'
           ELSE                   'Premium'
       END AS fascia
FROM prodotti
ORDER BY prezzo;

.print "\n── 3.11 CASE 'semplice': tradurre dei codici ──"
SELECT id, stato,
       CASE stato
           WHEN 'in_attesa'  THEN '⏳ In attesa'
           WHEN 'spedito'    THEN '🚚 Spedito'
           WHEN 'consegnato' THEN '✅ Consegnato'
           WHEN 'annullato'  THEN '❌ Annullato'
       END AS stato_leggibile
FROM ordini
WHERE id > 25;

.print "\n── 3.12 CASE in ORDER BY: ordinamento personalizzato ──"
-- Voglio prima gli ordini da lavorare, poi gli altri.
SELECT id, stato, data_ordine
FROM ordini
WHERE data_ordine >= '2025-03-01'
ORDER BY CASE stato
             WHEN 'in_attesa' THEN 1
             WHEN 'spedito'   THEN 2
             ELSE 3
         END,
         data_ordine;

.print "\n── 3.13 CASE per gestire le scorte ──"
SELECT nome, scorta,
       CASE
           WHEN scorta = 0  THEN 'ESAURITO - riordinare subito'
           WHEN scorta < 10 THEN 'In esaurimento'
           ELSE 'OK'
       END AS stato_magazzino
FROM prodotti
WHERE scorta < 20
ORDER BY scorta;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/03_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Mostra le iniziali dei clienti (es. "M.R." per Mario Rossi).
   2. Mostra i clienti con il cognome in maiuscolo e la città in minuscolo
      (le città mancanti devono apparire come '-').
   3. Mostra gli ordini del mese di novembre di qualsiasi anno.
   4. Per ogni ordine mostra il nome del giorno della settimana in italiano
      (usa strftime('%w', ...) e un CASE).
   5. Classifica i dipendenti: stipendio >= 4000 'Dirigente',
      >= 2000 'Impiegato', altrimenti 'Junior'.
   6. Mostra i prodotti con il prezzo scontato del 20% se la scorta è
      maggiore di 50, altrimenti il prezzo pieno. Colonna: prezzo_finale.
   7. Per ogni recensione mostra il voto come stelline (es. 3 -> '★★★').
      Suggerimento: SUBSTR('★★★★★', 1, voto)
   --------------------------------------------------------------------- */
