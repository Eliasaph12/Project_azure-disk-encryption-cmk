# Azure Disk Encryption and Customer-Managed Keys

> **Problem Statement:** Securing Azure VM disks requires customer managed encryption keys to prevent unauthorized access, breaches, and data loss.

---

## 1. Abstract

Azure Disk Encryption and Customer-Managed Keys is a cloud security project that demonstrates how to protect Azure Virtual Machine disks using a Customer-Managed Key (CMK) stored in Azure Key Vault. The project uses a Disk Encryption Set (DES) to connect the customer-managed key with Azure Managed Disks and encrypt the VM's operating-system and data disks.

The project also demonstrates key rotation, access control, monitoring, and key lifecycle management. It highlights the importance of protecting encryption keys because disabling or deleting a key used for disk encryption can make the associated encrypted data inaccessible.

---

## 2. Architecture Diagram

Architecture flow:

```text
                    AZURE SUBSCRIPTION
                           ?
                    Resource Group
                           ?
          ????????????????????????????????????
          ?                                  ?
          ?                                  ?
   Azure Key Vault                    Azure Virtual Machine
          ?                                  ?
          ?                                  ?
 Customer-Managed Key                  Managed Disk(s)
   disk-encryption-key                 ????????????????
          ?                            ? OS Disk      ?
          ?                            ? Data Disk    ?
          ?                            ????????????????
          ?                                   ?
          ?                                   ?
   Disk Encryption Set ????????????????????????
          ?
          ?
   Customer-Managed
    Disk Encryption

          ?
          ??? Key Rotation
          ?
          ??? Access Control
          ?
          ??? Monitoring / Activity Logs
```

---

## 3. Services Required

| Azure Service | Purpose |
| :--- | :--- |
| **Resource Group** | Organizes all resources used in the project |
| **Azure Key Vault** | Securely stores and manages the customer-managed encryption key |
| **Customer-Managed Key** | Encryption key controlled by the project owner |
| **Disk Encryption Set** | Connects the Key Vault key with Azure Managed Disks |
| **Azure Virtual Machine** | Provides the compute environment whose disks will be protected |
| **Azure Managed Disks** | Stores the VM's OS and optional data disks |
| **Managed Identity** | Allows the Disk Encryption Set to access the Key Vault key securely |
| **Azure Monitor / Activity Log** | Monitors and audits encryption, key, and resource-related activities |

---

## 4. Verification & Security Experiments

### 4.1 Encryption Verification Output
```json
{
  "DiskEncryptionSet": "/subscriptions/9a97bd8c-a261-4a91-81df-22880997e84e/resourceGroups/RG-DISK-ENCRYPTION/providers/Microsoft.Compute/diskEncryptionSets/des-disk-cmk",
  "DiskName": "vm-encrypted_OsDisk_1_f7bc4d5d7a334eb8a92eec80d954bc12",
  "EncryptionType": "EncryptionAtRestWithCustomerKey"
}
```

### 4.2 Security Experiments Conducted
* **Experiment A ? Key Rotation:** Generated a secondary RSA key version (`v2`) in Key Vault. Enabled `RotationToLatestKeyVersionEnabled: True` on the Disk Encryption Set to allow automatic zero-downtime key rotation.
* **Experiment B ? Key Disabling & Deletion Risk:** Disabled the customer-managed key (`enabled: false`) and deallocated the VM. Upon attempting to restart, Azure Compute blocked initialization due to lack of key unwrapping access. Re-enabling the key immediately restored VM functionality without data loss.

---

## 5. Security Audit Log (Azure Monitor)

Tamper-evident activity logs proving non-repudiation and governance:

| Event Time (UTC) | Identity (Caller) | Operation | Status |
| :--- | :--- | :--- | :--- |
| `2026-09-21T14:16:58Z` | `2400032815@kluniversity.in` | Deallocate Virtual Machine | Started |
| `2026-09-21T14:12:19Z` | `2400032815@kluniversity.in` | Update Key Vault | Succeeded |
| `2026-09-21T14:12:12Z` | `2400032815@kluniversity.in` | Create or Update Virtual Machine | Succeeded |
| `2026-09-21T14:11:48Z` | `des-disk-cmk (ServicePrincipal)`| Create or Update Disk | Accepted |
| `2026-09-21T14:04:49Z` | `2400032815@kluniversity.in` | Add Role Assignment (DES to KV) | Succeeded |
