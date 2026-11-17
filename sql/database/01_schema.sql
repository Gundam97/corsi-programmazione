-- =====================================================================
--  DATABASE DEL CORSO: "NEGOZIO ONLINE"
-- =====================================================================
--
--  Questo file CREA le tabelle (la struttura). Il file 02_dati.sql le
--  RIEMPIE. Non serve eseguirli a mano: ci pensa  ./esegui.sh crea
--
--  Il database rappresenta un piccolo negozio online:
--
--     categorie 1───N prodotti 1───N righe_ordine N───1 ordini N───1 clienti
--                         │                                │
--                         └──────N recensioni N────────────┼──── clienti
--                                                          │
--                                         dipendenti 1─────┘ (chi ha gestito l'ordine)
--                                             │
--                                             └── responsabile_id → dipendenti (sé stessa!)
--
--  Leggi "1───N" come "uno a molti": UNA categoria ha MOLTI prodotti,
--  UN cliente fa MOLTI ordini, UN ordine ha MOLTE righe, ecc.
--
--  Una "riga_ordine" collega un ordine a un prodotto: è la tabella che
--  risolve la relazione MOLTI-A-MOLTI tra ordini e prodotti (un ordine
--  contiene tanti prodotti, un prodotto compare in tanti ordini).
--
--  NB: i dati contengono di proposito dei "casi strani" (clienti senza
--  ordini, prodotti mai venduti, valori NULL, un ordine vuoto...). Sono
--  proprio quelli che rendono interessanti JOIN e GROUP BY!
-- =====================================================================

PRAGMA foreign_keys = ON;  -- in SQLite i vincoli di chiave esterna vanno attivati

DROP TABLE IF EXISTS recensioni;
DROP TABLE IF EXISTS righe_ordine;
DROP TABLE IF EXISTS ordini;
DROP TABLE IF EXISTS dipendenti;
DROP TABLE IF EXISTS clienti;
DROP TABLE IF EXISTS prodotti;
DROP TABLE IF EXISTS categorie;

CREATE TABLE categorie (
    id    INTEGER PRIMARY KEY,
    nome  TEXT    NOT NULL UNIQUE
);

CREATE TABLE prodotti (
    id                INTEGER PRIMARY KEY,
    nome              TEXT    NOT NULL,
    categoria_id      INTEGER REFERENCES categorie(id),   -- può essere NULL!
    prezzo            REAL    NOT NULL CHECK (prezzo > 0), -- prezzo di listino ATTUALE
    scorta            INTEGER NOT NULL DEFAULT 0 CHECK (scorta >= 0)
);

CREATE TABLE clienti (
    id                  INTEGER PRIMARY KEY,
    nome                TEXT NOT NULL,
    cognome             TEXT NOT NULL,
    email               TEXT NOT NULL UNIQUE,
    citta               TEXT,                 -- facoltativa: alcuni sono NULL
    data_registrazione  TEXT NOT NULL         -- formato 'AAAA-MM-GG'
);

CREATE TABLE dipendenti (
    id                INTEGER PRIMARY KEY,
    nome              TEXT NOT NULL,
    cognome           TEXT NOT NULL,
    ruolo             TEXT NOT NULL,
    reparto           TEXT NOT NULL,
    responsabile_id   INTEGER REFERENCES dipendenti(id),  -- chiave esterna verso SÉ STESSA
    stipendio         REAL NOT NULL,
    data_assunzione   TEXT NOT NULL
);

CREATE TABLE ordini (
    id                INTEGER PRIMARY KEY,
    cliente_id        INTEGER NOT NULL REFERENCES clienti(id),
    dipendente_id     INTEGER REFERENCES dipendenti(id),  -- NULL = ordine fatto online in autonomia
    data_ordine       TEXT    NOT NULL,
    stato             TEXT    NOT NULL
                      CHECK (stato IN ('in_attesa', 'spedito', 'consegnato', 'annullato')),
    spese_spedizione  REAL    NOT NULL DEFAULT 0
);

CREATE TABLE righe_ordine (
    ordine_id        INTEGER NOT NULL REFERENCES ordini(id),
    prodotto_id      INTEGER NOT NULL REFERENCES prodotti(id),
    quantita         INTEGER NOT NULL CHECK (quantita > 0),
    prezzo_unitario  REAL    NOT NULL,  -- prezzo AL MOMENTO dell'acquisto (può differire dal listino)
    PRIMARY KEY (ordine_id, prodotto_id)  -- chiave primaria COMPOSTA da due colonne
);

CREATE TABLE recensioni (
    id           INTEGER PRIMARY KEY,
    prodotto_id  INTEGER NOT NULL REFERENCES prodotti(id),
    cliente_id   INTEGER NOT NULL REFERENCES clienti(id),
    voto         INTEGER NOT NULL CHECK (voto BETWEEN 1 AND 5),
    commento     TEXT,
    data         TEXT    NOT NULL
);
