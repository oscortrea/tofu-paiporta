variable "pm_api_url" {
  type    = string
  default = "https://192.168.40.5:8006"
}

variable "pm_user" {
  type    = string
  default = "root@pam"
}

variable "pm_token_name" {
  type    = string
  default = "tofu"
}

variable "pm_token_secret" {
  type      = string
  sensitive = true
}

variable "ct_name" {
  type    = string
  default = "web-01"
}

variable "ct_ip" {
  type    = string
  default = "192.168.40.50"
}

variable "pm_host" {
  type    = string
  default = "root@10.0.2.3"
}

variable "pm_node" {
  type    = string
  default = "proxmox"
}

variable "ct_id" {
  type    = number
  default = 100
}

variable "ct_gw" {
  type    = string
  default = "192.168.40.254"
}

variable "ct_template" {
  type    = string
  default = "ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
}

variable "storage" {
  type    = string
  default = "local-lvm"
}

# ==========================================
# Nuevas variables para la Base de Datos (db-01)
# ==========================================
variable "db_id" {
  type    = number
  default = 101
}

variable "db_name" {
  type    = string
  default = "db-01"
}

variable "db_ip" {
  type    = string
  default = "192.168.40.51"
}
