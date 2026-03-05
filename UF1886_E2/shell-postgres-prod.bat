@echo off
docker exec -it postgres-prod psql -U odoo_prod -d odoo_prod
