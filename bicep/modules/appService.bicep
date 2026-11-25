@description('Azure region for the Web App.')
param location string = resourceGroup().location

@description('Name of the Web App.')
@minLength(2)
@maxLength(60)
param appName string

@description('Resource ID of the App Service Plan.')
param planId string

@description('Linux runtime stack (e.g., DOTNETCORE|8.0 or DOTNETCORE|10.0).')
param linuxFxVersion string = 'DOTNETCORE|8.0'

@description('Optional subnet resource ID for VNet regional integration.')
param subnetId string = ''

@description('Application settings array ({ name, value }). Supports @Microsoft.KeyVault(...) references.')
param appSettings array = []

@description('Connection strings array ({ name, connectionString, type }).')
param connectionStrings array = []

@description('Enable Microsoft Entra ID (Easy Auth v2) authentication.')
param useAuth bool = true

@description('Entra ID App Registration Client ID (plain value or @Microsoft.KeyVault(...) reference).')
param authClientId string = ''

@description('Entra ID App Registration Client Secret (plain value or @Microsoft.KeyVault(...) reference).')
@secure()
param authClientSecret string = ''

@description('Whether this app acts as a backend API (returns 401 instead of redirecting to login).')
param isApi bool = false

@description('Tags applied to the resource.')
param tags object = {}

var clientSecretSettingName = 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'

var secretAppSetting = (!empty(authClientSecret)) ? [
  {
    name: clientSecretSettingName
    value: authClientSecret
  }
] : []

var mergedAppSettings = union(appSettings, secretAppSetting)

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: planId
    virtualNetworkSubnetId: !empty(subnetId) ? subnetId : null
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      vnetRouteAllEnabled: true
      alwaysOn: true
      http20Enabled: true
      appSettings: mergedAppSettings
      connectionStrings: connectionStrings
    }
  }
}

resource authSettings 'Microsoft.Web/sites/config@2023-12-01' = if (useAuth) {
  name: 'authsettingsV2'
  parent: webApp
  properties: {
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: authClientId
          clientSecretSettingName: !empty(authClientSecret) ? clientSecretSettingName : null
          openIdIssuer: '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'
        }
        validation: {
          allowedAudiences: [
            'api://${authClientId}'
          ]
        }
      }
    }
    globalValidation: {
      redirectToProvider: 'AzureActiveDirectory'
      unauthenticatedClientAction: isApi ? 'Return401' : 'RedirectToLoginPage'
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
  }
}

@description('Resource ID of the App Service.')
output appId string = webApp.id

@description('Default hostname of the App Service.')
output appUrl string = webApp.properties.defaultHostName

@description('System-assigned managed identity principal ID.')
output principalId string = webApp.identity.principalId
