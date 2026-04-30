# GCP Post-Deployment Testing Manual

_Quasar InfoTech Data Foundation_

This guide outlines the step-by-step procedures for testing the Quasarhub IoT application once it has been successfully deployed to Google Cloud Run and Cloud SQL.

> [!IMPORTANT]
> Ensure that the CI/CD pipeline (`cloudbuild.yaml`) has completed successfully and the Next.js application is live on Cloud Run before beginning this procedure.

---

## Phase 1: Environment Verification

### 1. Retrieve the Production Cloud Run URL

After the deployment completes, retrieve your live Cloud Run URL:

1. Open the [Google Cloud Console](https://console.cloud.google.com/run).
2. Navigate to **Cloud Run** and select the `quasar-foundation` service.
3. Copy the public URL (e.g., `https://quasar-foundation-xyz.a.run.app`).

### 2. Connect to the Cloud SQL Database Locally

To run the Node.js testing scripts, your local environment needs a direct connection to the GCP PostgreSQL database.

1. Download and authenticate the Cloud SQL Auth Proxy.
2. Run the proxy using the instance details from `provision_gcp_database.sh`:
   ```bash
   ./cloud-sql-proxy quasar-infotech-prod:us-east1:quasar-primary-db
   ```
3. Update your local `.env` file to point to the proxied database:
   ```env
   DATABASE_URL="postgresql://postgres:<YOUR_SECURE_PASSWORD>@localhost:5432/quasar"
   ```

---

## Phase 2: Updating the Simulators

The workspace includes two Node.js scripts used to simulate IoT telemetry data: `test-ingestion.mjs` and `simulator.mjs`. Currently, they point to `localhost:3001`. You must update them to point to the production Cloud Run URL.

### 1. Update `test-ingestion.mjs`

Open the file and modify the `fetch` target (around line 69):

```diff
- const response = await fetch("http://localhost:3001/api/telemetry/ingest", {
+ const response = await fetch("https://<YOUR_CLOUD_RUN_URL>/api/telemetry/ingest", {
```

### 2. Update `simulator.mjs`

Open the file and modify both the console log and the `fetch` target (around line 29 and line 63):

```diff
- console.log(`📡 Target Backend : http://localhost:3001/api/telemetry/ingest\n`);
+ console.log(`📡 Target Backend : https://<YOUR_CLOUD_RUN_URL>/api/telemetry/ingest\n`);

- const response = await fetch("http://localhost:3001/api/telemetry/ingest", {
+ const response = await fetch("https://<YOUR_CLOUD_RUN_URL>/api/telemetry/ingest", {
```

> [!WARNING]
> Do not commit these URL changes to the `main` branch if you want to keep the repository defaulted to local development!

---

## Phase 3: Executing Tests

### Test 1: Single Payload Verification

Run the single ingestion script to ensure the API endpoint is reachable, accepts the payload, and connects to the database successfully.

```bash
node test-ingestion.mjs
```

**Expected Output:** You should see `✅ Success! Server responded with:` followed by the ingestion confirmation.

### Test 2: Continuous Load Testing

Once the single payload works, initiate the continuous simulator to test high-throughput ingestion and dashboard hydration.

```bash
node simulator.mjs
```

**Expected Output:** The script will automatically create dummy Rider and Policy data if none exists, and then begin streaming telemetry payloads (including simulated crash events) every 5 seconds.

---

## Phase 4: UI & Dashboard Validation

While the `simulator.mjs` script is running, perform the following manual verifications on the live application:

1. **Dashboard KPI Hydration:**
   Navigate to `https://<YOUR_CLOUD_RUN_URL>/manager`. Verify that the React Server Components (RSC) are successfully aggregating the new telemetry data and updating the KPI cards.
2. **Onboarding & AI Pipeline:**
   Navigate to `https://<YOUR_CLOUD_RUN_URL>/onboarding`.
   - Test the multi-step wizard.
   - Upload a test Cedula image to verify that the Firebase Genkit pipeline can successfully communicate with the Gemini Vision model and auto-fill the `react-hook-form` inputs.

> [!TIP]
> If ingestion fails during load testing, check the Cloud Run Logs in the GCP Console. If Next.js becomes overloaded, it is a signal to begin transitioning to the planned Apache Beam/Dataflow + Pub/Sub architecture for direct database insertion.
