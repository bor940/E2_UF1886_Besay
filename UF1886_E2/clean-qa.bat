@echo off
cd /d "%~dp0"
echo [AVISO] Esto eliminara contenedores Y datos de QA
set /p CONFIRM=^Â¿Estas seguro? [y/N]: 
if /i "%CONFIRM%"=="y" (
    docker compose -p uf1886-qa -f docker-compose.qa.yml down -v
    echo [OK] Limpieza completa de QA realizada
)
