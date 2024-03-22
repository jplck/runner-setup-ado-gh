param location string = resourceGroup().location
param containerRegistryName string
param managedIdentityName string

param supportingScripts array = []
param dockerfileLocation string
param imageName string

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
    arguments: '${containerRegistryName} ${subscription().subscriptionId} ${imageName} ${dockerfileLocation}'
    scriptContent: loadTextContent('./scripts/deploy_agent_images.sh')
    retentionInterval: 'P1D'
    supportingScriptUris: supportingScripts
  }
}
