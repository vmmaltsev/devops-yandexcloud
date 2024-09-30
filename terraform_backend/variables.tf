variable "cloud_id" {
  description = "The ID of the cloud under which to deploy the resources"
  type        = string
}

variable "folder_id" {
  description = "The ID of the folder under which to deploy the resources"
  type        = string
}

variable "default_zone" {
  description = "The default zone where resources will be deployed"
  type        = string
}
