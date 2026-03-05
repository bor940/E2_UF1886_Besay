@echo off
cd /d "%~dp0"
echo =======================================
echo  Estado de TODOS los entornos
echo =======================================
echo.
echo DEV:
docker compose -p uf1886-dev -f docker-compose.dev.yml ps 2>nul || echo   No iniciado
echo.
echo QA:
docker compose -p uf1886-qa -f docker-compose.qa.yml ps 2>nul || echo   No iniciado
echo.
echo PROD:
docker compose -p uf1886-prod -f docker-compose.prod.yml ps 2>nul || echo   No iniciado
