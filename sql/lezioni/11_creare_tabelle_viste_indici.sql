-- =====================================================================
--  SQL - LEZIONE 11: PROGETTARE IL DATABASE
--  CREATE TABLE, vincoli, normalizzazione, viste e indici
-- =====================================================================
--
--  Il DDL (Data Definition Language) definisce la STRUTTURA:
--     CREATE  crea tabelle, viste, indici
--     ALTER   modifica una tabella esistente
--     DROP    elimina
--
--  Anche qui lavoriamo dentro BEGIN ... ROLLBACK: alla fine tutto quello
--  che creiamo sparisce. (In SQLite e PostgreSQL anche il DDL è
--  transazionale; in MySQL e Oracle no: un CREATE fa COMMIT da solo!)
-- =====================================================================

BEGIN TRANSACTION;

-- =====================================================================
--  PARTE 1 - PERCHÉ SERVE PROGETTARE: la NORMALIZZAZIONE
-- =====================================================================
--  Immagina di gestire gli ordini con un unico foglio Excel:
-- =====================================================================

.print "\n── 11.1 Una tabella 'tutto in uno' (come un foglio Excel) ──"
CREATE TABLE ordini_excel (
    num_ordine     INTEGER,
    data           TEXT,
    cliente        TEXT,
    email_cliente  TEXT,
    citta_cliente  TEXT,
    prodotti       TEXT,    -- elenco separato da virgole!
    totale         REAL
);
INSERT INTO ordini_excel VALUES
    (1, '2024-01-10', 'Mario Rossi',   'mario@ex.com',   'Milano', 'Laptop, Mouse',       1324.90),
    (2, '2024-01-22', 'Giulia Bianchi','giulia@ex.com',  'Roma',   'Libro, Moka',         58.90),
    (3, '2024-02-05', 'Mario Rossi',   'mario@ex.com',   'Milano', 'Tastiera, Cuffie',    168.90),
    (4, '2024-03-01', 'Mario Rossi',   'mario.r@ex.com', 'Milan',  'Mouse',               25.90);
SELECT * FROM ordini_excel;

-- PROBLEMI ("ANOMALIE"):
--  - RIDONDANZA: i dati di Mario sono ripetuti in ogni ordine
--  - ANOMALIA DI AGGIORNAMENTO: Mario cambia email -> va cambiata in N righe.
--    Infatti nell'ordine 4 qualcuno ha scritto un'email e una città diverse:
--    ora quale è quella giusta?
--  - ANOMALIA DI INSERIMENTO: non posso registrare un cliente finché non ordina
--  - ANOMALIA DI CANCELLAZIONE: se elimino l'unico ordine di Giulia, perdo
--    anche i suoi dati di contatto
--  - "prodotti" contiene una LISTA: come conto quanti mouse ho venduto?
--    E "totale" è un dato CALCOLABILE: può andare fuori sincrono.
--
--  LE FORME NORMALI (versione pratica)
--   1NF: ogni cella contiene UN SOLO valore (niente liste "Laptop, Mouse")
--        -> una riga per ogni prodotto dell'ordine (tabella righe_ordine)
--   2NF: ogni colonna dipende da TUTTA la chiave, non da una parte
--        -> in righe_ordine (chiave ordine_id + prodotto_id) il nome del
--           prodotto dipende solo da prodotto_id: va nella tabella prodotti
--   3NF: nessuna colonna dipende da un'altra colonna non chiave
--        -> email e città dipendono dal cliente, non dall'ordine:
--           vanno nella tabella clienti
--  In sintesi: "ogni informazione in UN posto solo, collegata con le chiavi".
--  È esattamente come è fatto il database del corso.

DROP TABLE ordini_excel;

