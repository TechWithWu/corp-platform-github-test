# Azure Platform Connectivity Hub (Infrastructure as Code)

This repository provisions and manages the centralized **Connectivity Hub** for the Corporate Platform Azure Landing Zone (ALZ) using Microsoft's official Azure Verified Modules (**AVM**):
- **Resource Group**: `Azure/avm-res-resources-resourcegroup/azurerm`
- **Virtual Network Module**: `Azure/avm-res-network-virtualnetwork/azurerm`
- **Native Peering Submodule**: `./modules/spoke_peering` (powered by `azurerm_virtual_network_peering`)

---

## Key Design Principles

1. **Extendable Hub VNets via `local.config.tf`**:
   - Centralizes the definition of all Hub Virtual Networks in a dedicated configuration file (`local.config.tf`).
   - Adding a new Hub VNet (e.g. secondary region, management hub, transit hub) is as simple as adding an entry to the `hub_vnets` map in `local.config.tf`.
   - **Custom Subnets per Hub**: Each Hub VNet configures its own unique subnets, address prefixes, and names independently.
2. **Dynamic Spoke Peering via `config/spoke_vnets.csv`**:
   - Spoke virtual networks reside in separate individual subscriptions and application repositories.
   - Adding a row to `config/spoke_vnets.csv` dynamically establishes the Hub-to-Spoke peering connection.
3. **Least-Privilege Cross-Subscription Peering**:
   - Uses native `azurerm_virtual_network_peering` so the Hub pipeline only manages its own side (`peer-hub-to-<spoke>`).
   - The Hub pipeline requires **no write or network contributor permissions** inside any spoke subscription.
   - Spoke pipelines independently deploy their reciprocal `peer-<spoke>-to-hub` peering.

---

## 1. How to Add or Modify Hub VNets (`local.config.tf`)

Open `infraascode/local.config.tf` to customize existing Hub VNets or add new ones:

```hcl
locals {
  hub_vnets = {
    # Primary Hub
    "primary" = {
      name          = "vnet-hub-centralus-001"
      location      = "centralus"
      address_space = ["10.0.0.0/16"]

      # Subnets for this Hub VNet
      subnets = {
        default = {
          name             = "snet-default"
          address_prefixes = ["10.0.1.0/24"]
        }
        shared = {
          name             = "snet-shared-services"
          address_prefixes = ["10.0.2.0/24"]
        }
      }
    }

    # Example: Adding a secondary regional Hub
    "secondary" = {
      name          = "vnet-hub-centralus-001"
      location      = "centralus"
      address_space = ["10.10.0.0/16"]

      subnets = {
        default = {
          name             = "snet-default"
          address_prefixes = ["10.10.1.0/24"]
        }
        management = {
          name             = "snet-mgmt"
          address_prefixes = ["10.10.2.0/24"]
        }
      }
    }
  }
}
```

Terraform automatically iterates over `local.hub_vnets` via `for_each` in `main.tf` to deploy each virtual network and its dedicated subnets.

---

## 2. How to Register a Spoke VNet (`config/spoke_vnets.csv`)

When a new Spoke VNet is deployed in another subscription repository:

1. Obtain the target Spoke VNet Resource ID:
   ```text
   /subscriptions/<SPOKE_SUBSCRIPTION_ID>/resourceGroups/<SPOKE_RG_NAME>/providers/Microsoft.Network/virtualNetworks/<SPOKE_VNET_NAME>
   ```

2. Add a row to `infraascode/config/spoke_vnets.csv`:
   ```csv
   spoke_name,remote_virtual_network_id,hub_vnet_key,allow_forwarded_traffic,allow_gateway_transit,use_remote_gateways,allow_virtual_network_access
   spoke-finance,/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-finance/providers/Microsoft.Network/virtualNetworks/vnet-finance,primary,true,false,false,true
   spoke-eshop,/subscriptions/66666666-7777-8888-9999-000000000000/resourceGroups/rg-eshop/providers/Microsoft.Network/virtualNetworks/vnet-eshop,primary,true,false,false,true
   ```

3. Run `terraform plan` and `terraform apply`. The submodule (`modules/spoke_peering`) will provision the Hub-side peering.
4. In the Spoke subscription repository, configure the reciprocal Spoke-to-Hub peering targeting the Hub VNet ID (obtained via `terraform output -json hub_vnets`).

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
│       ├── variables.tf            # Submodule inputs (hub map & spoke map)
│       └── version.tf              # Provider constraints for peering module
├── .checkov.yaml                   # Policy-as-code and static analysis rules
├── data.tf                         # Client configurations and data sources
├── local.config.tf                 # EXTENDABLE: Central definition of Hub VNets & subnets
├── locals.tf                       # Local computations, tagging, and CSV parser
├── main.tf                         # Root orchestration & hub loop
├── outputs.tf                      # Hub VNet IDs, details, and peered spokes
├── provider.tf                     # azurerm & azapi provider configurations
├── variables.tf                    # Variable definitions, types, and validations
└── version.tf                      # Terraform and provider version constraints
```

---

## Deployment Instructions

### Prerequisites
- Terraform `>= 1.9, < 2.0`
- Azure CLI `>= 2.50.0`
- Contributor access to the Connectivity Subscription

### 1. Development Deployment
```bash
cd infraascode

# Initialize remote backend for Dev (or local state if backend is commented)
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

## Outputs

| Name | Description |
| :--- | :--- |
| `resource_group_id` | Resource ID of the Connectivity Hub resource group. |
| `resource_group_name` | Name of the Connectivity Hub resource group. |
| `hub_vnets` | Map of all provisioned Hub VNets with their IDs, names, locations, and subnets. |
| `peered_spoke_vnets` | List of active spoke VNets configured for Hub-side peering. |
