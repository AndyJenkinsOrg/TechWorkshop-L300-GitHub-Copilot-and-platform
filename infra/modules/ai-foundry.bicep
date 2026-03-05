param location string
param environment string
param aiServicesName string = 'ais-zavasf-${environment}-${location}'
param managedIdentityPrincipalId string
param logAnalyticsWorkspaceId string

// AI Services Multi-Service Resource (Foundry resource)
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: aiServicesName
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: {
    environment: environment
    application: 'ZavaStorefront'
  }
}

// GPT-4o Model Deployment
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
  }
}

// Phi-4 Model Deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: aiServices
  name: 'Phi-4'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '4'
    }
  }
  dependsOn: [
    gpt4oDeployment
  ]
}

// Cognitive Services User role scoped to this AI Services resource only
resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, managedIdentityPrincipalId, 'CognitiveServicesUser')
  scope: aiServices
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908') // Cognitive Services User
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output aiServicesId string = aiServices.id
output aiServicesName string = aiServices.name
output aiServicesEndpoint string = aiServices.properties.endpoint

// Diagnostic settings — send all logs and metrics to Log Analytics
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiServicesName}-diagnostics'
  scope: aiServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
      {
        category: 'RequestResponse'
        enabled: true
      }
      {
        category: 'AzureOpenAIRequestUsage'
        enabled: true
      }
      {
        category: 'Trace'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
