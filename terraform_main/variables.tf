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

# Переменные для настройки сети
variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "k8s-network"
}

variable "network_description" {
  description = "The description of the VPC network"
  type        = string
  default     = "VPC network for k8s"
}

# Список подсетей
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name        = string
    zone        = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      name        = "k8s-subnet-a"
      zone        = "ru-central1-a"
      cidr_blocks = ["10.10.1.0/24"]
      description = "Subnet A in zone ru-central1-a"
    },
    {
      name        = "k8s-subnet-b"
      zone        = "ru-central1-b"
      cidr_blocks = ["10.10.2.0/24"]
      description = "Subnet B in zone ru-central1-b"
    },
    {
      name        = "k8s-subnet-d"
      zone        = "ru-central1-d"
      cidr_blocks = ["10.10.3.0/24"]
      description = "Subnet D in zone ru-central1-d"
    }
  ]
}

variable "service_account_id" {
  description = "Service Account ID for the Kubernetes cluster"
}

variable "node_service_account_id" {
  description = "Service Account ID for the Kubernetes nodes"
}