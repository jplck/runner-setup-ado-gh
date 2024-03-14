param location string = resourceGroup().location
param containerRegistryName string
param managedIdentityName string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'loadTextContentCLI'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.53.0'
    arguments: '${containerRegistryName} ${subscription().subscriptionId}'
    scriptContent: loadTextContent('./scripts/deploy_agent_images.sh')
    retentionInterval: 'P1D'
    supportingScriptUris: [
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/ado/ado_agent_linux.dockerfile'
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/ado/start.sh'
    ]
  }
}
