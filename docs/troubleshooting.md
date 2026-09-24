# 🐛 Guía de Troubleshooting (Resolución de Problemas)

Esta guía documenta los 5 problemas más comunes al operar OPA Gatekeeper y el dashboard GPM en Kubernetes, junto con sus soluciones técnicas.

## 1. Error de Permisos Denegados al Ejecutar el Script
* **Síntoma:** Al ejecutar `./scripts/install.sh`, la terminal devuelve `bash: ./scripts/install.sh: Permission denied`.
* **Causa:** El archivo perdió los permisos de ejecución durante la clonación de Git.
* **Solución:** Otorga permisos de ejecución explícitos al archivo antes de correrlo.
  ```bash
  chmod +x scripts/install.sh
  ./scripts/install.sh
  ```

## 2. Pods del Sistema Bloqueados por el Webhook
* **Síntoma:** Pods críticos en `kube-system` o la red (ej. Calico/Flannel) fallan al crearse. Los logs muestran `admission webhook "validation.gatekeeper.sh" denied the request`.
* **Causa:** El Webhook de Gatekeeper está evaluando namespaces críticos de infraestructura.
* **Solución:** Verifica que el archivo de exclusiones globales esté aplicado.
  ```bash
  kubectl apply -f manifests/gatekeeper-config.yaml
  ```
  Esto inyecta la regla `match: excludedNamespaces: ["kube-system", "gatekeeper-system"]`.

## 3. Error "no matches for kind" al Inyectar Políticas
* **Síntoma:** Durante la instalación, aparece el error `no matches for kind "K8sRequiredLabels" in version "constraints.gatekeeper.sh/v1beta1"`.
* **Causa:** Se intentó crear un *Constraint* (la regla) antes de que Kubernetes terminara de procesar el *ConstraintTemplate* (la clase).
* **Solución:** Kubernetes requiere tiempo para registrar los nuevos CRDs. El script `install.sh` incluye un `sleep 15` para evitarlo. Si ocurre manualmente, espera 15 segundos y vuelve a aplicar la política.

## 4. El Dashboard GPM entra en CrashLoopBackOff
* **Síntoma:** El pod de `gatekeeper-policy-manager` se reinicia constantemente.
* **Causa:** Se configuró el `securityContext` con `readOnlyRootFilesystem: true`, pero no se le proporcionó al contenedor un volumen temporal para escribir sus cachés.
* **Solución:** Asegúrate de que el archivo `manifests/dashboard/gpm.yaml` tenga configurado el volumen `emptyDir` montado en `/tmp`.
  ```yaml
  volumeMounts:
  - name: tmp-vol
    mountPath: /tmp
  volumes:
  - name: tmp-vol
    emptyDir: {}
  ```

## 5. Violaciones de Políticas no Aparecen en el Dashboard
* **Síntoma:** Se despliegan pods que rompen las reglas en modo auditoría (`enforcementAction: dryrun`), pero el dashboard GPM no muestra las violaciones.
* **Causa:** El ciclo de auditoría de Gatekeeper no ha finalizado o los RBAC del dashboard no tienen permisos suficientes.
* **Solución:** 
  1. Verifica el intervalo de auditoría. Por defecto es de 60 segundos (`auditInterval=60`). Espera un minuto.
  2. Fuerza la revisión consultando el objeto directamente en Kubernetes para confirmar si Gatekeeper detectó la brecha:
  ```bash
  kubectl get k8srequiredlabels -o yaml
  ```
