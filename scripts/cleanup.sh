#!/bin/bash

echo "🛑 Iniciando limpieza total de Gatekeeper y GPM..."

# 1. Eliminar dashboard y políticas (manifiestos locales)
echo "🗑️ Eliminando dashboard, ConfigMaps y políticas..."
kubectl delete -f manifests/ --ignore-not-found

# 2. Desinstalar el motor de Gatekeeper (Helm)
echo "🗑️ Desinstalando motor Gatekeeper..."
helm uninstall gatekeeper -n gatekeeper-system

# 3. Eliminar el namespace
echo "🧹 Eliminando namespace gatekeeper-system..."
kubectl delete namespace gatekeeper-system --ignore-not-found

# 4. Borrar todas las plantillas (esto elimina en cascada las constraints)
echo "Eliminando las plantillas"
kubectl delete constrainttemplates --all

# 5. Borrar de tajo todos los CRDs de Gatekeeper que quedaron huérfanos
echo "Borrando los CRD huérfanos de gatekeeper"
kubectl delete crd $(kubectl get crd | grep gatekeeper | awk '{print $1}')


echo "✅ Limpieza finalizada. Clúster en estado original."
