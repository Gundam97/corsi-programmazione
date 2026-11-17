-- =====================================================================
--  SQL - LEZIONE 4: AGGREGAZIONI, GROUP BY e HAVING
-- =====================================================================
--
--  Finora ogni riga del risultato corrispondeva a una riga della tabella.
--  Le FUNZIONI DI AGGREGAZIONE invece RIASSUMONO tante righe in UN valore:
--
--     COUNT(*)            numero di righe
--     COUNT(colonna)      numero di valori NON NULL in quella colonna
--     COUNT(DISTINCT col) numero di valori DIVERSI (non NULL)
--     SUM(col)            somma
--     AVG(col)            media
--     MIN(col) / MAX(col) minimo / massimo (anche su testo e date)
--
--  REGOLA D'ORO: tutte le funzioni di aggregazione IGNORANO i NULL,
--  tranne COUNT(*) che conta le righe qualunque cosa contengano.
--
--  GROUP BY divide le righe in GRUPPI (le righe con lo stesso valore
--  finiscono nello stesso gruppo) e calcola le aggregazioni per OGNI
--  gruppo. Ogni gruppo diventa UNA riga del risultato.
--
--     tabella ordini                    GROUP BY stato
--     id | stato                        stato       | COUNT(*)
--     1  | consegnato  ─┐               ────────────+─────────
--     2  | consegnato   ├──────────▶    consegnato  |   21
--     3  | consegnato  ─┘               annullato   |    3
--     7  | annullato   ───────────▶     ...
--     ...
-- =====================================================================

.print "\n── 4.1 Aggregazioni su TUTTA la tabella (un unico gruppo) ──"
SELECT COUNT(*)              AS num_prodotti,
       SUM(scorta)           AS pezzi_in_magazzino,
       ROUND(AVG(prezzo), 2) AS prezzo_medio,
       MIN(prezzo)           AS piu_economico,
       MAX(prezzo)           AS piu_caro
FROM prodotti;

.print "\n── 4.2 COUNT(*) vs COUNT(colonna) vs COUNT(DISTINCT colonna) ──"
-- 16 clienti, ma solo 14 hanno la città, e le città diverse sono 6.
SELECT COUNT(*)              AS righe,
       COUNT(citta)          AS con_citta,
       COUNT(DISTINCT citta) AS citta_diverse
FROM clienti;

.print "\n── 4.3 TRAPPOLA: AVG ignora i NULL ──"
-- Su 31 ordini, 9 non hanno dipendente_id (sono online).
-- COUNT(dipendente_id) conta solo i 22 ordini gestiti da un dipendente.
SELECT COUNT(*)                                AS ordini_totali,
       COUNT(dipendente_id)                    AS ordini_con_dipendente,
       ROUND(AVG(spese_spedizione), 3)         AS media_spedizione
FROM ordini;
-- Qui non ci sono NULL nelle spese, quindi AVG = SUM/COUNT(*). Ma se una
-- colonna ha dei NULL, AVG divide solo per i valori presenti:
SELECT AVG(x)            AS avg_ignora_null,     -- (10 + 20) / 2 = 15
       SUM(x) / COUNT(*) AS somma_su_tutte       -- (10 + 20) / 3 = 10
FROM (SELECT 10 AS x UNION ALL SELECT 20 UNION ALL SELECT NULL);

.print "\n── 4.4 GROUP BY su una colonna: quanti ordini per stato? ──"
SELECT stato, COUNT(*) AS num_ordini
FROM ordini
GROUP BY stato
ORDER BY num_ordini DESC;

.print "\n── 4.5 Totale di ogni ordine (dalle righe d'ordine) ──"
SELECT ordine_id,
       COUNT(*)                               AS num_righe,
       SUM(quantita)                          AS pezzi,
       ROUND(SUM(quantita * prezzo_unitario), 2) AS totale
FROM righe_ordine
GROUP BY ordine_id
ORDER BY totale DESC
LIMIT 8;

.print "\n── 4.6 Il gruppo NULL: anche i NULL formano un gruppo ──"
SELECT citta, COUNT(*) AS num_clienti
FROM clienti
GROUP BY citta
ORDER BY num_clienti DESC, citta;

