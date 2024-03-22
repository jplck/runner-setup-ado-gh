@description('Location resources.')
param location string

@description('Define the project name')
param projectName string

param adoPat string
param adoPoolName string
param adoInstanceUrl string

param ghPat string
param ghOrgName string

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

module ado_agent_deploy 'deploy.bicep' = {
  name: 'ado_agent_deploy'
  scope: rg
  params: {
    location: rg.location
    containerRegistryName: acr.outputs.name
    managedIdentityName: deployPushIdentity.outputs.name
    dockerfileLocation: './ado_agent_linux.dockerfile'
    imageName: 'ado-agent:latest'
    supportingScripts: [
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/ado/ado_agent_linux.dockerfile'
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/ado/start.sh'
    ]
  }
  dependsOn: [
    deploymentScriptRoleAssignment
  ]
}

module gh_runner_deploy 'deploy.bicep' = {
  name: 'gh_runner_deploy'
  scope: rg
  params: {
    location: rg.location
    containerRegistryName: acr.outputs.name
    managedIdentityName: deployPushIdentity.outputs.name
    dockerfileLocation: './gh_runner_linux.dockerfile'
    imageName: 'gh-runner:latest'
    supportingScripts: [
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/gh/gh_runner_linux.dockerfile'
      'https://raw.githubusercontent.com/jplck/runner-setup-ado-gh/main/src/gh/start.sh'
    ]
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
    logAnalyticsName: logging.outputs.logAnalyticsWorkspaceName
    projectName: projectName
  }
  dependsOn: [
    acaPullRoleAssignment
  ]
}

module aca_ado_agent 'ado_agent.bicep' = {
  name: 'aca_ado_agent'
  scope: rg
  params: {
    location: rg.location
    acrName: acr.outputs.name
    acrPullIdentityId: acaACRPullIdentity.outputs.id
    containerAppEnvName: acae_deploy.outputs.containerAppEnvName
    adoInstanceUrl: adoInstanceUrl
    adoPersonalAccessToken: adoPat
    adoPoolName: adoPoolName
  }
}

module aca_gh_runner 'gh_runner.bicep' = {
  name: 'aca_gh_runner'
  scope: rg
  params: {
    location: rg.location
    acrName: acr.outputs.name
    acrPullIdentityId: acaACRPullIdentity.outputs.id
    containerAppEnvName: acae_deploy.outputs.containerAppEnvName
    ghOrgName: ghOrgName
    ghPersonalAccessToken: ghPat
  }
}

