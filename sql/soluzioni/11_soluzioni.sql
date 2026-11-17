-- =====================================================================
--  SOLUZIONI - LEZIONE 11: PROGETTAZIONE, VISTE, INDICI
-- =====================================================================

BEGIN TRANSACTION;

/* ---------------------------------------------------------------------
   Esercizio 1: la tabella "prenotazioni" del ristorante
   ---------------------------------------------------------------------
   (id, data, ora, nome_cliente, telefono_cliente, num_persone,
    tavolo, posti_tavolo, sala_tavolo)

   Anomalie:
   - i dati del cliente (nome, telefono) si ripetono a ogni prenotazione:
     se cambia telefono va aggiornato ovunque (anomalia di aggiornamento)
   - posti_tavolo e sala_tavolo dipendono dal TAVOLO, non dalla
     prenotazione (violazione della 3NF): se sposto un tavolo di sala
     devo modificare tutte le prenotazioni
   - non posso registrare un tavolo nuovo finché nessuno lo prenota
     (anomalia di inserimento)

   Tabelle normalizzate:
     clienti(id PK, nome, telefono UNIQUE)
     sale(id PK, nome UNIQUE)
     tavoli(id PK, numero UNIQUE, posti, sala_id FK -> sale)
     prenotazioni(id PK, cliente_id FK, tavolo_id FK, data, ora, num_persone)
   --------------------------------------------------------------------- */

.print "\n── Esercizio 2: schema di una biblioteca ──"
CREATE TABLE autori (
    id       INTEGER PRIMARY KEY,
    nome     VARCHAR(100) NOT NULL
);

CREATE TABLE libri (
    id       INTEGER PRIMARY KEY,
    titolo   VARCHAR(200) NOT NULL,
    isbn     VARCHAR(13)  NOT NULL UNIQUE CHECK (LENGTH(isbn) IN (10, 13)),
    anno     INTEGER      CHECK (anno BETWEEN 1450 AND 2100),
    copie    INTEGER      NOT NULL DEFAULT 1 CHECK (copie >= 0)
);

-- Un libro può avere più autori e un autore più libri: MOLTI-A-MOLTI
-- -> serve una tabella "ponte", come righe_ordine tra ordini e prodotti.
CREATE TABLE libri_autori (
    libro_id  INTEGER NOT NULL REFERENCES libri(id) ON DELETE CASCADE,
    autore_id INTEGER NOT NULL REFERENCES autori(id),
    PRIMARY KEY (libro_id, autore_id)
);

CREATE TABLE utenti (
    id       INTEGER PRIMARY KEY,
    nome     VARCHAR(100) NOT NULL,
    tessera  VARCHAR(10)  NOT NULL UNIQUE
);

CREATE TABLE prestiti (
    id              INTEGER PRIMARY KEY,
    libro_id        INTEGER NOT NULL REFERENCES libri(id),
    utente_id       INTEGER NOT NULL REFERENCES utenti(id),
    data_prestito   DATE    NOT NULL,
    data_scadenza   DATE    NOT NULL,
    data_restituzione DATE,                          -- NULL = non ancora restituito
    CHECK (data_scadenza > data_prestito),
    CHECK (data_restituzione IS NULL OR data_restituzione >= data_prestito)
);

SELECT name AS tabella_creata FROM sqlite_master
WHERE type = 'table' AND name IN ('autori', 'libri', 'libri_autori', 'utenti', 'prestiti');

.print "\n── Esercizio 3: vista v_prodotti_venduti ──"
CREATE VIEW v_prodotti_venduti AS
SELECT p.id,
       p.nome                                      AS prodotto,
       COALESCE(c.nome, '(senza categoria)')        AS categoria,
       COALESCE(SUM(v.quantita), 0)                 AS pezzi,
       COALESCE(SUM(v.quantita * v.prezzo_unitario), 0) AS fatturato
FROM prodotti p
LEFT JOIN categorie c ON c.id = p.categoria_id
LEFT JOIN (SELECT r.*
           FROM righe_ordine r
           JOIN ordini o ON o.id = r.ordine_id
           WHERE o.stato <> 'annullato') v ON v.prodotto_id = p.id
GROUP BY p.id, p.nome, c.nome;

SELECT prodotto, categoria, pezzi, ROUND(fatturato, 2) AS fatturato
FROM v_prodotti_venduti
ORDER BY fatturato DESC
LIMIT 3;

.print "\n── Esercizio 4: vista v_clienti_attivi ──"
CREATE VIEW v_clienti_attivi AS
SELECT c.*
FROM clienti c
WHERE EXISTS (SELECT 1 FROM ordini o
              WHERE o.cliente_id = c.id AND o.data_ordine >= '2025-01-01');

SELECT id, nome, cognome FROM v_clienti_attivi ORDER BY id;

.print "\n── Esercizio 5: indici utili ──"
-- Le chiavi esterne sono usate in quasi tutte le JOIN:
CREATE INDEX idx_prodotti_categoria ON prodotti(categoria_id);
CREATE INDEX idx_ordini_cliente     ON ordini(cliente_id);
CREATE INDEX idx_ordini_dipendente  ON ordini(dipendente_id);
CREATE INDEX idx_righe_prodotto     ON righe_ordine(prodotto_id);
CREATE INDEX idx_recensioni_prodotto ON recensioni(prodotto_id);
-- righe_ordine(ordine_id) NON serve: è la prima colonna della chiave
-- primaria (ordine_id, prodotto_id), che ha già il suo indice.
-- Filtri e ordinamenti frequenti per data:
CREATE INDEX idx_ordini_data ON ordini(data_ordine);

EXPLAIN QUERY PLAN
SELECT p.nome, SUM(r.quantita)
FROM prodotti p
JOIN righe_ordine r ON r.prodotto_id = p.id
WHERE p.categoria_id = 1
GROUP BY p.nome;

ROLLBACK;
