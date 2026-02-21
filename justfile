# MathTrail Local Infrastructure

set shell := ["bash", "-c"]

# Deploy all infrastructure components to the cluster
deploy:
    skaffold deploy

# Delete all deployed infrastructure components and persistent volumes from the cluster
delete:
    skaffold delete
    kubectl delete pvc --all -n mathtrail --ignore-not-found
