
# Сеть
resource "yandex_vpc_network" "k8s_network" {
  name        = var.network_name
  description = var.network_description
}

# Подсети
resource "yandex_vpc_subnet" "k8s_subnet" {
  count = length(var.subnets)

  name           = element(var.subnets, count.index).name
  zone           = element(var.subnets, count.index).zone
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = element(var.subnets, count.index).cidr_blocks
  description    = element(var.subnets, count.index).description
}

# Define reusable maintenance windows
locals {
  maintenance_windows = [
    {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    },
    {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  ]

  common_labels = {
    environment = "production"
    team        = "devops"
  }
}

# Kubernetes Cluster
resource "yandex_kubernetes_cluster" "regional_cluster" {
  name        = "regional-k8s-cluster"
  description = "Regional Kubernetes cluster in 3 zones"
  network_id  = yandex_vpc_network.k8s_network.id

  master {
    version = "1.29"

    regional {
      region = "ru-central1"

      dynamic "location" {
        for_each = var.subnets
        content {
          zone      = location.value.zone
          subnet_id = yandex_vpc_subnet.k8s_subnet[location.key].id
        }
      }
    }

    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      dynamic "maintenance_window" {
        for_each = local.maintenance_windows
        content {
          day        = maintenance_window.value.day
          start_time = maintenance_window.value.start_time
          duration   = maintenance_window.value.duration
        }
      }
    }

    master_logging {
      enabled                  = true
      folder_id                = var.folder_id
      kube_apiserver_enabled   = true
      cluster_autoscaler_enabled = true
      events_enabled           = true
      audit_enabled            = true
    }
  }

  service_account_id      = var.service_account_id
  node_service_account_id = var.node_service_account_id

  labels = local.common_labels

  release_channel = "STABLE"
}

# Node Group
resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id  = yandex_kubernetes_cluster.regional_cluster.id
  name        = "k8s-node-group"
  description = "Node group for regional Kubernetes cluster"
  version     = "1.29"

  labels = local.common_labels

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat = true
      subnet_ids = [for subnet in yandex_vpc_subnet.k8s_subnet : subnet.id]
    }

    resources {
      memory = 4  # Memory in GB
      cores  = 2  # Number of CPU cores
    }

    boot_disk {
      type = "network-ssd"
      size = 50  # Size in GB
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"  # Alternative can be "docker"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3  # Number of nodes in the group
    }
  }

  allocation_policy {
    location {
      zone = element(var.subnets, 0).zone
    }

    location {
      zone = element(var.subnets, 1).zone
    }

    location {
      zone = element(var.subnets, 2).zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    dynamic "maintenance_window" {
      for_each = local.maintenance_windows
      content {
        day        = maintenance_window.value.day
        start_time = maintenance_window.value.start_time
        duration   = maintenance_window.value.duration
      }
    }
  }
}
