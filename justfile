# MathTrail Local Infrastructure

set shell := ["bash", "-c"]

# Deploy all infrastructure components to the cluster
deploy:
    skaffold deploy
    kubectl apply -f manifests/pgbouncer.yaml -f manifests/pgbouncer-dashboard.yaml

# Delete all deployed infrastructure components and persistent volumes from the cluster
delete:
    skaffold delete
    kubectl delete --ignore-not-found -f manifests/pgbouncer.yaml -f manifests/pgbouncer-dashboard.yaml
    kubectl delete pvc --all -n mathtrail --ignore-not-found
