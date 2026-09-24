#!/bin/bash

echo "🧪 Iniciando Pruebas de Humo (Smoke Tests)..."

echo "1️⃣ Verificando estado de los componentes (Gatekeeper y GPM)..."
kubectl get pods -n gatekeeper-system -o wide
kubectl get svc -n gatekeeper-system

echo ""
echo "2️⃣ Probando el Webhook de Admisión (Debería ser RECHAZADO)..."
# Intentamos desplegar un recurso que viola nuestras políticas (ej. contenedor privilegiado)
kubectl apply -f examples/invalid-resource.yaml

# Comprobamos el código de salida del último comando
if [ $? -ne 0 ]; then
    echo "✅ ÉXITO: Gatekeeper bloqueó el recurso inseguro correctamente."
else
    echo "❌ ALARMA: Gatekeeper permitió la creación del recurso. Algo falló en la configuración."
    # Limpiamos si por error se llegó a crear
    kubectl delete -f examples/invalid-resource.yaml --ignore-not-found
    exit 1
fi

echo ""
echo "✅ Pruebas finalizadas. El sistema de seguridad está operando correctamente."
