@echo off
cd /d "%~dp0"
docker compose -p uf1886-dev -f docker-compose.dev.yml up -d
echo.
echo [OK] Odoo DEV iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-dev.bat
echo   Acceder  : http://localhost:8069
