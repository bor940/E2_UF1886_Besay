# =============================================================================
# setup_uf1886.ps1 - VERSIÓN WINDOWS (Docker Desktop) - DEV + QA + PROD
# =============================================================================
# Requisitos: Docker Desktop instalado y en ejecución
# Ejecución:  powershell -ExecutionPolicy Bypass -File setup_uf1886.ps1
#             powershell -ExecutionPolicy Bypass -File setup_uf1886.ps1 -BaseDir "C:\mis-proyectos"
# =============================================================================

param(
    [string]$BaseDir = ".\UF1886_E2"
)

$ErrorActionPreference = "Stop"

$BASE_DIR    = $BaseDir
$ENVS        = @("dev", "qa", "prod")
$PROJECT_PREFIX = "uf1886"

# ---------------------------------------------------------------------------
# Verificar Docker Desktop
# ---------------------------------------------------------------------------
try {
    docker info | Out-Null
} catch {
    Write-Error "Docker Desktop no está en ejecución. Inícialo e inténtalo de nuevo."
    exit 1
}

Write-Host "Creando proyecto en: $BASE_DIR"
Write-Host "--------------------------------------------"

# ---------------------------------------------------------------------------
# 1. Estructura de directorios
# ---------------------------------------------------------------------------
foreach ($env in $ENVS) {
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\secrets\$env"  | Out-Null
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\config\$env"   | Out-Null
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\addons\$env"   | Out-Null
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\backups\$env"  | Out-Null
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\scripts"       | Out-Null
    New-Item -ItemType Directory -Force -Path "$BASE_DIR\hop\$env"      | Out-Null
}
Write-Host "OK Directorios creados"

# ---------------------------------------------------------------------------
# 2. Archivos de secretos (vacíos, se rellenan al final)
# ---------------------------------------------------------------------------
foreach ($env in $ENVS) {
    $pgFile    = "$BASE_DIR\secrets\$env\postgres_password"
    $odooFile  = "$BASE_DIR\secrets\$env\odoo_admin_password"
    if (-not (Test-Path $pgFile))   { New-Item -ItemType File -Path $pgFile   | Out-Null }
    if (-not (Test-Path $odooFile)) { New-Item -ItemType File -Path $odooFile | Out-Null }
}
Write-Host "OK Archivos de secretos creados"

# ---------------------------------------------------------------------------
# 3. Docker Compose (DEV / QA / PROD)
# ---------------------------------------------------------------------------

# ── DEV ──────────────────────────────────────────────────────────────────────
@'
secrets:
  postgres_password:
    file: ./secrets/dev/postgres_password
  odoo_admin_password:
    file: ./secrets/dev/odoo_admin_password

services:
  odoo:
    image: odoo:18.0
    container_name: odoo-dev
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8069:8069"
    secrets:
      - postgres_password
      - odoo_admin_password
    volumes:
      - odoo-data-dev:/var/lib/odoo
      - ./config/dev/odoo.conf:/etc/odoo/odoo.conf:ro
      - ./addons/dev:/mnt/extra-addons:ro
      - ./scripts/entrypoint.sh:/entrypoint-custom.sh:ro
    entrypoint: ["/bin/bash", "/entrypoint-custom.sh"]
    networks:
      - odoo-net-dev

  postgres:
    image: postgres:16-alpine
    container_name: postgres-dev
    restart: unless-stopped
    environment:
      POSTGRES_DB: odoo_dev
      POSTGRES_USER: odoo_dev
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - postgres-data-dev:/var/lib/postgresql/data
    networks:
      - odoo-net-dev
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo_dev -d odoo_dev"]
      interval: 10s
      timeout: 5s
      retries: 5

  hop:
    image: apache/hop:latest
    container_name: hop-dev
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./hop/dev:/files
    networks:
      - odoo-net-dev

volumes:
  odoo-data-dev:
  postgres-data-dev:

networks:
  odoo-net-dev:
'@ | Set-Content -Encoding UTF8 "$BASE_DIR\docker-compose.dev.yml"

# ── QA ───────────────────────────────────────────────────────────────────────
@'
secrets:
  postgres_password:
    file: ./secrets/qa/postgres_password
  odoo_admin_password:
    file: ./secrets/qa/odoo_admin_password

