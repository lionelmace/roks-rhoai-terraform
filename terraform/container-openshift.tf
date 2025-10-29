########################################################################################################################
# Variables
########################################################################################################################

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}

variable "enable_openshift_version_upgrade" {
  type        = bool
  description = "When set to true, allows Terraform to manage major OpenShift version upgrades. This is intended for advanced users who manually control major version upgrades. Defaults to false to avoid unintended drift from IBM-managed patch updates. NOTE: Enabling this on existing clusters requires a one-time terraform state migration. See [README](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/README.md#openshift-version-upgrade) for details."
  default     = false
}

variable "default_worker_pool_machine_type" {
  type        = string
  description = "The machine type for the default worker pool"
  default     = "bx2.4x16"
}

variable "gpu_worker_pool_machine_type" {
  type        = string
  description = "The machine type for the GPU worker pool"
  default     = "gx3.16x80.l4"
}

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "When set to true, enabled outbound traffic."
  default     = false
}

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

########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}