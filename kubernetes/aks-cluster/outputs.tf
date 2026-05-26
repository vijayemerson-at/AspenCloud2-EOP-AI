output "kubernetes_cluster" {
  value = {
    id                     = azurerm_kubernetes_cluster.this.id
    name                   = azurerm_kubernetes_cluster.this.name
    fqdn                   = azurerm_kubernetes_cluster.this.fqdn
    private_fqdn           = azurerm_kubernetes_cluster.this.private_fqdn
    kube_config_raw        = azurerm_kubernetes_cluster.this.kube_config_raw
    node_resource_group    = azurerm_kubernetes_cluster.this.node_resource_group
    oidc_issuer_url        = azurerm_kubernetes_cluster.this.oidc_issuer_url
    host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
    cluster_ca_certificate = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  }
}