#!/bin/bash
set -euo pipefail

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
URL="https://$NODE_IP:$INGRESS_PORT"

echo "=========================================================="
echo "  SIMULACIÓN DE ATAQUE / TRÁFICO ANÓMALO (TP16)"
echo "=========================================================="
echo "Objetivo: $URL"
echo ""

echo "[1/3] Generando errores HTTP 401 (Unauthorized)..."
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" -k -X POST -H "Host: devops-portfolio.local" "$URL/api/v1/login" -d '{"user":"admin","pass":"wrong"}' || true
done

echo ""
echo "[2/3] Generando errores HTTP 403 (Forbidden)..."
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" -k -H "Host: devops-portfolio.local" "$URL/api/admin" || true
done

echo ""
echo "[3/3] Generando errores HTTP 500 (Internal Server Error)..."
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" -k -H "Host: devops-portfolio.local" "$URL/api/error" || true
done

echo ""
echo "=== Simulación completada con éxito ==="
echo "¡Revisá ahora los gráficos en Grafana!"
