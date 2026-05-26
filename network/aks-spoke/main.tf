# Local variables
locals {
  #   hubResourceGroupName = split("/", var.hubVnetResourceId)[4]
  #   hubVnetName          = split("/", var.hubVnetResourceId)[8]
  #   hubFirewallName      = "fw-${var.location}"
  #   laHubName            = "la-hub-${var.location}"
}

# # Data sources for existing resources
# data "azurerm_resource_group" "hub" {
#   name = local.hubResourceGroupName
# }

# data "azurerm_virtual_network" "hub" {
#   name                = local.hubVnetName
#   resource_group_name = data.azurerm_resource_group.hub.name
# }

# data "azurerm_firewall" "hub_firewall" {
#   name                = local.hubFirewallName
#   resource_group_name = data.azurerm_resource_group.hub.name
# }

# data "azurerm_log_analytics_workspace" "la_hub" {
#   name                = local.laHubName
#   resource_group_name = data.azurerm_resource_group.hub.name
# }

# # Resource - Route Table with a route to the regional hub's Azure Firewall
# resource "azurerm_route_table" "route_next_hop_to_firewall" {
#   name                = "route-to-${var.location}-hub-fw"
#   location            = var.location
#   resource_group_name = var.resource_group_name

#   route {
#     name                   = "r-nexthop-to-fw"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = data.azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
#   }
# }

#####################################
## Virtual Network Resources
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.domain_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.virtual_network.address_space
  tags                = merge(var.tags, var.virtual_network.tags)
}

# resource "azurerm_monitor_diagnostic_setting" "vnet_spoke" {
#   name                       = "default"
#   target_resource_id         = azurerm_virtual_network.this.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id
#   enabled_log {
#     category = "AllMetrics"
#   }
#   metric {
#     category = "AllMetrics"
#     enabled  = true
#   }
# }

# resource "azurerm_virtual_network_peering" "peeringSpokeToHub" {
#   name                         = substr("Peer-${azurerm_virtual_network.this.name}To${data.azurerm_virtual_network.hub.name}", 0, 64)
#   resource_group_name          = var.resource_group_name
#   virtual_network_name         = azurerm_virtual_network.this.name
#   remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
# }

# resource "azurerm_virtual_network_peering" "peeringHubToSpoke" {
#   name                         = substr("Peer-${data.azurerm_virtual_network.hub.name}To${azurerm_virtual_network.this.name}", 0, 64)
#   resource_group_name          = data.azurerm_virtual_network.hub.resource_group_name
#   virtual_network_name         = data.azurerm_virtual_network.hub.name
#   remote_virtual_network_id    = azurerm_virtual_network.this.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
#   depends_on                   = [azurerm_virtual_network_peering.peeringSpokeToHub]
# }


#####################################
## Subnet: privatelinkendpoints resources
resource "azurerm_subnet" "privatelinkendpoints" {
  name                 = "subnet-${var.domain_id}-privatelinkendpoints"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.subnet_privatelinkendpoints.address_prefixes
}

resource "azurerm_network_security_group" "privatelinkendpoints" {
  name                = "nsg-${var.domain_id}-privatelinkendpoints"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAll443InFromVnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.nsg_privatelinkendpoints.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# resource "azurerm_monitor_diagnostic_setting" "privatelinkendpoints" {
#   name                       = "default"
#   target_resource_id         = azurerm_network_security_group.privatelinkendpoints.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id

#   enabled_log {
#     category = "AllMetrics"
#   }
# }

resource "azurerm_subnet_network_security_group_association" "privatelinkendpoints" {
  subnet_id                 = azurerm_subnet.privatelinkendpoints.id
  network_security_group_id = azurerm_network_security_group.privatelinkendpoints.id
}

#####################################
## Subnet: AKS Internal Load Balancer resources
resource "azurerm_subnet" "aksilb" {
  name                 = "subnet-${var.domain_id}-aksilb"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.subnet_aksilb.address_prefixes
}

resource "azurerm_network_security_group" "aksilb" {
  name                = "nsg-${var.domain_id}-aksilbs"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# # Diagnostic settings for the NSG of the AKS internal load balancer subnet
# resource "azurerm_monitor_diagnostic_setting" "aksilb" {
#   name                       = "default"
#   target_resource_id         = azurerm_network_security_group.aksilb.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id
#   enabled_log {
#     category = "allLogs"
#   }
# }

resource "azurerm_subnet_network_security_group_association" "aksilb" {
  subnet_id                 = azurerm_subnet.aksilb.id
  network_security_group_id = azurerm_network_security_group.aksilb.id
}

#####################################
## Subnet: AKS Application Gateway
resource "azurerm_subnet" "applicationgateway" {
  name                 = "subnet-${var.domain_id}-applicationgateway"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.subnet_applicationgateway.address_prefixes
}

resource "azurerm_network_security_group" "applicationgateway" {
  name                = "nsg-${var.domain_id}-applicationgateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow443Inbound"
    description                = "Allow ALL web traffic into 443. (If you wanted to allow-list specific IPs, this is where you'd list them.)"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowControlPlaneInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHealthProbesInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# resource "azurerm_monitor_diagnostic_setting" "applicationgateway" {
#   name                       = "default"
#   target_resource_id         = azurerm_network_security_group.applicationgateway.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id
#   enabled_log {
#     category = "allLogs"
#   }
# }

resource "azurerm_subnet_network_security_group_association" "applicationgateway" {
  subnet_id                 = azurerm_subnet.applicationgateway.id
  network_security_group_id = azurerm_network_security_group.applicationgateway.id
}

#####################################
## Subnet: AKS clusternodes resources
resource "azurerm_subnet" "clusternodes" {
  name                 = "subnet-${var.domain_id}-clusternodes"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.subnet_clusternodes.address_prefixes
}

resource "azurerm_network_security_group" "clusternodes" {
  name                = "nsg-${var.domain_id}-clusternodes"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# # Diagnostic settings for the Network Security Group
# resource "azurerm_monitor_diagnostic_setting" "clusternodes" {
#   name                       = "default"
#   target_resource_id         = azurerm_network_security_group.clusternodes.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id
#   enabled_log {
#     category = "allLogs"
#   }
# }

resource "azurerm_subnet_network_security_group_association" "clusternodes" {
  subnet_id                 = azurerm_subnet.clusternodes.id
  network_security_group_id = azurerm_network_security_group.clusternodes.id
}

#####################################
## Public IP: pipPrimaryClusterIp

# resource "azurerm_public_ip" "pipPrimaryClusterIp" {
#   name                    = "pip-${var.domain_id}-00"
#   location                = var.location
#   resource_group_name     = var.resource_group_name
#   allocation_method       = "Static"
#   sku                     = "Standard"
#   zones                   = ["1", "2", "3"]
#   idle_timeout_in_minutes = 4
#   ip_version              = "IPv4"
# }

# resource "azurerm_monitor_diagnostic_setting" "pipPrimaryClusterIp_diagnosticSetting" {
#   name                       = "default"
#   target_resource_id         = azurerm_public_ip.pipPrimaryClusterIp.id
# #   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la_hub.id
#   enabled_log {
#     category = "audit"
#   }
#   metric {
#     category = "AllMetrics"
#     enabled  = true
#   }
# }

