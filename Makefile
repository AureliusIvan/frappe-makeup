up:
	docker compose -f docker-compose.yml --env-file=./.env up -d

up-rebuild:
	docker compose -f docker-compose.yml --env-file=./.env up -d --build --force-recreate