.PHONY: up down clean logs gen-secret hash-password send-tcp send-udp health

GRAYLOG_HOST ?= 127.0.0.1
CEF_PORT     ?= 5514

up:
	docker compose up -d --build

down:
	docker compose down

clean:
	docker compose down -v

logs:
	docker compose logs -f

# Start Graylog stack + optional Fluentd end-to-end sender
fluentd:
	docker compose --profile fluentd up --build

gen-secret:
	@./scripts/gen-secret.sh

hash-password:
	@printf "Password: "; read -rs pw; echo; ./scripts/hash-password.sh "$$pw"

send-tcp:
	@./scripts/send-cef-tcp.sh $(GRAYLOG_HOST) $(CEF_PORT)

send-udp:
	@./scripts/send-cef-udp.sh $(GRAYLOG_HOST) $(CEF_PORT)

health:
	@./scripts/healthcheck.sh $(GRAYLOG_HOST)
