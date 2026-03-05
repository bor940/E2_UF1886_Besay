@echo off
cd /d "%~dp0"
docker compose -p uf1886-dev -f docker-compose.dev.yml down
echo [OK] Odoo DEV detenido
