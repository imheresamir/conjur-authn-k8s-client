#!/usr/bin/env bash
set -euo pipefail

. utils.sh

set_namespace default

kubectl --namespace "$TEST_APP_NAMESPACE_NAME" delete --ignore-not-found job conjur-cli-init-job

# Prepare a given namespace with a subset of credentials from the golden configmap
announce "Installing application namespace prep chart"
pushd $(dirname "$0")/../../helm/application-namespace-prep > /dev/null
    # Namespace $TEST_APP_NAMESPACE_NAME will be created if it does not exist
    helm upgrade --install app-namespace-prep . -n "$TEST_APP_NAMESPACE_NAME" --debug --wait \
        --create-namespace \
        --set authnK8s.goldenConfigMap="authn-k8s-configmap" \
        --set authnK8s.namespace="$CONJUR_NAMESPACE" \
        # TODO: API Key, not password
        --set authnK8s.conjurAdminPassword="$(kubectl exec \
            --namespace "$CONJUR_NAMESPACE" \
            deploy/conjur-oss \
            --container conjur-oss \
            -- conjurctl role retrieve-key "$CONJUR_ACCOUNT":user:admin | tail -1)"
popd > /dev/null
