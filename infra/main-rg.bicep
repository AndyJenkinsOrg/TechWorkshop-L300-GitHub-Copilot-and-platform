targetScope = 'resourceGroup'

metadata description = 'Main orchestration template for ZavaStorefront deployment'

param location string = 'swedencentral'
param environment string = 'dev'

// Deploy Managed Identity
module managedIdentity 'modules/managed-identity.bicep' = {
  name: 'managed-identity-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Deploy Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Deploy Monitoring (Log Analytics + Application Insights)
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Deploy Redis Cache
module redisCache 'modules/redis-cache.bicep' = {
  name: 'redis-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Deploy AI Foundry Resources
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Deploy App Service
module appService 'modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    location: location
    environment: environment
    containerRegistryLoginServer: containerRegistry.outputs.acrLoginServer
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    redisCacheHostname: redisCache.outputs.redisCacheHostname
    redisCachePort: redisCache.outputs.redisCacheSslPort
    managedIdentityClientId: managedIdentity.outputs.managedIdentityClientId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    aiServicesEndpoint: aiFoundry.outputs.aiServicesEndpoint
  }
}

// Assign Cognitive Services OpenAI User role to managed identity on AI Services
resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundry.outputs.aiServicesId, managedIdentity.outputs.managedIdentityPrincipalId, 'CognitiveServicesOpenAIUser')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: managedIdentity.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output appServiceUrl string = appService.outputs.appServiceUrl
output appServiceName string = appService.outputs.appServiceName
output containerRegistryLoginServer string = containerRegistry.outputs.acrLoginServer
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString
output aiServicesEndpoint string = aiFoundry.outputs.aiServicesEndpoint
output redisCacheHostname string = redisCache.outputs.redisCacheHostname
