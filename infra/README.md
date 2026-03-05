# ZavaStorefront Infrastructure as Code

This directory contains Azure Bicep templates for deploying the ZavaStorefront e-commerce application.

## Architecture Overview

The infrastructure consists of:

- **Azure App Service (Linux)** - Container-based web application
- **Azure Container Registry** - Docker image repository with RBAC access
- **Azure Redis Cache** - Distributed session state management
- **Application Insights** - Monitoring and telemetry
- **Log Analytics Workspace** - Centralized logging
- **Azure AI Foundry** - AI model hosting (GPT-4 and Phi)
- **Managed Identity** - Service authentication without passwords

## File Structure

```
infra/
├── main.bicep                 # Root orchestration template
├── main.parameters.json       # Parameter values
├── resource-group.bicep       # Resource group definition
└── modules/
    ├── managed-identity.bicep # User-assigned managed identity
    ├── container-registry.bicep # ACR with RBAC
    ├── app-service.bicep      # App Service with Container deployment
    ├── monitoring.bicep       # Log Analytics + Application Insights
    ├── redis-cache.bicep      # Redis Cache for session state
    └── ai-foundry.bicep       # AI Foundry project + models
```

## Prerequisites

- Azure CLI (`az`) - latest version
- Azure Developer CLI (`azd`) - latest version
- Azure subscription with Contributor role
- Bash or PowerShell shell

## Deployment with AZD

### Quick Start

```bash
# Initialize or update AZD environment
azd env new dev

# Set subscription
azd env set AZURE_SUBSCRIPTION_ID "7d06c802-7121-4c24-a98c-4cda4941551a"
azd env set AZURE_LOCATION "westus3"

# Provision infrastructure
azd provision

# Deploy application
azd deploy
```

## Manual Deployment with Azure CLI

### 1. Create Resource Group

```bash
az group create \
  --name rg-zavasf-dev-westus3 \
  --location westus3
```

### 2. Deploy Infrastructure

```bash
az deployment group create \
  --resource-group rg-zavasf-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

## Configuration

### Environment Variables

The deployment reads the following from `.azure/.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `AZURE_LOCATION` | westus3 | Azure region for deployment |
| `AZURE_ENV_NAME` | dev | Environment name (dev/prod) |
| `AZURE_SUBSCRIPTION_ID` | — | Target Azure subscription |

### Application Settings

App Service receives these via Bicep:

- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection
- `RedisCache__Host` - Redis cache hostname
- `RedisCache__Port` - Redis cache port (6380 for SSL)
- `RedisCache__Ssl` - Enable SSL for Redis (true)
- `AZURE_CLIENT_ID` - Managed Identity client ID

## Monitoring

### Application Insights

The Application Insights instance automatically receives telemetry from:
- HTTP requests/responses
- Exceptions and error traces
- Performance metrics
- Custom events (when instrumented in code)

**Connection:** Application Insights is linked to Log Analytics Workspace for centralized logging.

### Log Analytics Workspace

Query logs with KQL (Kusto Query Language):

```kuql
AppServiceConsoleLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, ResultDescription
| order by TimeGenerated desc
```

## Security

### Managed Identity Authentication

- **System-assigned Managed Identity:** App Service uses this to:
  - Pull container images from ACR (AcrPull role)
  - Read application settings from Key Vault (future)
  - Access other Azure services without credentials

### Network Security

- HTTPS is enforced on App Service
- HSTS is enabled for production
- Redis Cache enforces TLS 1.2 minimum
- Container Registry has public network access for pulling images

### No Passwords

All authentication uses Azure RBAC:
- ✅ App Service ← ACR (via Managed Identity)
- ✅ App Service ← Redis Cache (via connection string)
- ✅ App Service ← Application Insights (via connection string)

## Container Builds

### ACR Tasks (Recommended - No Local Docker)

Build and push container images in Azure:

```bash
az acr build \
  --registry acrzavasfdevwestus3 \
  --image zavastorefront:latest \
  .
```

### Local Docker Build

If you have Docker installed locally:

```bash
docker build -t acrzavasfdevwestus3.azurecr.io/zavastorefront:latest .
docker login acrzavasfdevwestus3.azurecr.io
docker push acrzavasfdevwestus3.azurecr.io/zavastorefront:latest
```

## Troubleshooting

### Health Check Endpoint

The App Service health check is configured to:
- **Endpoint:** `/health`
- **Interval:** 30 seconds
- **Timeout:** 3 seconds
- **Failure threshold:** 3 consecutive failures

Check health manually:

```bash
curl -k https://app-zavasf-dev-westus3.azurewebsites.net/health
```

### View Logs

```bash
# Stream App Service logs
az webapp log tail \
  --resource-group rg-zavasf-dev-westus3 \
  --name app-zavasf-dev-westus3

# Query Application Insights
az monitor app-insights query \
  --resource rg-zavasf-dev-westus3 \
  --query "traces | order by timestamp desc" \
  --interval PT1H
```

### Managed Identity Issues

Verify role assignments:

```bash
az role assignment list \
  --resource-group rg-zavasf-dev-westus3 \
  --output table
```

## Cost Optimization

For development, the deployment uses cost-optimized SKUs:

| Service | SKU | Est. Cost |
|---------|-----|-----------|
| App Service | B1 Basic | $13/month |
| Container Registry | Basic | $5/month |
| Redis Cache | C0 Basic | $16/month |
| Application Insights | 0.5GB data ingestion | $5-10/month |
| Log Analytics Workspace | Pay-per-GB | $5/month |

**Total: ~$50-60/month** (excluding AI model usage)

## Next Steps

1. ✅ Deploy infrastructure with `azd provision`
2. Build and push container image to ACR
3. Update App Service container deployment
4. Test application health endpoint
5. Configure monitoring alerts
6. Deploy GPT-4 and Phi models in AI Foundry
7. Integrate AI endpoints into application

## References

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-foundry/)