.print "\n── 4.7 GROUP BY su più colonne: un gruppo per ogni COMBINAZIONE ──"
SELECT reparto, ruolo, COUNT(*) AS persone, AVG(stipendio) AS stipendio_medio
FROM dipendenti
GROUP BY reparto, ruolo
ORDER BY reparto, ruolo;

.print "\n── 4.8 GROUP BY su un'espressione: ordini per anno e mese ──"
SELECT strftime('%Y-%m', data_ordine) AS mese,
       COUNT(*)                        AS num_ordini
FROM ordini
GROUP BY strftime('%Y-%m', data_ordine)
ORDER BY mese;

-- =====================================================================
--  LA REGOLA FONDAMENTALE DEL GROUP BY
-- =====================================================================
--  Nella SELECT di una query con GROUP BY puoi mettere SOLO:
--    a) le colonne che compaiono nel GROUP BY
--    b) funzioni di aggregazione
--  Perché? Ogni gruppo diventa UNA riga. Se nel gruppo "Vendite" ci sono
--  5 dipendenti con 5 nomi diversi, quale nome dovrebbe mostrare?
--
--  PostgreSQL, SQL Server, Oracle e MySQL (in modalità standard) danno
--  ERRORE. SQLite invece lo permette e restituisce un valore A CASO del
--  gruppo: è un comportamento da NON sfruttare, perché altrove non funziona
--  e spesso nasconde un errore di ragionamento.
-- =====================================================================

.print "\n── 4.9 SBAGLIATO (funziona solo in SQLite): colonna non aggregata ──"
SELECT reparto, nome, COUNT(*) AS persone   -- "nome" di CHI? Di uno a caso!
FROM dipendenti
GROUP BY reparto;

.print "\n── 4.10 GIUSTO: decidi cosa vuoi vedere del gruppo ──"
-- Per esempio l'elenco di tutti i nomi, con GROUP_CONCAT
-- (MySQL: GROUP_CONCAT, PostgreSQL: STRING_AGG(nome, ', '))
SELECT reparto,
       COUNT(*)                  AS persone,
       GROUP_CONCAT(nome, ', ')  AS nomi
FROM dipendenti
GROUP BY reparto;
-- Se vuoi "il nome di chi guadagna di più nel reparto", servono le
-- subquery o le window function (lezioni 7 e 9).

-- =====================================================================
--  WHERE vs HAVING
-- =====================================================================
--   WHERE  filtra le RIGHE  PRIMA  che vengano raggruppate
--   HAVING filtra i GRUPPI  DOPO   il raggruppamento
--  Per questo in WHERE non puoi usare COUNT, SUM... (i gruppi non
--  esistono ancora!), mentre in HAVING sì.
-- =====================================================================

.print "\n── 4.11 HAVING: clienti con almeno 3 ordini ──"
SELECT cliente_id, COUNT(*) AS num_ordini
FROM ordini
GROUP BY cliente_id
HAVING COUNT(*) >= 3
ORDER BY num_ordini DESC, cliente_id;

.print "\n── 4.12 WHERE + HAVING insieme ──"
-- Clienti con almeno 3 ordini, contando SOLO quelli non annullati.
-- WHERE toglie prima gli annullati, poi si raggruppa, poi HAVING filtra.
SELECT cliente_id, COUNT(*) AS ordini_validi
FROM ordini
WHERE stato <> 'annullato'
GROUP BY cliente_id
HAVING COUNT(*) >= 3
ORDER BY ordini_validi DESC, cliente_id;
-- Confronta con 4.11: i clienti 1 e 2 sono scesi da 5 a 4 ordini.

.print "\n── 4.13 ERRORE tipico: aggregazione nel WHERE ──"
-- SELECT cliente_id FROM ordini WHERE COUNT(*) >= 3 GROUP BY cliente_id;
--   -> Error: misuse of aggregate: COUNT()
-- La query è commentata, altrimenti lo script si fermerebbe:
-- provala a mano con  ./esegui.sh shell  e leggi l'errore.
.print "   (query commentata: vedi il file)"

