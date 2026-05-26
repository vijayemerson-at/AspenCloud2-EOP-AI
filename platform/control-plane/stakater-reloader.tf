locals {
  stakater_namespace = "stakater"

  stakater_reloader_helm_release = templatefile(
    "${path.module}/files/stakater-reloader/stakater_reloader_helm_release.yaml.tftpl",
    {
      namespace              = local.stakater_namespace,
      stakater_chart_version = "2.2.9",
      image_registry         = local.cluster_primary_container_registry_host
    }
  )
}

## ---------------------------------------------------
# Stakater Namespace
## ---------------------------------------------------
resource "kubernetes_namespace" "stakater" {
  metadata {
    name = local.stakater_namespace
  }
}
