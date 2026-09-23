# 🛡️ Policy-as-Code con OPA Gatekeeper (Equipo 5)

Este repositorio contiene la implementación técnica de OPA Gatekeeper para asegurar un clúster de Kubernetes, garantizando el cumplimiento de los controles de la norma ISO/IEC 27001:2022 mediante políticas de seguridad como código.

## 📋 Prerrequisitos

Trabajeremos con la arquitectura de clúster en donde habrán dos máquinas: una que es el control y master, y otra que es el worker, tal como lo hicimos en el curso.

Antes de iniciar la instalación, el nodo maestro (`master01`) debe tener Kubernetes funcional y contar con las siguientes herramientas.

**1. Instalar Git y Helm (Ejecutar como `root`):**

su -
dnf install epel-release -y
dnf install git helm -y
exit

**2. Descargar el repositorio de este proyecto, para tener acceso a los scripts, ejemplos y manifiestos.

git clone [https://github.com/luisgleonv/proyecto-equipo-5.git](https://github.com/luisgleonv/proyecto-equipo-5.git)
cd proyecto-equipo-5
