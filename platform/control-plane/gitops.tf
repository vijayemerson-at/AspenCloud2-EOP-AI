# gitops.tf

locals {
  gitops_repository_name           = var.gitops.repository_name
  gitops_repository_default_branch = var.gitops.repository_target_branch

  gitops_repository_file_prefix = var.gitops.repository_target_path
  gitops_use_github             = var.gitops.external_repository_address == "" ? true : false

  # In here we send to the cluster some of the data we've got in Terraform that will be required later on.

  cluster_vars_yaml = templatefile(
    "${path.module}/files/gitops/cluster-vars.yaml.tftpl",
    {
      keda_user_assigned_identity_client_id = azurerm_user_assigned_identity.keda.client_id
      aks_oidc_audience                     = "api://AzureADTokenExchange"
      aks_oidc_issuer_url                   = var.kubernetes_cluster.oidc_issuer_url
      kubernetes_namespace                  = "kyverno"
      cluster_cloud_provider                = "azure"
      cluster_cloud_region                  = var.location
      cluster_primary_container_registry    = try(var.global.container_image_repositories[sort(keys(var.global.container_image_repositories))[0]].host, "")
      cluster_container_registries          = try(join(",", [for k, v in var.global.container_image_repositories : v.host]), "")
      cluster_dns_domain_name               = var.system_services.cluster_external_dns_zone_name
      cluster_name                          = var.kubernetes_cluster.name
      gitops_repository_name                = local.gitops_use_github ? local.gitops_repository_name : "external-repository"
      gitops_repository_url                 = local.gitops_use_github ? github_repository.gitops[0].http_clone_url : var.gitops.external_repository_address
      oidc_issuer                           = var.system_services.oidc_issuer
      oidc_metadata                         = var.system_services.oidc_metadata
      resource_group_name                   = var.resource_group.name
      monitor_workspace_query_endpoint      = azurerm_monitor_workspace.this.query_endpoint
    }
  )


  # Here we want to create a way to expose the manifests in a single collection. Will simplify use of rudimentary
  # help to commit those to GitOps. Also can be used to maintain compatibility with current GitOps repositories
  # on gitops-01.mtl.mnubo.com
  kubernetes_components_manifests = {
    fluxcd_cluster_production_infra_stage0_kustomization = {
      filename       = "${local.gitops_repository_file_prefix}/clusters/production/infra-stage0.yaml"
      content        = local.fluxcd_cluster_production_infra_stage0_kustomization
      commit_message = "chore: deploy production cluster infra-stage0 kustomization"
    }
    fluxcd_cluster_production_infra_stage1_kustomization = {
      filename       = "${local.gitops_repository_file_prefix}/clusters/production/infra-stage1.yaml"
      content        = local.fluxcd_cluster_production_infra_stage1_kustomization
      commit_message = "chore: deploy production cluster infra-stage1 kustomization"
    }
    fluxcd_cluster_production_infra_stage2_kustomization = {
      filename       = "${local.gitops_repository_file_prefix}/clusters/production/infra-stage2.yaml"
      content        = local.fluxcd_cluster_production_infra_stage2_kustomization
      commit_message = "chore: deploy production cluster stage2 kustomization"
    }
    fluxcd_cluster_production_infra_stage_final_kustomization = {
      filename       = "${local.gitops_repository_file_prefix}/clusters/production/infra-stage-final.yaml"
      content        = local.fluxcd_cluster_production_infra_stage_final_kustomization
      commit_message = "chore: deploy production cluster final stage kustomization"
    }
    fluxcd_cluster_infrastructure_directory = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/.gitkeep"
      content        = local.fluxcd_gitkeep_content
      commit_message = "chore: ensure infrastructure directory is created."
    }
    fluxcd_cluster_infra_stage0_directory = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/.gitkeep"
      content        = local.fluxcd_gitkeep_content
      commit_message = "chore: ensure infrastructure/stage0 directory is created."
    }
    fluxcd_cluster_infra_stage1_directory = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage1/.gitkeep"
      content        = local.fluxcd_gitkeep_content
      commit_message = "chore: ensure infrastructure/stage1 directory is created."
    }
    fluxcd_cluster_infra_stage2_directory = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage2/.gitkeep"
      content        = local.fluxcd_gitkeep_content
      commit_message = "chore: ensure infrastructure/stage2 directory is created."
    }
    fluxcd_cluster_infra_stage_final_directory = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage-final/.gitkeep"
      content        = local.fluxcd_gitkeep_content
      commit_message = "chore: ensure infrastructure/stage-final directory is created."
    }
    fluxcd_network_policy = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/fluxcd/network-policies.yaml"
      content        = local.fluxcd_network_policy_manifest
      commit_message = "chore: deploy extra network policy for fluxcd"
    }
    #Kyverno
    kyverno_helm_release = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/kyverno/helm-release.yaml"
      content        = local.kyverno_helm_release
      commit_message = "chore: deploy kyverno helm-release.yaml"
    }
    kyverno_network_policy = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/kyverno/network-policy.yaml"
      content        = local.kyverno_network_policy
      commit_message = "chore: deploy kyverno network policy"
    }
    #Kyverno Policies
    kyverno_policy_service_accounts_disable_sa_token = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage1/kyverno-policies/cluster-policy-disable-sa-token.yaml"
      content        = local.kyverno_service_accounts_disable_sa_token
      commit_message = "chore: deploy kyverno policy to disable default server account tokens"
    }
    kyverno_image_pull_secret_replication_policy = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage1/kyverno-policies/cluster-policy-pull-secrets.yaml"
      content        = local.kyverno_image_pull_secret_replication_policy
      commit_message = "chore: deploy kyverno policies to replicate image pull secrets"
    }
    kyverno_pod_image_pull_policy = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage1/kyverno-policies/cluster-policy-pod-add-pull-secrets.yaml"
      content        = local.kyverno_pod_image_pull_policy
      commit_message = "chore: deploy kyverno policies to automatically insert image pull secrets when required"
    }
    kyverno_sync_cluster_vars_policy = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage1/kyverno-policies/cluster-policy-sync-cluster-vars.yaml"
      content        = local.kyverno_sync_cluster_vars_policy
      commit_message = "chore: deploy kyverno policy to sync cluster-vars configmap"
    }

    ##Keda
    keda_helm_release = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage-final/keda/keda_helm_release.yaml"
      content        = local.keda_helm_release
      commit_message = "chore: deploy keda helm-release.yaml"
    }
    keda = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/keda/keda.yaml"
      content        = local.keda
      commit_message = "chore: deploy keda kubernetes components"
    }

    #Stakater reloader
    stakater_reloader_helm_release = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage-final/stakater-reloader/stakater-reloader_helm_release.yaml"
      content        = local.stakater_reloader_helm_release
      commit_message = "chore: deploy Stakater reloader helm release"
    }

    #System Service
    core_services_helm_release = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage-final/core-services/core-services_helm_release.yaml"
      content        = local.core_services_helm_release
      commit_message = "chore: deploy core-services helm release"
    }

    //Load balancer should go here

    /*
    aad_pod_identity = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/aad-pod-identity/components.yaml"
      content        = local.aad_pod_identity_manifest
      commit_message = "chore: deploy aad-pod-identity"
    }
*/

    // Disabling for now


    gitops_cluster_vars = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/gitops/cluster-vars.yaml"
      content        = local.cluster_vars_yaml
      commit_message = "chore: deploy cluster-vars configmap in kyverno namespace"
    }

    kube_system_namespace = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-system/ns.yaml"
      content        = local.kube_system_namespace
      commit_message = "chore: deploy namespace definition for kube-system"
    }
    kube_system_network_policies = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-system/networkpolicies.yaml"
      content        = local.kube_system_network_policies
      commit_message = "chore: deploy network-policies for kube-system"
    }
    kube_system_service_accounts = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-system/sa.yaml"
      content        = local.kube_system_service_accounts
      commit_message = "chore: deploy service accounts for kube-system"
    }
    default_namespace = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/default/ns.yaml"
      content        = local.default_namespace
      commit_message = "chore: deploy namespace definition for default"
    }
    default_network_policies = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/default/networkpolicies.yaml"
      content        = local.default_network_policies
      commit_message = "chore: deploy network-policies for default"
    }
    default_service_accounts = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/default/sa.yaml"
      content        = local.default_service_accounts
      commit_message = "chore: deploy service accounts for default"
    }

    kube_public_namespace = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-public/ns.yaml"
      content        = local.kube_public_namespace
      commit_message = "chore: deploy namespace definition for kube-public"
    }
    kube_public_network_policies = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-public/networkpolicies.yaml"
      content        = local.kube_public_network_policies
      commit_message = "chore: deploy network-policies for kube-public"
    }
    kube_public_service_accounts = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-public/sa.yaml"
      content        = local.kube_public_service_accounts
      commit_message = "chore: deploy service accounts for kube-public"
    }
    kube_node_lease_namespace = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-node-lease/ns.yaml"
      content        = local.kube_node_lease_namespace
      commit_message = "chore: deploy namespace definition for kube-node-lease"
    }
    kube_node_lease_network_policies = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-node-lease/networkpolicies.yaml"
      content        = local.kube_node_lease_network_policies
      commit_message = "chore: deploy network-policies for kube-node-lease"
    }
    kube_node_lease_service_accounts = {
      filename       = "${local.gitops_repository_file_prefix}/infrastructure/stage0/namespaces/kube-node-lease/sa.yaml"
      content        = local.kube_node_lease_service_accounts
      commit_message = "chore: deploy service accounts for kube-node-lease"
    }
  }

  github_manifests = local.gitops_use_github ? local.kubernetes_components_manifests : {}
}

