# SQL da zero, con la pratica

Questa sezione insegna SQL lavorando su un database realistico: un **piccolo negozio online** con clienti, prodotti, ordini, dipendenti e recensioni.
Ogni lezione è un file `.sql` eseguibile e commentato in italiano. Gli esempi sono numerati e mostrano il risultato a video. In fondo a ogni lezione ci sono gli **esercizi**, e le **soluzioni** sono in file separati.

Gran parte del percorso è dedicata alle parti che mettono davvero in difficoltà: **GROUP BY, JOIN, NULL, subquery e window function**, con le trappole tipiche spiegate una per una.

---

## Cosa serve

Si usa **SQLite**: è un database che sta in un singolo file e non richiede nessun server.

| Sistema | Installazione |
|---------|---------------|
| macOS   | già installato (`sqlite3 --version` per verificare) |
| Linux   | `sudo apt install sqlite3` (o il gestore pacchetti della tua distribuzione) |
| Windows | scarica *sqlite-tools* da [sqlite.org/download.html](https://www.sqlite.org/download.html), estrai `sqlite3.exe` e aggiungilo al PATH |

Serve la versione **3.39 o successiva** (per `RIGHT JOIN` e `FULL JOIN`).

In alternativa al terminale si può usare un programma grafico, per esempio [DB Browser for SQLite](https://sqlitebrowser.org/) o [DBeaver](https://dbeaver.io/): basta aprire il file `corso.db`. Le righe che iniziano con `.print` sono comandi del terminale sqlite3 e in questi programmi vanno ignorate.

---

## Come si usa

```bash
cd sql
./esegui.sh              # elenco delle lezioni
./esegui.sh 4            # esegue la lezione 4 (ricrea il database prima)
./esegui.sh soluzioni 4  # esegue le soluzioni della lezione 4
./esegui.sh shell        # apre sqlite3 per scrivere query a mano
./esegui.sh crea         # ricrea il database da zero
```

Il database viene **ricreato da zero** prima di ogni lezione, quindi non si rompe niente anche sbagliando un `UPDATE` o un `DELETE`.

**Il modo migliore per studiare:** apri il file della lezione nell'editor e, in un altro terminale, `./esegui.sh shell`. Copia le query, eseguile, poi **modificale** e guarda cosa cambia.

---

## Il database

```
categorie 1───N prodotti 1───N righe_ordine N───1 ordini N───1 clienti
                   │                                 │
                   └───N recensioni N────────────────┼─── clienti
                                                     │
                                   dipendenti 1──────┘   (chi ha gestito l'ordine)
                                       └── responsabile_id → dipendenti
```

| Tabella | Righe | Cosa contiene |
|---------|-------|---------------|
| `categorie` | 5 | Informatica, Libri, Casa, Sport, Giochi |
| `prodotti` | 18 | nome, categoria, prezzo di listino, scorta |
| `clienti` | 16 | anagrafica, città, data di registrazione |
| `dipendenti` | 10 | ruolo, reparto, stipendio, responsabile (gerarchia a 4 livelli) |
| `ordini` | 31 | cliente, dipendente (NULL = online), data, stato, spedizione |
| `righe_ordine` | 50 | prodotti di ogni ordine, quantità, prezzo pagato |
| `recensioni` | 15 | voto da 1 a 5 e commento |

I dati contengono **di proposito** dei casi particolari: una categoria senza prodotti, un prodotto senza categoria, prodotti mai venduti, clienti senza ordini, città mancanti (NULL), un ordine vuoto, sconti, omonimi. Sono proprio i casi in cui le query sbagliate danno risultati sbagliati senza nessun errore. L'elenco completo è in testa a [`database/02_dati.sql`](database/02_dati.sql).

---

## Il percorso

| # | Lezione | Argomenti |
|---|---------|-----------|
| 1 | [SELECT](lezioni/01_select.sql) | colonne, alias, calcoli, `ORDER BY`, `DISTINCT`, `LIMIT`/`OFFSET` |
| 2 | [WHERE e NULL](lezioni/02_where_e_null.sql) | operatori, precedenza `AND`/`OR`, `IN`, `BETWEEN`, `LIKE`, **logica a tre valori del NULL** |
| 3 | [Funzioni e CASE](lezioni/03_funzioni_e_case.sql) | testo, numeri, date, `COALESCE`, `NULLIF`, `CASE` |
| 4 | [**GROUP BY**](lezioni/04_aggregazioni_group_by.sql) | `COUNT(*)` vs `COUNT(col)`, la regola d'oro del GROUP BY, `WHERE` vs `HAVING`, **ordine di esecuzione**, aggregazione condizionale |
| 5 | [**JOIN**](lezioni/05_join.sql) | `INNER`, `LEFT`, `RIGHT`, `FULL`, `CROSS`, JOIN multiple, condizioni nell'`ON` |
| 6 | [**JOIN: trappole e tecniche**](lezioni/06_join_trappole_e_tecniche.sql) | report con JOIN e GROUP BY, LEFT JOIN + COUNT, **filtro nel WHERE che annulla la LEFT JOIN**, anti-join, semi-join, **righe moltiplicate dalla JOIN (fan-out)**, self join |
| 7 | [Subquery e CTE](lezioni/07_subquery_e_cte.sql) | subquery scalari, `IN`, **la trappola del `NOT IN` con i NULL**, `EXISTS`, subquery correlate, `WITH`, CTE ricorsive |
| 8 | [UNION, INTERSECT, EXCEPT](lezioni/08_operatori_insiemistici.sql) | operazioni tra insiemi, `UNION` vs `UNION ALL`, righe di totale |
| 9 | [**Window function**](lezioni/09_window_functions.sql) | `OVER`, `PARTITION BY`, `ROW_NUMBER`/`RANK`/`DENSE_RANK`, **top-N per gruppo**, totali progressivi, `LAG`/`LEAD`, frame |
| 10 | [Modificare i dati](lezioni/10_modificare_i_dati.sql) | `INSERT`, `UPDATE`, `DELETE`, `RETURNING`, upsert, **transazioni** e `SAVEPOINT` |
| 11 | [Progettare il database](lezioni/11_creare_tabelle_viste_indici.sql) | normalizzazione, `CREATE TABLE`, vincoli, `ON DELETE`, viste, **indici** ed `EXPLAIN` |
| 12 | [**Esercitazione finale**](lezioni/12_esercitazione_finale.sql) | metodo in 5 passi, esempio guidato, 12 domande "di business" di difficoltà crescente |

---

## Promemoria

### Ordine di esecuzione di una query

Si **scrive** in quest'ordine:
`SELECT … FROM … WHERE … GROUP BY … HAVING … ORDER BY … LIMIT`

ma il database lo **esegue** in quest'altro:

| Passo | Clausola | Cosa fa |
|-------|----------|---------|
| 1 | `FROM` / `JOIN` | prende le tabelle e le collega |
| 2 | `WHERE` | filtra le righe |
| 3 | `GROUP BY` | forma i gruppi |
| 4 | `HAVING` | filtra i gruppi |
| 5 | `SELECT` | calcola le colonne (anche le window function); qui nascono gli alias |
| 6 | `DISTINCT` | toglie i duplicati |
| 7 | `ORDER BY` | ordina |
| 8 | `LIMIT` | taglia |

### Le 10 trappole più comuni

1. `= NULL` non trova niente: si scrive `IS NULL`.
2. `NOT IN (subquery)` restituisce **zero righe** se la subquery contiene anche un solo NULL: meglio `NOT EXISTS`.
3. `COUNT(*)` conta le righe, `COUNT(colonna)` conta i valori non NULL. Dopo una `LEFT JOIN` per contare "zero" serve `COUNT(colonna_di_destra)`.
4. Una condizione sulla tabella di destra di una `LEFT JOIN` scritta nel `WHERE` la trasforma in `INNER JOIN`: va messa nell'`ON`.
5. Dopo una JOIN uno-a-molti le righe "padre" si **ripetono**: `SUM` su una colonna del padre gonfia il totale, e per contare i padri serve `COUNT(DISTINCT)`.
6. Nella `SELECT` con `GROUP BY` vanno solo colonne raggruppate o aggregate (SQLite è permissivo, gli altri database no).
7. `WHERE` non vede le aggregazioni: per filtrare su `COUNT`/`SUM` si usa `HAVING`.
8. Senza `ORDER BY` l'ordine delle righe **non è garantito**.
9. `AND` ha la precedenza su `OR`: usa le parentesi.
10. `UPDATE` e `DELETE` senza `WHERE` agiscono su **tutta** la tabella: prima prova il `WHERE` con una `SELECT`.

### SQLite e gli altri database

Il corso usa SQL standard il più possibile. Dove SQLite è diverso, i commenti nelle lezioni lo segnalano. Le differenze principali:

| Cosa | SQLite | PostgreSQL | MySQL |
|------|--------|-----------|-------|
| Concatenare testo | `a \|\| b` | `a \|\| b` | `CONCAT(a, b)` |
| Anno di una data | `strftime('%Y', d)` | `EXTRACT(YEAR FROM d)` | `YEAR(d)` |
| Aggiungere giorni | `date(d, '+7 days')` | `d + INTERVAL '7 days'` | `DATE_ADD(d, INTERVAL 7 DAY)` |
| Unire valori di un gruppo | `GROUP_CONCAT(x, ', ')` | `STRING_AGG(x, ', ')` | `GROUP_CONCAT(x SEPARATOR ', ')` |
| Tipo delle date | testo `'AAAA-MM-GG'` | `DATE` | `DATE` |
| Colonne non aggregate nel GROUP BY | permesse (attenzione!) | errore | errore (modalità standard) |
| `FULL OUTER JOIN` | sì | sì | no |
| Upsert | `ON CONFLICT … DO UPDATE` | `ON CONFLICT … DO UPDATE` | `ON DUPLICATE KEY UPDATE` |

---

## Suggerimenti per chi insegna

- **Prima la domanda, poi la query.** Prima di eseguire un esempio, chiedi allo studente quante righe si aspetta e perché. Con JOIN e GROUP BY questo esercizio vale più di qualsiasi spiegazione.
- **Guardare le righe "grezze".** Quando un risultato non torna, togli `GROUP BY` e aggregazioni e guarda le righe prima del raggruppamento: quasi sempre il problema si vede lì (lo fanno gli esempi 6.12 e 12, passo 3).
- **Le lezioni 4, 5 e 6 sono il cuore del corso.** Conviene dedicare a ciascuna almeno un incontro intero, e tornarci sopra con gli esercizi della lezione 12.
- **Contare a mano.** Il dataset è piccolo apposta: molti risultati si possono verificare a mano su un caso (un cliente, un ordine). È l'abitudine che distingue chi "scrive query" da chi sa che sono giuste.
