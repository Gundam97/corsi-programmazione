-- =====================================================================
--  SQL - LEZIONE 7: SUBQUERY e CTE (query dentro le query)
-- =====================================================================
--
--  Una SUBQUERY è una SELECT scritta dentro un'altra, tra parentesi.
--  Si può usare quasi ovunque:
--
--    - nel WHERE:   WHERE prezzo > (SELECT AVG(prezzo) FROM prodotti)
--    - nel FROM:    FROM (SELECT ...) AS t        ("tabella derivata")
--    - nella SELECT: SELECT nome, (SELECT ...) AS x
--
--  A seconda di cosa restituisce:
--    - SCALARE:  un solo valore (1 riga, 1 colonna) -> si usa come un numero
--    - LISTA:    una colonna, tante righe          -> con IN / NOT IN
--    - TABELLA:  tante righe e colonne             -> nel FROM
--
--  Una subquery è CORRELATA se usa colonne della query esterna: viene
--  (logicamente) rieseguita per OGNI riga esterna.
--
--  Le CTE (WITH ... AS) sono subquery con un NOME, scritte prima della
--  query principale: rendono leggibili le query complicate.
-- =====================================================================

.print "\n── 7.1 Subquery scalare nel WHERE: prodotti sopra la media ──"
-- Prima il DB calcola la media (una volta), poi la usa come un numero.
SELECT nome, prezzo
FROM prodotti
WHERE prezzo > (SELECT AVG(prezzo) FROM prodotti)
ORDER BY prezzo DESC;

.print "\n── 7.2 Subquery scalare nella SELECT: confronto con la media ──"
SELECT nome, prezzo,
       ROUND((SELECT AVG(prezzo) FROM prodotti), 2)          AS media,
       ROUND(prezzo - (SELECT AVG(prezzo) FROM prodotti), 2) AS differenza
FROM prodotti
WHERE categoria_id = 2;

.print "\n── 7.3 Il dipendente più pagato (senza LIMIT, funziona anche a pari merito) ──"
SELECT nome, cognome, stipendio
FROM dipendenti
WHERE stipendio = (SELECT MAX(stipendio) FROM dipendenti);

.print "\n── 7.4 Subquery con IN: clienti che hanno ordinato nel 2025 ──"
SELECT id, nome, cognome
FROM clienti
WHERE id IN (SELECT cliente_id FROM ordini WHERE data_ordine >= '2025-01-01')
ORDER BY id;
-- Nessun duplicato, a differenza di una JOIN: IN risponde solo "sì/no".

.print "\n── 7.5 NOT IN: clienti che NON hanno mai ordinato ──"
SELECT id, nome, cognome
FROM clienti
WHERE id NOT IN (SELECT cliente_id FROM ordini);

-- =====================================================================
--  LA TRAPPOLA DEL NOT IN CON I NULL  (classico da colloquio)
-- =====================================================================
--  Domanda: quali dipendenti NON sono responsabili di nessuno?
--  Sembra facile: "id NOT IN (elenco dei responsabile_id)".
-- =====================================================================

.print "\n── 7.6 SBAGLIATO: NOT IN su una lista che contiene NULL -> 0 righe! ──"
SELECT nome, cognome
FROM dipendenti
WHERE id NOT IN (SELECT responsabile_id FROM dipendenti);
-- Perché vuoto? La lista è (NULL, 1, 1, 2, 2, 2, 3, 3, 4, 1).
-- "5 NOT IN (NULL, 1, 2...)" significa "5 <> NULL AND 5 <> 1 AND ..."
-- e 5 <> NULL è SCONOSCIUTO -> tutta la condizione è sconosciuta -> scartata.
-- Basta UN NULL nella lista perché NOT IN non restituisca MAI nulla.

.print "\n── 7.7 Soluzione 1: escludere i NULL nella subquery ──"
SELECT nome, cognome
FROM dipendenti
WHERE id NOT IN (SELECT responsabile_id FROM dipendenti WHERE responsabile_id IS NOT NULL);

.print "\n── 7.8 Soluzione 2 (consigliata): NOT EXISTS ──"
-- EXISTS (subquery) è vero se la subquery restituisce ALMENO una riga.
-- Non soffre del problema dei NULL. È una subquery CORRELATA: per ogni
-- dipendente d, cerca se esiste qualcuno che ha d come responsabile.
SELECT d.nome, d.cognome
FROM dipendenti d
WHERE NOT EXISTS (SELECT 1               -- cosa selezioni non importa: conta se c'è una riga
                  FROM dipendenti sub
                  WHERE sub.responsabile_id = d.id);

