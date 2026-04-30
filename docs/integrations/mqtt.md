# RS-059 — MQTT Integration Guide

## Meeting with Thony

> Reference this document during the session.
> Everything the app needs from Thony is in Section 1.
> Everything Thony needs from the app is in Section 2.

---

## 1. What We Need From Thony

Ask these questions in order — each answer unblocks the next implementation step.

### 1.1 Broker connection

| #   | Question               | Why we need it                                | Example answer                               |
| --- | ---------------------- | --------------------------------------------- | -------------------------------------------- |
| A   | **Broker URL + port**  | Can't connect without it                      | `mqtt.gcp.ruedaseguro.com:8883`              |
| B   | **Transport protocol** | Flutter web needs WebSocket; native needs TCP | `mqtts://` (TLS/TCP) or `wss://` (WebSocket) |
| C   | **Auth method**        | Username/password or client certificates      | `username + password`                        |
| D   | **Credentials**        | The actual values                             | `user: rs_mobile / pass: xxxxxx`             |
| E   | **TLS required?**      | Affects which port and cert handling          | Yes/No + CA cert if self-signed              |

### 1.2 Topic namespace

| #   | Question                            | Why we need it                                       | Example                        |
| --- | ----------------------------------- | ---------------------------------------------------- | ------------------------------ |
| F   | **Topic structure**                 | Must match what the GCP dashboard subscribes to      | `rs/riders/{userId}/telemetry` |
| G   | **Separate topic for emergencies?** | Emergency events may need priority routing           | `rs/riders/{userId}/emergency` |
| H   | **QoS level**                       | Affects delivery guarantees and battery usage        | `QoS 1` (at least once)        |
| I   | **Retained messages?**              | Whether broker stores last value for new subscribers | Yes/No                         |

### 1.3 Message format (most critical)

Ask Thony to share **one example JSON payload** the GCP dashboard already consumes.
If none exists yet, propose the format in Section 3 and align on it.

### 1.4 GCP dashboard capabilities

| #   | Question                                        | Why we need it                                  |
| --- | ----------------------------------------------- | ----------------------------------------------- |
| J   | **What does the dashboard display?**            | So we publish the right fields                  |
| K   | **Does the dashboard publish back to the app?** | Determines if we need a subscribe loop          |
| L   | **Is there a DB schema we should match?**       | Supabase `telemetry_events` must align with GCP |

---

## 2. What Thony Needs From Us

Tell Thony this upfront so he can prepare too:

- **Client identifier format**: we will use `rs_mobile_{userId}` as the MQTT client ID
- **Publish rate**: telemetry events every 5 seconds while app is foregrounded; emergency events are fire-once
- **Payload size**: each telemetry message is ~200 bytes (JSON)
- **Platform**: Flutter app runs on Android, iOS, and Chrome (web) — broker must support both TCP and WebSocket if web demo is needed
- **User ID**: Supabase UUID (e.g. `aabbccdd-1234-5678-abcd-000000000001`)

---

## 3. Proposed Message Formats

Present these to Thony for approval. Adjust field names to match GCP schema if he has one.

### Telemetry event (published every 5s while riding)

```json
{
  "event": "telemetry",
  "userId": "aabbccdd-1234-5678-abcd-000000000001",
  "policyId": "pppppppp-1111-2222-3333-000000000001",
  "ts": "2026-03-29T14:32:00.000Z",
  "gForce": 0.98,
  "latitude": 10.4806,
  "longitude": -66.9036,
  "altitudeM": 900.0,
  "speedKmh": 42.5
}
```

### Emergency event (published once when SOS is activated)

```json
{
  "event": "emergency",
  "userId": "aabbccdd-1234-5678-abcd-000000000001",
  "policyId": "pppppppp-1111-2222-3333-000000000001",
  "ts": "2026-03-29T14:35:12.000Z",
  "triggerGForce": 4.2,
  "latitude": 10.4806,
  "longitude": -66.9036,
  "lastWindowSamples": 180
}
```

### Connection event (published on connect/disconnect for dashboard presence)

```json
{
  "event": "presence",
  "userId": "aabbccdd-1234-5678-abcd-000000000001",
  "status": "online",
  "ts": "2026-03-29T14:30:00.000Z"
}
```

---

## 4. What Gets Built (Implementation Plan)

Once Thony provides Section 1 answers, implementation takes ~1 session:

```
Step 1 — Add mqtt_client package
  pubspec.yaml: mqtt_client: ^10.0.0

Step 2 — Create MqttService singleton
  lib/features/telemetry/services/mqtt_service.dart
  - connect(userId, policyId)
  - disconnect()
  - publishTelemetry(TelemetrySample)
  - publishEmergency(TelemetrySample lastWindow)
  - reconnect loop (exponential backoff)

Step 3 — Wire into EmergencyScreen
  When countdown hits 0 → MqttService.publishEmergency(...)

Step 4 — Wire into sensor loop (Phase 1.5)
  When sensors_plus activates → TelemetryBufferService.insertSample(...)
                               → MqttService.publishTelemetry(...)

Step 5 — Add MQTT credentials to EnvConfig
  MQTT_BROKER_URL, MQTT_USERNAME, MQTT_PASSWORD
  (add to .env.example and dart-define)
```

### File that already exists and is ready to connect:

`lib/features/telemetry/services/telemetry_buffer_service.dart`

- `getWindow()` → returns the last 15 minutes of samples → goes into emergency payload
- `insertSample()` → call this from the MQTT publish loop to keep the buffer warm

---

## 5. Demo Flow (For the Meeting Presentation)

Once integrated, the live demo works like this:

```
1. Diego opens app on phone, logs in
   → MQTT publishes: presence { status: "online" }
   → GCP dashboard shows rider as ACTIVE

2. Diego taps the SOS button
   → 10-second countdown starts on phone

3. Thony watches GCP dashboard in real time

4. Countdown hits 0
   → MQTT publishes: emergency { triggerGForce, lat, lng, lastWindowSamples }
   → GCP dashboard shows EMERGENCY ALERT for that rider

5. Diego taps "Estoy bien"
   → MQTT publishes: presence { status: "safe" }
   → Dashboard clears the alert
```

---

## 6. Questions That Can Wait Until Later

These are non-blocking for the demo but important for Sprint 3+:

- Does the GCP backend write telemetry back to Supabase, or does the app write directly?
- What's the retention policy on the GCP broker (how long are messages kept)?
- Should the app subscribe to any topics? (e.g., push from GCP to app: policy status change, emergency acknowledgement from dispatch)
- Is there a test/staging broker separate from production?

---

## 7. Env Variables to Add After Meeting

Once Thony confirms the values, add these to both `.env` and `.env.example`:

```bash
# MQTT Broker (RS-059)
MQTT_BROKER_URL=mqtts://your-broker.gcp.example.com
MQTT_PORT=8883
MQTT_USERNAME=rs_mobile
MQTT_PASSWORD=your-password
```

And in `EnvConfig`:

```dart
static const mqttBrokerUrl = String.fromEnvironment('MQTT_BROKER_URL', defaultValue: '');
static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
static const mqttUsername = String.fromEnvironment('MQTT_USERNAME', defaultValue: '');
static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD', defaultValue: '');
```
