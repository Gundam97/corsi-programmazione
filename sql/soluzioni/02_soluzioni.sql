-- =====================================================================
--  SOLUZIONI - LEZIONE 2: WHERE e NULL
-- =====================================================================

.print "\n── Esercizio 1: prodotti esauriti ──"
SELECT nome, scorta FROM prodotti WHERE scorta = 0;

.print "\n── Esercizio 2: ordini annullati ──"
SELECT id, data_ordine, spese_spedizione
FROM ordini
WHERE stato = 'annullato';

.print "\n── Esercizio 3: Vendite con stipendio > 2300 ──"
SELECT nome, cognome, stipendio
FROM dipendenti
WHERE reparto = 'Vendite' AND stipendio > 2300;

.print "\n── Esercizio 4: clienti registrati nel 2024 (due modi) ──"
SELECT nome, cognome, data_registrazione
FROM clienti
WHERE data_registrazione BETWEEN '2024-01-01' AND '2024-12-31';

.print ""
SELECT nome, cognome, data_registrazione
FROM clienti
WHERE data_registrazione LIKE '2024-%';

.print "\n── Esercizio 5: nome con 'o' e prezzo < 30 ──"
SELECT nome, prezzo
FROM prodotti
WHERE nome LIKE '%o%' AND prezzo < 30;

.print "\n── Esercizio 6: dipendenti senza responsabile ──"
SELECT nome, cognome, ruolo FROM dipendenti WHERE responsabile_id IS NULL;

.print "\n── Esercizio 7: ordini con dipendente e non annullati ──"
SELECT id, data_ordine, dipendente_id, stato
FROM ordini
WHERE dipendente_id IS NOT NULL AND stato <> 'annullato';

.print "\n── Esercizio 8: email che NON finiscono con @example.com (nessuna) ──"
SELECT nome, email FROM clienti WHERE email NOT LIKE '%@example.com';
-- Verifica che la query funzioni "al contrario": senza NOT deve dare 16 righe.
SELECT COUNT(*) AS con_example FROM clienti WHERE email LIKE '%@example.com';

.print "\n── Esercizio 9: clienti NON di Milano, compresi quelli senza città ──"
-- citta <> 'Milano' con citta NULL vale NULL (sconosciuto) -> riga scartata.
SELECT nome, cognome, citta
FROM clienti
WHERE citta <> 'Milano' OR citta IS NULL;
-- Alternativa compatta: WHERE COALESCE(citta, '') <> 'Milano'
