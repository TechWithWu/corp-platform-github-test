# Azure Platform Connectivity Hub (Infrastructure as Code)

This repository provisions and manages the centralized **Connectivity Hub** for the Corporate Platform Azure Landing Zone (ALZ) using Microsoft's official Azure Verified Modules (**AVM**):
- **Hub & Spoke Pattern**: `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm`
- **Resource Group**: `Azure/avm-res-resources-resourcegroup/azurerm`
- **Peering Submodule**: `Azure/avm-res-network-virtualnetwork/azurerm//modules/peering`

---

## Architecture Overview

The Connectivity Hub serves as the central network transit, inspection, and security foundation for all corporate workloads:
- **Centralized Hub VNet**: Central routing hub (`10.0.0.0/16`) deployed in the connectivity subscription.
- **Azure Firewall (Basic SKU)**: Cost-effective centralized egress and ingress firewall inspection.
  - Basic SKU requires dedicated `/26` subnets: `AzureFirewallSubnet` (`10.0.100.0/26`) and `AzureFirewallManagementSubnet` (`10.0.101.0/26`).
  - Dual data-plane Public IPs (for SNAT & DNAT) + dedicated management Public IP.
  - Centralized firewall policy with baseline outbound network rules and Microsoft/Azure updates application rules.
- **No VPN Gateway**: VPN / Gateway components have been removed to maintain a lean, pure firewall hub architecture.
- **Decoupled Spoke VNets**: Spoke virtual networks reside in separate application subscriptions and repositories. The hub does not manage spoke lifecycles.
- **Configurable Spoke Peering Submodule**: As spokes are provisioned, adding a row to `config/spoke_vnets.csv` automatically establishes high-bandwidth, cross-subscription VNet peering to the Hub.

---

## Directory Structure

```text
infraascode/
├── config/
│   ├── README.md                   # Instructions for spoke registration
│   └── spoke_vnets.csv             # Configurable CSV table of peered spoke VNets
├── env/
│   ├── dev/
│   │   ├── backend.hcl             # Remote state backend configuration for Dev
│   │   └── terraform.tfvars        # Environment input variables for Dev
│   └── prod/
│       ├── backend.hcl             # Remote state backend configuration for Prod
│       └── terraform.tfvars        # Environment input variables for Prod
├── modules/
│   └── spoke_peering/              # Submodule for managing Hub <-> Spoke peerings
│       ├── main.tf                 # AVM VNet peering module instantiation
│       ├── outputs.tf              # Peering IDs and names outputs
│       ├── variables.tf            # Submodule inputs (hub ID & spoke map)
│       └── version.tf              # Provider constraints for peering module
├── .checkov.yaml                   # Policy-as-code and static analysis rules
├── data.tf                         # Client configurations and data sources
├── locals.tf                       # Local computations, tagging, and CSV parser
├── main.tf                         # Root orchestration & hub module
├── outputs.tf                      # Hub VNet ID, Firewall private/public IPs
├── provider.tf                     # azurerm & azapi provider configurations (OIDC)
├── variables.tf                    # Variable definitions, types, and validations
└── version.tf                      # Terraform and provider version constraints
```

---

## Managing Spoke Virtual Network Peerings

Spoke VNets are hosted in other individual subscriptions and repositories. To establish a peering connection with this Hub:

1. **Deploy your Spoke VNet** in its respective subscription repository.
2. Open `infraascode/config/spoke_vnets.csv`.
3. Add a row containing the unique spoke name and the full Azure Resource ID of the target VNet:

```csv
spoke_name,remote_virtual_network_id,allow_forwarded_traffic,allow_gateway_transit,use_remote_gateways,allow_virtual_network_access
spoke-finance,/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-finance/providers/Microsoft.Network/virtualNetworks/vnet-finance,true,false,false,true
```

4. Run `terraform plan` and `terraform apply`. The submodule (`modules/spoke_peering`) will automatically create the peering!

> **Note**: Comment lines starting with `#` and empty placeholder entries are safely ignored by the CSV parser.

---

## Routing Spoke Traffic via Central Firewall

In the Spoke subscription repositories, workloads should route their outbound internet traffic (`0.0.0.0/0`) through this Hub's Azure Firewall.

Retrieve the Firewall private IP from the Terraform output:
```bash
terraform output -raw firewall_private_ip
```

Then create a User-Defined Route (UDR) in the spoke's route table:
- **Prefix**: `0.0.0.0/0`
- **Next Hop Type**: `VirtualAppliance`
- **Next Hop IP Address**: `<firewall_private_ip>`

---

## Deployment Instructions

### Prerequisites
- Terraform `>= 1.9, < 2.0`
- Azure CLI `>= 2.50.0`
- Contributor access to the Connectivity Subscription

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
| `firewall_subnet_cidr` | `string` | `"10.0.100.0/26"` | Subnet CIDR for `AzureFirewallSubnet` (/26). |
| `firewall_management_subnet_cidr` | `string` | `"10.0.101.0/26"` | Subnet CIDR for `AzureFirewallManagementSubnet` (/26). |
| `hub_shared_subnet_cidr` | `string` | `"10.0.1.0/24"` | Shared services subnet in the Hub. |

---

## Outputs

| Name | Description |
| :--- | :--- |
| `hub_vnet_id` | Full Resource ID of the central Hub VNet. |
| `firewall_private_ip` | Private IP of Azure Firewall (used as next-hop UDR for spokes). |
| `firewall_public_ips` | Public IPs allocated to the Firewall. |
| `hub_route_table_id` | Resource ID of the Hub user subnets route table. |
| `peered_spoke_vnets` | List of active spoke VNets peered from `config/spoke_vnets.csv`. |
