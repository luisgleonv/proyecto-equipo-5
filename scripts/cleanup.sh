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

echo "✅ Limpieza finalizada. Clúster en estado original."
