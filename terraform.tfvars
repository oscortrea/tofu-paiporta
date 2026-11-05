# ==========================================
# Configuración general de Proxmox
# ==========================================
pm_api_url      = "https://192.168.40.5:8006"
pm_user         = "root@pam"
pm_token_name   = "tofu"
pm_token_secret = "033afeca-5b39-48a1-b7f8-cc41b4c4dea5"
pm_node         = "proxmox"
storage         = "local-lvm"
ct_gw           = "192.168.40.254"
ct_template     = "ubuntu-26.04-standard_26.04-1_amd64.tar.zst"

# ==========================================
# Contenedor 1: Servidor Web (Apache + PHP)
# ==========================================
ct_id           = 100
ct_name         = "web-01"
ct_ip           = "192.168.40.50"

# ==========================================
# Contenedor 2: Base de Datos (MySQL)
# ==========================================
db_id           = 101
db_name         = "db-01"
db_ip           = "192.168.40.51"
