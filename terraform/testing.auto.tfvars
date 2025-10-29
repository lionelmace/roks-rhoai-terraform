##############################################################################
## Global Variables
##############################################################################

prefix         = "rhoai"
region         = "eu-de"
resource_group = "geo-mace"

##############################################################################
## Module OCP VPC
##############################################################################
ocp_version                         = "4.18"
disable_outbound_traffic_protection = true
default_worker_pool_machine_type    = "bx2.16x64"
gpu_worker_pool_machine_type       = "gx3.16x80.l4"
