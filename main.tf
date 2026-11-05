# ==========================================
# 1. Contenedor Web (Apache + PHP)
# ==========================================
resource "proxmox_virtual_environment_container" "web" {
  node_name    = var.pm_node
  vm_id        = var.ct_id
  unprivileged = true
  started      = true

  features {
    nesting = true
  }

  initialization {
    hostname = var.ct_name
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "${var.ct_ip}/24"
        gateway = var.ct_gw
      }
    }
    user_account {
      keys = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = "local:vztmpl/${var.ct_template}"
    type             = "ubuntu"
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
  }
}

# Configuración y aprovisionamiento del contenedor Web
resource "terraform_data" "web_setup" {
  depends_on = [proxmox_virtual_environment_container.web]

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.ct_ip
    private_key = file("~/.ssh/id_ed25519")
    timeout     = "3m"
  }

  provisioner "file" {
    destination = "/usr/local/bin/backup-web.sh"
    content     = <<-EOT
      #!/bin/bash
      set -euo pipefail
      FECHA=$(date +%F)
      DEST=/var/backups-arboles/web
      mkdir -p "$DEST"
      logger -t backup-web "Inicio backup $FECHA"
      tar czf "$DEST/web-$FECHA.tar.gz" /var/www/html
      find "$DEST" -name 'web-*.tar.gz' -mtime +7 -delete
      logger -t backup-web "Fin backup OK: $(du -h "$DEST/web-$FECHA.tar.gz" | cut -f1)"
      EOT
  }

  provisioner "file" {
    destination = "/usr/local/bin/monitor-backup.sh"
    content     = <<-EOT
      #!/bin/bash
      exec &> >(logger -t monitor-backup)
      LAST=$(ls -t /var/backups-arboles/web/web-*.tar.gz 2>/dev/null | head -1)
      if [ -z "$LAST" ]; then
        echo "CRITICO: no existe ningun backup"
        exit 1
      fi
      EDAD=$(( ( $(date +%s) - $(stat -c %Y "$LAST") ) / 86400 ))
      [ "$EDAD" -le 1 ] && echo " * OK: backup reciente ($LAST)" || echo " [ AVISO ] : ultimo backup antiguo ($EDAD dias)"
      EOT
  }

  provisioner "file" {
    destination = "/etc/cron.d/web-backup"
    content     = <<-EOT
      30 2 * * * root /usr/local/bin/backup-web.sh
      30 8 * * * root /usr/local/bin/monitor-backup.sh
      EOT
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y apache2 php libapache2-mod-php php-mysqli git rsync cron certbot python3-certbot-apache",
      "rm -rf /var/www/html/*",
      "git clone https://github.com/oscortrea/Ubuntu-paiporta /var/www/html",

      # Creación del VirtualHost configurado para tu dominio
      "cat << 'EOF' > /etc/apache2/sites-available/paiport.conf",
      "<VirtualHost *:80>",
      "    ServerName oscortrea.yayat.es",
      "    ServerAdmin webmaster@localhost",
      "    DocumentRoot /var/www/html",
      "    <Directory /var/www/html>",
      "        Options Indexes FollowSymLinks",
      "        AllowOverride All",
      "        Require all granted",
      "    </Directory>",
      "    ErrorLog $${APACHE_LOG_DIR}/paiport_error.log",
      "    CustomLog $${APACHE_LOG_DIR}/paiport_access.log combined",
      "</VirtualHost>",
      "EOF",

      "a2ensite paiport.conf",
      "a2dissite 000-default.conf",
      "a2enmod rewrite",

      # Certificado SSL automático con Let's Encrypt para tu dominio de clase
      #"certbot --apache --non-interactive --agree-tos -m oscortrea@alu.edu.gva.es -d oscortrea.yatat.es --redirect",

      "chmod 755 /usr/local/bin/backup-web.sh /usr/local/bin/monitor-backup.sh",
      "chmod 644 /etc/cron.d/web-backup",
      "systemctl enable --now apache2 cron",
      "systemctl restart apache2",
      "/usr/local/bin/backup-web.sh",
    ]
  }
}


# ==========================================
# 2. Contenedor Base de Datos (MySQL)
# ==========================================
resource "proxmox_virtual_environment_container" "db" {
  node_name    = var.pm_node
  vm_id        = var.db_id
  unprivileged = true
  started      = true

  features {
    nesting = true
  }

  initialization {
    hostname = var.db_name
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "${var.db_ip}/24"
        gateway = var.ct_gw
      }
    }
    user_account {
      keys = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = "local:vztmpl/${var.ct_template}"
    type             = "ubuntu"
  }

  disk {
    datastore_id = var.storage
    size         = 10
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
  }
}

# Configuración y aprovisionamiento del contenedor MySQL
resource "terraform_data" "db_setup" {
  depends_on = [proxmox_virtual_environment_container.db]

  connection {
    type        = "ssh"
    user        = "root"
    host        = var.db_ip
    private_key = file("~/.ssh/id_ed25519")
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y mysql-server git rsync",
      "systemctl enable --now mysql",
      "sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf",
      "systemctl restart mysql",
      # Clonar el repositorio temporalmente en la BD para leer el create-db.sql directamente de GitHub
      "rm -rf /tmp/repo-db && git clone https://github.com/oscortrea/Ubuntu-paiporta /tmp/repo-db",
      "mysql -e \"CREATE DATABASE IF NOT EXISTS PaiportArbolado CHARACTER SET utf8mb4;\"",
      "mysql -e \"CREATE USER IF NOT EXISTS 'user_bd'@'192.168.40.50' IDENTIFIED BY 'passwdbd';\"",
      "mysql -e \"GRANT ALL PRIVILEGES ON PaiportArbolado.* TO 'user_bd'@'192.168.40.50';\"",
      "mysql -e \"FLUSH PRIVILEGES;\"",
      # Importar el esquema usando el fichero directamente desde el repositorio clonado
      "mysql PaiportArbolado < /tmp/repo-db/create-db.sql",
      "rm -rf /tmp/repo-db" # Limpiar el repositorio temporal
    ]
  }
}

# Outputs para consultar las IPs de ambos servicios
output "web_ip" {
  value = var.ct_ip
}

output "db_ip" {
  value = var.db_ip
}
