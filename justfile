# Local infrastructure deployment commands for MathTrail

set shell := ["bash", "-c"]

# Helm chart repos
HELM_REPO_NAME := "mathtrail"
HELM_REPO_URL := "https://RyazanovAlexander.github.io/mathtrail-charts/charts"
STRIMZI_REPO_NAME := "strimzi"
STRIMZI_REPO_URL := "https://strimzi.io/charts/"
NAMESPACE := "mathtrail"

# Deploy all infrastructure services to the cluster
deploy:
    #!/bin/bash
    set -e
    echo "🚀 Deploying infrastructure services..."

    # Add Helm repos if not already added
    if ! helm repo list 2>/dev/null | grep -q "{{ HELM_REPO_NAME }}"; then
        echo "📦 Adding Helm repo '{{ HELM_REPO_NAME }}'..."
        helm repo add {{ HELM_REPO_NAME }} {{ HELM_REPO_URL }}
    fi
    if ! helm repo list 2>/dev/null | grep -q "{{ STRIMZI_REPO_NAME }}"; then
        echo "📦 Adding Helm repo '{{ STRIMZI_REPO_NAME }}'..."
        helm repo add {{ STRIMZI_REPO_NAME }} {{ STRIMZI_REPO_URL }}
    fi
    helm repo update {{ HELM_REPO_NAME }} {{ STRIMZI_REPO_NAME }}

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
    echo "📦 Installing Strimzi Kafka Operator..."
    helm upgrade --install strimzi {{ STRIMZI_REPO_NAME }}/strimzi-kafka-operator \
        -n {{ NAMESPACE }} \
        -f values/strimzi-values.yaml \
        --wait --timeout 120s

    echo ""
    echo "📦 Deploying Kafka cluster..."
    kubectl apply -f manifests/kafka-cluster.yaml
    echo "⏳ Waiting for Kafka cluster to be ready..."
    kubectl wait kafka/kafka --for=condition=Ready -n {{ NAMESPACE }} --timeout=300s

    echo ""
    echo "✅ All infrastructure services deployed!"
    echo ""
    helm list -n {{ NAMESPACE }}

# Remove deployed infrastructure services
uninstall:
    #!/bin/bash
    set -e
    echo "🗑️  Removing infrastructure services..."

    kubectl delete -f manifests/kafka-cluster.yaml --ignore-not-found && echo "✅ Kafka cluster removed" || echo "⚠️  Kafka cluster not found"
    helm uninstall strimzi -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Strimzi operator removed" || echo "⚠️  Strimzi not found"
    helm uninstall redis -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Redis removed" || echo "⚠️  Redis not found"
    helm uninstall postgres -n {{ NAMESPACE }} 2>/dev/null && echo "✅ PostgreSQL removed" || echo "⚠️  PostgreSQL not found"

    echo ""
    echo "✅ All infrastructure services removed!"

# Show status of all infrastructure services
status:
    #!/bin/bash
    echo "📊 Infrastructure Services Status"
    echo "=================================="

    echo ""
    echo "🎯 Helm Releases ({{ NAMESPACE }}):"
    helm list -n {{ NAMESPACE }} 2>/dev/null || echo "  No releases found"

    echo ""
    echo "🔄 Pods:"
    kubectl get pods -n {{ NAMESPACE }} -o wide 2>/dev/null || echo "  No pods found"

    echo ""
    echo "🌐 Services:"
    kubectl get svc -n {{ NAMESPACE }} 2>/dev/null || echo "  No services found"

    echo ""
    echo "💾 Persistent Volume Claims:"
    kubectl get pvc -n {{ NAMESPACE }} 2>/dev/null || echo "  No PVCs found"
