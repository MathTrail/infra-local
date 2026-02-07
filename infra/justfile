# Local infrastructure deployment commands for MathTrail

set shell := ["bash", "-c"]

# Helm chart repo
HELM_REPO_NAME := "mathtrail"
HELM_REPO_URL := "https://RyazanovAlexander.github.io/mathtrail-charts/charts"
NAMESPACE := "mathtrail"

# Deploy PostgreSQL, Redis, and Kafka to the cluster
deploy:
    #!/bin/bash
    set -e
    echo "🚀 Deploying infrastructure services..."

    # Add Helm repo if not already added
    if ! helm repo list 2>/dev/null | grep -q "{{ HELM_REPO_NAME }}"; then
        echo "📦 Adding Helm repo '{{ HELM_REPO_NAME }}'..."
        helm repo add {{ HELM_REPO_NAME }} {{ HELM_REPO_URL }}
    fi
    helm repo update {{ HELM_REPO_NAME }}

    # Create namespace if it doesn't exist
    kubectl create namespace {{ NAMESPACE }} --dry-run=client -o yaml | kubectl apply -f -

    echo ""
    echo "📦 Installing PostgreSQL..."
    helm upgrade --install postgres {{ HELM_REPO_NAME }}/postgresql \
        -n {{ NAMESPACE }} \
        -f values/postgresql-values.yaml \
        --wait --timeout 120s

    echo ""
    echo "📦 Installing Redis..."
    helm upgrade --install redis {{ HELM_REPO_NAME }}/redis \
        -n {{ NAMESPACE }} \
        -f values/redis-values.yaml \
        --wait --timeout 120s

    echo ""
    echo "📦 Installing Kafka..."
    helm upgrade --install kafka {{ HELM_REPO_NAME }}/kafka \
        -n {{ NAMESPACE }} \
        -f values/kafka-values.yaml \
        --wait --timeout 180s

    echo ""
    echo "✅ All infrastructure services deployed!"
    echo ""
    helm list -n {{ NAMESPACE }}

# Remove deployed infrastructure services
uninstall:
    #!/bin/bash
    set -e
    echo "🗑️  Removing infrastructure services..."

    helm uninstall kafka -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Kafka removed" || echo "⚠️  Kafka not found"
    helm uninstall redis -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Redis removed" || echo "⚠️  Redis not found"
    helm uninstall postgres -n {{ NAMESPACE }} 2>/dev/null && echo "✅ PostgreSQL removed" || echo "⚠️  PostgreSQL not found"

    echo ""
    echo "✅ All infrastructure services removed!"
