#!/bin/bash

# Activar modo estricto: el script se detiene si algún comando falla
set -e

echo "========================================================"
echo "🚀 Iniciando instalación de OPA Gatekeeper y Políticas"
echo "========================================================"

# Asegurar que estamos en la raíz del repositorio independientemente de dónde se llame el script
cd "$(dirname "$0")/.."

echo "1. Añadiendo repositorio Helm de Gatekeeper..."
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

echo "2. Instalando OPA Gatekeeper en el namespace gatekeeper-system..."
helm upgrade --install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --set auditInterval=60

echo "3. Esperando a que los Webhooks de Gatekeeper estén listos (30s)..."
sleep 30

echo "4. Aplicando archivo de configuración global (Exclusiones de namespaces)..."
kubectl apply -f manifests/gatekeeper-config.yaml

echo "5. Desplegando ConstraintTemplates (Clases de políticas)..."
# Usamos comodines (*template*.yaml) para atrapar cualquier archivo de plantilla
find manifests -type f -name "*template*.yaml" -exec kubectl apply -f {} \;

echo "6. Esperando a que Kubernetes registre los nuevos CRDs (15s)..."
# Si aplicamos los constraints de inmediato, Kubernetes dará error porque no conoce la plantilla aún
sleep 15

echo "7. Desplegando Constraints (Reglas activas, auditoría y excepciones)..."
# Usamos comodines (*constraint*.yaml) para atrapar constraint.yaml, audit-constraint.yaml, etc.
find manifests -type f -name "*constraint*.yaml" -exec kubectl apply -f {} \;

echo "8. Desplegando Gatekeeper Policy Manager (Dashboard GPM)..."
# Inyectar el ConfigMap antes del dashboard
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/gpm.yaml

echo "========================================================"
echo "✅ Instalación completada con éxito."
echo "========================================================"
echo "Para verificar el estado de los pods, ejecuta:"
echo "kubectl get pods -n gatekeeper-system"
echo ""
echo "Para acceder al dashboard, abre en tu navegador:"
echo "http://<IP_DEL_NODO>:30080"
