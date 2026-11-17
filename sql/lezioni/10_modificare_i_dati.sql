-- =====================================================================
--  SQL - LEZIONE 10: INSERT, UPDATE, DELETE e TRANSAZIONI
-- =====================================================================
--
--  Finora abbiamo solo LETTO i dati (SELECT). Ora li modifichiamo:
--     INSERT  aggiunge righe
--     UPDATE  modifica righe esistenti
--     DELETE  elimina righe
--  (Insieme a SELECT formano il DML: Data Manipulation Language.)
--
--  ⚠️  REGOLA DI SOPRAVVIVENZA
--  UPDATE e DELETE senza WHERE agiscono su TUTTE le righe della tabella.
--  Prima di lanciare un UPDATE o un DELETE, scrivi una SELECT con lo
--  STESSO WHERE e controlla che restituisca esattamente le righe giuste.
--
--  TRANSAZIONI
--  Questo file lavora tutto dentro una TRANSAZIONE: BEGIN all'inizio e
--  ROLLBACK alla fine, che ANNULLA ogni modifica. Così puoi rieseguirlo
--  quante volte vuoi senza rovinare il database. (Comunque ./esegui.sh
--  ricrea il database da zero prima di ogni lezione.)
-- =====================================================================

BEGIN TRANSACTION;

-- =====================================================================
--  INSERT
-- =====================================================================

.print "\n── 10.1 INSERT di una riga, indicando le colonne ──"
-- Elenca SEMPRE le colonne: se un giorno la tabella cambia, la query
-- continua a funzionare. Le colonne omesse prendono il DEFAULT (o NULL).
INSERT INTO categorie (nome) VALUES ('Giardino');      -- l'id lo genera il DB

SELECT * FROM categorie;

.print "\n── 10.2 INSERT con RETURNING: farsi restituire l'id generato ──"
-- RETURNING esiste in SQLite (dalla 3.35) e PostgreSQL.
-- (In Java/JDBC si usa getGeneratedKeys.)
INSERT INTO prodotti (nome, categoria_id, prezzo)      -- scorta: DEFAULT 0
VALUES ('Tagliaerba elettrico', 6, 189.00)
RETURNING id, nome, scorta;

.print "\n── 10.3 INSERT di più righe in un colpo solo ──"
INSERT INTO prodotti (nome, categoria_id, prezzo, scorta) VALUES
    ('Annaffiatoio 10L',  6, 12.50, 40),
    ('Forbici da potatura', 6, 22.90, 25);

SELECT id, nome, categoria_id, prezzo, scorta FROM prodotti WHERE categoria_id = 6;

.print "\n── 10.4 INSERT ... SELECT: copiare il risultato di una query ──"
-- Creo una tabella di appoggio e ci copio i prodotti esauriti.
CREATE TEMP TABLE da_riordinare (prodotto_id INTEGER, nome TEXT, quantita INTEGER);

INSERT INTO da_riordinare (prodotto_id, nome, quantita)
SELECT id, nome, 20
FROM prodotti
WHERE scorta < 10;

SELECT * FROM da_riordinare;

.print "\n── 10.5 Le violazioni dei vincoli vengono RIFIUTATE ──"
-- Queste istruzioni sono commentate perché farebbero fermare lo script.
-- Provale a mano in  ./esegui.sh shell  e leggi il messaggio d'errore:
--
-- INSERT INTO clienti (nome, cognome, email, data_registrazione)
-- VALUES ('Mario', 'Bis', 'mario.rossi@example.com', '2025-01-01');
--   -> UNIQUE constraint failed: clienti.email
--
-- INSERT INTO prodotti (nome, prezzo) VALUES ('Gratis', 0);
--   -> CHECK constraint failed: prezzo > 0
--
-- INSERT INTO ordini (cliente_id, data_ordine, stato) VALUES (999, '2025-01-01', 'in_attesa');
--   -> FOREIGN KEY constraint failed        (il cliente 999 non esiste)
--
-- INSERT INTO ordini (cliente_id, data_ordine, stato) VALUES (1, '2025-01-01', 'perso');
--   -> CHECK constraint failed: stato IN ('in_attesa', 'spedito', ...)
--
-- INSERT INTO categorie (id, nome) VALUES (1, 'Doppione');
--   -> UNIQUE constraint failed: categorie.id    (chiave primaria duplicata)
.print "   (istruzioni commentate: vedi il file)"

