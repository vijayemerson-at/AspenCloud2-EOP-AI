output "cluster_node_pool" {
  value = {
    id = azurerm_kubernetes_cluster_node_pool.this.id
  }
}