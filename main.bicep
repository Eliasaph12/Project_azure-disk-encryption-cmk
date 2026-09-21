@description('Azure Region')
param location string = resourceGroup().location

@description('Unique Key Vault Name')
param keyVaultName string = 'kvcmk${uniqueString(resourceGroup().id)}'

@description('Key Name')
param keyName string = 'disk-encryption-key'

@description('Disk Encryption Set Name')
param desName string = 'des-disk-cmk'

// 1. Key Vault with Purge Protection & Soft Delete
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
  }
}

// 2. Customer-Managed Key (RSA 2048)
resource rsaKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
  }
}

// 3. Disk Encryption Set
resource des 'Microsoft.Compute/diskEncryptionSets@2023-10-02' = {
  name: desName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    rotationToLatestKeyVersionEnabled: true
    activeKey: {
      keyUrl: rsaKey.properties.keyUriWithVersion
      sourceVault: {
        id: keyVault.id
      }
    }
  }
}

// 4. Role Assignment: DES Identity -> Key Vault Crypto Service Encryption User
var cryptoServiceEncryptionUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

resource desRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, des.id, cryptoServiceEncryptionUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cryptoServiceEncryptionUserRoleId)
    principalId: des.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultId string = keyVault.id
output desId string = des.id
