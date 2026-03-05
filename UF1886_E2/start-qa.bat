@echo off
cd /d "%~dp0"
docker compose -p uf1886-qa -f docker-compose.qa.yml up -d
echo.
echo [OK] Odoo QA iniciando...
echo   La primera vez puede tardar 1-2 minutos en inicializar la BD
echo.
echo   Ver logs : logs-qa.bat
echo   Acceder  : http://localhost:8070
