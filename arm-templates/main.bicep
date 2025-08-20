param keyVaultName string = 'my-keyvault-name'

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'cert-auto-agent'
  location: resourceGroup().location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'UseDevelopmentStorage=true'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'cert-checker'
  dependsOn: [ functionApp]
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: loadTextContent('../logicapp/certificate-checker.json')
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}

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
        }
      }
    ]
  }
}