services:
  odoo:
    image: odoo:18.0
    container_name: odoo-qa
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8070:8069"
    secrets:
      - postgres_password
      - odoo_admin_password
    volumes:
      - odoo-data-qa:/var/lib/odoo
      - ./config/qa/odoo.conf:/etc/odoo/odoo.conf:ro
      - ./addons/qa:/mnt/extra-addons:ro
      - ./scripts/entrypoint.sh:/entrypoint-custom.sh:ro
    entrypoint: ["/bin/bash", "/entrypoint-custom.sh"]
    networks:
      - odoo-net-qa

  postgres:
    image: postgres:16-alpine
    container_name: postgres-qa
    restart: unless-stopped
    environment:
      POSTGRES_DB: odoo_qa
      POSTGRES_USER: odoo_qa
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - postgres-data-qa:/var/lib/postgresql/data
    networks:
      - odoo-net-qa
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo_qa -d odoo_qa"]
      interval: 10s
      timeout: 5s
      retries: 5

  hop:
    image: apache/hop:latest
    container_name: hop-qa
    restart: unless-stopped
    ports:
      - "8081:8080"
    volumes:
      - ./hop/qa:/files
    networks:
      - odoo-net-qa

volumes:
  odoo-data-qa:
  postgres-data-qa:

networks:
  odoo-net-qa:
'@ | Set-Content -Encoding UTF8 "$BASE_DIR\docker-compose.qa.yml"

# ── PROD ─────────────────────────────────────────────────────────────────────
@'
secrets:
  postgres_password:
    file: ./secrets/prod/postgres_password
  odoo_admin_password:
    file: ./secrets/prod/odoo_admin_password

services:
  odoo:
    image: odoo:18.0
    container_name: odoo-prod
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8071:8069"
    secrets:
      - postgres_password
      - odoo_admin_password
    volumes:
      - odoo-data-prod:/var/lib/odoo
      - ./config/prod/odoo.conf:/etc/odoo/odoo.conf:ro
      - ./addons/prod:/mnt/extra-addons:ro
      - ./scripts/entrypoint.sh:/entrypoint-custom.sh:ro
    entrypoint: ["/bin/bash", "/entrypoint-custom.sh"]
    networks:
      - odoo-net-prod

  postgres:
    image: postgres:16-alpine
    container_name: postgres-prod
    restart: unless-stopped
    environment:
      POSTGRES_DB: odoo_prod
      POSTGRES_USER: odoo_prod
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - postgres-data-prod:/var/lib/postgresql/data
    networks:
      - odoo-net-prod
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo_prod -d odoo_prod"]
      interval: 10s
      timeout: 5s
      retries: 5

  hop:
    image: apache/hop:latest
    container_name: hop-prod
    restart: unless-stopped
    ports:
      - "8082:8080"
    volumes:
      - ./hop/prod:/files
    networks:
      - odoo-net-prod

volumes:
  odoo-data-prod:
  postgres-data-prod:

networks:
  odoo-net-prod:
'@ | Set-Content -Encoding UTF8 "$BASE_DIR\docker-compose.prod.yml"

Write-Host "OK Docker Compose creado (DEV/QA/PROD)"

# ---------------------------------------------------------------------------
# 4. odoo.conf por entorno
# ---------------------------------------------------------------------------
foreach ($env in $ENVS) {
    @"
[options]
db_host     = postgres
db_port     = 5432
db_name     = odoo_$env
db_user     = odoo_$env

admin_passwd = PLACEHOLDER_SECRET

http_port   = 8069
workers     = 0
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
log_level   = info
logfile     = False
list_db     = True
"@ | Set-Content -Encoding UTF8 "$BASE_DIR\config\$env\odoo.conf"
}
Write-Host "OK odoo.conf creado para DEV/QA/PROD"

# ---------------------------------------------------------------------------
# 5. Entrypoint personalizado (bash, se ejecuta dentro del contenedor Linux)
# ---------------------------------------------------------------------------
@'
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
'@ | Set-Content -Encoding UTF8 -NoNewline "$BASE_DIR\scripts\entrypoint.sh"

