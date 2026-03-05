# UF1886_E2 - Odoo Multi-Entorno (Windows + Docker Desktop)

## Requisitos
- Windows 10/11
- Docker Desktop instalado y en ejecuciÃ³n
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

> IMPORTANTE: No dejes espacios ni saltos de linea extra al escribir las contraseÃ±as.

### 2. Levantar entorno
Haz doble clic en el .bat o ejecuta desde cmd/PowerShell:

```
start-dev.bat    # Desarrollo  â†’ http://localhost:8069
start-qa.bat     # QA          â†’ http://localhost:8070
start-prod.bat   # Produccion  â†’ http://localhost:8071
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
| Limpiar (Â¡borra!)   | clean-dev.bat         | clean-qa.bat         | clean-prod.bat         |
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

- ContraseÃ±as en Docker Secrets (nunca en texto plano en compose)
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
guarda con LF o usa VS Code ("CRLF" â†’ "LF" en la barra inferior derecha).

---

## Estructura
```
UF1886_E2\
â”œâ”€â”€ docker-compose.dev.yml
â”œâ”€â”€ docker-compose.qa.yml
â”œâ”€â”€ docker-compose.prod.yml
â”œâ”€â”€ secrets\
â”‚   â”œâ”€â”€ dev\   (postgres_password, odoo_admin_password)
â”‚   â”œâ”€â”€ qa\
â”‚   â””â”€â”€ prod\
â”œâ”€â”€ config\
â”‚   â”œâ”€â”€ dev\odoo.conf
â”‚   â”œâ”€â”€ qa\odoo.conf
â”‚   â””â”€â”€ prod\odoo.conf
â”œâ”€â”€ addons\  (dev | qa | prod)
â”œâ”€â”€ hop\     (dev | qa | prod)
â”œâ”€â”€ backups\
â”œâ”€â”€ scripts\
â”‚   â””â”€â”€ entrypoint.sh  (bash, ejecutado dentro del contenedor Linux)
â””â”€â”€ *.bat  (scripts para cada entorno)
```
