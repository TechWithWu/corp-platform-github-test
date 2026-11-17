# Azure Landing Zone Management Infrastructure as Code

This repository manages core management resources for the Corporate Platform Azure Landing Zone (ALZ) using the official Microsoft Azure Verified Module (**AVM**): `Azure/avm-ptn-alz-management/azurerm`.

## Architecture Overview

The module automates the provisioning of:
- **Central Management Resource Group**: Houses platform observability and automation resources.
- **Log Analytics Workspace**: Centralized logging workspace with environment-tailored SKU cost tiering.
- **Azure Automation Account**: Automation foundation for operational runbooks and state configuration.
- **Data Collection Rules (DCRs)**:
  - Change Tracking (`dcr-change-tracking-*`)
  - VM Insights (`dcr-vm-insights-*`)
  - Microsoft Defender for SQL (`dcr-defender-sql-*`)
- **Tags & Metadata**: Standardized corporate tagging (`Environment`, `ManagementType`, `ManagedBy`, `Organization`).

---

## Directory Structure

```text
infraascode/
├── .checkov.yaml                   # Static analysis & policy-as-code rule suppressions
├── env/
│   ├── dev/
│   │   ├── backend.hcl             # Remote state backend configuration for Dev
│   │   └── terraform.tfvars        # Environment-specific variables for Dev (Free SKU)
│   └── prod/
│       ├── backend.hcl             # Remote state backend configuration for Prod
│       └── terraform.tfvars        # Environment-specific variables for Prod (PerGB2018 SKU)
├── locals.tf                       # Local computations, environment flags, and tags
├── main.tf                         # Root orchestration & module instantiation
├── outputs.tf                      # Output definitions for downstream consumers
├── provider.tf                     # Provider configurations (azurerm, azapi with OIDC)
├── README.md                       # Architecture, operations, and reference guide
├── variables.tf                    # Input variable declarations and validation rules
└── version.tf                      # Terraform & provider version constraints
```

---

## Cost Optimization Strategy (SKU Selection)

To balance operational expenditure across environments, Log Analytics Workspace pricing is dynamically tiered:

| Environment | SKU | Pricing Model | Rationale |
| :--- | :--- | :--- | :--- |
| **Development / Non-Prod** | `Free` | Free Tier (500 MB/day limit) | **Cheapest available tier**: Ideal for dev/testing workloads without incurring unnecessary log ingestion charges. |
| **Production** | `PerGB2018` | Pay-As-You-Go (Per GB) | **Moderate cost**: Standard enterprise telemetry tier. Avoids high-cost `CapacityReservation` tiers (which require 100+ GB/day minimum commitments) while providing SLA-backed durability. |

The SKU is dynamically determined in `main.tf` based on `var.environment`, and can also be explicitly overridden via `.tfvars`.

---

## Prerequisites

- **Terraform**: `>= 1.9, < 2.0`
- **Azure CLI**: `az` CLI `>= 2.50.0`
- **Azure Permissions**: Contributor or Owner on the target Azure Subscription.
- **Authentication**: OIDC authentication is enabled (`use_oidc = true`) for secure CI/CD pipelines (e.g. GitHub Actions Workflows) without stored credentials.

---

## Deployment Guide

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 2. Deploy to Development (`dev`)

```bash
# Initialize Terraform with Dev remote backend
terraform init -backend-config=env/dev/backend.hcl

# Plan Dev deployment (verifies Free SKU)
terraform plan -var-file=env/dev/terraform.tfvars

# Apply Dev deployment
terraform apply -var-file=env/dev/terraform.tfvars
```

### 3. Deploy to Production (`prod`)

```bash
# Switch / Re-initialize for Prod remote backend
terraform init -reconfigure -backend-config=env/prod/backend.hcl

# Plan Prod deployment (verifies PerGB2018 SKU)
terraform plan -var-file=env/prod/terraform.tfvars

# Apply Prod deployment
terraform apply -var-file=env/prod/terraform.tfvars
```

---

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `environment` | `string` | `"nonprod"` | Deployment environment (`dev`, `test`, `stage`, `nonprod`, `prod`). |
| `location` | `string` | `"centralus"` | Default Azure region for resources and ALZ artifacts. |
| `enable_telemetry` | `bool` | `false` | Enable AVM telemetry via `modtm`. |
| `management_resource_group` | `string` | `"rg-corp-platform-management"` | Name of the Azure Resource Group. |
| `log_analytics_workspace_name` | `string` | `"corp-platform-log-analytics-workspace"` | Name of the Log Analytics Workspace. |
| `log_analytics_workspace_sku` | `string` | `"Free"` | Log Analytics SKU (`Free` for non-prod, `PerGB2018` for prod). |
| `automation_account_name` | `string` | `"corp-automation"` | Name of the Azure Automation Account. |

---

## Outputs

| Name | Description |
| :--- | :--- |
| `resource_group_id` | Resource ID of the management resource group. |
| `resource_group_name` | Name of the management resource group. |
| `resource_group_location` | Azure region of the management resource group. |
| `log_analytics_workspace_sku` | The effective SKU applied to the Log Analytics Workspace. |
| `log_analytics_workspace_name` | The name of the Log Analytics Workspace. |
| `automation_account_name` | The name of the Azure Automation account. |

---

## Quality, Linting & Security

- **Formatting**: Run `terraform fmt -recursive` to enforce standard indentation.
- **Validation**: Run `terraform validate` to ensure configuration syntax and type consistency.
- **Security Scanning**: Scan with Checkov (`checkov -d .`) using `.checkov.yaml` policy definitions.
