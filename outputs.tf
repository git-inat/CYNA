# ============================================================================
# Projet CYNA - Outputs Terraform
# Fichier : terraform/outputs.tf
# Objet   : Informations affichées après terraform apply
# ============================================================================

output "container_vm_id" {
  description = "VMID du conteneur LXC créé dans Proxmox."
  value       = proxmox_virtual_environment_container.ct_test.vm_id
}

output "container_hostname" {
  description = "Nom d'hôte du conteneur LXC créé."
  value       = var.container_hostname
}

output "container_node" {
  description = "Noeud Proxmox sur lequel le conteneur est déployé."
  value       = var.node_name
}

output "container_pool" {
  description = "Pool Proxmox utilisé pour organiser la ressource."
  value       = var.pool_id
}

output "container_bridge" {
  description = "Bridge réseau utilisé par le conteneur."
  value       = var.network_bridge
}

output "container_ipv4_mode" {
  description = "Mode d'adressage IPv4 configuré pour le conteneur."
  value       = var.container_ipv4_address
}

output "deployment_summary" {
  description = "Résumé du déploiement Terraform CYNA."
  value = {
    project      = "CYNA"
    resource     = "LXC Proxmox"
    node         = var.node_name
    vm_id        = proxmox_virtual_environment_container.ct_test.vm_id
    hostname     = var.container_hostname
    pool         = var.pool_id
    bridge       = var.network_bridge
    datastore    = var.datastore_id
    started      = var.container_started
  }
}
