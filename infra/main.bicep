param ubicacion string = resourceGroup().location
param nombreEntorno string = 'production'
param nombreAcr string = 'acr${uniqueString(resourceGroup().id)}'
param nombreKeyVault string = 'kv-${take(uniqueString(resourceGroup().id), 16)}'
param nombreContainerApp string = 'ca-cloud-health'
param nombreContainerAppEnv string = 'cae-cloud-health'
param nombreLogAnalytics string = 'log-${take(uniqueString(resourceGroup().id), 16)}'
param imagenContenedor string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

@secure()
param valorSecretoSaludo string = ''

resource registroContenedores 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: nombreAcr
  location: ubicacion
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: nombreEntorno
    Project: 'Bootcamp-Azure'
  }
}

resource bovedaClaves 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: nombreKeyVault
  location: ubicacion
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: nombreEntorno
    Project: 'Bootcamp-Azure'
  }
}

resource secretoSaludo 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: bovedaClaves
  name: 'AppGreeting'
  properties: {
    value: empty(valorSecretoSaludo) ? 'Hola desde Azure Key Vault' : valorSecretoSaludo
    contentType: 'text/plain'
  }
}

resource espacioLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: nombreLogAnalytics
  location: ubicacion
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    Environment: nombreEntorno
    Project: 'Bootcamp-Azure'
  }
}

resource entornoContainerApps 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: nombreContainerAppEnv
  location: ubicacion
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: espacioLogAnalytics.properties.customerId
        sharedKey: espacioLogAnalytics.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    Environment: nombreEntorno
    Project: 'Bootcamp-Azure'
  }
}

resource aplicacionContenedor 'Microsoft.App/containerApps@2024-03-01' = {
  name: nombreContainerApp
  location: ubicacion
  properties: {
    environmentId: entornoContainerApps.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      secrets: [
        {
          name: 'app-greeting'
          value: empty(valorSecretoSaludo) ? 'Hola desde Azure Key Vault' : valorSecretoSaludo
        }
        {
          name: 'acr-password'
          value: registroContenedores.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: registroContenedores.properties.loginServer
          username: registroContenedores.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'cloud-health-service'
          image: imagenContenedor
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ENVIRONMENT'
              value: nombreEntorno
            }
            {
              name: 'APP_GREETING'
              secretRef: 'app-greeting'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

output servidorAcr string = registroContenedores.properties.loginServer
output nombreAcr string = registroContenedores.name
output nombreKeyVault string = bovedaClaves.name
output nombreContainerApp string = aplicacionContenedor.name
output urlContainerApp string = aplicacionContenedor.properties.configuration.ingress.fqdn
