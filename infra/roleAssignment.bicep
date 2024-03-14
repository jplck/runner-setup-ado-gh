param role string
param principalId string

resource uaiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, role)
  properties: {
    roleDefinitionId: role
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
