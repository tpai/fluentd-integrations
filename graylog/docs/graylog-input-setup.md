# Graylog Input Setup

This guide walks through creating a CEF TCP input in Graylog after the stack is running.

## Prerequisites

- Stack is up: `make up`
- Graylog UI is reachable at http://127.0.0.1:9000
- You are logged in as admin

Allow ~60 seconds after `docker compose up` for Graylog to finish initializing.

---

## Create a CEF TCP Input

1. Open http://127.0.0.1:9000 and log in.

2. Navigate to **System** → **Inputs** (top menu bar).

3. In the **Select input** dropdown, choose **CEF TCP**.

4. Click **Launch new input**.

5. Fill in the form:

   | Field | Value |
   |-------|-------|
   | Title | `CEF TCP 5514` |
   | Bind address | `0.0.0.0` |
   | Port | `5514` |
   | Max message size | `2 MB` (default is fine) |
   | TLS | Leave unchecked for local testing |

6. Click **Save**.

7. The input should appear in the list with a **green** running indicator. If it shows red, check that port 5514 is not already in use on the host.

---

## Create a CEF UDP Input (optional)

Repeat the steps above but choose **CEF UDP** in the dropdown and use the same port `5514`.

UDP input is useful only if your log source requires it. Prefer TCP for integration tests.

---

## Verify the Input is Receiving Events

1. With the input running, send a test event:

   ```bash
   make send-tcp
   ```

2. In Graylog, click **Show received messages** next to the `CEF TCP 5514` input.

3. You should see the event with parsed CEF fields.

---

## Verify CEF Field Parsing

After sending events, open **Search** (top nav) and run a query. Confirm these fields appear in the message sidebar:

| Graylog Field | Source |
|---------------|--------|
| `DeviceVendor` | CEF header field 2 |
| `DeviceProduct` | CEF header field 3 |
| `DeviceVersion` | CEF header field 4 |
| `EventClassID` | CEF header field 5 (SignatureID) |
| `Name` | CEF header field 6 |
| `Severity` | CEF header field 7 |
| `src` | CEF extension |
| `dst` | CEF extension |
| `suser` | CEF extension |
| `duser` | CEF extension |
| `msg` | CEF extension |
| `cs1`, `cs1Label` | CEF extension (namespace) |
| `cs2`, `cs2Label` | CEF extension (service) |
| `cs3`, `cs3Label` | CEF extension (pod) |
| `cs4`, `cs4Label` | CEF extension (trace_id) |

If fields are not showing, the CEF message may not be correctly formatted. See [troubleshooting.md](troubleshooting.md).

---

## Useful Graylog Search Queries

```
DeviceVendor:AcmeCorp
DeviceProduct:PlatformAuth
Name:"Login Failed"
src:203.0.113.42
suser:bob.smith
cs1:production
cs2:auth-service
Severity:8
```
