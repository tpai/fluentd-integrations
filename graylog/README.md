# Graylog

A local Docker Compose environment for validating CEF (Common Event Format) log delivery and parsing using Graylog.

## What This Does

- Verify Fluentd can generate and ship CEF-formatted logs
- Test Graylog CEF TCP and UDP inputs end-to-end
- Confirm CEF extension fields (`src`, `suser`, `cs1`–`cs4`, etc.) are parsed and searchable

## Stack

| Component  | Role | Exposed Port |
|------------|------|-------------|
| Graylog    | CEF ingestion, parsing, search UI | 9000 |
| OpenSearch | Log storage and indexing | — (internal) |
| MongoDB    | Graylog configuration and metadata | — (internal) |
| Fluentd    | Optional — transforms app logs → CEF → Graylog | — |

## Prerequisites

- Docker >= 24 and Docker Compose >= 2.x
- `openssl` — for credential generation (pre-installed on macOS and most Linux)
- `nc` (netcat) — for sending test CEF events
  - macOS: `brew install netcat`
  - Debian/Ubuntu: `apt-get install netcat-openbsd`

## Quick Start

### 1. Generate credentials

```bash
make gen-secret       # outputs GRAYLOG_PASSWORD_SECRET
make hash-password    # prompts for a password, outputs GRAYLOG_ROOT_PASSWORD_SHA2
```

### 2. Configure environment

```bash
cp .env.example .env
# Paste the generated values into .env
# The defaults in .env.example work for a quick local test (password: admin)
```

### 3. Start the stack

```bash
make up
```

Allow ~60 seconds for Graylog to finish initializing.

### 4. Open Graylog UI

http://127.0.0.1:9000 — log in with `admin` and the password you hashed.

### 5. Create a CEF TCP input

See [docs/graylog-input-setup.md](docs/graylog-input-setup.md) for step-by-step instructions.

### 6. Send test CEF events

```bash
make send-tcp    # sends all samples/cef-events.txt over TCP
make send-udp    # sends via UDP (requires CEF UDP input in Graylog)
```

### 7. Validate in Graylog Search

Open http://127.0.0.1:9000/search and confirm events appear with parsed fields.

---

## Validation Checklist

- [ ] `make health` reports all services OK
- [ ] Graylog UI reachable at http://127.0.0.1:9000
- [ ] CEF TCP input is green in **System → Inputs**
- [ ] `make send-tcp` completes without error
- [ ] Events visible in Graylog Search
- [ ] Fields `DeviceVendor`, `DeviceProduct`, `Name`, `src`, `suser`, `msg`, `cs1`–`cs4` are parsed
- [ ] Search by `suser:alice.jones`, `cs1:production`, `Severity:8` returns expected events
- [ ] (Optional) Fluentd end-to-end test passes

---

## Fluentd End-to-End Test

Fluentd is optional and runs as a separate Compose profile. It reads `samples/app-logs.txt`, transforms each JSON log into a CEF message, and ships it to Graylog over TCP.

**Requires:** CEF TCP input already created in Graylog (step 5 above).

```bash
docker compose --profile fluentd up --build fluentd
```

Or via Make:

```bash
make fluentd
```

Watch Fluentd logs to confirm delivery:

```bash
docker compose logs -f fluentd
```

---

## Stopping the Stack

```bash
make down     # stops containers, keeps data volumes
make clean    # stops containers and removes all data volumes (full reset)
```

---

## Version Updates

Versions are pinned in `.env`. To upgrade:

```env
GRAYLOG_VERSION=6.1
MONGO_VERSION=7.0
OPENSEARCH_VERSION=2.17.0
```

Check the [Graylog compatibility matrix](https://go2docs.graylog.org/current/planning_your_deployment/system_requirements.html) before changing major versions. Graylog 5.x/6.x requires MongoDB 6.0+ and OpenSearch 2.x.

---

## Security Notes

This repo is for **local PoC and demo only**.

- Default `.env.example` credentials (`admin`/`admin`) must not be used in shared environments
- Do not expose ports 9000 or 5514 publicly without firewall rules
- Prefer TCP over UDP for integration tests — UDP has no delivery guarantee
- OpenSearch security plugin is disabled — do not expose port 9200 externally
- TLS is not configured — enable it only if your target SIEM requires it

---

## Docs

- [Architecture](docs/architecture.md)
- [Graylog Input Setup](docs/graylog-input-setup.md)
- [CEF Field Mapping](docs/cef-field-mapping.md)
- [Troubleshooting](docs/troubleshooting.md)

---

## Limitation

This lab validates CEF delivery and Graylog parsing only. It does **not** emulate:

- ArcSight SmartConnector normalization or connector-side parsing
- ArcSight ESM correlation rules and active lists
- ArcSight Logger reporting and archiving behavior
- Customer-specific ArcSight parser customizations

Final validation must be done against a real ArcSight SmartConnector endpoint.