-- =====================================================================
--  PARTE 2 - CREATE TABLE e VINCOLI
-- =====================================================================
--  Progettiamo un piccolo database per un'altra situazione: una scuola
--  di programmazione con studenti, corsi e iscrizioni.
--
--     studenti 1───N iscrizioni N───1 corsi N───1 docenti
--
--  TIPI DI DATO (i principali, nei DB "classici")
--     INTEGER / BIGINT        interi
--     DECIMAL(10,2)/NUMERIC   decimali ESATTI -> per i SOLDI
--     REAL / DOUBLE           decimali approssimati (scientifici)
--     VARCHAR(n) / TEXT       testo
--     DATE / TIMESTAMP        date e date+ora
--     BOOLEAN                 vero/falso
--  SQLite è molto permissivo sui tipi (le date sono testo, i boolean 0/1),
--  gli altri database sono rigidi: scrivi comunque tipi "seri".
--
--  VINCOLI
--     PRIMARY KEY   identifica la riga (unica e non NULL)
--     FOREIGN KEY   deve puntare a una riga esistente (REFERENCES)
--     NOT NULL      obbligatorio
--     UNIQUE        nessun duplicato
--     CHECK         condizione da rispettare
--     DEFAULT       valore se non specificato
--  I vincoli sono la PRIMA difesa della qualità dei dati: meglio un errore
--  oggi che dati sbagliati per sempre.
-- =====================================================================

