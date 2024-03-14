@description('Location resources.')
param location string

@description('Define the project name')
param projectName string

var acrPushRole = resourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var deploymentScriptRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a5687739-dd36-420c-903b-820d2ac53125')

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${projectName}-rg'
  location: location
}

module acr 'registry.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: rg.location
    containerRegistryName: 'acr${projectName}'
  }
}

module logging 'logging.bicep' = {
  name: 'logging'
  scope: rg
  params: {
    location: rg.location
    logAnalyticsWorkspaceName: 'log${projectName}'
    applicationInsightsName: 'appi${projectName}'
  }
}

module deployPushIdentity 'identity.bicep' = {
  name: 'deployPushIdentity'
  scope: rg
  params: {
    location: rg.location
    name: 'deployId-${projectName}'
  }
}

module acaACRPullIdentity 'identity.bicep' = {
  name: 'acaACRPullIdentity'
  scope: rg
  params: {
    location: rg.location
    name: 'acaId-${projectName}'
  }
}

module acrPushRoleAssignment 'roleAssignment.bicep' = {
  name: 'acrPushRoleAssignment'
  scope: rg
  params: {
    principalId: deployPushIdentity.outputs.principalId
    role: acrPushRole
  }
}

module deploymentScriptRoleAssignment 'roleAssignment.bicep' = {
  name: 'deploymentScriptRole'
  scope: rg
  params: {
    principalId: deployPushIdentity.outputs.principalId
    role: deploymentScriptRole
  }
}

module acaPullRoleAssignment 'roleAssignment.bicep' = {
  name: 'acaPullRoleAssignment'
  scope: rg
  params: {
    principalId: acaACRPullIdentity.outputs.principalId
    role: acrPullRole
  }
}

module agent_deploy 'deploy.bicep' = {
  name: 'agent_deploy'
  scope: rg
  params: {
    location: rg.location
    containerRegistryName: acr.outputs.name
    managedIdentityName: deployPushIdentity.outputs.name
  }
  dependsOn: [
    acrPushRoleAssignment
    deploymentScriptRoleAssignment
  ]
}
