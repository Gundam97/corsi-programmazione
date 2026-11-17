-- =====================================================================
--  SQL - LEZIONE 6: JOIN + GROUP BY, TRAPPOLE E TECNICHE
-- =====================================================================
--
--  Le JOIN in sé sono semplici. Gli errori veri nascono quando:
--    - si combinano con GROUP BY e COUNT
--    - si filtrano le LEFT JOIN nel posto sbagliato
--    - una JOIN "moltiplica" le righe e i totali si gonfiano
--  Questa lezione è dedicata proprio a questi casi: sono gli errori più
--  frequenti nel lavoro reale (e le domande più frequenti nei colloqui).
--
--  CONSIGLIO DI METODO: prima di aggregare, esegui la query SENZA il
--  GROUP BY e guarda le righe "grezze". Quasi tutti i problemi si vedono lì.
-- =====================================================================

-- =====================================================================
--  PARTE 1 - JOIN + GROUP BY: i report
-- =====================================================================

.print "\n── 6.1 Fatturato per categoria ──"
-- Passi: righe d'ordine -> prodotto -> categoria, poi raggruppo.
-- Escludo gli ordini annullati (serve anche la tabella ordini).
SELECT COALESCE(cat.nome, '(senza categoria)')        AS categoria,
       SUM(r.quantita)                                 AS pezzi,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2)   AS fatturato
FROM righe_ordine r
JOIN ordini o         ON o.id = r.ordine_id
JOIN prodotti p       ON p.id = r.prodotto_id
LEFT JOIN categorie cat ON cat.id = p.categoria_id
WHERE o.stato <> 'annullato'
GROUP BY cat.nome
ORDER BY fatturato DESC;

.print "\n── 6.2 Spesa totale per cliente: raggruppa per ID, non per nome! ──"
-- Due clienti diversi possono avere lo stesso nome/cognome. Raggruppa
-- per la chiave (c.id) e aggiungi al GROUP BY le colonne da mostrare.
SELECT c.id,
       c.nome || ' ' || c.cognome                     AS cliente,
       COUNT(DISTINCT o.id)                           AS ordini,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2)  AS speso
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.stato <> 'annullato'
GROUP BY c.id, c.nome, c.cognome
ORDER BY speso DESC;
-- Nota COUNT(DISTINCT o.id): dopo la JOIN con righe_ordine ogni ordine
-- compare tante volte quante sono le sue righe. COUNT(*) conterebbe le
-- RIGHE, non gli ordini. (Prova a cambiarlo!)

.print "\n── 6.3 Prova: COUNT(*) vs COUNT(DISTINCT o.id) dopo la JOIN ──"
SELECT c.cognome,
       COUNT(*)             AS righe_dopo_join,
       COUNT(DISTINCT o.id) AS ordini_veri
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE c.id IN (1, 8)
GROUP BY c.id, c.cognome;

-- =====================================================================
--  PARTE 2 - LEFT JOIN + COUNT: contare anche gli "zero"
-- =====================================================================

.print "\n── 6.4 SBAGLIATO: COUNT(*) con LEFT JOIN conta 1 anche chi ha 0 ordini ──"
SELECT c.id, c.cognome, COUNT(*) AS num_ordini
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.id, c.cognome
ORDER BY num_ordini, c.id
LIMIT 5;
-- Greco, Bruno e De Luca non hanno ordini, ma risultano con 1! Perché la
-- LEFT JOIN produce comunque UNA riga per loro (con le colonne di o a NULL)
-- e COUNT(*) conta le righe.

.print "\n── 6.5 GIUSTO: COUNT(colonna della tabella di destra) ──"
-- COUNT(o.id) ignora i NULL -> 0 per chi non ha ordini.
SELECT c.id, c.cognome, COUNT(o.id) AS num_ordini
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.id, c.cognome
ORDER BY num_ordini, c.id
LIMIT 5;

.print "\n── 6.6 Numero di prodotti per categoria, comprese quelle vuote ──"
SELECT cat.nome, COUNT(p.id) AS num_prodotti
FROM categorie cat
LEFT JOIN prodotti p ON p.categoria_id = cat.id
GROUP BY cat.id, cat.nome
ORDER BY num_prodotti DESC;

-- =====================================================================
--  PARTE 3 - LA TRAPPOLA PIÙ SUBDOLA: filtrare una LEFT JOIN nel WHERE
-- =====================================================================
--  Obiettivo: TUTTI i clienti, con il numero di ordini CONSEGNATI
--  (0 per chi non ne ha).
-- =====================================================================

.print "\n── 6.7 SBAGLIATO: la condizione nel WHERE trasforma la LEFT in INNER ──"
SELECT c.id, c.cognome, COUNT(o.id) AS consegnati
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
WHERE o.stato = 'consegnato'
GROUP BY c.id, c.cognome
ORDER BY c.id;
-- Mancano i clienti 10, 11, 13, 14, 16! Per loro o.stato è NULL (oppure
-- non è 'consegnato'), quindi il WHERE scarta le loro righe DOPO la JOIN.
-- Il risultato è identico a una INNER JOIN.

