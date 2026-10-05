## TP16 — Escaneo de Seguridad de Contenedores, Dependencias e IaC con Trivy (Pipeline 3 Fases)

Integración de **Trivy** en la fábrica de software (CI/CD) aplicando la arquitectura de **3 Fases con Paso de Artefactos** y la resolución de falsos positivos mediante el patrón **Render First (TP10B)**.

### Matriz de Control e Integración (Formato CSV)
```csv
Fase / Job;Dominio Evaluado;Severidades;Exit Code;Acción ante Hallazgos;Evidencia
Fase 1: build-and-package;Compilación Docker;-;0;Exporta app-image.tar como artefacto;Artefacto en GitHub Actions
Fase 2A: trivy-andon-cord;SCA, Contenedor e IaC Renderizado (TP10B);HIGH, CRITICAL;1;Andon Cord: Detiene el pipeline y bloquea el despliegue;Resumen en $GITHUB_STEP_SUMMARY
Fase 2B: trivy-audit-report;Contenedores y Dependencias;LOW, MEDIUM;0;Informativo: Genera reporte de inspección;Artifact descargable + $GITHUB_STEP_SUMMARY
Fase 3: deploy-k8s-helm;Publicación y Despliegue;-;0;Promueve la imagen aprobada a Docker Hub y Helm;Release en Kubernetes

Comandos de Auditoría Local
# 1. Auditoría SCA
trivy fs ./app/backend/

# 2. Auditoría de Imagen
trivy image devops-portfolio:latest

# 3. Renderizado previo e IaC Scanning (TP10B)
helm template mi-app ./chart -f values-local.yaml > manifests-rendered.yaml
trivy config manifests-rendered.yaml
