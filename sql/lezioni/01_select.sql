-- =====================================================================
--  SQL - LEZIONE 1: LEGGERE I DATI CON SELECT
-- =====================================================================
--
--  COS'È UN DATABASE RELAZIONALE?
--  Un insieme di TABELLE. Ogni tabella è come un foglio Excel:
--    - le COLONNE (o campi) sono fisse e hanno un tipo (testo, numero...)
--    - le RIGHE (o record) sono i dati veri e propri
--  Le tabelle sono collegate tra loro da CHIAVI (lo vedremo con le JOIN).
--
--  SQL (Structured Query Language) è il linguaggio per parlare con il
--  database. È DICHIARATIVO: dici COSA vuoi, non COME ottenerlo.
--  (In Java scrivevi il ciclo for; in SQL dici "dammi i clienti di Roma"
--   e il database decide da solo come trovarli.)
--
--  LA FORMA BASE
--        SELECT colonne      -- cosa voglio vedere
--        FROM   tabella;     -- da dove
--
--  REGOLE DI SCRITTURA
--   - Le parole chiave (SELECT, FROM...) non distinguono maiuscole e
--     minuscole, ma per convenzione si scrivono in MAIUSCOLO.
--   - Le stringhe vanno tra apici SINGOLI: 'Roma'  (non "Roma")
--   - Ogni istruzione termina con ;
--   - I commenti iniziano con  --  (una riga) oppure  /* ... */
--
--  COME SI LEGGE QUESTO FILE
--  Le righe che iniziano con  .print  sono comandi di sqlite3 che stampano
--  un titolo: non sono SQL. Se usi un altro programma (DBeaver, DB Browser),
--  ignorale e copia solo le query.
-- =====================================================================

.print "\n── 1.1 Tutte le colonne di una tabella: SELECT * ──"
-- L'asterisco significa "tutte le colonne". Comodo per esplorare,
-- ma nelle query "vere" è meglio elencare solo le colonne che servono.
SELECT * FROM categorie;

.print "\n── 1.2 Solo alcune colonne, nell'ordine che voglio ──"
SELECT nome, prezzo FROM prodotti;

.print "\n── 1.3 Colonne calcolate e ALIAS (AS) ──"
-- Si possono fare calcoli. AS dà un nome alla colonna del risultato.
SELECT nome,
       prezzo,
       scorta,
       prezzo * scorta        AS valore_magazzino,
       ROUND(prezzo * 1.22, 2) AS prezzo_con_iva
FROM prodotti;

.print "\n── 1.4 Concatenare testo con || ──"
-- In SQLite e PostgreSQL si usa ||. In MySQL si usa CONCAT(a, b).
SELECT nome || ' ' || cognome AS nome_completo,
       email
FROM clienti;

.print "\n── 1.5 Ordinare: ORDER BY ──"
-- ASC = crescente (default), DESC = decrescente
SELECT nome, prezzo
FROM prodotti
ORDER BY prezzo DESC;

.print "\n── 1.6 Ordinare per più colonne ──"
-- Prima per città; a parità di città, per cognome.
-- I NULL in SQLite finiscono PRIMA in ordine crescente (in altri DB dopo!)
SELECT citta, cognome, nome
FROM clienti
ORDER BY citta, cognome;

.print "\n── 1.7 Togliere i duplicati: DISTINCT ──"
-- Quali città abbiamo? Senza DISTINCT vedremmo "Milano" tre volte.
SELECT DISTINCT citta
FROM clienti
ORDER BY citta;

.print "\n── 1.8 DISTINCT su più colonne: conta la COMBINAZIONE ──"
SELECT DISTINCT reparto, ruolo
FROM dipendenti
ORDER BY reparto;

.print "\n── 1.9 Limitare il numero di righe: LIMIT ──"
-- I 3 prodotti più cari. (SQL Server usa TOP 3, Oracle FETCH FIRST 3 ROWS ONLY)
SELECT nome, prezzo
FROM prodotti
ORDER BY prezzo DESC
LIMIT 3;

.print "\n── 1.10 Paginazione: LIMIT + OFFSET ──"
-- "Pagina 2" con 5 risultati per pagina: salta i primi 5, prendine 5.
SELECT id, nome
FROM prodotti
ORDER BY id
LIMIT 5 OFFSET 5;

.print "\n── 1.11 ATTENZIONE: senza ORDER BY l'ordine NON è garantito ──"
-- Una tabella è un INSIEME di righe, non una lista. Il database può
-- restituirle nell'ordine che preferisce. Se l'ordine conta, usa sempre
-- ORDER BY. (Questo è uno degli errori più comuni nei colloqui!)
SELECT nome FROM clienti LIMIT 3;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/01_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Mostra nome, cognome e città di tutti i dipendenti.
   2. Mostra nome e stipendio dei dipendenti, dal più pagato al meno pagato.
   3. Mostra lo stipendio annuo (13 mensilità) di ogni dipendente,
      chiamando la colonna "stipendio_annuo".
   4. Quali stati diversi possono avere gli ordini?
   5. Mostra i 5 prodotti con la scorta più bassa.
   6. Mostra "Cognome, Nome" (es. "Rossi, Mario") di tutti i clienti,
      ordinati per cognome e poi per nome.
   7. Mostra il 2° e il 3° prodotto più economico (usa LIMIT e OFFSET).
   --------------------------------------------------------------------- */