.print "\n── 7.9 EXISTS: clienti che hanno comprato almeno un libro ──"
-- Lo stesso problema della 6.11, senza duplicati e senza DISTINCT.
SELECT c.id, c.cognome
FROM clienti c
WHERE EXISTS (SELECT 1
              FROM ordini o
              JOIN righe_ordine r ON r.ordine_id = o.id
              JOIN prodotti p     ON p.id = r.prodotto_id
              JOIN categorie cat  ON cat.id = p.categoria_id
              WHERE o.cliente_id = c.id          -- <- la correlazione
                AND cat.nome = 'Libri')
ORDER BY c.cognome;

.print "\n── 7.10 Subquery CORRELATA: prodotti più cari della media DELLA LORO categoria ──"
-- Per ogni prodotto p, la subquery calcola la media della categoria di p.
SELECT p.nome, p.categoria_id, p.prezzo
FROM prodotti p
WHERE p.prezzo > (SELECT AVG(p2.prezzo)
                  FROM prodotti p2
                  WHERE p2.categoria_id = p.categoria_id)
ORDER BY p.categoria_id;

.print "\n── 7.11 Il più pagato DI OGNI reparto (la domanda rimasta aperta nella 4.10) ──"
SELECT d.reparto, d.nome, d.cognome, d.stipendio
FROM dipendenti d
WHERE d.stipendio = (SELECT MAX(d2.stipendio)
                     FROM dipendenti d2
                     WHERE d2.reparto = d.reparto)
ORDER BY d.reparto;

.print "\n── 7.12 Subquery nel FROM (tabella derivata): media dei totali d'ordine ──"
-- Non si può scrivere AVG(SUM(...)): prima calcolo i totali, poi la media.
SELECT COUNT(*)              AS ordini,
       ROUND(AVG(totale), 2) AS scontrino_medio,
       MAX(totale)           AS scontrino_massimo
FROM (SELECT ordine_id, SUM(quantita * prezzo_unitario) AS totale
      FROM righe_ordine
      GROUP BY ordine_id) AS totali;

.print "\n── 7.13 Confronto con un aggregato: ordini sopra lo scontrino medio ──"
SELECT ordine_id, ROUND(SUM(quantita * prezzo_unitario), 2) AS totale
FROM righe_ordine
GROUP BY ordine_id
HAVING SUM(quantita * prezzo_unitario) >
       (SELECT AVG(t) FROM (SELECT SUM(quantita * prezzo_unitario) AS t
                            FROM righe_ordine GROUP BY ordine_id))
ORDER BY totale DESC;
-- Funziona, ma è illeggibile. Ecco a cosa servono le CTE...

-- =====================================================================
--  CTE: COMMON TABLE EXPRESSION  (WITH)
-- =====================================================================
--     WITH nome1 AS (SELECT ...),
--          nome2 AS (SELECT ... FROM nome1 ...)
--     SELECT ... FROM nome2;
--  Ogni CTE è una "tabella temporanea" con un nome, visibile solo in
--  questa query. Si leggono dall'alto in basso come i passi di una ricetta.
-- =====================================================================

.print "\n── 7.14 La 7.13 riscritta con una CTE ──"
WITH totali_ordine AS (
    SELECT ordine_id, SUM(quantita * prezzo_unitario) AS totale
    FROM righe_ordine
    GROUP BY ordine_id
)
SELECT ordine_id, ROUND(totale, 2) AS totale
FROM totali_ordine
WHERE totale > (SELECT AVG(totale) FROM totali_ordine)
ORDER BY totale DESC;

.print "\n── 7.15 Più CTE in fila: segmentazione dei clienti ──"
-- Passo 1: quanto ha speso ogni cliente (ordini non annullati)
-- Passo 2: assegno un segmento
-- Passo 3: conto i clienti per segmento
WITH spesa_cliente AS (
    SELECT o.cliente_id, SUM(r.quantita * r.prezzo_unitario) AS speso
    FROM ordini o
    JOIN righe_ordine r ON r.ordine_id = o.id
    WHERE o.stato <> 'annullato'
    GROUP BY o.cliente_id
),
segmenti AS (
    SELECT c.id,
           c.cognome,
           COALESCE(s.speso, 0) AS speso,
           CASE
               WHEN s.speso IS NULL THEN '0 - Mai acquistato'
               WHEN s.speso >= 1000 THEN '1 - Gold'
               WHEN s.speso >= 200  THEN '2 - Silver'
               ELSE                      '3 - Bronze'
           END AS segmento
    FROM clienti c
    LEFT JOIN spesa_cliente s ON s.cliente_id = c.id
)
SELECT segmento,
       COUNT(*)                  AS clienti,
       ROUND(SUM(speso), 2)      AS fatturato,
       GROUP_CONCAT(cognome, ', ') AS chi
