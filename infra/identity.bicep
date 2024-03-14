param location string = resourceGroup().location
param name string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: name
  location: location
}

output principalId string = identity.properties.principalId
output name string = identity.name
