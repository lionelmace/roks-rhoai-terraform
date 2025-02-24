
##############################################################################
# Monitoring Services
##############################################################################


# Monitoring Variables
##############################################################################
variable "sysdig_plan" {
  description = "plan type"
  type        = string
  default     = "graduated-tier"
  # default     = "graduated-tier-sysdig-secure-plus-monitor"
}

variable "sysdig_service_endpoints" {
  description = "Only allow the value public-and-private. Previously it incorrectly allowed values of public and private however it is not possible to create public only or private only Cloud Monitoring instances."
  type        = string
  default     = "public-and-private"
}

variable "sysdig_private_endpoint" {
  description = "Add this option to connect to your Sysdig service instance through the private service endpoint"
  type        = bool
  default     = true
}

variable "sysdig_enable_platform_metrics" {
  type        = bool
  description = "Receive platform metrics in Sysdig"
  default     = false
}

# Monitoring Resource
##############################################################################

module "cloud_monitoring" {
  source = "terraform-ibm-modules/observability-instances/ibm//modules/cloud_monitoring"
  # version = "latest" # Replace "latest" with a release version to lock into a specific release

  resource_group_id       = ibm_resource_group.group.id
  instance_name           = format("%s-%s", local.basename, "monitoring")
  plan                    = var.sysdig_plan
  service_endpoints       = var.sysdig_service_endpoints
  enable_platform_metrics = var.sysdig_enable_platform_metrics
  region                  = var.region
  tags                    = var.tags
  manager_key_tags        = var.tags
}

output "cloud_monitoring_crn" {
  description = "The CRN of the Cloud Monitoring instance"
  value       = module.cloud_monitoring.crn
}


# Metrics Target
# A route defines the rules that indicate what metrics are routed in a region 
# and where to store them
##############################################################################
resource "ibm_metrics_router_target" "metrics_router_target" {
  destination_crn = module.cloud_monitoring.crn
  name            = format("%s-%s", local.basename, "metric-target")
  region          = var.region
}

# Set the default target for the metrics router
resource "ibm_metrics_router_settings" "metrics_router_settings_instance" {
  default_targets {
    id = ibm_metrics_router_target.metrics_router_target.id
  }
  permitted_target_regions  = [var.region]
  primary_metadata_region   = var.region
  backup_metadata_region    = "eu-es"
  private_api_endpoint_only = false
}

# Metrics Route
# A route defines the rules that indicate what metrics are routed in a region 
# and where to store them
##############################################################################
resource "ibm_metrics_router_route" "metrics_route_eu_de" {
  name = format("%s-%s", local.basename, "route-to-de")
  rules {
    action = "send"
    targets {
      id = ibm_metrics_router_target.metrics_router_target.id
    }
    inclusion_filters {
      operand  = "location"
      operator = "is"
      values   = [var.region]
    }
  }
}

## IAM
##############################################################################

resource "ibm_iam_access_group_policy" "iam-sysdig" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Writer", "Editor"]

  resources {
    service           = "sysdig-monitor"
    resource_group_id = ibm_resource_group.group.id
  }
}
