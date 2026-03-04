targetScope = 'subscription'

metadata description = 'Subscription-level orchestration template for ZavaStorefront deployment'

param location string = 'swedencentral'
param environment string = 'dev'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-zavasf-${environment}-${location}'
  location: location
  tags: {
    environment: environment
    application: 'zavastorefront'
  }
}

// Deploy resources into the resource group
module deployResources 'main-rg.bicep' = {
  scope: resourceGroup
  name: 'resources-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output appServiceUrl string = deployResources.outputs.appServiceUrl
output appServiceName string = deployResources.outputs.appServiceName
output containerRegistryLoginServer string = deployResources.outputs.containerRegistryLoginServer
output appInsightsConnectionString string = deployResources.outputs.appInsightsConnectionString
output aiServicesEndpoint string = deployResources.outputs.aiServicesEndpoint
output redisCacheHostname string = deployResources.outputs.redisCacheHostname