####################################################################################################################################
# Setup the Github repository for this instance
####################################################################################################################################


resource "github_repository" "gitops" {
  count       = local.gitops_use_github ? 1 : 0
  name        = local.gitops_repository_name
  description = "Repository for the ${var.kubernetes_cluster.name} platform instance instance"
  visibility  = "private"
  auto_init   = true
}

# Add a deploy key
resource "github_repository_deploy_key" "gitops_repository_deploy_key" {
  title      = "AC20 Deploy Key"
  repository = local.gitops_repository_name
  key        = tls_private_key.fluxcd.public_key_openssh
  read_only  = "false"

  depends_on = [github_repository.gitops, tls_private_key.fluxcd]
}

####################################################################################################################################
# Create manifests in github
####################################################################################################################################

resource "random_string" "tmp_prefix_manifests" {
  length  = 10
  special = false
}

resource "local_file" "github_manifests" {
  for_each = { for key, val in local.github_manifests :
  key => val if val.filename != null }


  content  = each.value.content
  filename = "/tmp/${random_string.tmp_prefix_manifests.result}/${each.value.filename}"
}

resource "github_repository_file" "gitops" {
  for_each = { for key, val in local.github_manifests :
  key => val if val.filename != null }

  repository          = github_repository.gitops[0].name
  branch              = local.gitops_repository_default_branch
  file                = each.value.filename
  content             = each.value.content
  commit_message      = each.value.commit_message
  commit_author       = "Terraform Bootstrap Process"
  commit_email        = "noreply@aspentech.ai"
  overwrite_on_create = true
}
