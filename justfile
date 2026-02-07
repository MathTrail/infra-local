# K3d cluster management commands for MathTrail development

set shell := ["bash", "-c"]

# Cluster configuration
CLUSTER_NAME := "mathtrail-dev"
K3D_PORT_HTTP := "80:80@loadbalancer"
K3D_PORT_HTTPS := "443:443@loadbalancer"

# Install k3d on the system
install:
    #!/bin/bash
    set -e
    echo "📋 Checking prerequisites..."
    echo ""
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is required but not installed"
        echo "   Install from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    echo "✅ Docker is installed"
    
    # Check if k3d is already installed
    if command -v k3d &> /dev/null; then
        echo "✅ K3d is already installed: $(k3d --version)"
    else
        echo "📥 Installing k3d..."
        curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
        echo "✅ K3d installed successfully"
        k3d --version
    fi
    
    echo ""
    echo "✅ All prerequisites installed!"
    echo "🚀 Ready to create cluster: just create"

# Create k3d development cluster
create:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    K3D_PORT_HTTP="{{ K3D_PORT_HTTP }}"
    K3D_PORT_HTTPS="{{ K3D_PORT_HTTPS }}"
    
    echo "Cleaning up conflicting containers..."
    # Remove any existing registry containers that might conflict
    docker rm -f mathtrail-registry 2>/dev/null || true
    
    # Check if cluster already exists and remove it if it's in a bad state
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        echo "Found existing cluster '$CLUSTER_NAME', checking its state..."
        if ! kubectl cluster-info --context k3d-$CLUSTER_NAME &>/dev/null 2>&1; then
            echo "⚠️  Cluster is in bad state, removing it..."
            just delete
        else
            echo "⚠️  Cluster '$CLUSTER_NAME' already exists and healthy"
            exit 0
        fi
    fi
    
    echo "Creating k3d cluster '$CLUSTER_NAME'..."
    
    k3d cluster create "$CLUSTER_NAME" \
        --servers 1 \
        --agents 2 \
        --port "$K3D_PORT_HTTP" \
        --port "$K3D_PORT_HTTPS" \
        --wait \
        --timeout 120s
    
    echo "✅ Cluster '$CLUSTER_NAME' created successfully"
    just kubeconfig

# Delete the k3d development cluster
delete:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    echo "Deleting k3d cluster '$CLUSTER_NAME'..."
    
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        echo "⚠️  Cluster '$CLUSTER_NAME' does not exist"
        exit 0
    fi
    
    k3d cluster delete "$CLUSTER_NAME" --all
    
    # Wait a moment for cleanup
    sleep 2
    
    echo "✅ Cluster deleted"

# Start the k3d development cluster
start:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    echo "Starting k3d cluster '$CLUSTER_NAME'..."
    
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        echo "❌ Cluster '$CLUSTER_NAME' does not exist. Run 'just create' first"
        exit 1
    fi
    
    k3d cluster start "$CLUSTER_NAME"
    echo "✅ Cluster started"
    just kubeconfig

# Stop the k3d development cluster
stop:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    echo "Stopping k3d cluster '$CLUSTER_NAME'..."
    k3d cluster stop "$CLUSTER_NAME"
    echo "✅ Cluster stopped"

# Check cluster status
status:
    #!/bin/bash
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    echo "Cluster status:"
    k3d cluster list
    echo ""
    echo "Cluster info:"
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        kubectl cluster-info --context k3d-$CLUSTER_NAME 2>/dev/null || echo "⚠️  Cluster not accessible"
    else
        echo "❌ Cluster '$CLUSTER_NAME' does not exist"
    fi

# View cluster logs
logs:
    #!/bin/bash
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    k3d logs -c "$CLUSTER_NAME" -f

# Get kubeconfig for the cluster
kubeconfig:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    KUBECONFIG_DIR="${HOME}/.kube"
    KUBECONFIG_DEST="${KUBECONFIG_DIR}/k3d-${CLUSTER_NAME}.yaml"
    
    mkdir -p "${KUBECONFIG_DIR}"
    
    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        k3d kubeconfig get "$CLUSTER_NAME" > "${KUBECONFIG_DEST}"
    elif [ "$(uname)" == "Linux" ]; then
        # Linux
        k3d kubeconfig get "$CLUSTER_NAME" > "${KUBECONFIG_DEST}"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash or Cygwin)
        k3d kubeconfig get "$CLUSTER_NAME" > "${KUBECONFIG_DEST}"
    fi
    
    chmod 600 "${KUBECONFIG_DEST}" 2>/dev/null || true
    echo "✅ Kubeconfig saved to ${KUBECONFIG_DEST}"
    echo "🔗 Set as default: export KUBECONFIG=${KUBECONFIG_DEST}"

# Initialize cluster with essential components (Dapr, etc.)
init-cluster:
    #!/bin/bash
    set -e
    CLUSTER_NAME="{{ CLUSTER_NAME }}"
    echo "Initializing cluster with essential components..."
    
    # Set kubeconfig context
    CONTEXT="k3d-${CLUSTER_NAME}"
    if ! kubectl config get-contexts | grep -q "$CONTEXT"; then
        echo "❌ Context '$CONTEXT' not found. Run 'just kubeconfig' first"
        exit 1
    fi
    
    kubectl config use-context "$CONTEXT"
    
    # Wait for cluster to be ready
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=60s 2>/dev/null || true
    
    echo "✅ Cluster initialized"
    kubectl get nodes

# Clean up Docker resources (stopped containers, dangling images)
clean:
    #!/bin/bash
    echo "🧹 Cleaning up Docker resources..."
    
    # Remove stopped containers
    STOPPED=$(docker ps -aq -f status=exited)
    if [ -n "$STOPPED" ]; then
        echo "Removing stopped containers..."
        docker rm $STOPPED 2>/dev/null || true
    fi
    
    # Remove dangling images
    DANGLING=$(docker images -q -f dangling=true)
    if [ -n "$DANGLING" ]; then
        echo "Removing dangling images..."
        docker rmi $DANGLING 2>/dev/null || true
    fi
    
    echo "✅ Cleanup complete"
    echo "Tip: Use 'docker system prune -a' for more aggressive cleanup"

# Helm chart repo
HELM_REPO_NAME := "mathtrail"
HELM_REPO_URL := "https://RyazanovAlexander.github.io/mathtrail-charts/charts"
NAMESPACE := "mathtrail"

# Deploy PostgreSQL, Redis, Kafka, and Dapr to the cluster
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
    echo "📦 Installing Dapr..."
    helm upgrade --install dapr {{ HELM_REPO_NAME }}/dapr \
        -n dapr-system --create-namespace \
        --wait --timeout 120s

    echo ""
    echo "✅ All infrastructure services deployed!"
    echo ""
    helm list -n {{ NAMESPACE }}
    echo ""
    helm list -n dapr-system

# Remove deployed infrastructure services
uninstall:
    #!/bin/bash
    set -e
    echo "🗑️  Removing infrastructure services..."

    helm uninstall dapr -n dapr-system 2>/dev/null && echo "✅ Dapr removed" || echo "⚠️  Dapr not found"
    helm uninstall kafka -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Kafka removed" || echo "⚠️  Kafka not found"
    helm uninstall redis -n {{ NAMESPACE }} 2>/dev/null && echo "✅ Redis removed" || echo "⚠️  Redis not found"
    helm uninstall postgres -n {{ NAMESPACE }} 2>/dev/null && echo "✅ PostgreSQL removed" || echo "⚠️  PostgreSQL not found"

    echo ""
    echo "✅ All infrastructure services removed!"
