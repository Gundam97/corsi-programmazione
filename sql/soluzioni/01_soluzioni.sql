-- =====================================================================
--  SOLUZIONI - LEZIONE 1: SELECT
-- =====================================================================

.print "\n── Esercizio 1: nome, cognome e città dei dipendenti ──"
-- Trabocchetto: i dipendenti NON hanno la colonna città! Si legge l'errore
-- ("no such column: citta") e si sceglie cosa mostrare: qui il reparto.
SELECT nome, cognome, reparto FROM dipendenti;

.print "\n── Esercizio 2: dipendenti dal più pagato ──"
SELECT nome, stipendio
FROM dipendenti
ORDER BY stipendio DESC;

.print "\n── Esercizio 3: stipendio annuo ──"
SELECT nome, cognome, stipendio, stipendio * 13 AS stipendio_annuo
FROM dipendenti;

.print "\n── Esercizio 4: stati possibili degli ordini ──"
SELECT DISTINCT stato FROM ordini ORDER BY stato;

.print "\n── Esercizio 5: i 5 prodotti con meno scorta ──"
SELECT nome, scorta
FROM prodotti
ORDER BY scorta
LIMIT 5;

.print "\n── Esercizio 6: 'Cognome, Nome' ordinati ──"
SELECT cognome || ', ' || nome AS cliente
FROM clienti
ORDER BY cognome, nome;

.print "\n── Esercizio 7: 2° e 3° prodotto più economico ──"
SELECT nome, prezzo
FROM prodotti
ORDER BY prezzo
LIMIT 2 OFFSET 1;