.print "\n── 11.2 Creiamo le tabelle della scuola ──"
CREATE TABLE docenti (
    id        INTEGER PRIMARY KEY,
    nome      VARCHAR(50)  NOT NULL,
    email     VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE corsi (
    id           INTEGER PRIMARY KEY,
    titolo       VARCHAR(100) NOT NULL,
    docente_id   INTEGER REFERENCES docenti(id) ON DELETE SET NULL,
    ore          INTEGER NOT NULL CHECK (ore > 0),
    prezzo_cent  INTEGER NOT NULL CHECK (prezzo_cent >= 0),  -- soldi in CENTESIMI interi
    livello      VARCHAR(20) NOT NULL DEFAULT 'base'
                 CHECK (livello IN ('base', 'intermedio', 'avanzato'))
);

CREATE TABLE studenti (
    id           INTEGER PRIMARY KEY,
    nome         VARCHAR(50)  NOT NULL,
    email        VARCHAR(100) NOT NULL UNIQUE,
    nato_il      DATE
);

CREATE TABLE iscrizioni (
    studente_id  INTEGER NOT NULL REFERENCES studenti(id) ON DELETE CASCADE,
    corso_id     INTEGER NOT NULL REFERENCES corsi(id),
    data         DATE    NOT NULL DEFAULT CURRENT_DATE,
    voto         INTEGER CHECK (voto BETWEEN 18 AND 30),      -- NULL = esame non ancora fatto
    PRIMARY KEY (studente_id, corso_id)   -- uno studente non si iscrive due volte allo stesso corso
);
-- ON DELETE CASCADE:  se elimino lo studente, le sue iscrizioni spariscono con lui
-- ON DELETE SET NULL: se elimino il docente, il corso resta ma senza docente
-- (default):          se ci sono righe collegate, l'eliminazione è RIFIUTATA

INSERT INTO docenti VALUES (1, 'Prof. Turing', 'turing@scuola.it'), (2, 'Prof.ssa Lovelace', 'ada@scuola.it');
INSERT INTO corsi (id, titolo, docente_id, ore, prezzo_cent, livello) VALUES
    (1, 'Java da zero', 2, 40, 29900, 'base'),
    (2, 'SQL pratico',  1, 24, 19900, 'base'),
    (3, 'Spring Boot',  2, 32, 39900, 'avanzato');
INSERT INTO studenti (id, nome, email) VALUES
    (1, 'Luca', 'luca@mail.it'), (2, 'Sofia', 'sofia@mail.it'), (3, 'Omar', 'omar@mail.it');
INSERT INTO iscrizioni (studente_id, corso_id, voto) VALUES
    (1, 1, 28), (1, 2, NULL), (2, 1, 30), (2, 3, NULL), (3, 2, 24);

SELECT s.nome AS studente, c.titolo AS corso, d.nome AS docente,
       printf('%.2f €', c.prezzo_cent / 100.0) AS prezzo, i.voto
FROM iscrizioni i
JOIN studenti s     ON s.id = i.studente_id
JOIN corsi c        ON c.id = i.corso_id
LEFT JOIN docenti d ON d.id = c.docente_id
ORDER BY s.nome, c.titolo;

.print "\n── 11.3 ON DELETE CASCADE e SET NULL in azione ──"
DELETE FROM studenti WHERE id = 1;       -- spariscono anche le sue 2 iscrizioni
DELETE FROM docenti  WHERE id = 1;       -- i suoi corsi restano, con docente NULL
SELECT (SELECT COUNT(*) FROM iscrizioni)               AS iscrizioni_rimaste,
       (SELECT docente_id FROM corsi WHERE id = 2)     AS docente_corso_sql;

.print "\n── 11.4 Perché i soldi NON vanno in REAL/DOUBLE ──"
-- I numeri decimali "a virgola mobile" sono APPROSSIMATI (come double in Java).
SELECT 0.1 + 0.2              AS somma_double,
       0.1 + 0.2 = 0.3        AS uguale_a_0_3,
       (10 + 20) / 100.0      AS con_centesimi_interi;
-- Soluzioni: DECIMAL(10,2) nei database che lo supportano davvero
-- (PostgreSQL, MySQL, Oracle, SQL Server), oppure interi in centesimi.
-- (Il database del corso usa REAL per semplicità: in un progetto vero no!)

-- =====================================================================
--  PARTE 3 - ALTER TABLE: modificare una tabella esistente
-- =====================================================================

.print "\n── 11.5 ALTER TABLE ──"
ALTER TABLE studenti ADD COLUMN telefono VARCHAR(20);           -- nuova colonna (NULL per tutti)
ALTER TABLE studenti RENAME COLUMN nato_il TO data_nascita;     -- rinomina
UPDATE studenti SET telefono = '333 1234567' WHERE id = 2;
SELECT * FROM studenti;
-- NB: SQLite supporta poche forme di ALTER TABLE (ad esempio non può
-- aggiungere un vincolo a una colonna esistente); gli altri DB molte di più.

-- =====================================================================
--  PARTE 4 - LE VISTE (VIEW)
-- =====================================================================
--  Una VISTA è una query salvata con un nome, che si usa come una tabella.
--  Non contiene dati: ogni volta che la interroghi, riesegue la query.
--  Servono a:
--    - nascondere la complessità (una JOIN di 5 tabelle diventa "una tabella")
--    - riusare la stessa logica ovunque (il "totale ordine" si calcola in un posto solo)
--    - limitare cosa vedono gli utenti (solo alcune colonne/righe)
-- =====================================================================

.print "\n── 11.6 Una vista con i totali degli ordini ──"
CREATE VIEW v_ordini_totali AS
SELECT o.id                                         AS ordine_id,
       o.data_ordine,
       o.stato,
       c.nome || ' ' || c.cognome                   AS cliente,
       COUNT(r.prodotto_id)                         AS num_righe,
       COALESCE(SUM(r.quantita * r.prezzo_unitario), 0) AS totale_merce,
       o.spese_spedizione,
       COALESCE(SUM(r.quantita * r.prezzo_unitario), 0) + o.spese_spedizione AS totale
FROM ordini o
JOIN clienti c           ON c.id = o.cliente_id
LEFT JOIN righe_ordine r ON r.ordine_id = o.id
GROUP BY o.id, o.data_ordine, o.stato, c.nome, c.cognome, o.spese_spedizione;

-- Da ora la uso come una tabella qualsiasi:
SELECT ordine_id, cliente, num_righe, ROUND(totale, 2) AS totale
FROM v_ordini_totali
WHERE stato = 'in_attesa'
ORDER BY totale DESC;

.print "\n── 11.7 La vista usata in un report annuale ──"
SELECT strftime('%Y', data_ordine) AS anno,
       COUNT(*)                    AS ordini,
       ROUND(SUM(totale), 2)       AS incasso
FROM v_ordini_totali
WHERE stato <> 'annullato'
GROUP BY anno;

-- =====================================================================
--  PARTE 5 - GLI INDICI
-- =====================================================================
--  Senza indice, per trovare gli ordini di una certa data il database
--  legge TUTTA la tabella (SCAN). Con un indice sulla colonna, salta
--  direttamente alle righe giuste (SEARCH), come l'indice analitico di un
--  libro.
--
--  PRO: ricerche, JOIN e ORDER BY molto più veloci sulle tabelle grandi
--  CONTRO: occupano spazio e rallentano INSERT/UPDATE/DELETE (l'indice
--          va aggiornato a ogni modifica)
--  Le PRIMARY KEY e le colonne UNIQUE hanno già un indice automatico.
--  Candidati tipici: colonne usate spesso in WHERE, JOIN (le chiavi
--  esterne!) e ORDER BY.
--
--  EXPLAIN QUERY PLAN mostra COME il database eseguirà la query.
--  (PostgreSQL/MySQL: EXPLAIN)
-- =====================================================================

.print "\n── 11.8 Piano di esecuzione SENZA indice ──"
EXPLAIN QUERY PLAN
SELECT * FROM ordini WHERE cliente_id = 1;

.print "\n── 11.9 Creo un indice sulla chiave esterna e riprovo ──"
CREATE INDEX idx_ordini_cliente ON ordini(cliente_id);
EXPLAIN QUERY PLAN
SELECT * FROM ordini WHERE cliente_id = 1;
-- Da "SCAN ordini" (leggo tutto) a "SEARCH ordini USING INDEX" (vado diretto).
-- Con 31 righe non cambia niente; con 31 milioni fa la differenza tra
-- 5 millisecondi e 5 minuti.

.print "\n── 11.10 Un indice NON viene usato se 'nascondo' la colonna in una funzione ──"
CREATE INDEX idx_ordini_data ON ordini(data_ordine);
EXPLAIN QUERY PLAN
SELECT * FROM ordini WHERE strftime('%Y', data_ordine) = '2025';    -- SCAN: l'indice è inutile

.print ""
EXPLAIN QUERY PLAN
SELECT * FROM ordini WHERE data_ordine >= '2025-01-01' AND data_ordine < '2026-01-01';  -- SEARCH
-- Stessa domanda, scritta in modo che l'indice possa lavorare.

.print "\n── 11.11 Indice UNIQUE: anche un vincolo ──"
CREATE UNIQUE INDEX idx_un_voto_per_prodotto ON recensioni(prodotto_id, cliente_id);
-- Da ora un cliente non può recensire due volte lo stesso prodotto.
-- (Il cliente 1 ha recensito il prodotto 1 una volta: OK. Riprovarci darebbe
--  "UNIQUE constraint failed".)
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%';

ROLLBACK;   -- annulla tabelle, viste e indici creati in questa lezione

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/11_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Questa tabella "prenotazioni" di un ristorante non è normalizzata:
        (id, data, ora, nome_cliente, telefono_cliente, num_persone,
         tavolo, posti_tavolo, sala_tavolo)
      Individua le anomalie e proponi le tabelle normalizzate.
   2. Scrivi i CREATE TABLE per il tuo progetto: una biblioteca con
      libri, autori (un libro può avere più autori!), utenti e prestiti.
      Usa tutti i vincoli che hanno senso (PK, FK, NOT NULL, UNIQUE, CHECK).
   3. Crea una vista  v_prodotti_venduti  con: prodotto, categoria, pezzi
      venduti e fatturato (ordini non annullati), inclusi i mai venduti.
      Poi usala per trovare i 3 prodotti con il fatturato più alto.
   4. Crea una vista  v_clienti_attivi  con i clienti che hanno ordinato
      negli ultimi 6 mesi del dataset (dal 2025-01-01).
   5. Quali indici creeresti sul database del corso? Per ognuno spiega
      quale query renderebbe più veloce. Verifica con EXPLAIN QUERY PLAN.
   --------------------------------------------------------------------- */