# Convertir a saltos de línea Unix (LF) para que funcione dentro del contenedor Linux
$content = [System.IO.File]::ReadAllText("$BASE_DIR\scripts\entrypoint.sh") -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText("$BASE_DIR\scripts\entrypoint.sh", $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "OK Entrypoint creado (line endings Unix LF)"

# ---------------------------------------------------------------------------
# 6. .gitignore
# ---------------------------------------------------------------------------
@'
secrets/
backups/
*.log
__pycache__/
*.pyc
.DS_Store
Thumbs.db
'@ | Set-Content -Encoding UTF8 "$BASE_DIR\.gitignore"
Write-Host "OK .gitignore creado"

# ---------------------------------------------------------------------------
# 7. Scripts helper (.bat) para Windows
# ---------------------------------------------------------------------------

# ── Función interna para generar .bat ────────────────────────────────────────
function New-ComposeScript {
    param($Path, $Content)
    $Content | Set-Content -Encoding UTF8 $Path
}

# DEV
New-ComposeScript "$BASE_DIR\start-dev.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml up -d
echo.
echo [OK] Odoo DEV iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-dev.bat
echo   Acceder  : http://localhost:8069
"@

New-ComposeScript "$BASE_DIR\stop-dev.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml down
echo [OK] Odoo DEV detenido
"@

New-ComposeScript "$BASE_DIR\logs-dev.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml logs -f
"@

New-ComposeScript "$BASE_DIR\restart-dev.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml restart
echo [OK] Odoo DEV reiniciado
"@

New-ComposeScript "$BASE_DIR\clean-dev.bat" @"
@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de DEV
set /p CONFIRM=^¿Estas seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml down -v
    echo [OK] Limpieza completa de DEV realizada
)
"@

# QA
New-ComposeScript "$BASE_DIR\start-qa.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml up -d
echo.
echo [OK] Odoo QA iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-qa.bat
echo   Acceder  : http://localhost:8070
"@

New-ComposeScript "$BASE_DIR\stop-qa.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml down
echo [OK] Odoo QA detenido
"@

New-ComposeScript "$BASE_DIR\logs-qa.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml logs -f
"@

New-ComposeScript "$BASE_DIR\restart-qa.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml restart
echo [OK] Odoo QA reiniciado
"@

New-ComposeScript "$BASE_DIR\clean-qa.bat" @"
@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de QA
set /p CONFIRM=^¿Estas seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml down -v
    echo [OK] Limpieza completa de QA realizada
)
"@

# PROD
New-ComposeScript "$BASE_DIR\start-prod.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml up -d
echo.
echo [OK] Odoo PROD iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-prod.bat
echo   Acceder  : http://localhost:8071
"@

New-ComposeScript "$BASE_DIR\stop-prod.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml down
echo [OK] Odoo PROD detenido
"@

New-ComposeScript "$BASE_DIR\logs-prod.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml logs -f
"@

New-ComposeScript "$BASE_DIR\restart-prod.bat" @"
@echo off
cd /d "%~dp0"
docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml restart
echo [OK] Odoo PROD reiniciado
"@

New-ComposeScript "$BASE_DIR\clean-prod.bat" @"
@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de PROD
set /p CONFIRM=^¿Estas COMPLETAMENTE seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml down -v
    echo [OK] Limpieza completa de PROD realizada
)
"@

