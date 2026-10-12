# Requires Docker with the compose plugin.
PROMTOOL = docker run --rm -v "$$PWD":/w -w /w --entrypoint promtool prom/prometheus:v2.54.1
AMTOOL   = docker run --rm -v "$$PWD":/w -w /w --entrypoint sh prom/alertmanager:v0.27.0 -c

.PHONY: init up down logs check reload

init: ## Create .env and the secrets placeholder
	test -f .env || cp .env.example .env
	test -f secrets/telegram_bot_token || touch secrets/telegram_bot_token
	@echo "Edit .env (Grafana password, Telegram chat ID) and secrets/telegram_bot_token"

up: ## Start everything: Grafana http://localhost:3000
	docker compose up -d --wait
	@echo "Grafana: http://localhost:3000  Prometheus: http://localhost:9090  Alertmanager: http://localhost:9093"

down: ## Stop (data volumes are kept)
	docker compose down

logs: ## Follow logs
	docker compose logs -f

check: ## Validate Prometheus config, alert rules (with unit tests) and Alertmanager config
	$(PROMTOOL) check rules prometheus/rules/alerts.yml
	$(PROMTOOL) test rules prometheus/tests/alerts.test.yml
	$(AMTOOL) 'amtool check-config alertmanager/alertmanager.yml && sed s/__TELEGRAM_CHAT_ID__/1/ alertmanager/telegram.yml > /tmp/am.yml && amtool check-config /tmp/am.yml'

reload: ## Reload Prometheus after editing rules or prometheus.yml
	curl -fsS -X POST http://localhost:9090/-/reload && echo reloaded
