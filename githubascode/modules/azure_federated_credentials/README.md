# Azure Federated Credentials Module

Configures Azure AD Application Federated Identity Credentials for passwordless GitHub Actions OIDC authentication, based on `config/azure-identity/federated_credentials.csv`.

## Features
- Generates exact OIDC subjects for environments, pull requests, and branches (`repo:<org>/<repo>:environment:<env>`).
- Explicitly depends on `repositories` module so that repository IDs and organization context are guaranteed before credentials are created.
