##############################################################################
# COS Instance with 1 bucket
##############################################################################

# COS instance
##############################################################################

resource "ibm_resource_instance" "cos-instance" {
  name              = format("%s-%s", local.basename, "cos-model")
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = local.resource_group_id
  tags              = var.tags

  parameters = {
    service-endpoints = "private"
  }
}

## COS Bucket
##############################################################################
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = format("%s-%s", local.basename, "cos-bucket")
  resource_instance_id = ibm_resource_instance.cos-instance.id
  storage_class        = "smart"

  cross_region_location = "eu"
  endpoint_type         = "public"
  #   endpoint_type = "private"
}

## HMAC Service Credentials
##############################################################################
resource "ibm_resource_key" "cos-hmac" {
  name                 = format("%s-%s", local.basename, "cos-instance-key")
  resource_instance_id = ibm_resource_instance.cos-instance.id
  role                 = "Writer"
  parameters           = { HMAC = true }
}

locals {
  cos-credentials = [
    {
      cos_bucket_name       = ibm_cos_bucket.bucket.bucket_name
      cos_bucket_id         = ibm_cos_bucket.bucket.id
      cos_access_key_id     = nonsensitive(ibm_resource_key.cos-hmac.credentials["cos_hmac_keys.access_key_id"])
      cos_secret_access_key = nonsensitive(ibm_resource_key.cos-hmac.credentials["cos_hmac_keys.secret_access_key"])
      cos_endpoint          = ibm_cos_bucket.bucket.s3_endpoint_direct
    }
  ]
}

output "cos-instance-credentials" {
  value = local.cos-credentials
}
