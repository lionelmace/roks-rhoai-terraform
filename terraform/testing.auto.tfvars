##############################################################################
## Global Variables
##############################################################################

#region     = "eu-de"     # eu-de for Frankfurt MZR
#icr_region = "de.icr.io"

##############################################################################
## VPC
##############################################################################
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster ROKS
##############################################################################
# Optional: Specify OpenShift version. If not included, 4.17 is used
openshift_version = "4.19_openshift"
# openshift_os             = "REDHAT_8_64"
openshift_os             = "RHCOS"
openshift_machine_flavor = "bx2.8x32"
# openshift_machine_flavor = "bx2.16x64" # ODF Flavors
install_addons = true

# Scale up   by adding a worker pool
# Scale down by setting the number of worker to Zero
# Uncomment to create worker pool
create_secondary_roks_pool = true
roks_worker_pools = [
  {
    pool_name        = "gpu"
    machine_type     = "gx3.24x120.l40s"
    workers_per_zone = 1
  },
  # {
  #   pool_name        = "wpool-odf"
  #   machine_type     = "bx2.16x64"
  #   workers_per_zone = 1
  # },
  # {
  #   pool_name        = "default"
  #   machine_type     = "mx2.4x32"
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
