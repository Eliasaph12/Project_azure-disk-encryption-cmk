# Architecture Deep Dive

## Security Principles
1. **Cryptographic Sovereignty**: Keys generated and managed in Key Vault with hardware security module (HSM) backing.
2. **Zero-Trust Privilege Separation**: Storage infrastructure uses Azure Managed Identity; no service principal client secrets are stored or transmitted.
3. **Data Loss Protection**: Purge Protection ensures a mandatory 90-day retention lock on deleted cryptographic material.
4. **Envelope Encryption**: Azure Storage generates an AES-256 Data Encryption Key (DEK) which is wrapped by an RSA 2048 Key Encryption Key (KEK).
