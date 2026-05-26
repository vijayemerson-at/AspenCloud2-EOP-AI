# kubernetes-namespaces.tf

####################################################################################################################################
# Read files
####################################################################################################################################

locals {
  # namespace: kube-system
  kube_system_namespace        = file("${path.module}/files/namespaces/kube-system/ns.yaml")
  kube_system_network_policies = file("${path.module}/files/namespaces/kube-system/networkpolicies.yaml")
  kube_system_service_accounts = file("${path.module}/files/namespaces/kube-system/sa.yaml")

  # namespace: default
  default_namespace        = file("${path.module}/files/namespaces/default/ns.yaml")
  default_network_policies = file("${path.module}/files/namespaces/default/networkpolicies.yaml")
  default_service_accounts = file("${path.module}/files/namespaces/default/sa.yaml")

  # namespace: kube-public
  kube_public_namespace        = file("${path.module}/files/namespaces/kube-public/ns.yaml")
  kube_public_network_policies = file("${path.module}/files/namespaces/kube-public/networkpolicies.yaml")
  kube_public_service_accounts = file("${path.module}/files/namespaces/kube-public/sa.yaml")

  # namespace: kube-node-lease
  kube_node_lease_namespace        = file("${path.module}/files/namespaces/kube-node-lease/ns.yaml")
  kube_node_lease_network_policies = file("${path.module}/files/namespaces/kube-node-lease/networkpolicies.yaml")
  kube_node_lease_service_accounts = file("${path.module}/files/namespaces/kube-node-lease/sa.yaml")
}
