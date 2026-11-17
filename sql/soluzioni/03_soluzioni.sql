-- =====================================================================
--  SOLUZIONI - LEZIONE 3: FUNZIONI e CASE
-- =====================================================================

.print "\n── Esercizio 1: iniziali ──"
SELECT nome, cognome,
       SUBSTR(nome, 1, 1) || '.' || SUBSTR(cognome, 1, 1) || '.' AS iniziali
FROM clienti;

.print "\n── Esercizio 2: cognome maiuscolo, città minuscola o '-' ──"
SELECT nome,
       UPPER(cognome)              AS cognome,
       COALESCE(LOWER(citta), '-') AS citta
FROM clienti;

.print "\n── Esercizio 3: ordini di novembre (di qualsiasi anno) ──"
SELECT id, data_ordine
FROM ordini
WHERE strftime('%m', data_ordine) = '11';

.print "\n── Esercizio 4: giorno della settimana in italiano ──"
SELECT id, data_ordine,
       CASE strftime('%w', data_ordine)
           WHEN '0' THEN 'Domenica'
           WHEN '1' THEN 'Lunedì'
           WHEN '2' THEN 'Martedì'
           WHEN '3' THEN 'Mercoledì'
           WHEN '4' THEN 'Giovedì'
           WHEN '5' THEN 'Venerdì'
           WHEN '6' THEN 'Sabato'
       END AS giorno
FROM ordini
LIMIT 10;
-- NB: strftime restituisce TESTO, quindi si confronta con '0', non con 0.

.print "\n── Esercizio 5: classificazione dei dipendenti ──"
SELECT nome, cognome, stipendio,
       CASE
           WHEN stipendio >= 4000 THEN 'Dirigente'
           WHEN stipendio >= 2000 THEN 'Impiegato'
           ELSE 'Junior'
       END AS livello
FROM dipendenti
ORDER BY stipendio DESC;

.print "\n── Esercizio 6: prezzo finale con sconto sulle scorte alte ──"
SELECT nome, scorta, prezzo,
       CASE WHEN scorta > 50 THEN ROUND(prezzo * 0.8, 2) ELSE prezzo END AS prezzo_finale
FROM prodotti;

.print "\n── Esercizio 7: voto in stelline ──"
SELECT id, prodotto_id, voto,
       SUBSTR('★★★★★', 1, voto) || SUBSTR('☆☆☆☆☆', 1, 5 - voto) AS stelle
FROM recensioni;
