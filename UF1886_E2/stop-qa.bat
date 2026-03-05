@echo off
cd /d "%~dp0"
docker compose -p uf1886-qa -f docker-compose.qa.yml down
echo [OK] Odoo QA detenido
