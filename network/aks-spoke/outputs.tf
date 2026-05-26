output "virtual_network" {
  value = {
    id            = azurerm_virtual_network.this.id
    name          = azurerm_virtual_network.this.name
    address_space = azurerm_virtual_network.this.address_space
  }
}

output "subnet_clusternodes" {
  value = {
    id               = azurerm_subnet.clusternodes.id
    address_prefixes = azurerm_subnet.clusternodes.address_prefixes
  }
}

output "subnet_applicationgateway" {
  value = {
    id               = azurerm_subnet.applicationgateway.id
    address_prefixes = azurerm_subnet.applicationgateway.address_prefixes
  }
}

output "subnet_aksilb" {
  value = {
    id               = azurerm_subnet.aksilb.id
    address_prefixes = azurerm_subnet.aksilb.address_prefixes
  }
}

output "subnet_privatelinkendpoints" {
  value = {
    id               = azurerm_subnet.privatelinkendpoints.id
    address_prefixes = azurerm_subnet.privatelinkendpoints.address_prefixes
  }
}
