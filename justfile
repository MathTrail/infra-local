deploy:
    skaffold deploy --namespace ${NAMESPACE}

delete:
    skaffold delete --namespace ${NAMESPACE}
