param projectName string
param location string = resourceGroup().location
param virtualNetworkName string = '${projectName}-vnet'
param vnetAddressPrefix string = '10.0.0.0/16'
param containerAppEnvSubnetPrefix string = '10.0.0.0/23'
param containerAppEnvSubnetName string = 'Subnet1'
param containerAppEnvName string = '${projectName}-acae'
param logAnalyticsName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: logAnalyticsName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: containerAppEnvSubnetName
        properties: {
          addressPrefix: containerAppEnvSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: vnet.properties.subnets[0].id
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

output containerAppEnvName string = containerAppEnv.name
