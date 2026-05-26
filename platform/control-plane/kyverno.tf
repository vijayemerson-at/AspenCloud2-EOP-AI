# kyverno.tf

###
### Setup guide here: https://kyverno.io/docs/installation/#install-kyverno-using-yamls
### Manifests here: https://raw.githubusercontent.com/kyverno/kyverno/release-1.6/config/release/install.yaml
###

locals {
  ####################################################################################################################################
  # Kyverno policy engine
  ####################################################################################################################################

  cluster_primary_container_registry_host = try(var.global.container_image_repositories[sort(keys(var.global.container_image_repositories))[0]].host, "")
  cluster_primary_container_registry_key  = try(sort(keys(var.global.container_image_repositories))[0], "")
  image_pull_secret                       = "regcred-${local.cluster_primary_container_registry_key}"

  kyverno_helm_release   = templatefile("${path.module}/files/kyverno/helm-release.yaml.tftpl", { kyverno_chart_version = "3.7.1", image_registry = local.cluster_primary_container_registry_host, image_pull_secret = local.image_pull_secret })
  kyverno_network_policy = file("${path.module}/files/kyverno/network-policy.yaml")

  ####################################################################################################################################
  # Kyverno policies
  ####################################################################################################################################

  # Disable default service account automount token for new accounts
  kyverno_service_accounts_disable_sa_token = file("${path.module}/files/kyverno-policies/cluster-policy-disable-sa-token.yaml")

  # Pull secret replication policy
  kyverno_image_pull_secret_replication_policy = templatefile(
    "${path.module}/files/kyverno-policies/cluster-policy-pull-secrets.yaml.tftpl",
    {
      registries = var.global.container_image_repositories
    }
  )

  # Pod image pull secrets policy
  kyverno_pod_image_pull_policy = templatefile(
    "${path.module}/files/kyverno-policies/cluster-policy-pod-add-pull-secrets.yaml.tftpl",
    {
      registries = var.global.container_image_repositories
    }
  )

  # cluster-vars configmap sync
  kyverno_sync_cluster_vars_policy = file("${path.module}/files/kyverno-policies/cluster-policy-cluster-vars.yaml")

}

resource "kubectl_manifest" "kyverno_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: kyverno
YAML
}
