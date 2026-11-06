# Infraestructura Cloud Automatizada con OpenTofu y Proxmox

Proyecto de despliegue y gestión automatizada de servicios web y bases de datos sobre contenedores LXC en un hipervisor Proxmox VE utilizando OpenTofu.

## Arquitectura

La infraestructura despliega dos contenedores LXC interconectados sobre el puente de red `vmbr0` con direccionamiento IP estático:

- **`web` (`192.168.40.50`)**: Servidor web principal.
- **`db` (`192.168.40.51`)**: Servidor de base de datos relacional (MariaDB/MySQL).

## Seguridad y Firewall

El proyecto implementa hardening de red mediante el firewall nativo de Proxmox gestionado por código:
- **Política predeterminada:** `DROP` (bloqueo total de entrada por defecto en las interfaces de red).
- **Tráfico Web:** Puertos **80** (HTTP) abiertos al tráfico autorizado.
- **Tráfico de Base de Datos:** Puerto **3306** (MySQL) estrictamente limitado y accesible **únicamente** desde la IP del contenedor web (`192.168.40.50`).

## Despliegue

1. Inicializa el directorio de trabajo de OpenTofu:
   ```bash
   tofu init
   tofu plan
   tofu apply
