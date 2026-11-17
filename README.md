# Corsi di programmazione

Una raccolta di corsi pratici, in italiano, pensati per chi parte da zero.
Ogni corso sta in una cartella a sé. Le lezioni sono file eseguibili e commentati riga per riga, con esercizi in fondo a ogni lezione.

## I corsi

| Corso | Cartella | Contenuto | Requisiti |
|-------|----------|-----------|-----------|
| **Java da zero** | [`java/`](java/README.md) | 15 lezioni: dalle variabili alla programmazione a oggetti (classi, ereditarietà, interfacce, polimorfismo), eccezioni, collezioni e un progetto finale | Java 17+ |
| **SQL pratico** | [`sql/`](sql/README.md) | 12 lezioni su un database di esempio: SELECT, GROUP BY, JOIN e le loro trappole, subquery, window function, transazioni, progettazione, con esercizi e soluzioni | SQLite 3.39+ |

Ordine consigliato per chi inizia: prima **Java**, poi **SQL**. I due corsi sono comunque indipendenti.

## Scaricare il materiale

Chi non usa git può scaricare tutto da **Code → Download ZIP**. Con git:

```bash
git clone https://github.com/Gundam97/corsi-programmazione.git
```

Per ricevere gli aggiornamenti, dalla cartella della repo:

```bash
git pull
```

## Struttura

```
corsi-programmazione/
├── README.md          <- questo indice
├── java/              <- corso Java
│   ├── README.md
│   ├── esegui.sh
│   └── src/
└── sql/               <- corso SQL
    ├── README.md
    ├── esegui.sh
    ├── database/
    ├── lezioni/
    └── soluzioni/
```

Ogni nuovo corso va in una nuova cartella con il suo `README.md`, e si aggiunge una riga alla tabella qui sopra.
