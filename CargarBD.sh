#!/bin/bash
set -euo pipefail

DB="sistema"
USER="root"
PASS="Root.123" #PONER CONTRASEÑA DE BD ACÁ
HOST="localhost"

LISTADO_FILE="Listado.csv"
OUT_USUARIOS="usuarios.csv"
OUT_DEPENDENCIAS="dependencias.csv"
OUT_SOLICITUDES="solicitudes.csv"

# ============================
# 1) Preguntar sistema
# ============================
read -p "Ingrese el nombre del sistema a cargar: " SISTEMA_MANUAL

# ============================
# 2) Procesar Listado.csv con Python
# ============================
python3 - <<PY
import csv, unicodedata
from datetime import datetime

in_file = "$LISTADO_FILE"
out_users = "$OUT_USUARIOS"
out_deps  = "$OUT_DEPENDENCIAS"
out_solic = "$OUT_SOLICITUDES"
SISTEMA_MANUAL = "$SISTEMA_MANUAL"

def read_rows(file):
    with open(file, newline="", encoding="latin-1", errors="replace") as f:
        return list(csv.DictReader(f))

rows = read_rows(in_file)
if not rows:
    raise SystemExit("❌ Listado.csv no tiene filas")

# Normalización de encabezados
def nrm(s: str) -> str:
    import unicodedata
    if not s: return ""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return s.strip().lower()

headers = {nrm(h): h for h in rows[0].keys() if h}

ALIASES = {
    "login": ["login","usuario","user"],
    "nombApe": ["apellido y nombres","apellido y nombre","nombre y apellido","nombre completo","nombre"],
    "dependencia": ["dependencia"],
    "secretaria": ["secretaria","secretaría"],
    "cil": ["cil"],
    "nro": ["nro","numero","número","id solicitud"],
    "operacion": ["operacion","operación","op"],
    "estado": ["estado"],
    "fecha": ["fecha fin","ultimo movimiento","último movimiento","creado el","fecha inicio"]
}

def pick(key):
    for alias in ALIASES[key]:
        if nrm(alias) in headers:
            return headers[nrm(alias)]
    return None

h_login = pick("login")
h_nom   = pick("nombApe")
h_dep   = pick("dependencia")
h_sec   = pick("secretaria")
h_cil   = pick("cil")
h_nro   = pick("nro")
h_op    = pick("operacion")
h_est   = pick("estado")
h_fecha = pick("fecha")

# Tomamos como fecha principal "Fecha Fin" o en su defecto "Último Movimiento"
h_fecha = headers.get("fecha fin") or headers.get("último movimiento") or headers.get("ultimo movimiento")

def norm_date(s):
    s = (s or "").strip()
    if not s:
        return ""
    for fmt in ("%d/%m/%Y","%Y-%m-%d","%d-%m-%Y","%Y/%m/%d"):
        try: return datetime.strptime(s, fmt).strftime("%Y-%m-%d")
        except: pass
    try:
        return datetime.fromisoformat(s).strftime("%Y-%m-%d")
    except:
        return ""

# Dependencias
dep_index = {}
dep_seq = 1
usuarios = {}
solicitudes = {}

for row in rows:
    login = (row.get(h_login,"") if h_login else "").strip()
    nomb  = (row.get(h_nom,"")   if h_nom   else "").strip()
    dep   = (row.get(h_dep,"")   if h_dep   else "").strip()
    sec   = (row.get(h_sec,"")   if h_sec   else "").strip()
    cil   = (row.get(h_cil,"")   if h_cil   else "").strip()
    nro   = (row.get(h_nro,"")   if h_nro   else "").strip()
    op    = (row.get(h_op,"")    if h_op    else "").strip()
    est   = (row.get(h_est,"")   if h_est   else "").strip()
    fecha = norm_date(row.get(h_fecha,"")) if h_fecha else ""

    # Dependencias
    id_dep = None
    if dep:
        if dep not in dep_index:
            dep_index[dep] = (dep_seq, dep, sec, cil)
            dep_seq += 1
        id_dep = dep_index[dep][0]

    # Usuarios
    if login:
        usuarios[login] = (login, nomb, id_dep)

    # Solicitudes (con sistema manual)
    if login:
        key = (login, SISTEMA_MANUAL)
        prev = solicitudes.get(key)
        if prev:
            prev_fecha = prev[4] or ""
            if fecha > prev_fecha:
                solicitudes[key] = (nro, SISTEMA_MANUAL, op, est, fecha, login)
        else:
            solicitudes[key] = (nro, SISTEMA_MANUAL, op, est, fecha, login)

