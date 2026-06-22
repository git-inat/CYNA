# ============================================================================
# Projet CYNA - Variables Terraform
# Fichier : terraform/variables.tf
# Objet   : Paramètres utilisés pour le provisionnement Proxmox
# ============================================================================

variable "proxmox_endpoint" {
  description = "URL de l'API Proxmox utilisée par Terraform."
  type        = string
  default     = "https://10.0.40.10:8006/api2/json"
}

variable "proxmox_username" {
  description = "Compte Proxmox dédié à Terraform."
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Mot de passe du compte Proxmox Terraform. A renseigner localement dans terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

variable "proxmox_insecure" {
  description = "Autorise le certificat auto-signé de Proxmox dans le lab CYNA."
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Nom du noeud Proxmox utilisé pour le déploiement."
  type        = string
  default     = "Geneve"
}

variable "pool_id" {
  description = "Pool Proxmox utilisé pour regrouper les ressources créées par Terraform."
  type        = string
  default     = "terraform-test"
}

variable "datastore_id" {
  description = "Stockage Proxmox utilisé pour le disque du conteneur."
  type        = string
  default     = "local"
}

variable "template_file_id" {
  description = "Template LXC Debian utilisé pour créer le conteneur de test."
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "network_bridge" {
  description = "Bridge réseau Proxmox utilisé par le conteneur."
  type        = string
  default     = "Admin"
}

variable "container_vm_id" {
  description = "Identifiant VMID du conteneur LXC créé par Terraform."
  type        = number
  default     = 114
}

variable "container_hostname" {
  description = "Nom d'hôte du conteneur LXC de test."
  type        = string
  default     = "tf-test-ct"
}

variable "container_description" {
  description = "Description visible dans Proxmox."
  type        = string
  default     = "CT de test cree avec Terraform pour le projet CYNA"
}

variable "container_password" {
  description = "Mot de passe initial du compte root du conteneur. A renseigner localement dans terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

variable "container_ipv4_address" {
  description = "Adresse IPv4 du conteneur. La valeur dhcp permet une attribution automatique."
  type        = string
  default     = "dhcp"
}

variable "container_disk_size" {
  description = "Taille du disque du conteneur en Go."
  type        = number
  default     = 4
}

variable "container_cpu_cores" {
  description = "Nombre de coeurs CPU attribués au conteneur."
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Mémoire RAM dédiée au conteneur en Mo."
  type        = number
  default     = 512
}

variable "container_swap" {
  description = "Mémoire swap attribuée au conteneur en Mo."
  type        = number
  default     = 512
}

variable "container_started" {
  description = "Démarre automatiquement le conteneur après création."
  type        = bool
  default     = true
}
