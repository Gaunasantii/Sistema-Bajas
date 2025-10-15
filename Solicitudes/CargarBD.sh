#!/bin/bash

# --- Validar argumento ---
if [ -z "$1" ]; then
  echo "Uso: $0 archivo.csv"
  exit 1
fi

CSV="$1"

# Configuración de conexión
USER="root"
PASS="Root.123"
DB="Sistema"
TABLE="solicitudes"

# Crear base de datos si no existe
mysql -u $USER -p$PASS -e "CREATE DATABASE IF NOT EXISTS $DB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# Eliminar la tabla si ya existe
mysql -u $USER -p$PASS -D $DB -e "DROP TABLE IF EXISTS $TABLE;"

# Crear tabla
mysql -u $USER -p$PASS -D $DB -e "
CREATE TABLE $TABLE (
    Nro INT,
    \`Último Movimiento\` DATE,
    Operación VARCHAR(255),
    Solicitud VARCHAR(255),
    \`Secretaría\` VARCHAR(255),
    Dependencia VARCHAR(255),
    Estado VARCHAR(255),
    \`Apellido y Nombres\` VARCHAR(255),
    Login VARCHAR(255),
    Cil VARCHAR(255),
    Oficina VARCHAR(255),
    Servicio VARCHAR(255),
    Sistema VARCHAR(255),
    \`Tipo Sistema\` VARCHAR(255),
    \`Tipo Soporte\` VARCHAR(255),
    \`Subtipo soporte\` VARCHAR(255),
    \`Descripción\` TEXT,
    \`Registrado por\` VARCHAR(255),
    \`Fecha Inicio\` DATE,
    \`Fecha Fin\` DATE,
    \`Tomado por\` VARCHAR(255),
    \`Autorizado el\` DATE,
    \`Creado el\` DATE,
    \`Diferencia (días)\` INT,
    \`Retornos (días)\` INT,
    \`A ser resuelto por Rol\` VARCHAR(255),
    \`Asignado a\` VARCHAR(255)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
"

# Importar datos
mysql --local-infile=1 -u $USER -p$PASS -D $DB -e "
LOAD DATA LOCAL INFILE '$CSV'
INTO TABLE $TABLE
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    Nro,
    @UltimoMovimiento,
    Operación,
    Solicitud,
    \`Secretaría\`,
    Dependencia,
    Estado,
    \`Apellido y Nombres\`,
    Login,
    Cil,
    Oficina,
    Servicio,
    Sistema,
    \`Tipo Sistema\`,
    \`Tipo Soporte\`,
    \`Subtipo soporte\`,
    \`Descripción\`,
    \`Registrado por\`,
    @FechaInicio,
    @FechaFin,
    \`Tomado por\`,
    @AutorizadoEl,
    @CreadoEl,
    \`Diferencia (días)\`,
    \`Retornos (días)\`,
    \`A ser resuelto por Rol\`,
    \`Asignado a\`
)
SET
    \`Último Movimiento\` = STR_TO_DATE(@UltimoMovimiento, '%d/%m/%Y'),
    \`Fecha Inicio\` = STR_TO_DATE(@FechaInicio, '%d/%m/%Y'),
    \`Fecha Fin\` = STR_TO_DATE(@FechaFin, '%d/%m/%Y'),
    \`Autorizado el\` = STR_TO_DATE(@AutorizadoEl, '%d/%m/%Y'),
    \`Creado el\` = STR_TO_DATE(@CreadoEl, '%d/%m/%Y');
"

# Crear vistas de análisis
mysql -u $USER -p$PASS -D $DB -e "
CREATE OR REPLACE VIEW usuarios_estado AS
SELECT
    s.Login,
    MAX(s.\`Fecha Fin\`) AS ultima_fecha,
    SUBSTRING_INDEX(
        GROUP_CONCAT(s.Estado ORDER BY s.\`Fecha Fin\` DESC SEPARATOR '|'),
        '|',
        1
    ) AS estado_mas_reciente,
    CASE
        WHEN LOWER(SUBSTRING_INDEX(
            GROUP_CONCAT(s.Estado ORDER BY s.\`Fecha Fin\` DESC SEPARATOR '|'),
            '|',
            1
        )) IN ('servicio eliminado', 'solicitud resuelta')
        THEN 1 ELSE 0
    END AS baja_por_estado
FROM $TABLE s
GROUP BY s.Login;
"

mysql -u $USER -p$PASS -D $DB -e "
CREATE OR REPLACE VIEW usuarios_baja_final AS
SELECT
    ue.Login,
    ue.ultima_fecha,
    ue.estado_mas_reciente,
    CASE
        WHEN ue.baja_por_estado = 1
             OR ubt.Login IS NOT NULL
             OR ubm.Login IS NOT NULL
        THEN 1 ELSE 0
    END AS baja_final
FROM usuarios_estado ue
LEFT JOIN usuarios_BajaTotal ubt
    ON ue.Login COLLATE utf8mb4_general_ci = ubt.Login COLLATE utf8mb4_general_ci
LEFT JOIN usuarios_BajaTotal_Manual ubm
    ON ue.Login COLLATE utf8mb4_general_ci = ubm.Login COLLATE utf8mb4_general_ci

"