-- =====================================================================
--  UPDATE
-- =====================================================================
--     UPDATE tabella
--     SET colonna1 = valore1, colonna2 = valore2
--     WHERE condizione;
-- =====================================================================

.print "\n── 10.6 Prima la SELECT di controllo, poi l'UPDATE ──"
SELECT id, nome, prezzo FROM prodotti WHERE categoria_id = 2;  -- quali righe tocco?

UPDATE prodotti
SET prezzo = ROUND(prezzo * 1.10, 2)        -- +10% ai libri
WHERE categoria_id = 2;

SELECT id, nome, prezzo FROM prodotti WHERE categoria_id = 2;  -- verifica

.print "\n── 10.7 UPDATE di più colonne con CASE ──"
UPDATE prodotti
SET scorta = scorta + 20,
    prezzo = CASE WHEN prezzo > 100 THEN prezzo * 0.95 ELSE prezzo END
WHERE scorta < 10;

SELECT id, nome, prezzo, scorta FROM prodotti WHERE id IN (1, 8, 10, 14);

.print "\n── 10.8 UPDATE con subquery: segnare 'spediti' gli ordini in attesa di Milano ──"
SELECT o.id, o.stato, c.citta
FROM ordini o JOIN clienti c ON c.id = o.cliente_id
WHERE o.stato = 'in_attesa' AND c.citta = 'Milano';

UPDATE ordini
SET stato = 'spedito'
WHERE stato = 'in_attesa'
  AND cliente_id IN (SELECT id FROM clienti WHERE citta = 'Milano');
-- (In PostgreSQL e SQLite esiste anche UPDATE ... FROM, in MySQL UPDATE ... JOIN:
--  la versione con subquery funziona ovunque.)

SELECT id, stato FROM ordini WHERE id = 29;

.print "\n── 10.9 Il disastro: UPDATE senza WHERE (e come salvarsi) ──"
-- Prima creo un SAVEPOINT: un "punto di ripristino" dentro la transazione
-- (lo approfondiamo in fondo alla lezione).
SAVEPOINT prima_del_disastro;

-- Volevo cambiare la città di UN cliente...
UPDATE clienti SET citta = 'Pisa';            -- ...ma ho dimenticato il WHERE!
SELECT citta, COUNT(*) AS clienti FROM clienti GROUP BY citta;
-- Tutti i 16 clienti ora "abitano" a Pisa.

ROLLBACK TO prima_del_disastro;               -- torno al punto di ripristino
SELECT citta, COUNT(*) AS clienti FROM clienti GROUP BY citta ORDER BY clienti DESC LIMIT 3;
-- Salvi. Senza transazione (o senza backup) i dati originali sarebbero
-- persi per sempre: per questo in produzione si lavora con cautela.

-- =====================================================================
--  DELETE
-- =====================================================================
--     DELETE FROM tabella WHERE condizione;
-- =====================================================================

.print "\n── 10.10 DELETE semplice ──"
DELETE FROM recensioni WHERE voto <= 2 RETURNING id, prodotto_id, voto;

.print "\n── 10.11 L'integrità referenziale protegge i dati ──"
-- Non posso eliminare un cliente che ha degli ordini: gli ordini
-- resterebbero "orfani" (cliente_id che punta al nulla).
--   DELETE FROM clienti WHERE id = 1;
--     -> FOREIGN KEY constraint failed
-- Posso invece eliminare un cliente SENZA ordini né recensioni:
DELETE FROM clienti WHERE id = 11 RETURNING id, nome, cognome;

.print "\n── 10.12 Eliminare un ordine: prima i 'figli', poi il 'padre' ──"
-- Le righe_ordine dipendono dall'ordine: vanno eliminate PRIMA.
-- (Con ON DELETE CASCADE il DB lo farebbe da solo: lezione 11.)
DELETE FROM righe_ordine WHERE ordine_id = 30;
DELETE FROM ordini       WHERE id = 30;
SELECT COUNT(*) AS ordini_rimasti FROM ordini;

-- =====================================================================
--  UPSERT: "inserisci, oppure aggiorna se esiste già"
-- =====================================================================

