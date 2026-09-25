# Policy-as-Code con OPA Gatekeeper (Equipo 5)

## 🎯 Descripción del proyecto
Este proyecto implementa **OPA Gatekeeper** como un motor de "Policy-as-Code" (Políticas como Código) en un clúster de Kubernetes. Su objetivo principal es asegurar y gobernar la infraestructura mediante un Webhook de Admisión Dinámico que intercepta, evalúa y, en su caso, bloquea la creación o modificación de recursos que no cumplen con los estándares de seguridad definidos. 

Alineado a los controles de la norma **ISO/IEC 27001:2022**, este despliegue automatiza la seguridad por diseño (Security by Design), previniendo activamente vulnerabilidades críticas como la ejecución de contenedores privilegiados, el montaje de volúmenes sensibles del host, el escalado de privilegios o la falta de límites de recursos (CPU/RAM). Adicionalmente, se incluye el **Gatekeeper Policy Manager (GPM)**, un dashboard gráfico que permite auditar visualmente las políticas activas y las violaciones existentes en tiempo real, facilitando la gestión y cumplimiento normativo.

## 👥 Integrantes del equipo
* **Luis Guillermo León Vargas**
* **Luis Enrique Quintanar Ramírez** 

## 🔧 Prerrequisitos (versiones de software)
Para desplegar este proyecto, el entorno (ej. nodo `master01`) debe cumplir con los siguientes requisitos técnicos básicos:
* **Sistema Operativo:** Distribución Linux (validado con Rocky Linux 9, pero debería funcionar con cualquier otra distribuciónm popular como  Ubuntu o Debian).
* **Kubernetes:** v1.25 o superior (clúster funcional con `kube-apiserver` accesible).
* **Helm:** v3.0+ (Gestor de paquetes de Kubernetes).
* **Git:** Para la clonación del código fuente.
* **Permisos:** Acceso al clúster mediante un archivo `kubeconfig` válido con privilegios de administrador de clúster (`cluster-admin`).

## 📦 Instalación paso a paso
La instalación ha sido completamente automatizada para evitar errores humanos, asegurar la reproducibilidad y agilizar el despliegue.

Para la explicación línea por línea de lo que hace el script y los prerrequisitos de instalación, consulta [docs/installation.md](docs/installation.md).

## 📜 Las 14 Políticas de Seguridad Implementadas (Controles ISO 27001)
El núcleo de este proyecto radica en 14 restricciones (Constraints) desarrolladas a medida para mitigar vectores de ataque críticos:

| # | Política (Constraint) | Descripción y Propósito |
|---|-------------------------|---------------------------|
| 1 | Privileged Container | Bloquea contenedores con privilegios administrativos (privileged: true), evitando que un pod tome control del nodo. |
| 2 | Host Filesystem | Impide montar rutas sensibles del sistema operativo del host (hostPath), previniendo fugas de datos. |
| 3 | Required Resources | Obliga a definir límites de CPU y Memoria, mitigando ataques DDoS por inanición de recursos. |
| 4 | Read-Only Root FS | Fuerza a los contenedores a ejecutarse con sistemas de archivos raíz de solo lectura. |
| 5 | Privilege Escalation | Exige allowPrivilegeEscalation: false para evitar que un proceso hijo obtenga más permisos que su padre. |
| 6 | Run As Non-Root | Impide que el contenedor se ejecute con el usuario root interno (UID 0). |
| 7 | Drop Capabilities | Obliga a eliminar las capacidades del kernel de Linux (ALL), reduciendo la superficie de ataque. |
| 8 | Allowed Repositories | Restringe la descarga de imágenes a registries confiables, evitando software envenenado. |
| 9 | Block Latest Tag | Prohíbe el uso de la etiqueta :latest en imágenes, garantizando trazabilidad en despliegues. |
| 10| Host Namespaces | Bloquea el uso compartido de espacios de red y procesos del nodo (hostNetwork, hostPID). |
| 11| Required Labels | Fuerza el uso de etiquetas organizacionales (ej. entorno) para aislamiento lógico. |
| 12| Required Probes | Obliga a definir sondas de salud (readinessProbe), garantizando disponibilidad de los servicios. |
| 13| Require PDB | Exige un PodDisruptionBudget en despliegues críticos para evitar cortes durante mantenimientos. |
| 14| Network Policies | Requiere que los Namespaces contengan una etiqueta específica de política de red para segmentación. |

