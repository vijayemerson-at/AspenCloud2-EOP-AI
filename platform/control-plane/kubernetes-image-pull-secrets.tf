# kubernetes-image-pull-secrets.tf

####################################################################################################################################
# Create the main secrets to be replicated
####################################################################################################################################

locals {
  namespaces_repositories = { "kyverno" : var.global.container_image_repositories, "flux-system" : var.global.container_image_repositories }
  flatten_repos = merge([
    for ns, repos in local.namespaces_repositories : {
      for name, info in repos : "${ns}-${name}" => merge(
        { namespace : ns, repo_name : name },
        info
      )
    }
  ]...)
}

resource "kubernetes_secret" "pull_secrets" {

  for_each = local.flatten_repos

  metadata {
    name      = "regcred-${each.value.repo_name}"
    namespace = each.value.namespace
    labels = {
      "app.kubernetes.io/name"       = "bootstrap"
      "app.kubernetes.io/component"  = "private-registry-credentials"
      "app.kubernetes.io/managed-by" = "Terraform"
      "app.kubernetes.io/created-by" = "Terraform"
    }
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" = {
        (each.value.host) = {
          "username" = each.value.username
          "password" = each.value.password
          "email"    = each.value.email
          "auth"     = base64encode("${each.value.username}:${each.value.password}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    ignore_changes = [
      # Kyverno will add labels
      metadata[0].labels,
    ]
  }

  depends_on = [kubectl_manifest.kyverno_namespace, kubectl_manifest.fluxcd_namespace]
}