-- =====================================================================
--  ORDINE LOGICO DI ESECUZIONE  (da sapere a memoria!)
-- =====================================================================
--  Scriviamo la query in quest'ordine:
--      SELECT  ...  FROM  ...  WHERE  ...  GROUP BY  ...  HAVING  ...  ORDER BY  ...  LIMIT
--  ma il database la ESEGUE (logicamente) in quest'altro:
--
--      1. FROM       quali tabelle (e JOIN)
--      2. WHERE      quali righe tengo
--      3. GROUP BY   come formo i gruppi
--      4. HAVING     quali gruppi tengo
--      5. SELECT     quali colonne calcolo (qui nascono gli alias!)
--      6. DISTINCT   tolgo i duplicati
--      7. ORDER BY   ordino
--      8. LIMIT      taglio
--
--  Conseguenze pratiche:
--   - un alias definito nella SELECT NON esiste ancora in WHERE
--     (ma si può usare in ORDER BY, che viene dopo)
--   - per questo in HAVING si riscrive COUNT(*) invece di usare l'alias
--     (SQLite e MySQL sono permissivi, PostgreSQL no)
-- =====================================================================

.print "\n── 4.14 Alias in ORDER BY: OK (ORDER BY viene dopo SELECT) ──"
SELECT categoria_id, ROUND(AVG(prezzo), 2) AS prezzo_medio
FROM prodotti
GROUP BY categoria_id
ORDER BY prezzo_medio DESC;

-- =====================================================================
--  AGGREGAZIONE CONDIZIONALE  (tecnica potentissima)
-- =====================================================================
--  Mettendo un CASE DENTRO una funzione di aggregazione posso calcolare
--  più conteggi diversi in una sola query, trasformando righe in colonne
--  (si chiama anche "pivot").
-- =====================================================================

.print "\n── 4.15 Per ogni anno: ordini per stato, su colonne separate ──"
SELECT strftime('%Y', data_ordine)                         AS anno,
       COUNT(*)                                            AS totale,
       SUM(CASE WHEN stato = 'consegnato' THEN 1 ELSE 0 END) AS consegnati,
       SUM(CASE WHEN stato = 'annullato'  THEN 1 ELSE 0 END) AS annullati,
       SUM(CASE WHEN stato IN ('in_attesa', 'spedito') THEN 1 ELSE 0 END) AS aperti
FROM ordini
GROUP BY anno
ORDER BY anno;

.print "\n── 4.16 Percentuale di ordini online per anno ──"
SELECT strftime('%Y', data_ordine) AS anno,
       COUNT(*)                    AS ordini,
       ROUND(100.0 * SUM(CASE WHEN dipendente_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1)
                                   AS perc_online
FROM ordini
GROUP BY anno;

.print "\n── 4.17 Distribuzione dei voti nelle recensioni ──"
SELECT voto, COUNT(*) AS quante,
       SUBSTR('██████████', 1, COUNT(*)) AS grafico
FROM recensioni
GROUP BY voto
ORDER BY voto DESC;

/* ---------------------------------------------------------------------
   ESERCIZI   (soluzioni in: soluzioni/04_soluzioni.sql)
   ---------------------------------------------------------------------
   1. Quanti prodotti ci sono per ogni categoria_id? (Anche quelli senza.)
   2. Stipendio totale, medio, minimo e massimo per reparto.
   3. Quanti clienti si sono registrati in ogni anno?
   4. Per ogni prodotto (prodotto_id): pezzi venduti in totale e incasso
      totale, dal più venduto. (Usa righe_ordine.)
   5. Quali prodotti (prodotto_id) sono stati venduti in almeno 4 ordini
      diversi?
   6. Voto medio di ogni prodotto recensito, solo per i prodotti con
      almeno 2 recensioni, arrotondato a 1 decimale.
   7. Per ogni mese del 2024: numero di ordini e spese di spedizione
      incassate. Mostra solo i mesi con spese > 0.
   8. Quanti ordini ha gestito ogni dipendente? (Gli ordini online
      formano il gruppo NULL: va bene così.) Mostra solo chi ne ha più di 4.
   9. In una sola query: quanti prodotti costano meno di 30, quanti tra
      30 e 100 e quanti più di 100 (tre colonne, aggregazione condizionale).
  10. DOMANDA: perché questa query dà errore in PostgreSQL? Correggila.
        SELECT citta, nome, COUNT(*) FROM clienti GROUP BY citta;
   --------------------------------------------------------------------- */
