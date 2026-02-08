# Local infrastructure deployment commands for MathTrail

set shell := ["bash", "-c"]

NAMESPACE := "mathtrail"

# Deploy all infrastructure services to the cluster
deploy:
    #!/bin/bash
    set -e
    echo "🚀 Deploying infrastructure services..."
    kubectl create namespace {{ NAMESPACE }} 2>/dev/null || true
    skaffold deploy
    echo ""
    echo "⏳ Waiting for Kafka cluster to be ready..."
    kubectl wait kafka/kafka --for=condition=Ready -n {{ NAMESPACE }} --timeout=300s
    echo ""
    echo "✅ All infrastructure services deployed!"

# Remove deployed infrastructure services
uninstall:
    #!/bin/bash
    set -e
    echo "🗑️  Removing infrastructure services..."
    skaffold delete
    echo ""
    echo "✅ All infrastructure services removed!"
