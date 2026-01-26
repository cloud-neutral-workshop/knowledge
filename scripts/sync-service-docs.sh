#!/usr/bin/env bash
set -euo pipefail

# Sync documentation from multiple service repositories into the knowledge base
# This script pulls docs from each service repo and organizes them into the docs/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${REPO_ROOT}/docs"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "${TMP_DIR}"' EXIT

echo "==> Syncing service documentation to ${DOCS_DIR}"

# Define service repositories and their target directories
declare -A SERVICES=(
    ["https://github.com/cloud-neutral-toolkit/console.svc.plus.git"]="01-console"
    ["https://github.com/cloud-neutral-toolkit/accounts.svc.plus.git"]="02-accounts"
    ["https://github.com/cloud-neutral-toolkit/rag-server.svc.plus.git"]="03-rag-server"
    ["https://github.com/cloud-neutral-toolkit/postgresql.svc.plus.git"]="04-postgresql"
)

# Sync each service
for repo_url in "${!SERVICES[@]}"; do
    target_dir="${SERVICES[$repo_url]}"
    service_name=$(basename "${repo_url}" .git)
    
    echo ""
    echo "==> Processing ${service_name} -> docs/${target_dir}"
    
    # Clone the repository
    clone_dir="${TMP_DIR}/${service_name}"
    echo "    Cloning ${repo_url}..."
    git clone --depth=1 --single-branch --branch main "${repo_url}" "${clone_dir}" 2>/dev/null || {
        echo "    Warning: Failed to clone ${repo_url}, skipping..."
        continue
    }
    
    # Check if docs directory exists in the service repo
    if [ ! -d "${clone_dir}/docs" ]; then
        echo "    Warning: No docs/ directory found in ${service_name}, skipping..."
        continue
    fi
    
    # Create target directory
    target_path="${DOCS_DIR}/${target_dir}"
    mkdir -p "${target_path}"
    
    # Remove existing content (except .git if any)
    find "${target_path}" -mindepth 1 -not -path "*/.git/*" -delete 2>/dev/null || true
    
    # Copy documentation files
    echo "    Copying documentation files..."
    cp -r "${clone_dir}/docs/"* "${target_path}/" 2>/dev/null || {
        echo "    Warning: Failed to copy docs from ${service_name}"
        continue
    }
    
    # Add collection metadata if index.md exists
    if [ -f "${target_path}/index.md" ]; then
        # Check if frontmatter already has collection field
        if ! grep -q "^collection:" "${target_path}/index.md"; then
            # Add collection metadata to frontmatter
            temp_file=$(mktemp)
            awk -v collection="${target_dir}" '
                BEGIN { in_frontmatter=0; added=0 }
                /^---$/ { 
                    in_frontmatter++
                    print
                    if (in_frontmatter == 1) {
                        print "collection: " collection
                        print "collectionLabel: " toupper(substr(collection, 4, 1)) substr(collection, 5)
                        added=1
                    }
                    next
                }
                { print }
            ' "${target_path}/index.md" > "${temp_file}"
            mv "${temp_file}" "${target_path}/index.md"
        fi
    fi
    
    echo "    ✓ Successfully synced ${service_name}"
done

echo ""
echo "==> Generating docs/index.md..."

# Generate the main index.md file
cat > "${DOCS_DIR}/index.md" << 'EOF'
---
title: Cloud-Neutral Toolkit Documentation
description: Comprehensive documentation for all Cloud-Neutral Toolkit services
collection: index
collectionLabel: Documentation Home
---

# Cloud-Neutral Toolkit Documentation

Welcome to the **Cloud-Neutral Toolkit** documentation. This comprehensive guide covers all services in the toolkit, helping you build, deploy, and manage cloud-native applications across any vendor.

## 🚀 Services

EOF

# Add service sections dynamically
declare -A SERVICE_TITLES=(
    ["01-console"]="Console Service"
    ["02-accounts"]="Accounts & Identity Service"
    ["03-rag-server"]="RAG Server (AI/ML)"
    ["04-postgresql"]="PostgreSQL Service"
)

declare -A SERVICE_DESCRIPTIONS=(
    ["01-console"]="The main dashboard and control plane for managing your cloud-neutral infrastructure."
    ["02-accounts"]="Centralized authentication, authorization, and identity management with OIDC support."
    ["03-rag-server"]="Retrieval-Augmented Generation service for AI-powered features and intelligent assistance."
    ["04-postgresql"]="Managed PostgreSQL database service with cloud-neutral deployment options."
)

for target_dir in $(echo "${SERVICES[@]}" | tr ' ' '\n' | sort); do
    if [ -d "${DOCS_DIR}/${target_dir}" ]; then
        service_title="${SERVICE_TITLES[$target_dir]}"
        service_desc="${SERVICE_DESCRIPTIONS[$target_dir]}"
        
        cat >> "${DOCS_DIR}/index.md" << EOF
### ${service_title}

${service_desc}

**[View ${service_title} Documentation →](/docs/${target_dir}/index)**

EOF
    fi
done

# Add footer
cat >> "${DOCS_DIR}/index.md" << 'EOF'

## 📚 Quick Links

- **[Getting Started](/docs/01-console/index)** - Begin with the Console Service
- **[Architecture Overview](/docs/01-console/architecture)** - Understand the system design
- **[API Reference](/docs/02-accounts/api)** - Explore the APIs

## 🔗 Resources

- [GitHub Organization](https://github.com/cloud-neutral-toolkit)
- [Community Forum](https://github.com/orgs/cloud-neutral-toolkit/discussions)
- [Issue Tracker](https://github.com/cloud-neutral-toolkit/console.svc.plus/issues)

---

*Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")*
EOF

echo "    ✓ Generated docs/index.md"

echo ""
echo "==> Documentation sync complete!"
echo "    Updated directories:"
for target_dir in "${SERVICES[@]}"; do
    if [ -d "${DOCS_DIR}/${target_dir}" ]; then
        file_count=$(find "${DOCS_DIR}/${target_dir}" -type f \( -name "*.md" -o -name "*.mdx" \) | wc -l | tr -d ' ')
        echo "    - docs/${target_dir} (${file_count} files)"
    fi
done
