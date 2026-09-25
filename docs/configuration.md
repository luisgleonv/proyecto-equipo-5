# Documentación de Configuración (OPA Gatekeeper & GPM)

Este documento detalla las configuraciones clave implementadas en el clúster para garantizar que el motor de políticas opere de manera segura, sin interrumpir los servicios críticos de Kubernetes, y cómo se parametrizan las reglas de seguridad.

## 1. Configuración Global (Exclusiones del Webhook)
**Archivo:** `manifests/gatekeeper-config.yaml`

Por diseño, el Webhook de admisión de Gatekeeper intercepta absolutamente todas las peticiones al clúster. Si una política restrictiva bloquea recursos internos del sistema, el clúster colapsará irremediablemente. Para evitar esto, implementamos un recurso `Config` de Gatekeeper que excluye de la evaluación a los namespaces críticos:

*   `kube-system`: Donde operan los componentes del Control Plane (CoreDNS, CNI, kube-proxy). Excluirlo garantiza la estabilidad de la red y el enrutamiento interno.
*   `gatekeeper-system`: Se excluye para evitar que el controlador de políticas se bloquee a sí mismo al intentar escalar o actualizar sus propios pods.

## 2. Configuración de Políticas y Parametrización
**Archivos:** `manifests/<numero>-<nombre-politica>/constraint.yaml`

La arquitectura del proyecto separa la lógica de evaluación (escrita en Rego dentro de los `ConstraintTemplates`) de la configuración operativa. En lugar de incrustar valores estáticos en el código, inyectamos los parámetros dinámicamente a través de los manifiestos `Constraint`. 

Configuraciones aplicadas en el entorno:
*   **Listas Blancas (Whitelists):** En la política de repositorios (regla 08), se configura una lista de *registries* autorizados directamente en el bloque `parameters` del manifiesto.
*   **Inyección de Variables:** En la política de etiquetas (regla 11), el manifiesto configura el parámetro `labels`, exigiendo específicamente la clave `entorno` sin tener que reescribir la plantilla Rego.
*   **Modo de Ejecución (Enforcement Action):** La configuración operativa define cómo actúa Gatekeeper frente a una violación. Todas las políticas de prevención están configuradas en `deny` (bloqueo activo). Para los recursos heredados, la configuración se ajusta a `dryrun` (auditoría), permitiendo que el recurso opere mientras es reportado en el dashboard.

## 3. Configuración del Gatekeeper Policy Manager (Dashboard)
**Archivo:** `manifests/dashboard/gpm.yaml`

El entorno gráfico GPM cuenta con una configuración orientada a la seguridad (Principio de Privilegio Mínimo) y accesibilidad externa:

*   **Exposición de Red (NodePort):** Se configuró un servicio tipo `NodePort` mapeado estáticamente al puerto **30080**. Esto permite el acceso directo a la interfaz desde cualquier navegador en la red externa sin necesidad de desplegar un Ingress Controller.
*   **Control de Acceso (RBAC):** Se definió un `ClusterRole` estrictamente de solo lectura (`get`, `list`, `watch`) atado a la `ServiceAccount` del dashboard. Esto garantiza que GPM funcione exclusivamente como un visor de estado y auditoría, eliminando la posibilidad de que sea utilizado como vector de ataque para alterar las políticas de seguridad.
*   **Inmutabilidad del Contenedor:** Se configuró un volumen `emptyDir` para la ruta temporal del contenedor, lo que permite que GPM cumpla con nuestra propia política ISO 27001 de `Read-Only Root Filesystem` y arranque sin ser bloqueado por Gatekeeper.
