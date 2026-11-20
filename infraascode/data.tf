###############################################################################
# Data Sources
###############################################################################

# ALWAYS use `current`.
# The previous configuration referenced `data.azapi_client_config.this`,
# which was never defined and caused plan-time failures.
data "azapi_client_config" "current" {}