.print "\n── 10.13 INSERT ... ON CONFLICT DO UPDATE ──"
-- Se la categoria esiste già (conflitto sul vincolo UNIQUE di nome),
-- invece di dare errore aggiorno la riga esistente.
-- SQLite e PostgreSQL: ON CONFLICT      MySQL: ON DUPLICATE KEY UPDATE
INSERT INTO categorie (id, nome) VALUES (5, 'Giochi')
ON CONFLICT (nome) DO UPDATE SET nome = 'Giochi e passatempi';

INSERT INTO categorie (nome) VALUES ('Musica')
ON CONFLICT (nome) DO NOTHING;          -- non esiste: viene inserita

SELECT * FROM categorie ORDER BY id;

-- =====================================================================
--  TRANSAZIONI
-- =====================================================================
--  Una TRANSAZIONE raggruppa più istruzioni in un'unica operazione
--  "tutto o niente". Proprietà ACID:
--    A - Atomicità:   o vanno a buon fine TUTTE, o NESSUNA
--    C - Coerenza:    il database passa da uno stato valido a un altro valido
--    I - Isolamento:  le transazioni contemporanee non si disturbano
--    D - Durabilità:  dopo il COMMIT, i dati sopravvivono anche a un crash
--
--      BEGIN;      inizio
--      ...
--      COMMIT;     conferma tutto     |  ROLLBACK;  annulla tutto
--
--  SAVEPOINT crea un "punto di ripristino" dentro una transazione.
--  Esempio tipico: un nuovo ordine = inserire l'ordine + le righe +
--  scalare le scorte. Se una delle operazioni fallisce, NON deve restare
--  un ordine a metà.
-- =====================================================================

.print "\n── 10.14 Un nuovo ordine completo, con SAVEPOINT ──"
SAVEPOINT nuovo_ordine;

INSERT INTO ordini (id, cliente_id, dipendente_id, data_ordine, stato, spese_spedizione)
VALUES (100, 10, 5, '2025-07-01', 'in_attesa', 4.90);

INSERT INTO righe_ordine (ordine_id, prodotto_id, quantita, prezzo_unitario)
SELECT 100, id, 2, prezzo FROM prodotti WHERE id = 13;

UPDATE prodotti SET scorta = scorta - 2 WHERE id = 13;

SELECT o.id, o.cliente_id, r.prodotto_id, r.quantita, p.scorta AS scorta_aggiornata
FROM ordini o
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
WHERE o.id = 100;

.print "\n── 10.15 ...ci ripensiamo: ROLLBACK TO SAVEPOINT ──"
ROLLBACK TO nuovo_ordine;   -- annulla solo ciò che è successo dopo il savepoint
SELECT COUNT(*) AS ordine_100_esiste FROM ordini WHERE id = 100;
SELECT scorta AS scorta_tappetino FROM prodotti WHERE id = 13;

.print "\n── 10.16 ROLLBACK finale: annulliamo TUTTE le modifiche della lezione ──"
ROLLBACK;

SELECT (SELECT COUNT(*) FROM prodotti)   AS prodotti,
       (SELECT COUNT(*) FROM clienti)    AS clienti,
       (SELECT COUNT(*) FROM categorie)  AS categorie,
       (SELECT citta FROM clienti WHERE id = 3) AS citta_cliente_3;
-- Tutto è tornato come all'inizio: 18 prodotti, 16 clienti, 5 categorie.

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/10_soluzioni.sql)
   Lavora sempre dentro BEGIN ... ROLLBACK!
   ---------------------------------------------------------------------
   1. Inserisci un nuovo cliente (tuo nome) e fatti restituire l'id.
   2. Inserisci un ordine per quel cliente con due prodotti a scelta,
      usando il prezzo di listino attuale (INSERT ... SELECT).
   3. Aumenta del 5% il prezzo dei prodotti che sono stati venduti in
      almeno 3 ordini diversi.
   4. Imposta 'consegnato' tutti gli ordini 'spedito' fatti prima del
      1° aprile 2025. Controlla PRIMA con una SELECT quali sono.
   5. Elimina le recensioni senza commento dei clienti che non hanno mai
      ordinato quel prodotto (ricordi la 6.18?).
   6. Scala la scorta di ogni prodotto in base ai pezzi presenti negli
      ordini 'in_attesa' (UPDATE con subquery correlata).
   7. Prova: elimina la categoria 'Informatica'. Cosa succede e perché?
   --------------------------------------------------------------------- */
