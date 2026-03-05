@echo off
cd /d "%~dp0"
docker compose -p uf1886-dev -f docker-compose.dev.yml restart
echo [OK] Odoo DEV reiniciado
