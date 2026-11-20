# Spoke Virtual Networks Configuration Table

This folder contains the configuration CSV table used by the Connectivity Hub Terraform configuration to dynamically manage peering connections to Spoke Virtual Networks located across different subscriptions.

## How to Add a Spoke VNet

When a Spoke VNet is created in its dedicated subscription repository:

1. Obtain the full Azure Resource ID of the remote Spoke VNet.
   Example:
   `/subscriptions/<SPOKE_SUBSCRIPTION_ID>/resourceGroups/<SPOKE_RG_NAME>/providers/Microsoft.Network/virtualNetworks/<SPOKE_VNET_NAME>`

2. Add a new row to `spoke_vnets.csv`:

   ```csv
   spoke_name,remote_virtual_network_id,allow_forwarded_traffic,allow_gateway_transit,use_remote_gateways,allow_virtual_network_access
   spoke-finance,/subscriptions/11111111-2222-3333-4444-555555555555/resourceGroups/rg-finance-prod/providers/Microsoft.Network/virtualNetworks/vnet-finance,true,false,false,true
   spoke-eshop,/subscriptions/66666666-7777-8888-9999-000000000000/resourceGroups/rg-eshop-prod/providers/Microsoft.Network/virtualNetworks/vnet-eshop,true,false,false,true
   ```

3. Run Terraform in the Connectivity Hub:
   ```bash
   terraform plan -var-file=env/prod/terraform.tfvars
   terraform apply -var-file=env/prod/terraform.tfvars
   ```

Terraform will automatically read the CSV, detect the new spoke entry, and provision the peering connection between the centralized Hub and the Spoke VNet.

## CSV Column Specifications

| Column | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `spoke_name` | string | (required) | Unique identifier for the spoke (used in Terraform resource keys and peering names). |
| `remote_virtual_network_id` | string | (required) | Full Azure Resource ID of the target Spoke VNet. |
| `allow_forwarded_traffic` | boolean | `true` | Allows forwarded traffic from outside the Hub VNet to be accepted by the peering. |
| `allow_gateway_transit` | boolean | `false` | Specifies whether the Hub gateway can be used by the remote VNet. |
| `use_remote_gateways` | boolean | `false` | Specifies whether the Hub will use remote gateways in the spoke. |
| `allow_virtual_network_access` | boolean | `true` | Permits virtual network address space communication across the peering. |

> **Note**: Rows starting with `#` or containing placeholder IDs (e.g., `example`) are automatically ignored by Terraform.
