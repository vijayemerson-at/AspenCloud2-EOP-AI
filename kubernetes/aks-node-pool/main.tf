resource "azurerm_kubernetes_cluster_node_pool" "this" {

  name = var.cluster_node_pool.name
  mode = var.cluster_node_pool.mode

  vm_size                       = var.cluster_node_pool.vm_size
  zones                         = var.cluster_node_pool.zones
  capacity_reservation_group_id = var.cluster_node_pool.capacity_reservation_group_id
  temporary_name_for_rotation   = var.cluster_node_pool.temporary_name_for_rotation # needed for node pool rotation after changing vm_size

  kubernetes_cluster_id = var.cluster_node_pool.kubernetes_cluster_id
  orchestrator_version  = var.cluster_node_pool.orchestrator_version

  vnet_subnet_id         = var.cluster_node_pool.vnet_subnet_id
  node_public_ip_enabled = var.cluster_node_pool.node_public_ip_enabled
  pod_subnet_id          = var.cluster_node_pool.pod_subnet_id

  os_sku            = var.cluster_node_pool.os_sku
  os_type           = var.cluster_node_pool.os_type
  os_disk_size_gb   = var.cluster_node_pool.os_disk_size_gb
  os_disk_type      = var.cluster_node_pool.os_disk_type
  max_pods          = var.cluster_node_pool.max_pods
  gpu_instance      = var.cluster_node_pool.gpu_instance
  kubelet_disk_type = var.cluster_node_pool.kubelet_disk_type
  ultra_ssd_enabled = var.cluster_node_pool.ultra_ssd_enabled

  auto_scaling_enabled         = var.cluster_node_pool.auto_scaling_enabled
  node_count                   = var.cluster_node_pool.node_count
  min_count                    = var.cluster_node_pool.min_count
  max_count                    = var.cluster_node_pool.max_pods
  priority                     = var.cluster_node_pool.priority
  proximity_placement_group_id = var.cluster_node_pool.proximity_placement_group_id
  spot_max_price               = var.cluster_node_pool.spot_max_price
  scale_down_mode              = var.cluster_node_pool.scale_down_mode
  workload_runtime             = var.cluster_node_pool.workload_runtime

  host_encryption_enabled = var.cluster_node_pool.host_encryption_enabled
  fips_enabled            = var.cluster_node_pool.fips_enabled

  eviction_policy = var.cluster_node_pool.eviction_policy
  host_group_id   = var.cluster_node_pool.host_group_id

  dynamic "kubelet_config" {
    for_each = var.cluster_node_pool.kubelet_config[*]
    content {
      allowed_unsafe_sysctls    = var.cluster_node_pool.kubelet_config.allowed_unsafe_sysctls
      container_log_max_size_mb = var.cluster_node_pool.kubelet_config.container_log_max_size_mb
      cpu_cfs_quota_enabled     = var.cluster_node_pool.kubelet_config.cpu_cfs_quota_enabled
      cpu_cfs_quota_period      = var.cluster_node_pool.kubelet_config.cpu_cfs_quota_period
      cpu_manager_policy        = var.cluster_node_pool.kubelet_config.cpu_manager_policy
      image_gc_high_threshold   = var.cluster_node_pool.kubelet_config.image_gc_high_threshold
      image_gc_low_threshold    = var.cluster_node_pool.kubelet_config.image_gc_low_threshold
      pod_max_pid               = var.cluster_node_pool.kubelet_config.pod_max_pid
      topology_manager_policy   = var.cluster_node_pool.kubelet_config.topology_manager_policy
    }
  }
  dynamic "linux_os_config" {
    for_each = var.cluster_node_pool.linux_os_config[*]
    content {
      swap_file_size_mb = var.cluster_node_pool.linux_os_config.swap_file_size_mb

      dynamic "sysctl_config" {
        for_each = var.cluster_node_pool.linux_os_config.sysctl_config[*]
        content {
          fs_aio_max_nr                      = var.cluster_node_pool.linux_os_config.sysctl_config.fs_aio_max_nr
          fs_file_max                        = var.cluster_node_pool.linux_os_config.sysctl_config.fs_file_max
          fs_inotify_max_user_watches        = var.cluster_node_pool.linux_os_config.sysctl_config.fs_inotify_max_user_watches
          fs_nr_open                         = var.cluster_node_pool.linux_os_config.sysctl_config.fs_nr_open
          kernel_threads_max                 = var.cluster_node_pool.linux_os_config.sysctl_config.kernel_threads_max
          net_core_netdev_max_backlog        = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_netdev_max_backlog
          net_core_optmem_max                = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_optmem_max
          net_core_rmem_default              = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_rmem_default
          net_core_rmem_max                  = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_rmem_max
          net_core_somaxconn                 = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_somaxconn
          net_core_wmem_default              = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_wmem_default
          net_core_wmem_max                  = var.cluster_node_pool.linux_os_config.sysctl_config.net_core_wmem_max
          net_ipv4_ip_local_port_range_max   = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_max
          net_ipv4_ip_local_port_range_min   = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_min
          net_ipv4_neigh_default_gc_thresh1  = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh1
          net_ipv4_neigh_default_gc_thresh2  = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh2
          net_ipv4_neigh_default_gc_thresh3  = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh3
          net_ipv4_tcp_fin_timeout           = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_fin_timeout
          net_ipv4_tcp_keepalive_intvl       = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_intvl
          net_ipv4_tcp_keepalive_probes      = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_probes
          net_ipv4_tcp_keepalive_time        = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_time
          net_ipv4_tcp_max_syn_backlog       = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_max_syn_backlog
          net_ipv4_tcp_max_tw_buckets        = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_max_tw_buckets
          net_ipv4_tcp_tw_reuse              = var.cluster_node_pool.linux_os_config.sysctl_config.net_ipv4_tcp_tw_reuse
          net_netfilter_nf_conntrack_buckets = var.cluster_node_pool.linux_os_config.sysctl_config.net_netfilter_nf_conntrack_buckets
          net_netfilter_nf_conntrack_max     = var.cluster_node_pool.linux_os_config.sysctl_config.net_netfilter_nf_conntrack_max
          vm_max_map_count                   = var.cluster_node_pool.linux_os_config.sysctl_config.vm_max_map_count
          vm_swappiness                      = var.cluster_node_pool.linux_os_config.sysctl_config.vm_swappiness
          vm_vfs_cache_pressure              = var.cluster_node_pool.linux_os_config.sysctl_config.vm_vfs_cache_pressure
        }
      }
      transparent_huge_page_defrag  = var.cluster_node_pool.linux_os_config.transparent_huge_page_defrag
      transparent_huge_page_enabled = var.cluster_node_pool.linux_os_config.transparent_huge_page_enabled
    }
  }

  dynamic "node_network_profile" {
    for_each = var.cluster_node_pool.node_network_profile[*]
    content {
      dynamic "allowed_host_ports" {
        for_each = var.cluster_node_pool.node_network_profile.allowed_host_ports
        content {
          port_start = var.cluster_node_pool.node_network_profile.allowed_host_ports.port_start
          port_end   = var.cluster_node_pool.node_network_profile.allowed_host_ports.port_end
          protocol   = var.cluster_node_pool.node_network_profile.allowed_host_ports.protocol
        }
      }
      application_security_group_ids = var.cluster_node_pool.node_network_profile.application_security_group_ids
      node_public_ip_tags            = var.cluster_node_pool.node_network_profile.node_public_ip_tags
    }
  }

  snapshot_id = var.cluster_node_pool.snapshot_id

  dynamic "upgrade_settings" {
    for_each = var.cluster_node_pool.upgrade_settings[*]
    content {
      drain_timeout_in_minutes      = var.cluster_node_pool.upgrade_settings.drain_timeout_in_minutes
      node_soak_duration_in_minutes = var.cluster_node_pool.upgrade_settings.node_soak_duration_in_minutes
      max_surge                     = var.cluster_node_pool.upgrade_settings.max_surge
    }

  }

  dynamic "windows_profile" {
    for_each = var.cluster_node_pool.windows_profile[*]
    content {
      outbound_nat_enabled = var.cluster_node_pool.windows_profile.outbound_nat_enabled
    }
  }

  node_labels = var.cluster_node_pool.node_labels
  node_taints = var.cluster_node_pool.node_taints

  tags = merge(var.tags, var.cluster_node_pool.tags)

  lifecycle {
    ignore_changes = [
      tags,
      node_count,
    ]
  }
}