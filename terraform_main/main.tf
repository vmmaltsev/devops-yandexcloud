
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