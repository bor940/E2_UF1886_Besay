@echo off
cd /d "%~dp0"
docker compose -p uf1886-prod -f docker-compose.prod.yml restart
echo [OK] Odoo PROD reiniciado
