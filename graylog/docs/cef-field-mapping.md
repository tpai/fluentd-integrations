# CEF Field Mapping

This document defines how application log fields map to CEF header and extension fields.

## CEF Header

```
CEF:0|DeviceVendor|DeviceProduct|DeviceVersion|SignatureID|Name|Severity|extensions
```

| CEF Position | Field | Source | Example |
|---|---|---|---|
| 0 | Protocol version | Constant | `CEF:0` |
| 1 | DeviceVendor | Company name | `AcmeCorp` |
| 2 | DeviceProduct | Application or platform name | `PlatformAuth` |
| 3 | DeviceVersion | App version or chart version | `1.0` |
| 4 | SignatureID (EventClassID) | Stable event type code | `AUTH-001` |
| 5 | Name | Short human-readable event name | `Login Failed` |
| 6 | Severity | Numeric 0–10 (see below) | `8` |
| 7 | Extensions | Space-separated key=value pairs | see below |

### Severity Mapping

| Application Level | CEF Severity | Meaning |
|---|---|---|
| DEBUG | 3 | Low |
| INFO | 5 | Medium |
| WARN | 6 | Medium-High |
| ERROR | 8 | High |
| FATAL | 10 | Very High |

CEF severity ranges: 0–3 Low, 4–6 Medium, 7–8 High, 9–10 Very-High.

---

## CEF Extensions

| CEF Key | App Field | Description | Example Value |
|---|---|---|---|
| `src` | source IP | Client or originating IP | `198.51.100.10` |
| `dst` | destination IP | Server or target IP | `10.0.1.5` |
| `suser` | source user | Authenticated or acting user | `alice.jones` |
| `duser` | destination user | Target user (if applicable) | `alice.jones` |
| `msg` | log message | Original log message body | `User authenticated successfully` |
| `rt` | event time | Event timestamp in epoch milliseconds | `1715340005000` |
| `cs1` | namespace | Kubernetes namespace | `production` |
| `cs1Label` | — | Label for `cs1` | `namespace` |
| `cs2` | service | Kubernetes service or microservice name | `auth-service` |
| `cs2Label` | — | Label for `cs2` | `service` |
| `cs3` | pod | Kubernetes pod name | `auth-service-7d4f8b-xk2p9` |
| `cs3Label` | — | Label for `cs3` | `pod` |
| `cs4` | trace_id | Distributed trace ID or request ID | `req-def456` |
| `cs4Label` | — | Label for `cs4` | `trace_id` |

### Custom String (cs) Fields — ArcSight Limit

ArcSight supports cs1–cs6. This mapping uses cs1–cs4. If you need additional fields, use cs5 and cs6, or consider `flexString1`/`flexString2`.

---

## EventClassID (SignatureID) Convention

Use a stable, dot-free string that identifies the event type. Recommended format: `<DOMAIN>-<NNN>`.

| Domain | Prefix | Examples |
|---|---|---|
| Authentication | `AUTH` | `AUTH-001` login failed, `AUTH-002` login success |
| HTTP / API | `HTTP` | `HTTP-400` bad request, `HTTP-500` server error |
| Application | `APP` | `APP-001` startup, `APP-500` unhandled exception |
| Kubernetes | `K8S` | `K8S-001` pod crash, `K8S-002` OOM killed |
| Database | `DB` | `DB-001` connection failed, `DB-002` query timeout |

---

## CEF Escaping Rules

Characters that must be escaped in CEF header fields (position 1–6):

| Character | Escaped form |
|---|---|
| `\` | `\\` |
| `\|` | `\|` |

Characters that must be escaped in extension values:

| Character | Escaped form |
|---|---|
| `\` | `\\` |
| `=` | `\=` |
| `\|` | `\|` |
| newline | `\n` |

The Fluentd `fluent.conf` in this repo escapes `\`, `=`, and `|` in `msg` values.

---

## Full Example

```
CEF:0|AcmeCorp|PlatformAuth|1.0|AUTH-001|Login Failed|8|src=203.0.113.42 dst=10.0.1.5 suser=bob.smith duser=bob.smith msg=Invalid password attempt rt=1715340001000 cs1=production cs1Label=namespace cs2=auth-service cs2Label=service cs3=auth-service-7d4f8b-xk2p9 cs3Label=pod cs4=req-abc123 cs4Label=trace_id
```