# Guardar CSVs
with open(out_deps,"w",newline="",encoding="utf-8") as f:
    w=csv.writer(f); w.writerow(["id","dependencia","secretaria","cil"])
    for d in dep_index.values(): w.writerow(d)

with open(out_users,"w",newline="",encoding="utf-8") as f:
    w=csv.writer(f); w.writerow(["login","nombApe","id_dependencia"])
    for u in usuarios.values(): w.writerow(u)

with open(out_solic,"w",newline="",encoding="utf-8") as f:
    w=csv.writer(f); w.writerow(["nro","nombSistema","operacion","estado","fecha","login"])
    for s in solicitudes.values(): w.writerow(s)

print("✅ Archivos generados:", out_users, out_deps, out_solic)
print("📦 Filas Listado:", len(rows))
print("🧾 Solicitudes generadas:", len(solicitudes))
PY

# ============================
# 3) Crear BD y tablas
# ============================
mysql -u"$USER" -p"$PASS" -h"$HOST" <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB\`;
USE \`$DB\`;

CREATE TABLE IF NOT EXISTS dependencias (
  id INT PRIMARY KEY,
  dependencia VARCHAR(200),
  secretaria VARCHAR(200),
  cil VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  login VARCHAR(100) NOT NULL UNIQUE,
  nombApe VARCHAR(200),
  id_dependencia INT,
  FOREIGN KEY (id_dependencia) REFERENCES dependencias(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS solicitud (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nro INT,
  nombSistema VARCHAR(200),
  operacion   VARCHAR(200),
  estado      VARCHAR(100),
  fecha DATE,
  login VARCHAR(100),
  UNIQUE KEY unq_login_sistema (login, nombSistema)
);
EOF

# ============================
# 4) Cargar datos
# ============================
# Dependencias
mysql --local-infile=1 -u"$USER" -p"$PASS" -h"$HOST" "$DB" <<EOF
LOAD DATA LOCAL INFILE '$OUT_DEPENDENCIAS'
REPLACE INTO TABLE dependencias
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, dependencia, secretaria, cil);
EOF

# Usuarios
mysql --local-infile=1 -u"$USER" -p"$PASS" -h"$HOST" "$DB" <<EOF
LOAD DATA LOCAL INFILE '$OUT_USUARIOS'
REPLACE INTO TABLE usuarios
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(login, nombApe, id_dependencia);
EOF

# Solicitudes
mysql --local-infile=1 -u"$USER" -p"$PASS" -h"$HOST" "$DB" <<EOF
CREATE TEMPORARY TABLE tmp_solicitud LIKE solicitud;

LOAD DATA LOCAL INFILE '$OUT_SOLICITUDES'
INTO TABLE tmp_solicitud
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(nro, nombSistema, operacion, estado, @fecha, login)
SET fecha = NULLIF(@fecha,'');


INSERT INTO solicitud (nro, nombSistema, operacion, estado, fecha, login)
SELECT nro, nombSistema, operacion, estado, fecha, login FROM tmp_solicitud
ON DUPLICATE KEY UPDATE
  operacion = IF(VALUES(fecha) > solicitud.fecha, VALUES(operacion), solicitud.operacion),
  estado    = IF(VALUES(fecha) > solicitud.fecha, VALUES(estado), solicitud.estado),
  fecha     = GREATEST(solicitud.fecha, VALUES(fecha));
EOF

echo "🎉 Proceso completo: Listado.csv dividido y cargado en MySQL."