# Shells (abren nueva ventana de cmd dentro del contenedor)
New-ComposeScript "$BASE_DIR\shell-odoo-dev.bat"      "@echo off`r`ndocker exec -it odoo-dev /bin/bash"
New-ComposeScript "$BASE_DIR\shell-odoo-qa.bat"       "@echo off`r`ndocker exec -it odoo-qa /bin/bash"
New-ComposeScript "$BASE_DIR\shell-odoo-prod.bat"     "@echo off`r`ndocker exec -it odoo-prod /bin/bash"
New-ComposeScript "$BASE_DIR\shell-postgres-dev.bat"  "@echo off`r`ndocker exec -it postgres-dev psql -U odoo_dev -d odoo_dev"
New-ComposeScript "$BASE_DIR\shell-postgres-qa.bat"   "@echo off`r`ndocker exec -it postgres-qa psql -U odoo_qa -d odoo_qa"
New-ComposeScript "$BASE_DIR\shell-postgres-prod.bat" "@echo off`r`ndocker exec -it postgres-prod psql -U odoo_prod -d odoo_prod"
New-ComposeScript "$BASE_DIR\shell-hop-dev.bat"       "@echo off`r`ndocker exec -it hop-dev /bin/bash"
New-ComposeScript "$BASE_DIR\shell-hop-qa.bat"        "@echo off`r`ndocker exec -it hop-qa /bin/bash"
New-ComposeScript "$BASE_DIR\shell-hop-prod.bat"      "@echo off`r`ndocker exec -it hop-prod /bin/bash"

# Status general
New-ComposeScript "$BASE_DIR\status.bat" @"
@echo off
cd /d "%~dp0"
echo =======================================
echo  Estado de TODOS los entornos
echo =======================================
echo.
echo DEV:
docker compose -p $PROJECT_PREFIX-dev -f docker-compose.dev.yml ps 2>nul || echo   No iniciado
echo.
echo QA:
docker compose -p $PROJECT_PREFIX-qa -f docker-compose.qa.yml ps 2>nul || echo   No iniciado
echo.
echo PROD:
docker compose -p $PROJECT_PREFIX-prod -f docker-compose.prod.yml ps 2>nul || echo   No iniciado
"@

Write-Host "OK Scripts .bat creados para DEV, QA y PROD"

# ---------------------------------------------------------------------------
# 8. README actualizado para Windows
# ---------------------------------------------------------------------------
@'
# UF1886_E2 - Odoo Multi-Entorno (Windows + Docker Desktop)

## Requisitos
- Windows 10/11
- Docker Desktop instalado y en ejecución
- PowerShell 5+ (incluido en Windows)

## Inicio Rapido

### 1. Configurar secretos
Abre PowerShell en la carpeta UF1886_E2 y ejecuta:

```powershell
# DEV
"TU_PASSWORD_POSTGRES" | Set-Content secrets\dev\postgres_password
"TU_PASSWORD_ADMIN"    | Set-Content secrets\dev\odoo_admin_password

# QA
"TU_PASSWORD_POSTGRES" | Set-Content secrets\qa\postgres_password
"TU_PASSWORD_ADMIN"    | Set-Content secrets\qa\odoo_admin_password

# PROD
"TU_PASSWORD_POSTGRES" | Set-Content secrets\prod\postgres_password
"TU_PASSWORD_ADMIN"    | Set-Content secrets\prod\odoo_admin_password
```

> IMPORTANTE: No dejes espacios ni saltos de linea extra al escribir las contraseñas.

### 2. Levantar entorno
Haz doble clic en el .bat o ejecuta desde cmd/PowerShell:

```
start-dev.bat    # Desarrollo  → http://localhost:8069
start-qa.bat     # QA          → http://localhost:8070
start-prod.bat   # Produccion  → http://localhost:8071
```

La primera vez tarda 1-2 minutos en inicializar la base de datos.

### 3. Apache Hop Web UI
- DEV:  http://localhost:8080
- QA:   http://localhost:8081
- PROD: http://localhost:8082

---

## Comandos disponibles (.bat)

| Accion              | DEV                   | QA                   | PROD                   |
|---------------------|-----------------------|----------------------|------------------------|
| Iniciar             | start-dev.bat         | start-qa.bat         | start-prod.bat         |
| Parar               | stop-dev.bat          | stop-qa.bat          | stop-prod.bat          |
| Ver logs            | logs-dev.bat          | logs-qa.bat          | logs-prod.bat          |
| Reiniciar           | restart-dev.bat       | restart-qa.bat       | restart-prod.bat       |
| Limpiar (¡borra!)   | clean-dev.bat         | clean-qa.bat         | clean-prod.bat         |
| Shell Odoo          | shell-odoo-dev.bat    | shell-odoo-qa.bat    | shell-odoo-prod.bat    |
| Shell PostgreSQL    | shell-postgres-dev.bat| shell-postgres-qa.bat| shell-postgres-prod.bat|
| Shell Hop           | shell-hop-dev.bat     | shell-hop-qa.bat     | shell-hop-prod.bat     |
| Estado general      | status.bat            |                      |                        |

