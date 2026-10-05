#!/bin/bash
set -uo pipefail

echo "================================================="
echo "  VERIFICACIÓN TÉCNICA - TP16 TRIVY SECURITY"
echo "================================================="
echo ""

# 1. Verificar herramientas locales
if command -v trivy &> /dev/null; then
  echo " [OK] Trivy instalado localmente ($(trivy --version | head -n 1))"
else
  echo " [WARN] Trivy no detectado localmente en PATH"
fi

if command -v helm &> /dev/null; then
  echo " [OK] Helm instalado localmente ($(helm version --short))"
else
  echo " [WARN] Helm no detectado localmente en PATH"
fi

echo ""
echo "--- 1. Ejecutando Auditoría SCA (trivy fs) ---"
if [ -d "app/backend" ]; then
  trivy fs ./app/backend/ || true
else
  echo " [WARN] Directorio app/backend no encontrado."
fi

echo ""
echo "--- 2. Renderizado de Helm Chart (TP10B) ---"
if [ -d "chart" ] && [ -f "values-local.yaml" ]; then
  helm template mi-app ./chart -f values-local.yaml > manifests-rendered.yaml
  echo " [OK] Manifiesto renderizado generado en manifests-rendered.yaml"
else
  echo " [WARN] No se encuentra la carpeta chart/ o values-local.yaml"
fi

echo ""
echo "--- 3. Escaneo de IaC sobre manifiestos (trivy config) ---"
if [ -f "manifests-rendered.yaml" ]; then
  trivy config manifests-rendered.yaml || true
else
  echo " [WARN] No se encontró manifests-rendered.yaml para escanear."
fi

# 4. Verificar configuración en el pipeline de GitHub Actions
WORKFLOW_FILE=".github/workflows/cicd.yml"
echo ""
echo "--- 4. Verificación del Workflow CI/CD ---"
if [ -f "$WORKFLOW_FILE" ]; then
  if grep -q "trivy-andon-cord" "$WORKFLOW_FILE" && grep -q "manifests-rendered-prod.yaml" "$WORKFLOW_FILE"; then
    echo " [OK] Workflow configurado con 3 fases y renderizado de Helm"
  else
    echo " [FAIL] Falta la configuración esperada en $WORKFLOW_FILE"
    exit 1
  fi
else
  echo " [FAIL] No se encontró el archivo $WORKFLOW_FILE"
  exit 1
fi

echo ""
echo "=== Verificación completada con éxito ==="
