// modules/sqlServer.bicep
@description('Azure region for the Azure SQL Logical Server.')
param location string = resourceGroup().location

@description('Name of the Azure SQL Logical Server.')
param sqlServerName string

@description('Administrator login name when SQL authentication is enabled.')
param sqlAdministratorLogin string = ''

@description('Administrator password when SQL authentication is enabled.')
@secure()
param sqlAdministratorLoginPassword string = ''

@description('Object ID of the Entra ID admin principal.')
param sqlAdminObjectId string

@description('Login/UPN or display name of the Entra ID admin principal.')
param sqlAdminLogin string

@description('Principal type for Entra ID admin (Application, User, or Group).')
@allowed([
  'Application'
  'User'
  'Group'
])
param sqlAdminPrincipalType string = 'Group'

@description('Enforce Microsoft Entra ID-only authentication.')
param azureAdOnlyAuthentication bool = true

@description('Disable public network access when using Private Endpoints.')
param disablePublicNetworkAccess bool = true

@description('Resource ID of User-Assigned Managed Identity for SQL Server.')
param userAssignedIdentityId string = ''

@description('Tags applied to the SQL Server.')
param tags object = {}

var hasUami = !empty(userAssignedIdentityId)

module sqlServerAvm 'br/public:avm/res/sql/server:0.21.3' = {
  name: 'avm-sql-${sqlServerName}'
  params: {
    name: sqlServerName
    location: location
    tags: tags
    managedIdentities: hasUami ? {
      userAssignedResourceIds: [
        userAssignedIdentityId
      ]
    } : {
      systemAssigned: true
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: disablePublicNetworkAccess ? 'Disabled' : 'Enabled'
    administratorLogin: !empty(sqlAdministratorLogin) ? sqlAdministratorLogin : null
    administratorLoginPassword: !empty(sqlAdministratorLoginPassword) ? sqlAdministratorLoginPassword : null
    primaryUserAssignedIdentityResourceId: hasUami ? userAssignedIdentityId : null
    administrators: !empty(sqlAdminObjectId) ? {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: azureAdOnlyAuthentication
      principalType: sqlAdminPrincipalType
      login: sqlAdminLogin
      sid: sqlAdminObjectId
      tenantId: subscription().tenantId
    } : null
  }
}

@description('FQDN of the SQL Logical Server.')
output serverFullyQualifiedDomainName string = sqlServerAvm.outputs.fullyQualifiedDomainName

@description('Resource ID of the SQL Logical Server.')
output serverId string = sqlServerAvm.outputs.resourceId

@description('Name of the SQL Logical Server.')
output serverName string = sqlServerAvm.outputs.name
