# Troubleshooting

## Graylog UI not reachable (http://127.0.0.1:9000)

**Check container status:**
```bash
docker compose ps
docker compose logs graylog | tail -50
```

Graylog can take 60–90 seconds to start after OpenSearch and MongoDB are healthy. Wait and retry.

**Common causes:**
- OpenSearch not yet healthy — Graylog refuses to start without it
- Incorrect `GRAYLOG_PASSWORD_SECRET` or `GRAYLOG_ROOT_PASSWORD_SHA2` — check `.env`
- Port 9000 already in use — change the host port in `docker-compose.yml`

---

## Graylog cannot connect to OpenSearch

**Symptom:** Graylog logs show `Unable to connect to Elasticsearch/OpenSearch`.

```bash
docker compose logs opensearch | tail -30
```

**Common causes:**

1. **vm.max_map_count too low** — OpenSearch requires at least 262144:
   ```bash
   # macOS / Docker Desktop — run inside the Docker VM:
   docker run --rm --privileged alpine sysctl -w vm.max_map_count=262144

   # Linux host:
   sudo sysctl -w vm.max_map_count=262144
   # To persist across reboots, add to /etc/sysctl.conf:
   # vm.max_map_count=262144
   ```

2. **OpenSearch still initializing** — wait for the health check to pass:
   ```bash
   curl http://127.0.0.1:9200/_cluster/health
   ```
   Status should be `green` or `yellow`.

---

## OpenSearch memory insufficient

Default heap is 1 GB (`-Xms1g -Xmx1g`). If your machine has less than 4 GB RAM available for Docker, lower it:

```yaml
# docker-compose.yml, opensearch service
environment:
  - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"
```

---

## CEF input not started / red in Graylog UI

1. Navigate to **System → Inputs**.
2. If the input shows red, click **Stop** then **Start**.
3. Check that port 5514 is not already bound on the host:
   ```bash
   lsof -i :5514
   ```
4. If another process is using 5514, change `CEF_PORT` in `.env` and update the Graylog input to match.

---

## Port 5514 already in use

```bash
lsof -i :5514    # macOS / Linux
```

Either stop the conflicting process or change `CEF_PORT` in `.env`:

```env
CEF_PORT=5515
```

Then recreate the stack:
```bash
make down && make up
```

And update the Graylog CEF input port to match.

---

## CEF message appears as raw text — fields are not parsed

The CEF input expects messages to start exactly with `CEF:0|`. Verify:

```bash
# Send a minimal valid CEF and check Graylog Search
echo 'CEF:0|Test|Test|1.0|001|Test Event|5|msg=hello' | nc -q 1 127.0.0.1 5514
```

If this parses correctly, the issue is in your message formatting. Common mistakes:
- Missing or misplaced `|` delimiters in the header
- Unescaped `|` or `=` inside extension values
- Leading whitespace before `CEF:`

See [cef-field-mapping.md](cef-field-mapping.md) for escaping rules.

---

## Fluentd not sending to Graylog

```bash
docker compose --profile fluentd logs fluentd
```

Common causes:
- Graylog CEF TCP input is not yet created — create it first (see [graylog-input-setup.md](graylog-input-setup.md))
- `GRAYLOG_HOST` env var not resolving — verify Graylog container is named `graylog`
- `app-logs.txt` already fully read and pos file exists — delete the pos file to re-read:
  ```bash
  rm fluentd/app-logs.pos
  docker compose --profile fluentd restart fluentd
  ```

---

## Docker volume cleanup (full reset)

```bash
make clean    # stops containers and removes all named volumes
```

This deletes all OpenSearch indices and Graylog configuration. You will need to recreate CEF inputs after restarting.

---

## Reset Graylog admin password

1. Stop the stack: `make down`
2. Generate a new hash: `make hash-password`
3. Update `GRAYLOG_ROOT_PASSWORD_SHA2` in `.env`
4. Start the stack: `make up`

---

## Version compatibility

If you update component versions in `.env`, verify compatibility:
- [Graylog system requirements](https://go2docs.graylog.org/current/planning_your_deployment/system_requirements.html)
- Graylog 5.x/6.x requires MongoDB 6.0+ and OpenSearch 2.x
- Do not mix major OpenSearch versions without checking Graylog's compatibility matrix
