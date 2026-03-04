targetScope = 'subscription'

param location string = 'swedencentral'
param environment string = 'dev'
param resourceGroupName string = 'rg-zavasf-${environment}-${location}'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environment
    application: 'ZavaStorefront'
  }
}

// Output resource group details
output resourceGroupId string = rg.id
output resourceGroupName string = rg.name
output location string = rg.location
