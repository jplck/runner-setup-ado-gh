param location string
param acrName string
param acrPullIdentityId string

param ghOrgName string
param ghPersonalAccessToken string

param containerName string = 'gh-runner'

param containerAppEnvName string

@allowed([
  '0.25'
  '0.5'
  '0.75'
  '1'
  '1.25'
  '1.5'
  '1.75'
  '2'
])
param adoAgentCpuCore string = '0.5'

@allowed([
  '0.5'
  '1'
  '1.5'
  '2'
  '3'
  '3.5'
  '4'
])
param adoAgentMemorySize string = '1'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrName
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvName
}



resource adoAgentApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acrPullIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: acrPullIdentityId
        }
      ]
      secrets: [
        {
          name: 'ACCESS_TOKEN'
          value: ghPersonalAccessToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerName
          image: '${acr.properties.loginServer}/gh-runner:latest'
          resources: {
            cpu: json(adoAgentCpuCore)
            memory: '${adoAgentMemorySize}Gi'
          }
          env: [
            {
              name: 'ORGANIZATION'
              value: ghOrgName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'gh-runner-scaler'
            custom: {
              type: 'github-runner'
              metadata: {
                owner: ghOrgName
              }
              auth: [
                {
                  secretRef: 'ACCESS_TOKEN'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}
