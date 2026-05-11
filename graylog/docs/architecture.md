# Architecture

## Overview

```
                         ┌─────────────────────────────────────────┐
                         │          Docker Compose Network          │
                         │                                          │
  [Test scripts]         │  ┌──────────┐     ┌──────────────────┐  │
  send-cef-tcp.sh ──TCP──┼─►│          │     │                  │  │
                         │  │ Graylog  │────►│   OpenSearch     │  │
                         │  │  :9000   │     │   (storage)      │  │
  [Optional]             │  │  :5514   │     └──────────────────┘  │
  Fluentd ──────TCP──────┼─►│          │                           │
                         │  └─────┬────┘                           │
                         │        │                                 │
                         │  ┌─────▼────┐                           │
                         │  │ MongoDB  │                           │
                         │  │ (config) │                           │
                         │  └──────────┘                           │
                         └─────────────────────────────────────────┘
```

## Component Roles

| Component  | Role | Port |
|------------|------|------|
| Graylog    | CEF ingestion, parsing, search UI | 9000 (UI), 5514 (CEF TCP) |
| OpenSearch | Stores and indexes parsed log events | 9200 (internal) |
| MongoDB    | Stores Graylog configuration and metadata | 27017 (internal) |
| Fluentd    | Optional — reads app logs, transforms to CEF, ships to Graylog | — |

## Data Flow

### Direct CEF injection (scripts or real ArcSight SmartConnector)

```
send-cef-tcp.sh → TCP :5514 → Graylog CEF Input → parsed fields → OpenSearch
```

Graylog's CEF input parses the raw CEF message and extracts:
- `DeviceVendor`, `DeviceProduct`, `DeviceVersion` from the CEF header
- `SignatureID` (EventClassID), `Name`, `Severity` from the CEF header
- All extension key-value pairs as individual Graylog fields

### Fluentd end-to-end flow

```
app-logs.txt (JSON)
  → Fluentd tail source
  → record_transformer: add cef_severity
  → record_transformer: build cef_message string
  → tcp output → Graylog CEF TCP Input :5514
  → parsed fields stored in OpenSearch
```

## Why OpenSearch, not Elasticsearch?

Graylog 5.x/6.x is certified against OpenSearch 2.x. The API is wire-compatible with Elasticsearch 7.x, so Graylog uses the same `GRAYLOG_ELASTICSEARCH_HOSTS` env var for both. In this lab, OpenSearch runs with security disabled to simplify the local setup.

## CEF Message Format

```
CEF:0|DeviceVendor|DeviceProduct|DeviceVersion|SignatureID|Name|Severity|extensions
```

Extensions are space-separated `key=value` pairs. Pipe characters (`|`) and backslashes (`\`) in header fields must be escaped. Equals signs (`=`) and backslashes in extension values must be escaped.

## Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 9000 | TCP | Graylog | Web UI and REST API |
| 5514 | TCP | Graylog | CEF TCP Input |
| 9200 | TCP | OpenSearch | REST API (internal only) |
| 27017 | TCP | MongoDB | Driver protocol (internal only) |
