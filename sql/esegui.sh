#!/usr/bin/env bash
# ------------------------------------------------------------------
#  Sezione SQL del corso - script di supporto (richiede sqlite3)
#
#  Uso:
#     ./esegui.sh               -> mostra l'elenco delle lezioni
#     ./esegui.sh crea          -> (ri)crea il database corso.db da zero
#     ./esegui.sh 5             -> ricrea il database ed esegue la lezione 5
#     ./esegui.sh soluzioni 5   -> ricrea il database ed esegue le soluzioni della lezione 5
#     ./esegui.sh shell         -> apre sqlite3 sul database per scrivere query a mano
#     ./esegui.sh tutte         -> esegue tutte le lezioni (utile per verificare)
# ------------------------------------------------------------------
set -e
cd "$(dirname "$0")"

DB="corso.db"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 non trovato. Vedi il README della sezione SQL per installarlo."
  exit 1
fi

crea_db() {
  rm -f "$DB"
  sqlite3 "$DB" < database/01_schema.sql
  sqlite3 "$DB" < database/02_dati.sql
}

trova() { # $1 = cartella, $2 = numero lezione
  local n
  n=$(printf "%02d" "$((10#$2))")
  ls "$1"/"$n"_*.sql 2>/dev/null | head -1
}

esegui_file() {
  echo "=================================================================="
  echo " >> $1"
  echo "=================================================================="
  # -bail: si ferma al primo errore. I vincoli di chiave esterna vanno attivati a ogni connessione.
  { echo "PRAGMA foreign_keys = ON;"; cat "$1"; } | sqlite3 -box -bail -nullvalue NULL "$DB"
  echo
}

case "$1" in
  "")
    echo "Uso: ./esegui.sh crea | <numero> | soluzioni <numero> | shell | tutte"
    echo
    for f in lezioni/*.sql; do echo "  $(basename "$f" .sql)"; done
    ;;
  crea)
    crea_db
    echo "Database $DB creato."
    ;;
  shell)
    [ -f "$DB" ] || crea_db
    echo "Scrivi una query terminata da ; e premi Invio. .tables elenca le tabelle, .quit per uscire."
    sqlite3 -box -nullvalue NULL -cmd "PRAGMA foreign_keys = ON;" "$DB"
    ;;
  tutte)
    for f in lezioni/*.sql soluzioni/*.sql; do
      crea_db
      esegui_file "$f"
    done
    ;;
  soluzioni)
    f=$(trova soluzioni "$2")
    [ -n "$f" ] || { echo "Soluzioni della lezione '$2' non trovate."; exit 1; }
    crea_db
    esegui_file "$f"
    ;;
  *)
    f=$(trova lezioni "$1")
    [ -n "$f" ] || { echo "Lezione '$1' non trovata."; exit 1; }
    crea_db
    esegui_file "$f"
    ;;
esac
