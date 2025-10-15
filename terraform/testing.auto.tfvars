##############################################################################
## Global Variables
##############################################################################

#region     = "eu-de"     # eu-de for Frankfurt MZR
#icr_region = "de.icr.io"

# Name of an existing RG (Resource Group) where to create resources.
# Otherwise the default RG is used.
existing_resource_group_name = "shared-emea-rg"

##############################################################################
## VPC
##############################################################################
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster ROKS
##############################################################################
# Oct 14, 2025: OpenShift AI only supports OpenShift version up to 4.17
openshift_version        = "4.17_openshift"
openshift_os             = "RHCOS"
openshift_machine_flavor = "bx2.8x32"
install_addons           = true

# Skip zones if insufficient capacity within those zones
excluded_zones = ["eu-de-2", "eu-de-3"]
# Set the worker_count to 2 to comply with minimum worker per cluster if 2 zones are excluded.
openshift_worker_nodes_per_zone = 1

# Scale up   by adding a worker pool
# Scale down by setting the number of worker to Zero
# Uncomment to create worker pool
create_secondary_roks_pool = true
roks_worker_pools = [
  {
    pool_name        = "gpu"
    machine_type     = "gx3.24x120.l40s"
    workers_per_zone = 0
    zones            = ["eu-de-1","eu-de-2","eu-de-3"]
  },
  {
    pool_name        = "gpu-a100"
    machine_type     = "gx3d.48x240.2a100p"
    workers_per_zone = 1
    zones            = ["eu-de-1"] # <- only one zone
  },

  # {
  #   pool_name        = "wpool-odf"
  #   machine_type     = "bx2.16x64"
  #   workers_per_zone = 1
  # }
]

openshift_disable_public_service_endpoint = false
# Secure By default - Public outbound access is blocked as of OpenShift 4.15
# Protect network traffic by enabling only the connectivity necessary 
# for the cluster to operate and preventing access to the public Internet.
# By default, value is false.
openshift_disable_outbound_traffic_protection = true

# Available values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
openshift_wait_till          = "OneWorkerNodeReady"
openshift_update_all_workers = true

##############################################################################
## Secrets Manager
##############################################################################
existing_secrets_manager_name = "secrets-manager"
