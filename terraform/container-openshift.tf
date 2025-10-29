########################################################################################################################
# Variables
########################################################################################################################
variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "When set to true, enabled outbound traffic."
  default     = false
}


########################################################################################################################
# Kube Audit
########################################################################################################################
########################################################################################################################
# OCP VPC cluster with default worker pool across 3 zones and a GPU worker pool in zone 1
########################################################################################################################

locals {
  # Get all subnets from the VPC module
  all_subnets = module.vpc.subnet_zone_list

  # Define subnets for the default worker pool (across 3 zones)
  default_vpc_subnets = {
    default = [
      for subnet in local.all_subnets :
      {
        id         = subnet.id
        cidr_block = subnet.cidr
        zone       = subnet.zone
      }
      if strcontains(subnet.name, "subnet-default")
    ]
  }

  # Define subnet for the GPU worker pool (single zone)
  gpu_vpc_subnets = {
    gpu = [
      for subnet in local.all_subnets :
      {
        id         = subnet.id
        cidr_block = subnet.cidr
        zone       = subnet.zone
      }
      if strcontains(subnet.name, "subnet-gpu") # Use strcontains rather than == given that a prefix is added by landing zone vpc to subnet names
    ]
  }

  # Combine all subnets
  cluster_vpc_subnets = merge(local.default_vpc_subnets, local.gpu_vpc_subnets)

  # Define worker pools
  worker_pools = [
    {
      subnet_prefix                     = "default"
      pool_name                         = "default"   # ibm_container_vpc_cluster automatically names default pool "default"
      machine_type                      = "bx2.16x64" # ODF Flavors
      workers_per_zone                  = 1
      operating_system                  = "RHCOS"
      boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    },
    {
      subnet_prefix     = "gpu"
      pool_name         = "gpu"
      machine_type      = "gx3.16x80.l4"
      secondary_storage = "600gb.10iops-tier"
      workers_per_zone  = 1
      operating_system  = "RHCOS"
    }
  ]
}

module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = var.prefix
  force_delete_storage                = true
  vpc_id                              = module.vpc.vpc_id
  vpc_subnets                         = local.cluster_vpc_subnets
  ocp_version                         = var.ocp_version
  worker_pools                        = local.worker_pools
  access_tags                         = var.access_tags
  ocp_entitlement                     = var.ocp_entitlement
  disable_outbound_traffic_protection = var.disable_outbound_traffic_protection
  addons = {
    "openshift-ai"              = { version = "417" }
    "openshift-data-foundation" = { version = "4.18.0" }
  }
}