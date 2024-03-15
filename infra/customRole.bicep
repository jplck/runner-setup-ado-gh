param roleName string = 'MyCustomRole'
param roleDefName string = 'CustomRoleDefinitionCreation'
param roleDescription string = 'Custom role definition for my application'
param actions array
param notActions array = []
param scope string

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(roleDefName)
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      scope
    ]
  }
}

output roleDefId string = roleDef.id
