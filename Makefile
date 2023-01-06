SHELL=/bin/bash
help:
	@echo "new-function: Use when creating a new function"
	@echo "new-procedure: Use when creating a new proc"
	@echo "new-view: Use when creating a new view"
	@echo "new-version: Use when creating a new version of db"
	@echo "build: Build dev image with flyway"
	@echo "core: Start pg service with migration executed"
	@echo "up: 'make core' with some base data"
	@echo "down: Teardown container/destroys local pg"
	@echo "connect: Start a local session to database (psql)"
	@echo "pg-logs: Attach to the local pg logs"

new-function:
	touch "prod-master-data/R__f_<FUNCTION_NAME>.sql"

new-procedure:
	touch "prod-master-data/R__p_<PROCEDURE_NAME>.sql"

new-view:
	touch "prod-master-data/R__v_<VIEW_NAME>.sql"

new-version:
	touch "prod-master-data/V`date -u +%Y.%m.%d.%H%M`__<BRANCH_NAME>.sql"

connect: 
	psql "postgresql://pguser:topsecret@127.0.0.1:15432/patient"

build:
	docker-compose build --no-cache

pg-logs:
	docker-compose logs -f db

core:
	docker-compose up -d db
	docker-compose run flyway

up:
	${MAKE} core
	docker-compose run seed
	
down:
	docker-compose down --remove-orphans
	sudo chmod -R 777 db-data
	rm -r db-data || true
