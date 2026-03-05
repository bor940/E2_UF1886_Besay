@echo off
cd /d "%~dp0"
docker compose -p uf1886-prod -f docker-compose.prod.yml up -d
echo.
echo [OK] Odoo PROD iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-prod.bat
echo   Acceder  : http://localhost:8071