## ⚙️ Configuración
El entorno se basa en Infraestructura como Código (IaC). Las configuraciones principales viven en el directorio `manifests/`:
* **`gatekeeper-config.yaml`**: Archivo crítico que define las exclusiones globales. Le indica al Webhook que omita la evaluación en namespaces del sistema (como `kube-system` y `gatekeeper-system`) para evitar bloqueos accidentales que rompan el clúster.
* **`gpm.yaml`**: Manifiesto del dashboard. Contiene su `Service` (NodePort 30080), un `emptyDir` para garantizar que el contenedor se ejecute con sistema de archivos de solo lectura (cumpliendo nuestra propia política ISO), y los roles `RBAC` estrictos de solo lectura (`get`, `list`, `watch`).
* **Directorio de Políticas**: Cada regla posee un `template.yaml` (la lógica en lenguaje Rego) y un `constraint.yaml` (la regla activa), los cuales incluyen el campo `excludedNamespaces` para generar excepciones controladas.

## 🧪 Testing y validación
El repositorio incluye una batería exhaustiva de pruebas en la carpeta `examples/`. Para validar la robustez de Gatekeeper:

**1. Ejecutar Suite Automatizada (Recomendado):** 
Asegúrate de estar en el namespace default y lanza el script:
kubectl config set-context --current --namespace=default
./tests/smoke-tests.sh

Este script intentará desplegar 14 recursos maliciosos y culminará desplegando el golden-pod.yaml (un recurso que cumple con todas las políticas).

**2. Validar el modo Bloqueo (Enforce / Deny):**
Intenta inyectar un recurso malicioso. Gatekeeper masacrará la petición en la entrada del clúster y mostrará la lista exacta de controles ISO violados.
```bash
kubectl apply -f examples/bad-01-privileged.yaml
```

**3. Validar el modo Auditoría (Dryrun):**
Aplica el pod de pruebas diseñado para pasar las reglas de bloqueo crítico, pero fallar intencionalmente una regla de etiquetado en modo auditoría.
```bash
kubectl apply -f examples/pod-auditoria.yaml
```
La terminal confirmará su creación (`created`), pero la brecha será reportada silenciosamente. Accede a `http://<IP_DEL_NODO>:30080`, pestaña **Constraints**, busca `auditar-etiquetas-estrictas` y despliega la lista de "Violations" para ver al pod reportado.

## 🐛 Troubleshooting
Si encuentras comportamientos inesperados o errores, consulta nuestro apartado de errores conocidos y sus soluciones:
👉 [docs/troubleshooting.md](docs/troubleshooting.md)

## 🔗 Referencias y documentación
* **OPA Gatekeeper Docs:** https://open-policy-agent.github.io/gatekeeper/website/docs/
* **Gatekeeper Policy Manager:** https://github.com/sighupio/gatekeeper-policy-manager
* **Guía de Arquitectura:** [docs/architecture.md](docs/architecture.md)

## 🛡️ Controles ISO/IEC 27001 cubiertos
La justificación de los controles exigidos (A.8.9, A.5.36, A.8.32, A.8.27, A.8.34), las evidencias técnicas en el código y el análisis de **brechas residuales**, se encuentran en nuestro documento normativo:

👉 [Ficha de Cumplimiento ISO/IEC 27001 (docs/iso27001.md)](docs/iso27001.md)
