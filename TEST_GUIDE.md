# Test Guide: Simulating End-to-End Certificate Rotation Workflow

This guide documents how to simulate the complete certificate rotation workflow in a safe test environment, ensuring the Azure Logic App, Function App, and certificate operations behave as expected without impacting production secrets.

---

## Overview

The purpose of this test is to validate:
- The Logic App correctly triggers the workflow.
- The Azure Function (`CertPolicyEvaluator`) evaluates certificate expiration.
- The `CertAutoRenew` script simulates a renewal event.
- All components interact correctly with a test certificate in a non-production Key Vault.

---

## Prerequisites

Ensure the following resources are deployed and configured:

| Resource | Requirement |
|----------|-------------|
| **Azure Key Vault** | Contains a **test certificate** with a past expiry date |
| **Logic App** | Deployed from `certificate-checker.json` |
| **Function App** | Deployed with `run.csx` and `CertPolicyEvaluator.csx` |
| **Service Principal / Managed Identity** | Has Key Vault access policy with `get`, `list`, `update` |
| **App Configuration** | Required environment variables or GitHub secrets |
| **Application Insights** | (Optional) for tracking logs |

---

## Environment Setup

### 1. Set Secrets for GitHub Actions

Go to your GitHub repo → Settings → Secrets → Actions:

- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `KEY_VAULT_NAME`
- `CERT_NAME`
- `LOGICAPP_NAME`

> These are required for the GitHub workflow to authenticate and deploy.

---

## 🔁 Simulation Steps

### Step 1: Upload Simulated Expiring Certificate

- Navigate to Azure Key Vault → Certificates → `+ Generate/Import`
- Upload a **self-signed certificate** with an expired or near-expiry date.
- Use the same name as defined in your workflow (e.g., `test-cert`).

---

### Step 2: Manually Trigger the Logic App

- Go to the Azure portal → Your Logic App
- Use the **Run Trigger → Manual** option.
- Observe the run status and steps in **Runs History**.

---

### Step 3: Monitor Azure Function Execution

- The Logic App will invoke the Azure Function.
- The function checks the certificate's expiry via the Key Vault SDK.
- Logs response and, if needed, invokes the simulated auto-renew logic.

---

### Step 3: Alternative: Test Using `curl` Command (Direct Function Trigger)

You can test the Azure Function endpoint locally with:

```bash
curl -X POST http://localhost:7071/api/CertPolicyEvaluator   -H "Content-Type: application/json"   -d '{
    "Issuer": "DigiCert",
    "Expires": "2024-12-31",
    "Thumbprint": "123"
}'
```

Expected response:

```json
{
  "Action": "AutoRenew",
  "Reason": "Certificate expires in XX days. Policy evaluated based on issuer and thumbprint."
}
```

### Step 4: Simulated Auto-Renew Script Execution

- If expiration condition is met, `CertAutoRenew` runs.
- Logs a message like: `Simulated renewal for cert: test-cert`
- (Does **not** replace real certificate in test mode.)

---

### Step 5: Validate Logs & Outputs

- Check:
  - **Application Insights Logs** (if enabled)
  - **Logic App Run Output**
  - **Function App Console Logs**
- Confirm:
  - Triggered correctly
  - Expiry check logic executed
  - Simulated renewal processed

---

## Success Criteria

| Task | Expected Result |
|------|------------------|
| Logic App Trigger | Runs without failure |
| Function App | Executes expiration check |
| Cert Renewal | Simulated successfully |
| Logs | Clearly show flow and messages |

---

## Notes & Tips

- Don’t test this on production Key Vault or certificates.
- Use GitHub Actions to deploy Bicep/Logic App Function as needed.
- You can also use `az logic workflow run trigger` CLI for automation.

---

## Related Files

- `arm-templates/main.bicep`
- `functionapp/run.csx`
- `functionapp/CertPolicyEvaluator.csx`
- `logicapp/certificate-checker.json`
- `.github/workflows/deploy.yml`

---