FROM segmenti
GROUP BY segmento
ORDER BY segmento;

-- =====================================================================
--  CTE RICORSIVE  (WITH RECURSIVE)
-- =====================================================================
--  Una CTE ricorsiva fa riferimento a SÉ STESSA. Ha due parti:
--     1) caso base         (le righe di partenza)
--     UNION ALL
--     2) passo ricorsivo   (nuove righe calcolate da quelle precedenti)
--  Si ferma quando il passo ricorsivo non produce più righe.
--  Come la ricorsione in Java: serve SEMPRE un modo per fermarsi!
-- =====================================================================

.print "\n── 7.16 CTE ricorsiva semplice: i numeri da 1 a 5 ──"
WITH RECURSIVE numeri(n) AS (
    SELECT 1                                  -- caso base
    UNION ALL
    SELECT n + 1 FROM numeri WHERE n < 5      -- passo ricorsivo (con condizione di stop)
)
SELECT n FROM numeri;

.print "\n── 7.17 L'organigramma completo con il livello gerarchico ──"
-- Una self join dà solo UN livello (dipendente -> responsabile).
-- Con la ricorsione scendo di quanti livelli servono.
WITH RECURSIVE organigramma AS (
    SELECT id, nome, cognome, ruolo, 1 AS livello,
           nome AS percorso
    FROM dipendenti
    WHERE responsabile_id IS NULL                 -- caso base: la CEO
    UNION ALL
    SELECT d.id, d.nome, d.cognome, d.ruolo, o.livello + 1,
           o.percorso || ' > ' || d.nome
    FROM dipendenti d
    JOIN organigramma o ON d.responsabile_id = o.id   -- i collaboratori di chi ho già trovato
)
SELECT SUBSTR('                ', 1, (livello - 1) * 4) || nome || ' ' || cognome AS albero,
       ruolo, livello, percorso
FROM organigramma
ORDER BY percorso;

.print "\n── 7.18 Riempire i 'buchi': calendario dei mesi con anche gli zeri ──"
-- GROUP BY mostra solo i mesi che HANNO ordini. Per un grafico servono
-- anche i mesi a zero: genero tutti i mesi e faccio una LEFT JOIN.
WITH RECURSIVE mesi(mese) AS (
    SELECT '2025-01-01'
    UNION ALL
    SELECT date(mese, '+1 month') FROM mesi WHERE mese < '2025-12-01'
),
ordini_mese AS (
    SELECT strftime('%Y-%m', data_ordine) AS anno_mese, COUNT(*) AS n
    FROM ordini
    GROUP BY anno_mese
)
SELECT strftime('%Y-%m', m.mese) AS mese,
       COALESCE(om.n, 0)         AS ordini
FROM mesi m
LEFT JOIN ordini_mese om ON om.anno_mese = strftime('%Y-%m', m.mese)
ORDER BY m.mese;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/07_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Prodotti che costano meno del prodotto più economico di Informatica.
   2. Clienti che non hanno mai lasciato una recensione (prima con
      NOT IN, poi con NOT EXISTS).
   3. Prodotti mai venduti, usando NOT EXISTS.
   4. Per ogni cliente che ha ordinato, la data del suo PRIMO ordine e
      dell'ULTIMO, e quanti giorni sono passati tra i due.
   5. Ordini il cui totale merce è superiore a 500 €, con nome del cliente
      (usa una CTE per i totali).
   6. Per ogni categoria, il prodotto più caro (subquery correlata).
   7. Con una CTE: il cliente che ha speso di più in ogni città.
   8. Con una CTE ricorsiva: tutte le persone che lavorano SOTTO Giorgio
      Moretti, a qualsiasi livello.
   9. Spiega perché  WHERE id NOT IN (SELECT dipendente_id FROM ordini)
      non restituisce nessun dipendente, e correggila.
   --------------------------------------------------------------------- */
