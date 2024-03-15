@description('Location resources.')
param location string

@description('Define the project name')
param projectName string

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

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

module acaACRPullIdentity 'identity.bicep' = {
  name: 'acaACRPullIdentity'
  scope: rg
  params: {
    location: rg.location
    name: 'acaId-${projectName}'
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

module deployPushIdentity 'identity.bicep' = {
  name: 'deployPushIdentity'
  scope: rg
  params: {
    location: rg.location
    name: 'deployId-${projectName}'
  }
}

module deploymentScriptRoleAssignment 'roleAssignment.bicep' = {
  name: 'deploymentScriptRole'
  scope: rg
  params: {
    principalId: deployPushIdentity.outputs.principalId
    role: deploymentScriptRole.outputs.roleDefId
  }
}

module deploymentScriptRole 'customRole.bicep' = {
  name: 'deploymentScriptRoleDefinition'
  scope: rg
  params: {
    roleName: 'DeploymentScriptRole-${projectName}'
    actions: [
      'Microsoft.Storage/storageAccounts/*'
      'Microsoft.ContainerInstance/containerGroups/*'
      'Microsoft.Resources/deployments/*'
      'Microsoft.Resources/deploymentScripts/*'
      'Microsoft.ContainerRegistry/registries/*' // Not optimal as it gives full access to the ACR. Change to a more granular role if possible. Required for the deployment script to (build)push to the ACR.
    ]
    scope: rg.id
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
    deploymentScriptRoleAssignment
  ]
}

module acae_deploy 'acae.bicep' = {
  name: 'acae_deploy'
  scope: rg
  params: {
    location: rg.location
    acrName: acr.outputs.name
    logAnalyticsName: logging.outputs.logAnalyticsWorkspaceName
    acrPullIdentityId: acaACRPullIdentity.outputs.id
    projectName: projectName
  }
  dependsOn: [
    acaPullRoleAssignment
  ]
}
