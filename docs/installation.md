# 📖 Guía de Instalación Detallada - OPA Gatekeeper

## ⏱️ Información General
* **Tiempo estimado de instalación:** 3 a 5 minutos.
* **Requisitos de Hardware:** 2 vCPUs, 4GB RAM (Recomendado para el nodo master).
* **Requisitos de Software:** Kubernetes v1.25+, Helm v3.0+, SO Linux (Rocky Linux 9 recomendado), Git.

## 🛠️ Prerrequisitos en el Sistema Operativo
Antes de interactuar con el clúster, necesitamos las herramientas base instaladas en el nodo principal (`master01`). Ejecuta esto con el usuario `root`.

```bash
su -
dnf install epel-release -y
dnf install git helm -y
exit
```
* **Explicación:** `epel-release` habilita repositorios adicionales en Enterprise Linux. `git` nos permite clonar el código y `helm` es el gestor de paquetes oficial de Kubernetes necesario para instalar Gatekeeper.
* **Output esperado:** Mensajes de "Complete!" indicando que los paquetes se descargaron e instalaron correctamente.

## 🚀 Instalación Automatizada (Script)
Inicia sesión con el usuario `ansible` (o el usuario con acceso al `kubeconfig`).

### 1. Obtener el repositorio
```bash
git clone [https://github.com/luisgleonv/proyecto-equipo-5.git](https://github.com/luisgleonv/proyecto-equipo-5.git)
cd proyecto-equipo-5
chmod +x scripts/install.sh
```
* **Explicación:** Descargamos la infraestructura como código. El comando `chmod +x` le otorga permisos de ejecución al script instalador para evitar errores de permisos denegados.

### 2. Ejecutar el despliegue
```bash
./scripts/install.sh
```
El script realiza automáticamente los siguientes pasos lógicos en el clúster:

**Paso A: Instalación del Motor (Helm)**
```bash
helm repo add gatekeeper [https://open-policy-agent.github.io/gatekeeper/charts](https://open-policy-agent.github.io/gatekeeper/charts)
helm upgrade --install gatekeeper gatekeeper/gatekeeper --namespace gatekeeper-system --create-namespace --set auditInterval=60
```
* **Explicación:** Registra el repositorio oficial y despliega los pods core de Gatekeeper (Controller Manager y Audit). El parámetro `auditInterval=60` configura el escáner para revisar el clúster cada minuto.

**Paso B: Exclusiones Globales**
```bash
kubectl apply -f manifests/gatekeeper-config.yaml
```
* **Explicación:** Aplica un CRD de configuración que le dice al Webhook que no evalúe los namespaces del sistema (`kube-system`). Previene interrupciones críticas.

**Paso C: Inyección de Plantillas (Templates)**
```bash
find manifests -type f -name "*template*.yaml" -exec kubectl apply -f {} \;
sleep 15
```
* **Explicación:** Carga la lógica en lenguaje Rego en la API de Kubernetes. El `sleep` es vital porque Kubernetes tarda unos segundos en registrar estos nuevos tipos de recursos (CRDs).

**Paso D: Inyección de Reglas Activas (Constraints)**
```bash
find manifests -type f -name "*constraint*.yaml" -exec kubectl apply -f {} \;
```
* **Explicación:** Instancia las reglas de seguridad reales (ej. no root, no hostPath, auditoría). A partir de este momento, el clúster está protegido.

**Paso E: Dashboard GPM**
```bash
kubectl apply -f manifests/gpm.yaml
```
* **Explicación:** Levanta la interfaz gráfica en modo de solo lectura (RBAC) expuesta por el NodePort 30080.

## ✅ Validación Final (Output Esperado)
Al finalizar, el script te pedirá ejecutar:
```bash
kubectl get pods -n gatekeeper-system
```
El output esperado debe mostrar 4 pods en estado `Running` (3 del controller-manager, 1 del audit) y el pod de `gatekeeper-policy-manager`. Ninguno debe estar en `CrashLoopBackOff`.
