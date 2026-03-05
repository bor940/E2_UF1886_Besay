#!/bin/bash
set -e

echo "=== Entrypoint Personalizado - Odoo ==="

# Inyectar admin_passwd desde Docker Secret
if [ -f /run/secrets/odoo_admin_password ]; then
    ADMIN_PASS=$(cat /run/secrets/odoo_admin_password)
    echo "OK Admin password cargada (${#ADMIN_PASS} caracteres)"
    sed "s/PLACEHOLDER_SECRET/${ADMIN_PASS}/" /etc/odoo/odoo.conf > /tmp/odoo.conf
else
    echo "AVISO: No se encontro admin password"
    cp /etc/odoo/odoo.conf /tmp/odoo.conf
fi

# Leer password de PostgreSQL
if [ -f /run/secrets/postgres_password ]; then
    DB_PASSWORD=$(cat /run/secrets/postgres_password)
    echo "OK DB password cargada (${#DB_PASSWORD} caracteres)"
else
    echo "ERROR: No se encontro postgres password"
    exit 1
fi

# Leer configuracion de odoo.conf
DB_HOST=$(grep "^db_host" /etc/odoo/odoo.conf | awk '{print $3}' | tr -d ' ')
DB_PORT=$(grep "^db_port" /etc/odoo/odoo.conf | awk '{print $3}' | tr -d ' ')
DB_NAME=$(grep "^db_name" /etc/odoo/odoo.conf | awk '{print $3}' | tr -d ' ')
DB_USER=$(grep "^db_user" /etc/odoo/odoo.conf | awk '{print $3}' | tr -d ' ')

echo "Configuracion detectada:"
echo "  Host: $DB_HOST"
echo "  Puerto: $DB_PORT"
echo "  Base de datos: $DB_NAME"
echo "  Usuario: $DB_USER"

# Esperar a que PostgreSQL este listo
echo "=== Esperando PostgreSQL ==="
MAX_TRIES=30
TRIES=0
until PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo "ERROR: PostgreSQL no responde despues de $MAX_TRIES intentos"
        exit 1
    fi
    echo "PostgreSQL no disponible, esperando... ($TRIES/$MAX_TRIES)"
    sleep 2
done
echo "OK PostgreSQL listo"

# Verificar si la BD necesita inicializacion
echo "=== Verificando estado de la BD ==="
TABLE_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tr -d ' ')

if [ "$TABLE_COUNT" = "0" ] || [ -z "$TABLE_COUNT" ]; then
    echo "AVISO: Base de datos vacia, inicializando con modulo base..."
    echo "   Esto puede tardar 1-2 minutos..."

    odoo \
        --config=/tmp/odoo.conf \
        --db_password="${DB_PASSWORD}" \
        -i base \
        --stop-after-init \
        --without-demo=all \
        --load-language=es_ES

    echo "OK Base de datos inicializada"

    echo "=== Actualizando contrasena del usuario admin ==="
    ADMIN_PASS_ESCAPED=$(printf '%s' "${ADMIN_PASS}" | sed "s/'/''/g")

    PGPASSWORD="${DB_PASSWORD}" psql \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -c "UPDATE res_users SET password = '${ADMIN_PASS_ESCAPED}' WHERE login = 'admin';"

    echo "OK Contrasena del usuario admin actualizada"
else
    echo "OK Base de datos ya inicializada ($TABLE_COUNT tablas)"
fi

# Iniciar Odoo
echo "=== Iniciando Odoo ==="
exec odoo \
    --config=/tmp/odoo.conf \
    --db_password="${DB_PASSWORD}"