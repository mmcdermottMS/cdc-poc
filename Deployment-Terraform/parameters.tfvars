/**************************************************************/
/*                           GLOBAL                           */
/**************************************************************/
vnet_addr_prefix = "10.0.0.0/16"

# The Region to deploy to
location = "eastus"

# This Prefix will be used on most deployed resources.  44 Characters max.
# The environment will also be used as part of the name
name_prefix = "msft-cdc"

region_code = "eus"

sb_sku = "Premium"

tags = {
  project   = "CDC Proof of Concept"
  deployenv = "dev"
}

/**************************************************************/
/*                      RESOURCE NAMES                        */
/**************************************************************/

### These values will be defaulted to the following naming convention:
### <name_prefix>-<region_code>-<resource_type>

### Uncomment these values to apply your own naming convention

#acr_mi_name       = ""
#acr_name          = ""
#ai_name           = ""
#kv_mi_name        = ""
#kv_name           = ""
#law_name          = ""
#network_rg_name   = ""
#sb_name           = ""
#sb_owner_mi_name  = ""
#sb_sender_mi_name = ""
#sb_sku            = ""
#vnet_name         = ""
#workload_rg_name  = ""
