// Parameters
param keyVaultName string
param location string = resourceGroup().location
param functionAppName string = 'cert-auto-agent'
param logicAppName string = 'cert-checker'
param storageAccountName string = 'certsa${uniqueString(resourceGroup().id)}'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
      ]
    }
  }
}

// Logic App
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  dependsOn: [ functionApp ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: loadTextContent('../logicapp/certificate-checker.json')
    parameters: {}
  }
}

// Key Vault (existing)
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}

// Access Policies
resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-11-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          certificates: [
            'get'
            'list'
            'update'
          ]
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        objectId: logicApp.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          certificates: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}
