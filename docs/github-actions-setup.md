# GitHub Actions Deployment Setup

This guide explains how to configure GitHub Actions to build and deploy the ZavaStorefront container to Azure App Service.

## Prerequisites

- Azure resources already provisioned (via `azd provision`)
- A GitHub repository with the workflow file at `.github/workflows/deploy.yml`

## 1. Create an Azure AD App Registration with OIDC Federation

```bash
# Create an app registration
az ad app create --display-name "github-zavasf-deploy"

# Note the appId from the output, then create a service principal
az ad sp create --id <APP_ID>

# Assign Contributor + AcrPush roles on the resource group
az role assignment create --assignee <APP_ID> --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-zavasf-dev-swedencentral

az role assignment create --assignee <APP_ID> --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-zavasf-dev-swedencentral

# Add federated credential for GitHub Actions
az ad app federated-credential create --id <APP_ID> --parameters '{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<GITHUB_ORG>/<REPO_NAME>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

> **Reference**: [Use GitHub Actions to connect to Azure (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)

## 2. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret                    | Value                          |
|---------------------------|--------------------------------|
| `AZURE_CLIENT_ID`        | App registration Application (client) ID |
| `AZURE_TENANT_ID`        | Azure AD tenant ID             |
| `AZURE_SUBSCRIPTION_ID`  | Azure subscription ID          |

## 3. Configure GitHub Variables

Go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable            | Value                              |
|---------------------|------------------------------------|
| `ACR_NAME`          | `acrzavasfdevswedencentral`        |
| `APP_SERVICE_NAME`  | `app-zavasf-dev-swedencentral`     |
| `RESOURCE_GROUP`    | `rg-zavasf-dev-swedencentral`      |

## 4. Run the Workflow

The workflow triggers automatically on push to `main`. You can also trigger it manually from the **Actions** tab using the "Run workflow" button.
