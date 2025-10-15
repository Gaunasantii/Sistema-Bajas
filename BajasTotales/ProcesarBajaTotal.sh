vi#!/bin/bash
set -euo pipefail

# ----------------- Configuración de la base -----------------
DB_HOST="localhost"
DB_USER="root"
DB_PASS="Root.123"     # poné la contraseña si corresponde
DB_NAME="Sistema"
# ------------------------------------------------------------

# Chequear argumento
if [ $# -lt 1 ]; then
  echo "Uso: $0 archivo.csv"
  exit 1
fi

CSV_FILE="$1"

# Archivos temporales
TMP_CSV="/tmp/usuarios_BajaTotal_filtered.csv"
TMP_SQL="/tmp/usuarios_BajaTotal_inserts.sql"

if [ ! -f "$CSV_FILE" ]; then
  echo "ERROR: no existe el CSV: $CSV_FILE" >&2
  exit 1
fi

echo "1) Filtrando CSV (solo 'servicio eliminado')..."
python3 - <<'PY' "$CSV_FILE" "$TMP_CSV"
import csv,sys
infile=sys.argv[1]; outfile=sys.argv[2]

def norm(s):
    return ''.join(ch.lower() for ch in s if ch.isalnum() or ch.isspace()).strip()

with open(infile, newline='', encoding='latin1') as inf:
    sample = inf.read(8192)
    inf.seek(0)
    try:
        dialect = csv.Sniffer().sniff(sample)
    except Exception:
        dialect = csv.get_dialect('excel')
    reader = csv.DictReader(inf, dialect=dialect)
    headers = reader.fieldnames or []

    # detección de columnas
    def score_login(nk): return ('login' in nk)*10 + ('user' in nk)*2
    def score_apellido(nk): return ('apellido' in nk)*10 + ('nombre' in nk)*3
    def score_estado(nk): return ('estado' in nk)*10 + ('status' in nk)*8

    best_login = max(headers, key=lambda h: score_login(norm(h)))
    best_apellido = max(headers, key=lambda h: score_apellido(norm(h)))
    best_estado = max(headers, key=lambda h: score_estado(norm(h)))

    with open(outfile, 'w', newline='', encoding='utf-8') as outf:
        w = csv.writer(outf)
        w.writerow(['Login','Apellido_Nombres'])
        for row in reader:
            if (row.get(best_estado) or '').strip().lower() in ('servicio eliminado', 'solicitud resuelta'):
              w.writerow([row.get(best_login, ''), row.get(best_apellido, '')])

PY

echo "2) Creando/vaciando tabla..."
mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" "$DB_NAME" -e "
CREATE TABLE IF NOT EXISTS usuarios_BajaTotal (
  Login VARCHAR(255),
  Apellido_Nombres VARCHAR(255)
);
TRUNCATE TABLE usuarios_BajaTotal;
"

echo "3) Cargando datos..."
mysql --local-infile=1 -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" "$DB_NAME" -e "
LOAD DATA LOCAL INFILE '$TMP_CSV'
INTO TABLE usuarios_BajaTotal
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Login, Apellido_Nombres);
"

rm -f "$TMP_CSV" "$TMP_SQL"
echo "Listo ✅"
