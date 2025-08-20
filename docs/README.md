# Agentic AI-Based Azure Key Vault Certificate Rotation

This repository contains a complete Agentic AI-powered solution to monitor, evaluate, and renew Azure Key Vault certificates automatically using Logic Apps, Azure Functions, and OpenAI prompts.

## 🧠 Agents

- **Monitoring Agent**: Logic App that checks certificates daily.
- **Policy Evaluation Agent**: Azure Function that determines renewal action.
- **Automation Agent**: Azure Function that performs renewal.
- **Notification Agent**: (Pluggable) Power Automate / Email.
- **Self-Healing Agent**: AI prompt for failure diagnostics.

## 🚀 Deployment

1. Configure `AZURE_CREDENTIALS` in GitHub secrets.
2. Update the Logic App definition JSON and cert names.
3. Push to GitHub main branch.

## 📂 Structure

See folder structure for detailed components.

## 🔐 Security

Uses **System Assigned Managed Identity** for Key Vault access.