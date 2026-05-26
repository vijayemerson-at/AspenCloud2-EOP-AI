# AspenTech Subsurface Intelligence (ASI) infrastructure example
# This example demonstrates how to deploy an AKS cluster with multiple node pools
# dedicated to different services of the ASI product: apps, data and compute

# node pool dedicated to ASI Apps: web server or low footprint backend for frontend
module "asi_apps_node_pool" {
  source = "../../kubernetes/aks-node-pool"

  cluster_node_pool = {
    name = "asiapps"
    mode = "User"

    vm_size = "Standard_D4ds_v5"
    zones   = [1, 2, 3]

    kubernetes_cluster_id = module.cluster.kubernetes_cluster.id
    orchestrator_version  = var.cluster_orchestrator_version

    vnet_subnet_id         = module.aks-spoke.subnet_clusternodes.id
    node_public_ip_enabled = false

    os_sku          = "AzureLinux"
    os_type         = "Linux"
    os_disk_size_gb = 32
    os_disk_type    = "Ephemeral"
    max_pods        = 30

    auto_scaling_enabled = true
    node_count           = 2
    min_count            = 2
    max_count            = 20
    priority             = "Regular"

    host_encryption_enabled = false
    fips_enabled            = false

    upgrade_settings = {
      max_surge = "33%"
    }

    node_labels = {
      "node.aspencloud.ai/nodepool" = "asi-apps",
      "sku"                         = "app",
    }

    tags = {
      "InstanceName" = module.cluster.kubernetes_cluster.name
    }
  }

  tags = local.tags
}

# node pool dedicated to ASI Data services
# This node pool needs to be in the same availability zone than the PostgreSQL server
# provision by the ASI terraform script
module "asi_data_node_pool_az1" {
  source = "../../kubernetes/aks-node-pool"

  cluster_node_pool = {
    name = "asidataaz1"
    mode = "User"

    vm_size = "Standard_D8d_v5"

    # This node pool needs to be in the same availability zone than the PostgreSQL server
    zones = [1]

    kubernetes_cluster_id = module.cluster.kubernetes_cluster.id
    orchestrator_version  = var.cluster_orchestrator_version

    vnet_subnet_id         = module.aks-spoke.subnet_clusternodes.id
    node_public_ip_enabled = false

    os_sku          = "AzureLinux"
    os_type         = "Linux"
    os_disk_size_gb = 64
    os_disk_type    = "Ephemeral"
    max_pods        = 30

    auto_scaling_enabled = true
    node_count           = 2
    min_count            = 2
    max_count            = 20
    priority             = "Regular"

    host_encryption_enabled = false
    fips_enabled            = false

    upgrade_settings = {
      max_surge = "33%"
    }

    node_labels = {
      "node.aspencloud.ai/nodepool" = "asi-data",
      "sku"                         = "data",
    }

    tags = {
      "InstanceName" = module.cluster.kubernetes_cluster.name
    }
  }

  tags = local.tags
}

# node pool dedicated to ASI Compute services
module "asi_compute_node_pool" {
  source = "../../kubernetes/aks-node-pool"

  cluster_node_pool = {
    name = "asicompute"
    mode = "User"

    vm_size = "Standard_D8d_v5"
    zones   = [1, 2, 3]

    kubernetes_cluster_id = module.cluster.kubernetes_cluster.id
    orchestrator_version  = var.cluster_orchestrator_version

    vnet_subnet_id         = module.aks-spoke.subnet_clusternodes.id
    node_public_ip_enabled = false

    os_sku          = "AzureLinux"
    os_type         = "Linux"
    os_disk_size_gb = 64
    os_disk_type    = "Ephemeral"
    max_pods        = 30

    auto_scaling_enabled = true
    node_count           = 2
    min_count            = 2
    max_count            = 100
    priority             = "Regular"

    host_encryption_enabled = false
    fips_enabled            = false

    upgrade_settings = {
      max_surge = "33%"
    }

    node_labels = {
      "node.aspencloud.ai/nodepool" = "asi-compute",
      "sku"                         = "compute",
    }

    tags = {
      "InstanceName" = module.cluster.kubernetes_cluster.name
    }
  }

  tags = local.tags
}
