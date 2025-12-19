variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "dlive_key" {
  description = "DLive stream key"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/api-secrets/hetzner-server/id_ed25519.pub"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx22"
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "hel1"
}

variable "image" {
  description = "Server OS image"
  type        = string
  default     = "ubuntu-24.04"
}
