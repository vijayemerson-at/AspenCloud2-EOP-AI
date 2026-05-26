## Provider configuration
The caller of this module must configure the `kubernetes`, `kubectl` and `github` providers. Here is an example of configuration using a service principal to connect to kubernetes:
```terraform
provider "kubectl" {
  apply_retry_count      = 15
  host                   = var.kubernetes_cluster.host
  cluster_ca_certificate = base64decode(var.kubernetes_cluster.cluster_ca_certificate)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "get-token",
      "--login",
      "spn",
      "--environment",
      "AzurePublicCloud",
      "--client-id",
      var.kubernetes_cluster.aad_sp_client_id,
      "--client-secret",
      var.kubernetes_cluster.aad_sp_client_secret,
      "--tenant-id",
      var.kubernetes_cluster.aad_sp_tenant_id,
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
    command = "kubelogin"
  }
}

provider "kubernetes" {
  host                   = var.kubernetes_cluster.host
  cluster_ca_certificate = base64decode(var.kubernetes_cluster.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "get-token",
      "--login",
      "spn",
      "--environment",
      "AzurePublicCloud",
      "--client-id",
      var.kubernetes_cluster.aad_sp_client_id,
      "--client-secret",
      var.kubernetes_cluster.aad_sp_client_secret,
      "--tenant-id",
      var.kubernetes_cluster.aad_sp_tenant_id,
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
    command = "kubelogin"
  }
}

provider "github" {
  owner = var.gitops.organization_name
}
```