param location string
param environment string
param containerRegistryLoginServer string
param appInsightsConnectionString string
param redisCacheHostname string
param redisCachePort int
param managedIdentityClientId string
param managedIdentityId string

var appServicePlanName = 'plan-zavasf-${environment}-${location}'
var appServiceName = 'app-zavasf-${environment}-${location}'
var appServiceSku = environment == 'dev' ? 'B1' : 'B2'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSku
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    application: 'ZavaStorefront'
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/zavastorefront:latest'
      alwaysOn: environment == 'dev' ? false : true
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      defaultDocuments: []
      healthCheckPath: '/health'
      numberOfWorkers: 1
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'RedisCache__Host'
          value: redisCacheHostname
        }
        {
          name: 'RedisCache__Port'
          value: '${redisCachePort}'
        }
        {
          name: 'RedisCache__Ssl'
          value: 'true'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentityClientId
        }
      ]
      connectionStrings: []
    }
    httpsOnly: true
  }
  tags: {
    environment: environment
    application: 'ZavaStorefront'
  }
}

// Configure managed identity for ACR pull
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appService.id, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: reference(managedIdentityId, '2023-01-31').principalId
    principalType: 'ServicePrincipal'
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
