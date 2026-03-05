@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de PROD
set /p CONFIRM=^Â¿Estas COMPLETAMENTE seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p uf1886-prod -f docker-compose.prod.yml down -v
    echo [OK] Limpieza completa de PROD realizada
)
