#!/bin/bash

echo "🧪 Iniciando Batería de Pruebas de Humo (Smoke Tests)..."

echo "1️⃣ Verificando estado de los componentes..."
kubectl get pods -n gatekeeper-system
kubectl get svc -n gatekeeper-system
echo "------------------------------------------------------"

echo "2️⃣ Pruebas Negativas: Intentando desplegar recursos prohibidos..."
# Iteramos sobre todos los archivos que empiezan con 'bad-' en la carpeta examples
fallos=0
for manifiesto in examples/bad-*.yaml; do
    echo -n "Probando $manifiesto ... "
    # Ocultamos la salida estándar y de error para mantener la consola limpia
    kubectl apply -f "$manifiesto" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "✅ BLOQUEADO (Correcto)"
    else
        echo "❌ PERMITIDO (¡Alarma de Seguridad!)"
        fallos=$((fallos + 1))
        # Limpiamos el recurso si se coló
        kubectl delete -f "$manifiesto" > /dev/null 2>&1
    fi
done

if [ $fallos -gt 0 ]; then
    echo "🚨 ERROR: Gatekeeper permitió $fallos recursos inválidos. Revisa tus constraints."
    exit 1
fi

echo "------------------------------------------------------"
echo "3️⃣ Prueba Positiva: Desplegando recurso válido (Golden Pod)..."
echo -n "Probando examples/golden-pod.yaml ... "
kubectl apply -f examples/golden-pod.yaml > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ ADMITIDO (Correcto)"
    # Limpiamos el clúster borrando el pod dorado al terminar
    kubectl delete -f examples/golden-pod.yaml > /dev/null 2>&1
else
    echo "❌ BLOQUEADO (¡Falso Positivo!)"
    echo "Gatekeeper está bloqueando recursos que deberían ser legales."
    exit 1
fi

echo "------------------------------------------------------"
echo "🛡️  Todas las pruebas pasaron exitosamente. El clúster está seguro."
