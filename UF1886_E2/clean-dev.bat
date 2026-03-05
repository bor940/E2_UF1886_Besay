@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de DEV
set /p CONFIRM=^Â¿Estas seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p uf1886-dev -f docker-compose.dev.yml down -v
    echo [OK] Limpieza completa de DEV realizada
)