.print "\n── 6.8 GIUSTO: la condizione sulla tabella di destra va nell'ON ──"
SELECT c.id, c.cognome, COUNT(o.id) AS consegnati
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id AND o.stato = 'consegnato'
GROUP BY c.id, c.cognome
ORDER BY c.id;
-- REGOLA:
--   condizione nell'ON    -> decide QUALI righe di destra si abbinano
--                            (le righe di sinistra restano TUTTE)
--   condizione nel WHERE  -> scarta righe dal risultato FINALE
-- Con le INNER JOIN è indifferente; con le LEFT JOIN cambia tutto.

-- =====================================================================
--  PARTE 4 - ANTI-JOIN e SEMI-JOIN: "chi NON ha..." e "chi HA almeno un..."
-- =====================================================================

.print "\n── 6.9 ANTI-JOIN: clienti che non hanno MAI ordinato ──"
-- LEFT JOIN + "la destra è NULL" = righe di sinistra SENZA corrispondenza
SELECT c.id, c.nome, c.cognome
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
WHERE o.id IS NULL;
-- Qui il filtro nel WHERE è VOLUTO: teniamo solo le righe "spaiate".

.print "\n── 6.10 ANTI-JOIN: prodotti mai venduti ──"
SELECT p.id, p.nome, p.scorta
FROM prodotti p
LEFT JOIN righe_ordine r ON r.prodotto_id = p.id
WHERE r.ordine_id IS NULL;

.print "\n── 6.11 SEMI-JOIN: clienti che hanno comprato almeno un libro ──"
-- Con la JOIN un cliente compare una volta PER OGNI libro comprato...
SELECT c.cognome
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
JOIN categorie cat  ON cat.id = p.categoria_id
WHERE cat.nome = 'Libri'
ORDER BY c.cognome;

.print "   ...quindi servono DISTINCT (o EXISTS, lezione 7):"
SELECT DISTINCT c.id, c.cognome
FROM clienti c
JOIN ordini o       ON o.cliente_id = c.id
JOIN righe_ordine r ON r.ordine_id = o.id
JOIN prodotti p     ON p.id = r.prodotto_id
JOIN categorie cat  ON cat.id = p.categoria_id
WHERE cat.nome = 'Libri'
ORDER BY c.cognome;

-- =====================================================================
--  PARTE 5 - IL "FAN-OUT": quando la JOIN gonfia i totali
-- =====================================================================
--  Le spese di spedizione stanno su ordini (una per ordine). Se faccio la
--  JOIN con righe_ordine, un ordine con 3 righe compare 3 volte e la sua
--  spedizione viene sommata 3 volte!
-- =====================================================================

.print "\n── 6.12 SBAGLIATO: spese di spedizione sommate dopo la JOIN ──"
SELECT o.cliente_id,
       ROUND(SUM(o.spese_spedizione), 2)              AS spedizioni_GONFIATE,
       ROUND(SUM(r.quantita * r.prezzo_unitario), 2)  AS merce
FROM ordini o
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.cliente_id = 8
GROUP BY o.cliente_id;

.print "\n   Vediamo le righe grezze: l'ordine 11 compare 3 volte!"
SELECT o.id, o.spese_spedizione, r.prodotto_id
FROM ordini o
JOIN righe_ordine r ON r.ordine_id = o.id
WHERE o.cliente_id = 8;

.print "\n── 6.13 GIUSTO: prima aggrego le righe per ordine, POI faccio la JOIN ──"
-- La sottoquery calcola UN totale per ordine; così la JOIN è 1 a 1.
SELECT o.cliente_id,
       ROUND(SUM(o.spese_spedizione), 2) AS spedizioni,
       ROUND(SUM(t.totale_merce), 2)  AS merce
FROM ordini o
JOIN (SELECT ordine_id, SUM(quantita * prezzo_unitario) AS totale_merce
      FROM righe_ordine
      GROUP BY ordine_id) t ON t.ordine_id = o.id
WHERE o.cliente_id = 8
GROUP BY o.cliente_id;
-- REGOLA: se sommi una colonna della tabella "1" (ordini) dopo una JOIN
-- con una tabella "N" (righe_ordine), il totale è sbagliato.
-- Aggrega la tabella "N" prima, in una sottoquery.

-- =====================================================================
--  PARTE 6 - SELF JOIN: una tabella con sé stessa
-- =====================================================================

.print "\n── 6.14 Ogni dipendente con il nome del suo responsabile ──"
-- La stessa tabella usata due volte con due alias e due "ruoli":
--   d = il dipendente,  r = il responsabile
SELECT d.nome || ' ' || d.cognome                  AS dipendente,
       d.ruolo,
       COALESCE(r.nome || ' ' || r.cognome, '-')   AS responsabile
