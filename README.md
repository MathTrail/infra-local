# MathTrail Infrastructure Local K3d

Local Kubernetes cluster setup using K3d for MathTrail development environment.

## Overview

This repository manages a local K3d (K3s in Docker) cluster that serves as the local development Kubernetes environment for MathTrail. The cluster can be created and managed from your host machine, and DevContainers across the workspace can deploy services to it using Helm.

## Prerequisites

### System Requirements

- **Docker** — K3d runs Kubernetes in Docker containers
- **Just** — Task runner for cluster management commands
- **kubectl** — (optional) Kubernetes command-line tool
- Internet access to download k3d and container images

### Supported Platforms

- Windows (with WSL2 or Docker Desktop)
- macOS
- Linux

## Install Just (Required)

The `just` command runner is required to use the cluster management scripts. Install it on your host machine:

### Windows

**Option 1: Using Chocolatey**
```powershell
choco install just
```

**Option 2: Using Cargo (Rust package manager)**
```powershell
cargo install just
```

**Option 3: Download binary manually**
1. Download from [GitHub Releases](https://github.com/casey/just/releases)
2. Extract the binary and add to `PATH`

Verify installation:
```powershell
just --version
```

### macOS

**Option 1: Using Homebrew** (recommended)
```bash
brew install just
```

**Option 2: Using Cargo**
```bash
cargo install just
```

Verify installation:
```bash
just --version
```

### Linux

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install just
```

**Fedora/RHEL:**
```bash
sudo dnf install just
```

**Using Cargo (all distributions):**
```bash
cargo install just
```

Verify installation:
```bash
just --version
```

## Quick Start

### 1. Install K3d

```bash
cd mathtrail-infrastructure-local-k3d
just install
```

This will download and install the latest k3d binary.

### 2. Create Development Cluster

```bash
just create
```

This creates a K3d cluster with:
- 1 server node (control plane)
- 2 agent nodes (workers)
- Built-in container registry for image caching (automatically managed by K3d)
- Port forwarding for HTTP/HTTPS traffic

### 3. Get Kubeconfig

```bash
just kubeconfig
```

This saves the cluster configuration to `~/.kube/k3d-mathtrail-dev.yaml` and makes it accessible to DevContainers.

### 4. Verify Cluster

```bash
just status
```

## Available Commands

All commands are managed through the `justfile`. View all available commands:

```bash
just help
```

### Essential Commands

| Command | Description |
|---------|-------------|
| `just install` | Install k3d on the host machine |
| `just create` | Create the local K3d cluster |
| `just start` | Start the cluster (if stopped) |
| `just stop` | Stop the cluster without removing it |
| `just delete` | Completely remove the cluster |
| `just reset` | Delete and recreate cluster from scratch (use if creation fails) |
| `just status` | Show cluster status and information |
| `just logs` | Stream cluster logs |
| `just kubeconfig` | Generate and save cluster kubeconfig |
| `just init-cluster` | Initialize cluster with essential components |
| `just clean` | Clean up Docker resources (stopped containers, dangling images) |

## DevContainer Integration

### For Helm Deployments from DevContainer

To deploy services from other DevContainers (like `mathtrail-mentor` or `mathtrail-ui-web`):

#### 1. Host Machine Setup

First, ensure the cluster is running and kubeconfig is available:

```bash
# In mathtrail-infrastructure-local-k3d directory
just create          # Create cluster once
just kubeconfig      # Generate kubeconfig file
```

#### 2. DevContainer Configuration

Update your DevContainer's `devcontainer.json` to mount the kubeconfig:

```jsonc
{
    "features": {
        "ghcr.io/devcontainers/features/kubectl:1.29.0": {},
        "ghcr.io/devcontainers/features/helm:3.14.0": {}
        // ... other features
    },
    "mounts": [
        "source=${localEnv:HOME}/.kube,target=/root/.kube,type=bind,readonly"
    ],
    "remoteEnv": {
        "KUBECONFIG": "/root/.kube/k3d-mathtrail-dev.yaml"
    }
}
```

#### 3. Verify Access from DevContainer

Inside the DevContainer:

```bash
kubectl cluster-info
kubectl get nodes
helm list
```

### Deploying Applications

Example deployment from mathtrail-mentor DevContainer:

```bash
# Inside DevContainer
helm upgrade --install mathtrail-mentor ./helm/mathtrail-mentor \
    --values ./helm/mathtrail-mentor/values.yaml \
    --kubeconfig /root/.kube/k3d-mathtrail-dev.yaml
```

## Architecture

```
Host Machine
├── Docker Desktop / Docker Engine
│   └── K3d Cluster (mathtrail-dev)
│       ├── Server Node (Control Plane)
│       ├── Agent Node 1
│       ├── Agent Node 2
│       ├── Local Registry (port 5000)
│       └── Ingress Controller
│
└── DevContainers
    ├── mathtrail-mentor
    ├── mathtrail-ui-web
    └── mathtrail-ui-chatgpt
    (All can access cluster via kubeconfig)
```

## Networking

### Port Forwarding

The cluster exposes:
- **HTTP**: localhost:80 → cluster ingress
- **HTTPS**: localhost:443 → cluster ingress
- **Registry**: localhost:5000 → local Docker registry

### DevContainer to Host Cluster Communication

- On Linux: Direct access via Docker network
- On macOS/Windows: Access via `host.docker.internal` or Docker Desktop networking
- Kubeconfig provides necessary connection details

## Container Image Registry

The K3d cluster includes a built-in Docker registry that is automatically managed. This registry is accessible from within the cluster at:

**Registry URL (inside cluster)**: `k3d-registry.localhost:5000`

**Push images from host:**

```bash
# Build image locally
docker build -t myapp:latest .

# Tag for registry (using docker.io registry for host access)
docker tag myapp:latest localhost:5555/myapp:latest

# Push to registry
docker push localhost:5555/myapp:latest

# Use in Kubernetes manifests (from inside cluster)
# image: k3d-registry.localhost:5000/myapp:latest
```

Note: The registry is internal to the cluster and accessible via DNS name from pods. External tagging uses the cluster's mapped ports.

## Troubleshooting

### Cluster creation fails

If `just create` fails with errors about registry nodes or bad state:

```bash
# Completely reset the cluster (removes old containers, networks, volumes)
just reset

# This is equivalent to:
just delete
sleep 2
just create
```

### Cluster won't start

```bash
# Check Docker is running
docker ps

# View recent logs
just logs

# Reset cluster if needed
just reset

# For persistent issues, clean up Docker resources
just clean
just reset
```

### DevContainer can't access cluster

```bash
# Verify kubeconfig exists
ls -la ~/.kube/k3d-mathtrail-dev.yaml

# Check from within DevContainer
kubectl config view
kubectl cluster-info
```

### Port conflicts

**Default ports:**
- **HTTP**: 80 (via ingress)
- **HTTPS**: 443 (via ingress)
- **Registry**: Built-in to K3d cluster (no external port needed)

If ports 80 or 443 are already in use, modify them in the `justfile`:

```bash
K3D_PORT_HTTP := "8080:80@loadbalancer"    # Use 8080 instead of 80
K3D_PORT_HTTPS := "8443:443@loadbalancer"  # Use 8443 instead of 443
```

## Performance Considerations

- **Memory**: Default K3d cluster uses ~1-2GB. Monitor Docker Desktop resources.
- **Disk space**: Container images can use several GB. Clean up with `docker system prune`.
- **CPU**: Typically requires 2+ CPU cores.

## Additional Resources

- [K3d Documentation](https://k3d.io/latest/)
- [K3s Documentation](https://docs.k3s.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

See LICENSE file in this repository.
