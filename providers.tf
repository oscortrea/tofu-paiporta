provider "proxmox" {
endpoint = var.pm_api_url
api_token = "${var.pm_user}!${var.pm_token_name}=${var.pm_token_secret}"
insecure = true # laboratorio con certificado autofirmado
}
