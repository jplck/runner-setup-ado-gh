param location string
param acrName string
param acrPullIdentityId string

param adoInstanceUrl string
param adoPersonalAccessToken string
param adoPoolName string
param adoAgentName string = 'ado-agent'

param adoAgentContainerName string = 'ado-agent'

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
  name: adoAgentContainerName
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
    }
    template: {
      containers: [
        {
          name: adoAgentName
          image: '${acr.properties.loginServer}/ado-agent:latest'
          resources: {
            cpu: json(adoAgentCpuCore)
            memory: '${adoAgentMemorySize}Gi'
          }
          env: [
            {
              name: 'AZP_URL'
              value: adoInstanceUrl
            }
            {
              name: 'AZP_TOKEN'
              value: adoPersonalAccessToken
            }
            {
              name: 'AZP_POOL'
              value: adoPoolName
            }
            {
              name: 'AZP_AGENT_NAME'
              value: adoAgentName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
      }
    }
  }
}