---

## Seguridad

| Entorno | Puerto Odoo | PostgreSQL  | BD desde host     |
|---------|-------------|-------------|-------------------|
| DEV     | 8069        | No expuesto | Solo via Docker   |
| QA      | 8070        | No expuesto | Solo via Docker   |
| PROD    | 8071        | No expuesto | Solo via Docker   |

- Contraseñas en Docker Secrets (nunca en texto plano en compose)
- PostgreSQL aislado en red interna Docker
- secrets/ excluido de Git

---

## Troubleshooting

### Contenedor en bucle de reinicios
```
logs-dev.bat
```

### Limpiar y empezar de nuevo
```
clean-dev.bat
start-dev.bat
```

### Entrypoint con error de saltos de linea (CRLF)
El script `scripts/entrypoint.sh` debe tener saltos de linea Unix (LF).
El setup ya lo genera correctamente. Si lo editas manualmente en Notepad,
guarda con LF o usa VS Code ("CRLF" → "LF" en la barra inferior derecha).

---

## Estructura
```
UF1886_E2\
├── docker-compose.dev.yml
├── docker-compose.qa.yml
├── docker-compose.prod.yml
├── secrets\
│   ├── dev\   (postgres_password, odoo_admin_password)
│   ├── qa\
│   └── prod\
├── config\
│   ├── dev\odoo.conf
│   ├── qa\odoo.conf
│   └── prod\odoo.conf
├── addons\  (dev | qa | prod)
├── hop\     (dev | qa | prod)
├── backups\
├── scripts\
│   └── entrypoint.sh  (bash, ejecutado dentro del contenedor Linux)
└── *.bat  (scripts para cada entorno)
```
'@ | Set-Content -Encoding UTF8 "$BASE_DIR\README.md"
Write-Host "OK README creado"

# ---------------------------------------------------------------------------
# 9. Pedir contraseñas interactivamente
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--------------------------------------------"
Write-Host "Configuracion de contrasenas"
Write-Host "--------------------------------------------"

foreach ($env in $ENVS) {
    Write-Host ""
    Write-Host "Entorno: $($env.ToUpper())"

    do {
        $pg_pass = Read-Host "  postgres_password" -AsSecureString
        $pg_plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pg_pass))
    } while ([string]::IsNullOrEmpty($pg_plain))
    # Escribir sin BOM y sin newline final
    [System.IO.File]::WriteAllText(
        (Resolve-Path "$BASE_DIR\secrets\$env\postgres_password"),
        $pg_plain,
        [System.Text.UTF8Encoding]::new($false)
    )

    do {
        $odoo_pass = Read-Host "  odoo_admin_password" -AsSecureString
        $odoo_plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                         [Runtime.InteropServices.Marshal]::SecureStringToBSTR($odoo_pass))
    } while ([string]::IsNullOrEmpty($odoo_plain))
    [System.IO.File]::WriteAllText(
        (Resolve-Path "$BASE_DIR\secrets\$env\odoo_admin_password"),
        $odoo_plain,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host "  OK Configurados"
}

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================"
Write-Host "OK Proyecto creado: $BASE_DIR"
Write-Host ""
Write-Host "Entornos disponibles:"
Write-Host "  DEV:  start-dev.bat  -> Odoo: http://localhost:8069 | Hop: http://localhost:8080"
Write-Host "  QA:   start-qa.bat   -> Odoo: http://localhost:8070 | Hop: http://localhost:8081"
Write-Host "  PROD: start-prod.bat -> Odoo: http://localhost:8071 | Hop: http://localhost:8082"
Write-Host ""
Write-Host "NOTA: La primera vez cada entorno tardara 1-2 minutos"
Write-Host "      en inicializar su BD."
Write-Host ""
Write-Host "Ver estado de todos:"
Write-Host "  status.bat"
Write-Host "============================================"