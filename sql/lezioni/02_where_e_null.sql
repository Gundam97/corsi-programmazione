-- =====================================================================
--  SQL - LEZIONE 2: FILTRARE CON WHERE (e il problema del NULL)
-- =====================================================================
--
--        SELECT colonne
--        FROM   tabella
--        WHERE  condizione      -- tiene solo le righe per cui è VERA
--        ORDER BY ...;
--
--  OPERATORI DI CONFRONTO
--     =   uguale (UNO solo, non == come in Java!)
--     <>  diverso (si può scrivere anche !=)
--     <  >  <=  >=
--
--  OPERATORI LOGICI:  AND, OR, NOT
--  OPERATORI SPECIALI: IN, BETWEEN, LIKE, IS NULL
-- =====================================================================

.print "\n── 2.1 Confronto semplice ──"
SELECT nome, cognome, citta
FROM clienti
WHERE citta = 'Milano';

.print "\n── 2.2 Confronto numerico ──"
SELECT nome, prezzo
FROM prodotti
WHERE prezzo >= 100
ORDER BY prezzo;

.print "\n── 2.3 AND: tutte le condizioni vere ──"
SELECT nome, prezzo, scorta
FROM prodotti
WHERE prezzo < 50 AND scorta > 40;

.print "\n── 2.4 OR: almeno una condizione vera ──"
SELECT nome, cognome, citta
FROM clienti
WHERE citta = 'Roma' OR citta = 'Napoli';

.print "\n── 2.5 TRAPPOLA: precedenza tra AND e OR ──"
-- AND viene valutato PRIMA di OR (come * prima di + in matematica).
-- Voglio: prodotti di Informatica o Libri, che costano meno di 50.
-- SBAGLIATO: si legge  categoria=1  OR  (categoria=2 AND prezzo<50)
SELECT nome, categoria_id, prezzo
FROM prodotti
WHERE categoria_id = 1 OR categoria_id = 2 AND prezzo < 50;

.print "\n   ...e la versione GIUSTA con le parentesi:"
SELECT nome, categoria_id, prezzo
FROM prodotti
WHERE (categoria_id = 1 OR categoria_id = 2) AND prezzo < 50;
-- Regola pratica: quando mescoli AND e OR, metti SEMPRE le parentesi.

.print "\n── 2.6 IN: appartenenza a un elenco ──"
-- Equivale a tanti OR, ma è più leggibile.
SELECT id, data_ordine, stato
FROM ordini
WHERE stato IN ('spedito', 'in_attesa');

.print "\n── 2.7 BETWEEN: intervallo (estremi INCLUSI) ──"
SELECT nome, prezzo
FROM prodotti
WHERE prezzo BETWEEN 20 AND 50
ORDER BY prezzo;

.print "\n── 2.8 BETWEEN con le date ──"
-- In SQLite le date sono testo 'AAAA-MM-GG': in questo formato l'ordine
-- alfabetico coincide con quello cronologico, quindi i confronti funzionano.
SELECT id, data_ordine
FROM ordini
WHERE data_ordine BETWEEN '2024-11-01' AND '2024-12-31';

.print "\n── 2.9 LIKE: ricerca per 'somiglianza' ──"
--   %  = qualsiasi sequenza di caratteri (anche vuota)
--   _  = esattamente UN carattere
SELECT nome FROM prodotti WHERE nome LIKE 'T%';      -- inizia con T

.print ""
SELECT nome FROM prodotti WHERE nome LIKE '%ca%';    -- contiene "ca"

.print ""
SELECT nome, cognome FROM clienti WHERE nome LIKE '_a%'; -- 2a lettera = a
-- NB: in SQLite LIKE non distingue maiuscole/minuscole per le lettere ASCII;
--     in PostgreSQL sì (lì esiste ILIKE per ignorarle).

.print "\n── 2.10 NOT: negare una condizione ──"
SELECT nome, cognome, citta
FROM clienti
WHERE citta NOT IN ('Milano', 'Roma');
-- Domanda: Davide Marino e Valentina De Luca (città NULL) compaiono?
-- NO! Scopri perché qui sotto.

-- =====================================================================
--  IL VALORE NULL  (uno dei concetti più importanti e insidiosi)
-- =====================================================================
--  NULL significa "valore SCONOSCIUTO / MANCANTE". NON è zero, NON è la
--  stringa vuota ''. È "non lo so".
--
--  Conseguenza: QUALSIASI confronto con NULL dà come risultato... NULL
--  ("non lo so"), che WHERE tratta come FALSO.
--      NULL = 'Roma'   -> NULL  (non so se la città sconosciuta è Roma)
--      NULL <> 'Roma'  -> NULL  (non so nemmeno se NON lo è!)
--      NULL = NULL     -> NULL  (due cose sconosciute non sono "uguali")
--
--  SQL usa quindi una LOGICA A TRE VALORI: VERO, FALSO, SCONOSCIUTO.
-- =====================================================================

.print "\n── 2.11 Visualizzare i risultati dei confronti con NULL ──"
SELECT NULL = NULL      AS null_uguale_null,
       NULL <> 1        AS null_diverso_1,
       NULL IS NULL     AS null_is_null,
       1 + NULL         AS uno_piu_null,
       'a' || NULL      AS testo_e_null;

.print "\n── 2.12 SBAGLIATO: = NULL non trova niente ──"
SELECT nome, cognome FROM clienti WHERE citta = NULL;  -- 0 righe!

.print "\n── 2.13 GIUSTO: IS NULL / IS NOT NULL ──"
SELECT nome, cognome FROM clienti WHERE citta IS NULL;

.print ""
SELECT id, data_ordine FROM ordini WHERE dipendente_id IS NULL;  -- ordini online

.print "\n── 2.14 Recuperare le righe NULL nel NOT IN di prima ──"
SELECT nome, cognome, citta
FROM clienti
WHERE citta NOT IN ('Milano', 'Roma') OR citta IS NULL;

.print "\n── 2.15 Prodotti senza categoria ──"
SELECT nome, categoria_id FROM prodotti WHERE categoria_id IS NULL;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/02_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Prodotti esauriti (scorta = 0).
   2. Ordini annullati, con data e spese di spedizione.
   3. Dipendenti del reparto Vendite che guadagnano più di 2300.
   4. Clienti registrati nel 2024 (prova sia con BETWEEN sia con LIKE).
   5. Prodotti il cui nome contiene la lettera "o" e che costano meno di 30.
   6. Dipendenti che NON hanno un responsabile.
   7. Ordini fatti da un dipendente (non online) e non annullati.
   8. Clienti la cui email NON finisce con "@example.com"
      (risultato atteso: nessuno - verifica che la query funzioni!).
   9. DOMANDA: perché  WHERE citta <> 'Milano'  non restituisce i clienti
      con città NULL? Riscrivi la query in modo che li includa.
   --------------------------------------------------------------------- */