FROM dipendenti d
LEFT JOIN dipendenti r ON r.id = d.responsabile_id   -- LEFT: la CEO non ha responsabile
ORDER BY d.id;

.print "\n── 6.15 Quante persone gestisce ogni responsabile? ──"
SELECT r.nome || ' ' || r.cognome AS responsabile,
       COUNT(d.id)                AS collaboratori_diretti
FROM dipendenti r
JOIN dipendenti d ON d.responsabile_id = r.id
GROUP BY r.id, r.nome, r.cognome
ORDER BY collaboratori_diretti DESC;

.print "\n── 6.16 Dipendenti che guadagnano più del proprio responsabile ──"
SELECT d.nome, d.stipendio, r.nome AS responsabile, r.stipendio AS stip_resp
FROM dipendenti d
JOIN dipendenti r ON r.id = d.responsabile_id
WHERE d.stipendio > r.stipendio;
-- Nessuno: meglio così! Prova a cambiare  >  in  >  r.stipendio * 0.5

.print "\n── 6.17 Coppie di clienti della stessa città ──"
-- a.id < b.id evita le coppie doppie (A-B e B-A) e quelle con sé stessi (A-A)
SELECT a.citta, a.cognome AS cliente_1, b.cognome AS cliente_2
FROM clienti a
JOIN clienti b ON b.citta = a.citta AND a.id < b.id
ORDER BY a.citta;

-- =====================================================================
--  PARTE 7 - JOIN SU PIÙ COLONNE e JOIN NON DI UGUAGLIANZA
-- =====================================================================

.print "\n── 6.18 Recensioni 'verificate': il cliente ha davvero comprato il prodotto? ──"
-- La condizione deve combaciare su DUE colonne: stesso cliente E stesso prodotto.
SELECT rec.id, c.cognome, p.nome AS prodotto, rec.voto,
       CASE WHEN COUNT(r.ordine_id) > 0 THEN 'verificata' ELSE 'NON verificata' END AS stato
FROM recensioni rec
JOIN clienti  c ON c.id = rec.cliente_id
JOIN prodotti p ON p.id = rec.prodotto_id
LEFT JOIN ordini o       ON o.cliente_id = rec.cliente_id
LEFT JOIN righe_ordine r ON r.ordine_id = o.id AND r.prodotto_id = rec.prodotto_id
GROUP BY rec.id, c.cognome, p.nome, rec.voto
ORDER BY stato, rec.id;

.print "\n── 6.19 JOIN con disuguaglianza: quanti prodotti costano più di ognuno? ──"
-- La condizione non deve per forza essere un "=". Qui ogni prodotto si
-- abbina a tutti quelli più cari di lui: contandoli ottengo la posizione.
SELECT p.nome, p.prezzo, COUNT(piu_cari.id) + 1 AS posizione
FROM prodotti p
LEFT JOIN prodotti piu_cari ON piu_cari.prezzo > p.prezzo
GROUP BY p.id, p.nome, p.prezzo
ORDER BY posizione
LIMIT 6;
-- (Nella lezione 9 vedremo RANK(), che fa la stessa cosa molto meglio.)

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/06_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Per ogni dipendente (TUTTI, anche chi non ha gestito ordini):
      numero di ordini gestiti e fatturato generato (ordini non annullati).
      Attenzione al fan-out e al COUNT!
   2. Categorie che non hanno mai venduto nulla (anti-join su più tabelle).
   3. Per ogni città: numero di clienti e numero di ordini. I clienti senza
      ordini vanno contati tra i clienti! (Suggerimento: COUNT(DISTINCT ...))
   4. Clienti che hanno ordinato sia nel 2024 che nel 2025.
      (Suggerimento: self join su ordini, oppure GROUP BY + HAVING con
      aggregazione condizionale.)
   5. Per ogni prodotto: nome, numero di recensioni e voto medio.
      Includi anche i prodotti senza recensioni (voto medio NULL).
   6. Clienti che hanno recensito un prodotto senza averlo mai comprato.
   7. Trova l'errore: questa query dovrebbe dare TUTTI i prodotti con i
      pezzi venduti nel 2025 (0 se nessuno), ma ne restituisce pochi.
         SELECT p.nome, COALESCE(SUM(r.quantita), 0) AS venduti_2025
         FROM prodotti p
         LEFT JOIN righe_ordine r ON r.prodotto_id = p.id
         LEFT JOIN ordini o ON o.id = r.ordine_id
         WHERE o.data_ordine >= '2025-01-01'
         GROUP BY p.id, p.nome;
   8. Per ogni dipendente, il nome del responsabile del suo responsabile
      ("nonno" nella gerarchia). Chi non ce l'ha mostra NULL.
   --------------------------------------------------------------------- */
