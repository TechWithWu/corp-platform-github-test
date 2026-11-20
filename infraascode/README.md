# Azure Platform Connectivity Hub (Infrastructure as Code)

This repository provisions and manages the centralized **Connectivity Hub** for the Corporate Platform Azure Landing Zone (ALZ) using Microsoft's official Azure Verified Modules (**AVM**):
- **Hub & Spoke Pattern**: `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm`
- **Resource Group**: `Azure/avm-res-resources-resourcegroup/azurerm`
- **Native Peering Submodule**: `./modules/spoke_peering` (powered by `azurerm_virtual_network_peering`)

---

## Architecture Overview

The Connectivity Hub serves as the central network transit backbone for the corporate cloud platform:
- **Centralized Hub VNet**: Deployed in the Connectivity subscription (`10.0.0.0/16`), providing shared connectivity and management subnets.
- **Lean Network Transit Foundation**: Firewall and VPN Gateway components are removed, keeping the hub lightweight, cost-effective, and focused on core routing.
- **Decoupled Spoke VNets**: Spoke virtual networks reside in separate individual subscriptions and application repositories.
- **Configurable Hub-Side Peering**: A configurable CSV table (`config/spoke_vnets.csv`) dynamically establishes Hub-to-Spoke peerings as new spokes are deployed across subscriptions.

---

## Least-Privilege Cross-Subscription Peering Model

In enterprise multi-subscription architectures, granting a central pipeline service principal write access across multiple independent spoke subscriptions introduces severe security and blast-radius risks.

To enforce the **Principle of Least Privilege**:
1. **This Hub Repository (Hub-Side Only)**:
   - Uses the native `azurerm_virtual_network_peering` resource inside `./modules/spoke_peering`.
   - Provisions only the local peering from the Hub VNet to the remote Spoke VNet (`peer-hub-to-<spoke>`).
   - Requires permissions **strictly within the Connectivity Subscription**; it does not require contributor or write access in any spoke subscription.
2. **Spoke Repositories (Spoke-Side Only)**:
   - Spoke pipelines independently deploy their own reciprocal `azurerm_virtual_network_peering` resource from the Spoke VNet to the Hub (`peer-<spoke>-to-hub`) using the Hub VNet Resource ID (`terraform output -raw hub_vnet_id`).
3. **Automatic Connection**:
   - Once both halves of the peering are established, Azure automatically marks the peering status as **`Connected`**, completing bidirectional communication.

---

## Directory Structure

```text
infraascode/
├── config/
│   ├── README.md                   # Instructions for spoke registration & architecture
│   └── spoke_vnets.csv             # Configurable CSV table of peered spoke VNets
├── env/
│   ├── dev/
│   │   ├── backend.hcl             # Remote state backend configuration for Dev
│   │   └── terraform.tfvars        # Environment input variables for Dev
│   └── prod/
│       ├── backend.hcl             # Remote state backend configuration for Prod
│       └── terraform.tfvars        # Environment input variables for Prod
├── modules/
│   └── spoke_peering/              # Submodule for managing Hub-side VNet peerings
│       ├── main.tf                 # Native azurerm_virtual_network_peering resource
│       ├── outputs.tf              # Peering IDs and spoke names outputs
│       ├── variables.tf            # Submodule inputs (hub name, RG, spoke map)
│       └── version.tf              # Provider constraints for peering module
├── .checkov.yaml                   # Policy-as-code and static analysis rules
├── data.tf                         # Client configurations and data sources
├── locals.tf                       # Local computations, tagging, and CSV parser
├── main.tf                         # Root orchestration & hub module
├── outputs.tf                      # Hub VNet ID, Hub VNet Name, peered spokes
├── provider.tf                     # azurerm & azapi provider configurations (OIDC)
├── variables.tf                    # Variable definitions, types, and validations
└── version.tf                      # Terraform and provider version constraints
```

---

## Managing Spoke Virtual Network Peerings

Spoke VNets are hosted in separate subscription repositories. To establish a peering connection with this Hub:

1. **Deploy your Spoke VNet** in its respective subscription repository.
2. Open `infraascode/config/spoke_vnets.csv`.
3. Add a row containing the unique spoke name and the full Azure Resource ID of the target VNet:

```csv
spoke_name,remote_virtual_network_id,allow_forwarded_traffic,allow_gateway_transit,use_remote_gateways,allow_virtual_network_access
spoke-finance,/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-finance-prod/providers/Microsoft.Network/virtualNetworks/vnet-finance,true,false,false,true
spoke-eshop,/subscriptions/66666666-7777-8888-9999-000000000000/resourceGroups/rg-eshop-prod/providers/Microsoft.Network/virtualNetworks/vnet-eshop,true,false,false,true
```

4. Run `terraform plan` and `terraform apply`. The submodule (`modules/spoke_peering`) will provision the Hub-side peering.
5. In the Spoke subscription repository, configure the reciprocal Spoke-to-Hub peering targeting the Hub VNet ID (obtained via `terraform output -raw hub_vnet_id`).

> **Note**: Comment lines starting with `#` and empty placeholder entries are safely ignored by the CSV parser in `locals.tf`.

---

## Deployment Instructions

### Prerequisites
- Terraform `>= 1.9, < 2.0`
- Azure CLI `>= 2.50.0`
- Contributor access to the Connectivity Subscription (OIDC enabled)

### 1. Development Deployment
```bash
cd infraascode

# Initialize remote backend for Dev
terraform init -backend-config=env/dev/backend.hcl

# Preview changes
terraform plan -var-file=env/dev/terraform.tfvars

# Apply infrastructure
terraform apply -var-file=env/dev/terraform.tfvars
```

### 2. Production Deployment
```bash
cd infraascode

# Switch backend to Prod
terraform init -reconfigure -backend-config=env/prod/backend.hcl

# Preview changes
terraform plan -var-file=env/prod/terraform.tfvars

# Apply infrastructure
terraform apply -var-file=env/prod/terraform.tfvars
```

---

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `environment` | `string` | `"dev"` | Target environment tier (`dev`, `prod`, etc.). |
| `location` | `string` | `"swedencentral"` | Azure region for Connectivity Hub resources. |
| `enable_telemetry` | `bool` | `false` | Enable AVM telemetry via `modtm`. |
| `hub_vnet_name` | `string` | `"vnet-platform-connectivity"` | Name of the central Hub VNet. |
| `hub_vnet_cidr` | `string` | `"10.0.0.0/16"` | Address space for the Hub VNet. |
| `hub_shared_subnet_cidr` | `string` | `"10.0.1.0/24"` | Shared services subnet in the Hub. |
| `resource_group_name` | `string` | `""` | Optional custom name for the Hub resource group. |
| `custom_tags` | `map(string)` | `{}` | Additional tags to apply to all resources. |

---

## Outputs

| Name | Description |
| :--- | :--- |
| `resource_group_id` | Resource ID of the Connectivity Hub resource group. |
| `resource_group_name` | Name of the Connectivity Hub resource group. |
| `resource_group_location` | Azure region of the Connectivity Hub. |
| `hub_vnet_id` | Full Resource ID of the centralized Hub VNet. |
| `hub_vnet_name` | Name of the centralized Hub VNet. |
| `peered_spoke_vnets` | List of active spoke VNets configured for Hub-side peering. |
