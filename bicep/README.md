# Enterprise Azure Bicep Infrastructure & Deployment Stacks

This directory contains modular, enterprise-grade Azure Bicep templates orchestrated via **Azure Deployment Stacks** at the **subscription scope**. The platform follows the Microsoft Cloud Adoption Framework (CAF) and Azure Well-Architected Framework (WAF), partitioning resources across **three dedicated resource groups** by lifecycle and security boundaries, and leveraging **Azure Verified Modules (AVM)** for standardized governance.

---

## 🏛️ Multi-Resource Group Architecture

The deployment is decoupled into three dedicated Resource Groups, each with its own location parameterization:

```
+---------------------------------------------------------------------------------------------------------+
|                                    SUBSCRIPTION DEPLOYMENT STACK                                         |
|                                       (bicep/main.bicep)                                                |
+---------------------------------------------------------------------------------------------------------+
       |                                           |                                           |
       v                                           v                                           v
+-----------------------------+     +-----------------------------+     +-----------------------------+
|    Security Resource Group  |     |   Persistence Resource Group|     |   Application & Networking  |
|       (rg-kv-<seed>)        |     |       (rg-data-<seed>)      |     |       (rg-app-<seed>)       |
|                             |     |                             |     |                             |
|  - AVM Key Vault (0.11.1)   |     |  - AVM SQL Server (0.21.3)  |     |  - Spoke VNet (10.x.0.0/16) |
|    * Secrets & Encryption   |     |  - Azure SQL Database       |     |  - Subnets: web, api, pe    |
|    * RBAC Authorization     |     |    * DTU/vCore Capacity     |     |  - NSG & Hub Peering        |
|    * Purge Protection       |     |    * Collation & Max Size   |     |  - AVM App Service Plan     |
|  - Key Vault Private Endpt  |     |  - SQL Private Endpoint     |     |  - AVM API App (EasyAuth)   |
|  - Private DNS: vaultcore   |     |  - Private DNS: sqlServer   |     |  - AVM Web App (EasyAuth)   |
|                             |     |                             |     |  - API Private Endpoint     |
|                             |     |                             |     |  - Private DNS: azurewebsites|
+-----------------------------+     +-----------------------------+     +-----------------------------+
```

### 1. Dedicated Resource Group Breakdown

| Resource Group | Default Name | Location Parameter | Purpose & Components |
| :--- | :--- | :--- | :--- |
| **Key Vault** | `rg-kv-${workload}-${env}-${index}` | `keyVaultLocation` | Security & secrets tier: AVM Key Vault, Entra ID app credentials, encryption keys, and private endpoint. |
| **Database** | `rg-data-${workload}-${env}-${index}` | `databaseLocation` | Persistence tier: AVM Azure SQL Logical Server (Entra ID only), SQL Database with custom capacity/size, and private endpoint. |
| **App & Network** | `rg-app-${workload}-${env}-${index}` | `appServiceLocation` | Compute & connectivity tier: Spoke VNet, NSG, Hub peering, AVM Linux App Service Plan, AVM Web and API Apps, and API private endpoint. |

---

## 📦 Azure Verified Modules (AVM) Standard

All core resources leverage official, production-ready Microsoft Azure Verified Modules sourced from the public registry (`br/public`):

- **Key Vault**: `br/public:avm/res/key-vault/vault:0.11.1`
- **SQL Logical Server**: `br/public:avm/res/sql/server:0.21.3`
- **App Service Plan**: `br/public:avm/res/web/serverfarm:0.4.1`
- **Web & API App Services**: `br/public:avm/res/web/site:0.15.1`

---

## 📁 File Structure

```
bicep/
├── bicepconfig.json            # Bicep compiler & linter configuration
├── main.bicep                  # Subscription-scoped deployment stack entry point (< 150 lines)
├── main.dev.bicepparam         # Development environment parameters (locations, SKUs, capacities)
├── main.prod.bicepparam        # Production environment parameters (locations, SKUs, capacities)
├── README.md                   # Architecture and operations documentation
└── modules/
    ├── appTier.bicep           # App service tier orchestrator (AVM Plan + Sites + PE + DNS)
    ├── databaseTier.bicep      # Data tier orchestrator (AVM SQL Server + DB + PE + DNS)
    ├── keyVaultTier.bicep      # Security tier orchestrator (AVM Vault + Secrets + PE + DNS)
    ├── networkTier.bicep       # Spoke VNet, subnets, and Hub peering orchestrator
    ├── appService.bicep        # AVM wrapper for App Service with EasyAuth v2
    ├── appServicePlan.bicep    # AVM wrapper for Linux App Service Plan
    ├── keyVault.bicep          # AVM wrapper for Key Vault & secrets
    ├── sqlServer.bicep         # AVM wrapper for Azure SQL Server
    ├── sqlDatabase.bicep       # Azure SQL Database with configurable SKU, tier, and size
    ├── network.bicep           # Spoke Virtual Network and Network Security Group
    ├── privateDns.bicep        # Private DNS Zones with VNet link auto-registration
    └── privateEndpoint.bicep   # Private Endpoints with DNS Zone Group registration
```

---

## ⚙️ Environment Configurations (`.bicepparam`)

Both `main.prod.bicepparam` and `main.dev.bicepparam` allow independent control over locations, SKUs, capacities, and network spaces:

| Configuration Area | Production (`main.prod.bicepparam`) | Development (`main.dev.bicepparam`) |
| :--- | :--- | :--- |
| **Environment** | `prod` | `dev` |
| **Locations** | `westus2` (KeyVault, DB, App) | `centralus` (KeyVault, DB, App) |
| **Key Vault SKU** | `standard` (Soft delete 90 days, Purge Protection `true`) | `standard` (Soft delete 7 days, Purge Protection `false`) |
| **SQL Database SKU** | `S0` (Standard, 10 DTUs, 250 GB) | `Basic` (Basic, 5 DTUs, 32 GB) |
| **App Service Plan SKU** | `B1` (Basic, 1 worker) | `B1` (Basic, 1 worker) |
| **Spoke VNet CIDR** | `10.1.0.0/16` | `10.2.0.0/16` |
| **Hub Connection** | `rg-connectivity-hub-prod` | `rg-connectivity-hub-dev` |
| **Tags** | `Environment: Production`, `DataClassification: Confidential` | `Environment: Development`, `AutoShutdown: True` |

---

## 🚀 Deployment & Operations

### 1. Validate Template
```bash
az bicep build --file bicep/main.bicep
```

### 2. Preview Deployment Stack (What-If)
```bash
az stack-whatif sub create \
  --name "wi-finance-prod" \
  --location "westus2" \
  --template-file "bicep/main.bicep" \
  --parameters "bicep/main.prod.bicepparam" \
  --action-on-unmanage "deleteAll" \
  --deny-settings-mode "denyWriteAndDelete" \
  --validation-level "ProviderNoRbac"
```

### 3. Deploy Stack (Production)
```bash
az stack sub create \
  --name "financeDeploymentStack" \
  --location "westus2" \
  --template-file "bicep/main.bicep" \
  --parameters "bicep/main.prod.bicepparam" \
  --action-on-unmanage "deleteAll" \
  --deny-settings-mode "denyWriteAndDelete" \
  --deny-settings-apply-to-child-scopes \
  --yes
```

### 4. Teardown Stack
```bash
az stack sub delete --name "financeDeploymentStack" --action-on-unmanage "deleteAll" --yes
```
