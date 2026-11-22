# Spoke Virtual Networks Configuration Table

This folder contains the configuration CSV table used by the Connectivity Hub Terraform configuration to dynamically manage Hub-side virtual network peering connections to Spoke Virtual Networks located across separate subscriptions.

---

## Least-Privilege Peering Architecture

In Azure, a complete VNet peering consists of two reciprocal peering resources:
1. **Hub-to-Spoke Peering**: Created by this Connectivity Hub repository in the Hub subscription using native `azurerm_virtual_network_peering`.
2. **Spoke-to-Hub Peering**: Created by the Spoke repository in the Spoke subscription using its own local pipeline credentials.

Once both sides establish their respective peering resource, Azure automatically transitions the peering status to **`Connected`**.

This decoupled architecture ensures that the Hub CI/CD pipeline account **never needs write access or network contributor privileges in the spoke subscriptions**, enforcing strict least-privilege security boundaries.

---

## How to Register a Spoke VNet in the Hub

When a Spoke VNet is created in its dedicated subscription repository:

1. Obtain the full Azure Resource ID of the remote Spoke VNet:
   ```text
   /subscriptions/<SPOKE_SUBSCRIPTION_ID>/resourceGroups/<SPOKE_RG_NAME>/providers/Microsoft.Network/virtualNetworks/<SPOKE_VNET_NAME>
   ```

2. Add a new row to `spoke_vnets.csv`:
   ```csv
   spoke_name,remote_virtual_network_id,hub_vnet_key,allow_forwarded_traffic,allow_gateway_transit,use_remote_gateways,allow_virtual_network_access
   spoke-finance,/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-finance-prod/providers/Microsoft.Network/virtualNetworks/vnet-finance,primary,true,false,false,true
   spoke-eshop,/subscriptions/66666666-7777-8888-9999-000000000000/resourceGroups/rg-eshop-prod/providers/Microsoft.Network/virtualNetworks/vnet-eshop,primary,true,false,false,true
   ```

3. Run Terraform in the Connectivity Hub:
   ```bash
   terraform plan -var-file=env/prod/terraform.tfvars
   terraform apply -var-file=env/prod/terraform.tfvars
   ```

4. In the Spoke subscription repository, configure the reciprocal Spoke-to-Hub peering using the Hub's Resource ID (available via `terraform output -json hub_vnets`).

---

## CSV Column Specifications

| Column | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `spoke_name` | string | (required) | Unique identifier for the spoke (used in Terraform resource keys and peering name). |
| `remote_virtual_network_id` | string | (required) | Full Azure Resource ID of the target Spoke VNet. |
| `hub_vnet_key` | string | `"primary"` | Target Hub VNet key defined in `local.config.tf` (e.g. `primary`, `secondary`). Defaults to the first Hub VNet if omitted. |
| `allow_forwarded_traffic` | boolean | `true` | Allows forwarded traffic from outside the Hub VNet to be accepted by the peering. |
| `allow_gateway_transit` | boolean | `false` | Specifies whether the Hub gateway can be used by the remote VNet. |
| `use_remote_gateways` | boolean | `false` | Specifies whether the Hub will use remote gateways in the spoke. |
| `allow_virtual_network_access` | boolean | `true` | Permits virtual network address space communication across the peering. |

> **Note**: Rows starting with `#` and empty placeholder entries are safely ignored by the CSV parser in `locals.tf`.
