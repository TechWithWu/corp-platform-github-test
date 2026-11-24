# Enterprise Azure Bicep Infrastructure & Deployment Stacks

This directory contains modular, enterprise-grade Azure Bicep templates orchestrated via **Azure Deployment Stacks** at the **subscription scope**. It provisions a secure, multi-tier corporate workload platform following Microsoft Cloud Adoption Framework (CAF) and Azure Well-Architected Framework (WAF) best practices.

---

## 🏛️ Architecture Overview

The solution provisions an isolated, zero-trust spoke workload connected to a centralized connectivity hub:

```
                  +----------------------------------------------+
                  |            Hub Connectivity VNet             |
                  |     (vnet-platform-connectivity-prod)       |
                  +----------------------+-----------------------+
                                         |
                            VNet Peering (Spoke <-> Hub)
                                         |
                  +----------------------v-----------------------+
                  |         Spoke VNet (10.x.0.0/16)             |
                  |  +----------------------------------------+  |
                  |  | snet-web (10.x.1.0/24)                 |  |
                  |  | -> Web App Service (VNet integrated)   |  |
                  |  +----------------------------------------+  |
                  |  +----------------------------------------+  |
                  |  | snet-api (10.x.2.0/24)                 |  |
                  |  | -> API App Service (VNet integrated)   |  |
                  |  +----------------------------------------+  |
                  |  +----------------------------------------+  |
                  |  | snet-pe (10.x.3.0/24)                  |  |
                  |  | -> Private Endpoint: API App Service   |  |
                  |  | -> Private Endpoint: Azure SQL Server  |  |
                  |  +----------------------------------------+  |
                  |                                              |
                  |  +----------------------------------------+  |
                  |  | Private DNS Zones:                     |  |
                  |  | - privatelink.azurewebsites.net        |  |
                  |  | - privatelink.database.windows.net     |  |
                  |  +----------------------------------------+  |
                  +----------------------------------------------+
```

### Security & Governance Baseline
- **Azure Deployment Stacks**: All resources are managed as a single transactional unit with **Deny Settings** (`denyWriteAndDelete`) preventing configuration drift or unauthorized manual changes.
- **Identity-First Security**: Microsoft Entra ID (Active Directory Default) authentication is enforced on Azure SQL Server—local SQL passwords are completely disabled.
- **Easy Auth v2**: App Services are secured with Microsoft Entra ID authentication (`authsettingsV2`). Unauthenticated access returns HTTP 401 for APIs or redirects to corporate SSO for web apps.
- **Private Link & DNS**: Inter-service traffic (Web to API, API to SQL) travels strictly over private IP addresses via Azure Private Endpoints and Private DNS Zones.
- **Zero Public Ingress**: Public network access is disabled on the Azure SQL database.
- **VNet Regional Integration**: Both Web and API App Services route all outbound traffic through dedicated delegated subnets with NSG boundaries.

---

## 📁 Directory Structure

```
bicep/
├── bicepconfig.json            # Bicep compiler & linter configuration
├── main.bicep                  # Subscription-scoped deployment stack entry point
├── main.dev.bicepparam         # Development environment parameters
├── main.prod.bicepparam        # Production environment parameters
├── README.md                   # Architecture and operations documentation
└── modules/
    ├── appService.bicep        # Linux App Service with EasyAuth v2 & VNet integration
    ├── appServicePlan.bicep    # Linux App Service Plan (App Service Farms)
    ├── network.bicep           # Spoke VNet, NSG, and Hub-to-Spoke peering
    ├── privateDns.bicep        # Private DNS Zones and VNet auto-linking
    ├── privateEndpoint.bicep   # Private Endpoints with DNS Zone Group registration
    ├── sqlDatabase.bicep       # Azure SQL Database with custom collation & DTU/vCore
    ├── sqlServer.bicep         # Azure SQL Logical Server with Entra ID admin
    └── vnet.bicep              # Standalone virtual network module
```

---

## ⚙️ Environments & Parameters

Each environment maintains its own dedicated parameter file (`.bicepparam`) referencing `main.bicep`:

| Parameter | Dev (`main.dev.bicepparam`) | Prod (`main.prod.bicepparam`) |
| :--- | :--- | :--- |
| `environment` | `dev` | `prod` |
| `vnetAddressPrefix` | `10.2.0.0/16` | `10.1.0.0/16` |
| `appServicePlanSku` | `B1` | `B1` (or `P1v3`) |
| `sqlDatabaseName` | `sqldb-finance-dev` | `sqldb-finance-prod` |
| `hubResourceGroupName`| `rg-connectivity-hub-dev` | `rg-connectivity-hub-prod` |
| `hubVnetName` | `vnet-platform-connectivity-dev` | `vnet-platform-connectivity-prod` |
| `tags.Environment` | `Development` | `Production` |
| `tags.DataClassification`| `Internal` | `Confidential` |

---

## 🚀 Local CLI Usage

### 1. Validate & Compile Bicep
```bash
az bicep build --file bicep/main.bicep
```

### 2. Preview Changes (What-If)
```bash
az stack-whatif sub create \
  --name "wi-finance-prod-preview" \
  --location "centralus" \
  --template-file "bicep/main.bicep" \
  --parameters "bicep/main.prod.bicepparam" \
  --action-on-unmanage "deleteAll" \
  --deny-settings-mode "denyWriteAndDelete" \
  --deny-settings-apply-to-child-scopes \
  --deny-settings-excluded-principals "<PIPELINE_SP_OBJECT_ID>" \
  --validation-level "ProviderNoRbac"
```

### 3. Deploy via Deployment Stack
```bash
az stack sub create \
  --name "financeDeploymentStack" \
  --location "centralus" \
  --template-file "bicep/main.bicep" \
  --parameters "bicep/main.prod.bicepparam" \
  --action-on-unmanage "deleteAll" \
  --deny-settings-mode "denyWriteAndDelete" \
  --deny-settings-apply-to-child-scopes \
  --deny-settings-excluded-principals "<PIPELINE_SP_OBJECT_ID>" \
  --yes
```

### 4. Inspect or Delete Deployment Stack
```bash
# View stack status and managed resources
az stack sub show --name "financeDeploymentStack"

# Delete stack and remove managed resources (clean teardown)
az stack sub delete --name "financeDeploymentStack" --action-on-unmanage "deleteAll" --yes
```

---

## 🔒 CI/CD Workflow Integration

- **Pull Request Automation (`bicep-stack-pr-whatif.yml`)**:
  - Automatically runs when a PR targets the `main` branch.
  - Generates a timestamped What-If execution and posts a formatted review comment with direct HTTPS links to Azure Portal resources and a base64 comparison payload.
- **Deployment Automation (`bicep-stack-main-deploy.yml`)**:
  - Automatically runs on push to `main` or via manual `workflow_dispatch`.
  - Re-runs the What-If command, compares against the PR What-If result, highlights differences, uploads full run artifacts, and deploys the stack to production.
