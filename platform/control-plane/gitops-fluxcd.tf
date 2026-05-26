# gitops-fluxcd.tf

###
### Setup guide here: https://fluxcd.io/docs/installation/
### Initial YAML here: https://github.com/fluxcd/flux2/releases/download/v0.26.0/install.yaml
###

locals {
  # This is the name of the Kubernetes secret, not the content
  # tfsec:ignore:general-secrets-sensitive-in-local
  fluxcd_ssh_credentials_secret_name = "fluxcd-ssh-credentials"
  fluxcd_repository_target_url       = local.gitops_use_github ? replace(github_repository.gitops[0].ssh_clone_url, "git@github.com:", "ssh://git@github.com/") : var.gitops.external_repository_address
  fluxcd_ssh_known_hosts             = local.gitops_use_github ? file("${path.module}/files/github-ssh-known_hosts") : var.fluxcd.external_repository_ssh_known_hosts
  fluxcd_gitkeep_content             = ""

  fluxcd_cluster_production_infra_stage0_kustomization      = templatefile("${path.module}/files/fluxcd/kustomization-infra-stage0.yaml.tftpl", { prefix = var.gitops.repository_target_path })
  fluxcd_cluster_production_infra_stage1_kustomization      = templatefile("${path.module}/files/fluxcd/kustomization-infra-stage1.yaml.tftpl", { prefix = var.gitops.repository_target_path })
  fluxcd_cluster_production_infra_stage2_kustomization      = templatefile("${path.module}/files/fluxcd/kustomization-infra-stage2.yaml.tftpl", { prefix = var.gitops.repository_target_path })
  fluxcd_cluster_production_infra_stage_final_kustomization = templatefile("${path.module}/files/fluxcd/kustomization-infra-stage-final.yaml.tftpl", { prefix = var.gitops.repository_target_path })

  fluxcd_network_policy_manifest = file("${path.module}/files/fluxcd/network-policy.yaml")
}

####################################################################################################################################
# Install flux
####################################################################################################################################

data "kubectl_file_documents" "fluxcd_install" {
  content = templatefile(
    "${path.module}/files/fluxcd/flux-install.yaml.tftpl",
    {
      image_registry    = local.cluster_primary_container_registry_host
      image_pull_secret = local.image_pull_secret
    }
  )
}

resource "kubectl_manifest" "fluxcd_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.fluxcd.namespace}
YAML
}

resource "kubectl_manifest" "fluxcd_install" {
  count     = length(data.kubectl_file_documents.fluxcd_install.documents)
  yaml_body = element(data.kubectl_file_documents.fluxcd_install.documents, count.index)

  depends_on = [kubectl_manifest.fluxcd_namespace]
}

####################################################################################################################################
# Configure Flux main repository
####################################################################################################################################

resource "tls_private_key" "fluxcd" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# Inject in Kubernetes the secret directly.
resource "kubernetes_secret" "fluxcd_ssh_credentials" {
  metadata {
    name      = local.fluxcd_ssh_credentials_secret_name
    namespace = var.fluxcd.namespace
    labels = {
      "app.kubernetes.io/name"       = "bootstrap"
      "app.kubernetes.io/component"  = "fluxcd"
      "app.kubernetes.io/managed-by" = "Terraform"
      "app.kubernetes.io/created-by" = "Terraform"
    }
  }

  data = {
    "identity"     = tls_private_key.fluxcd.private_key_pem
    "identity.pub" = tls_private_key.fluxcd.public_key_openssh
    "known_hosts"  = local.fluxcd_ssh_known_hosts
  }
  type = "Opaque"

  depends_on = [
    kubectl_manifest.fluxcd_install,
  ]
}


resource "kubectl_manifest" "fluxcd_sync" {
  yaml_body = templatefile(
    "${path.module}/files/fluxcd/gitrepository-flux-system.yaml.tftpl",
    {
      url      = local.fluxcd_repository_target_url
      branch   = var.gitops.repository_target_branch
      interval = var.fluxcd.repository_scan_interval
      secret   = local.fluxcd_ssh_credentials_secret_name
    }
  )

  depends_on = [
    kubernetes_secret.fluxcd_ssh_credentials,
    kubectl_manifest.fluxcd_install,
  ]
}

# Create the initial kustomization
resource "kubectl_manifest" "fluxcd_infra_stage0_kustomization" {
  yaml_body = local.fluxcd_cluster_production_infra_stage0_kustomization

  depends_on = [
    kubectl_manifest.fluxcd_sync,
  ]
}

# Create the initial kustomization
resource "kubectl_manifest" "fluxcd_infra_stage1_kustomization" {
  yaml_body = local.fluxcd_cluster_production_infra_stage1_kustomization

  depends_on = [
    kubectl_manifest.fluxcd_infra_stage0_kustomization,
  ]
}

# Create the initial kustomization
resource "kubectl_manifest" "fluxcd_infra_stage2_kustomization" {
  yaml_body = local.fluxcd_cluster_production_infra_stage2_kustomization

  depends_on = [
    kubectl_manifest.fluxcd_infra_stage1_kustomization,
  ]
}

# Create the initial kustomization
resource "kubectl_manifest" "fluxcd_infra_stage_final_kustomization" {
  yaml_body = local.fluxcd_cluster_production_infra_stage_final_kustomization

  depends_on = [
    kubectl_manifest.fluxcd_infra_stage2_kustomization,
  ]
}

####################################################################################################################################
# Configure Helm Repositories
####################################################################################################################################

locals {
  helm_repositories = var.gitops.helm_repositories
}

# Create secrets for the helm repositories
resource "kubernetes_secret" "fluxcd_extra_helm_repositories" {
  for_each = local.helm_repositories

  metadata {
    name      = "helm-creds-${each.key}"
    namespace = var.fluxcd.namespace
    labels = {
      "app.kubernetes.io/name"       = "bootstrap"
      "app.kubernetes.io/component"  = "fluxcd"
      "app.kubernetes.io/managed-by" = "Terraform"
      "app.kubernetes.io/created-by" = "Terraform"
    }
  }

  data = {
    "username" = each.value.username
    "password" = each.value.password
  }
  type = "Opaque"

  depends_on = [
    kubectl_manifest.fluxcd_install,
  ]
}

# Create the helm repositories themselves
resource "kubectl_manifest" "fluxcd_extra_helm_repositories" {
  for_each = local.helm_repositories
  yaml_body = templatefile(
    "${path.module}/files/fluxcd/helmrepository-flux-system.yaml.tftpl",
    {
      name        = each.key
      namespace   = var.fluxcd.namespace
      url         = each.value.url
      secret_name = "helm-creds-${each.key}"
      interval    = var.fluxcd.artifact_repository_scan_interval
      type        = each.value.type
    }
  )

  depends_on = [
    kubernetes_secret.fluxcd_extra_helm_repositories,
    kubectl_manifest.fluxcd_install,
  ]
}
