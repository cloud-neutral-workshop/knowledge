#!/usr/bin/env bash
set -euo pipefail

# Cloud-Neutral Radar: init empty Markdown files (NO directory creation / renaming)
# Usage:
#   ./init-cloud-neutral-radar.sh
# Optional:
#   ROOT=/path/to/repo ./init-cloud-neutral-radar.sh
#
# This script only creates (touch) markdown files inside existing directories.
# It will FAIL if any required一级/二级目录不存在.

ROOT="${ROOT:-.}"

require_dir() {
  local d="$1"
  if [[ ! -d "$ROOT/$d" ]]; then
    echo "ERROR: required directory missing: $ROOT/$d" >&2
    exit 1
  fi
}

touch_file() {
  local f="$1"
  local path="$ROOT/$f"
  mkdir -p "$(dirname "$path")" 2>/dev/null || true
  # NOTE: mkdir -p above only touches parent dirs if they exist; but we forbid creating new一级/二级目录.
  # So we still validate the target second-level dir explicitly via require_dir() calls.
  if [[ -e "$path" ]]; then
    echo "SKIP  $f"
  else
    : > "$path"
    echo "CREATE $f"
  fi
}

# ---- Validate fixed repo structure (do NOT create them) ----
require_dir "content"
require_dir "content/00-global"
require_dir "content/00-global/essays"
require_dir "content/00-global/workshops"
require_dir "content/00-global/weekly-radar"
require_dir "content/01-id-security"
require_dir "content/02-iac-devops"
require_dir "content/03-observability"
require_dir "content/04-infra-platform"
require_dir "content/05-data-ai"

# ---- Identity & Security ----
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_Keycloak.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_ZITADEL.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_Dex.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_Vault.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_SPIFFE-SPIRE.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_Trivy.md"
touch_file "content/01-id-security/Cloud-Neutral-Radar_Identity-Security_Cosign.md"

# ---- Delivery & Change Control ----
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Terraform-OpenTofu.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Pulumi.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Argo-CD.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_FluxCD.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Ansible.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Puppet.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_GitLab.md"
touch_file "content/02-iac-devops/Cloud-Neutral-Radar_Delivery-Change-Control_Gitea.md"

# ---- Observability ----
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_Prometheus.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_VictoriaMetrics.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_VictoriaLogs.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_OpenTelemetry.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_Grafana.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_OpenObserve.md"
touch_file "content/03-observability/Cloud-Neutral-Radar_Observability_Vector.md"

# ---- Runtime & Platform Boundaries ----
# Runtime view
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Linux-Runtime.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_containerd.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Kubernetes-Runtime.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Cilium.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Calico.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Kube-OVN.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Nginx.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_OpenResty.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_Kong.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Runtime-Boundary_APISIX.md"

# Platform view (Infrastructure Foundation)
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_Linux-Platform.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_KVM-QEMU.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_OpenStack.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_SUSE-Harvester.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_Public-Cloud-IaaS.md"
touch_file "content/04-infra-platform/Cloud-Neutral-Radar_Platform-Foundation_Kubernetes-Platform.md"

# ---- Data & AI ----
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_PostgreSQL-pgvector.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_MySQL.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_ClickHouse.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_DuckDB.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_Doris-StarRocks.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_Databend.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_Iceberg-DeltaLake.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_Apache-Flink.md"
touch_file "content/05-data-ai/Cloud-Neutral-Radar_Data-AI_Milvus-Qdrant.md"

echo "DONE"
