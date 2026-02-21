# Deploy all infrastructure components to the Kubernetes cluster
deploy:
    skaffold deploy --namespace ${NAMESPACE}

# Delete all deployed infrastructure components from the Kubernetes cluster
delete:
    skaffold delete --namespace ${NAMESPACE}
