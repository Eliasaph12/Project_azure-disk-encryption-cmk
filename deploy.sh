#!/bin/bash
set -e

LOCATION="centralindia"
RG="rg-disk-encryption"
KV="kvcmk$RANDOM"
KEY="disk-encryption-key"
DES="des-disk-cmk"
VM="vm-encrypted"
VM_SIZE="Standard_B2ats_v2"

echo "Deploying Azure CMK Disk Encryption Architecture..."
az group create --name "$RG" --location "$LOCATION"
az keyvault create --name "$KV" -g "$RG" -l "$LOCATION" --enable-purge-protection true --enable-rbac-authorization true

USER_ID=$(az ad signed-in-user show --query id -o tsv)
KV_ID=$(az keyvault show --name "$KV" --query id -o tsv)
az role assignment create --assignee "$USER_ID" --role "Key Vault Crypto Officer" --scope "$KV_ID"
sleep 15

az keyvault key create --vault-name "$KV" --name "$KEY" --kty RSA --size 2048
KEY_URL=$(az keyvault key show --vault-name "$KV" --name "$KEY" --query key.kid -o tsv)

az disk-encryption-set create --name "$DES" -g "$RG" -l "$LOCATION" --key-url "$KEY_URL" --source-vault "$KV_ID" --enable-auto-key-rotation true
DES_ID=$(az disk-encryption-set show -n "$DES" -g "$RG" --query id -o tsv)
DES_IDENTITY=$(az disk-encryption-set show -n "$DES" -g "$RG" --query identity.principalId -o tsv)

az role assignment create --assignee "$DES_IDENTITY" --role "Key Vault Crypto Service Encryption User" --scope "$KV_ID"
sleep 20

az vm create -g "$RG" -n "$VM" --image Ubuntu2404 --size "$VM_SIZE" --admin-username azureuser --generate-ssh-keys --os-disk-encryption-set "$DES_ID"

echo "Deployment complete! Verified encryption:"
OS_DISK=$(az vm show -g "$RG" -n "$VM" --query "storageProfile.osDisk.name" -o tsv)
az disk show -g "$RG" -n "$OS_DISK" --query "{Disk:name, Encryption:encryption.type, DES:encryption.diskEncryptionSetId}" -o json
