# Create Kubernetes resources and apply manifests
locals {
  core_services_helm_release = templatefile(
    "${path.module}/files/core-services/core-services-helm-release.yaml.tftpl",
    {
      core_services_version               = "0.114.9"
      core_services_application_id        = "9282b52a-689a-44e3-9a60-6cdacb999136"
      core_services_version_id            = "74f30b3f-b06a-4949-b134-4929591a038b"
      core_services_software_id           = "e26ecdfe-ad86-4297-bb44-cac306388575"
      core_services_helm_repository       = "platform"
      core_service_release_name           = "aspencloud-core-services-0"
      secret_store_name                   = var.system_services.key_vault_name
      secret_store_tenant_id              = var.system_services.key_vault_tenant_id
      secret_store_client_id              = var.system_services.key_vault_identity_user_assigned_client_id
      software_license_manager_server_url = var.system_services.software_license_manager_server_url
      software_license_manager_buckets    = var.system_services.software_license_manager_buckets
    }
  )
}

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = {
      "linkerd.io/is-control-plane" = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_namespace" "envoy-gateway-system" {
  metadata {
    name = "envoy-gateway-system"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_namespace" "aspencloud" {
  metadata {
    name = "aspencloud"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}



