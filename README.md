# 🛡️ Policy-as-Code con OPA Gatekeeper (Equipo 5)

## 🎯 Descripción del proyecto
Este proyecto implementa **OPA Gatekeeper** como un motor de "Policy-as-Code" (Políticas como Código) en un clúster de Kubernetes. Su objetivo principal es asegurar y gobernar la infraestructura mediante un Webhook de Admisión Dinámico que intercepta, evalúa y, en su caso, bloquea la creación o modificación de recursos que no cumplen con los estándares de seguridad definidos. 

Alineado a los controles de la norma **ISO/IEC 27001:2022**, este despliegue automatiza la seguridad por diseño (Security by Design), previniendo activamente vulnerabilidades críticas como la ejecución de contenedores privilegiados, el montaje de volúmenes sensibles del host, el escalado de privilegios o la falta de límites de recursos (CPU/RAM). Adicionalmente, se incluye el **Gatekeeper Policy Manager (GPM)**, un dashboard gráfico que permite auditar visualmente las políticas activas y las violaciones existentes en tiempo real, facilitando la gestión y cumplimiento normativo.

## 👥 Integrantes del equipo
* **Luis Guillermo León Vargas** - Arquitecto de Seguridad y K8s
* **[Nombre de tu compañero]** - Ingeniero DevSecOps

## 🔧 Prerrequisitos (versiones de software)
Para desplegar este proyecto, el entorno (ej. nodo `master01`) debe cumplir con los siguientes requisitos técnicos básicos:
* **Sistema Operativo:** Distribución Linux (ej. Rocky Linux 9, Ubuntu, Debian).
* **Kubernetes:** v1.25 o superior (clúster funcional con `kube-apiserver` accesible).
* **Helm:** v3.0+ (Gestor de paquetes de Kubernetes).
* **Git:** Para la clonación del código fuente.
* **Permisos:** Acceso al clúster mediante un archivo `kubeconfig` válido con privilegios de administrador de clúster (`cluster-admin`).

## 📦 Instalación paso a paso
La instalación ha sido completamente automatizada para evitar errores humanos, asegurar la reproducibilidad y agilizar el despliegue. Ejecuta los siguientes comandos desde un usuario con acceso al comando `kubectl`:

```bash
# 1. Clonar el repositorio
git clone https://github.com/luisgleonv/proyecto-equipo-5.git
cd proyecto-equipo-5

# 2. Asignar permisos de ejecución al script instalador
chmod +x scripts/install.sh

# 3. Ejecutar el despliegue automatizado
./scripts/install.sh
```
*(Para una explicación línea por línea de lo que hace el script, consulta [docs/installation.md](docs/installation.md)).*

## ⚙️ Configuración
El entorno se basa en Infraestructura como Código (IaC). Las configuraciones principales viven en el directorio `manifests/`:
* **`gatekeeper-config.yaml`**: Archivo crítico que define las exclusiones globales. Le indica al Webhook que omita la evaluación en namespaces del sistema (como `kube-system` y `gatekeeper-system`) para evitar bloqueos accidentales que rompan el clúster.
* **`gpm.yaml`**: Manifiesto del dashboard. Contiene su `Service` (NodePort 30080), un `emptyDir` para garantizar que el contenedor se ejecute con sistema de archivos de solo lectura (cumpliendo nuestra propia política ISO), y los roles `RBAC` estrictos de solo lectura (`get`, `list`, `watch`).
* **Directorio de Políticas**: Cada regla posee un `template.yaml` (la lógica en lenguaje Rego) y un `constraint.yaml` (la regla activa), los cuales incluyen el campo `excludedNamespaces` para generar excepciones controladas.

## 🧪 Testing y validación
El repositorio incluye una batería exhaustiva de pruebas en la carpeta `examples/`. Para validar la robustez de Gatekeeper:

**1. Validar el modo Bloqueo (Enforce / Deny):**
Intenta inyectar un recurso malicioso. Gatekeeper masacrará la petición en la entrada del clúster y mostrará la lista exacta de controles ISO violados.
```bash
kubectl apply -f examples/bad-01-privileged.yaml
```

**2. Validar el modo Auditoría (Dryrun):**
Aplica el pod de pruebas diseñado para pasar las reglas de bloqueo crítico, pero fallar intencionalmente una regla de etiquetado en modo auditoría.
```bash
kubectl apply -f examples/pod-auditoria.yaml
```
La terminal confirmará su creación (`created`), pero la brecha será reportada silenciosamente. Accede a `http://<IP_DEL_NODO>:30080`, pestaña **Constraints**, busca `auditar-etiquetas-estrictas` y despliega la lista de "Violations" para ver al pod reportado.

## 🐛 Troubleshooting
Si encuentras comportamientos inesperados (ej. problemas de "CrashLoopBackOff" por permisos de escritura, errores 403 Forbidden de RBAC al levantar el dashboard, o fallas extrayendo imágenes de Helm), consulta nuestra tabla de diagnóstico:
👉 [docs/troubleshooting.md](docs/troubleshooting.md)

## 🔗 Referencias y documentación
* **OPA Gatekeeper Docs:** https://open-policy-agent.github.io/gatekeeper/website/docs/
* **Gatekeeper Policy Manager:** https://github.com/sighupio/gatekeeper-policy-manager
* **Guía de Arquitectura:** [docs/architecture.md](docs/architecture.md)

## 🛡️ Controles ISO/IEC 27001 cubiertos
La justificación de los controles exigidos (A.8.9, A.5.36, A.8.32, A.8.27, A.8.34), las evidencias técnicas en el código y el análisis de **brechas residuales**, se encuentran en nuestro documento normativo:

👉 [Ficha de Cumplimiento ISO/IEC 27001 (docs/iso27001.md)](docs/iso27001.md)
