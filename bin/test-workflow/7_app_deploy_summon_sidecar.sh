#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Deploying summon sidecar test app in $TEST_APP_NAMESPACE_NAME."

set_namespace $TEST_APP_NAMESPACE_NAME

# Deploy sidecar app
pushd $(dirname "$0")/../../helm/app-summon-sidecar > /dev/null
  # Deploy a given app with yet another subset of the subset of our golden configmap, allowing
  # connection to Conjur
  announce "Installing sidecar application chart"

  if [ "$(helm list -q -n $TEST_APP_NAMESPACE_NAME | grep "^app-summon-sidecar$")" = "app-summon-sidecar" ]; then
    helm uninstall app-summon-sidecar -n "$TEST_APP_NAMESPACE_NAME"
  fi

  $cli delete --ignore-not-found pvc -l app.kubernetes.io/instance=app-summon-sidecar

  helm dependency update

  helm upgrade --install app-summon-sidecar . --namespace "$TEST_APP_NAMESPACE_NAME" --debug --wait \
      --set conjur.connConfigMap="conjur-connect-configmap" \
      --set conjur.authnLogin="$CONJUR_AUTHN_LOGIN_PREFIX/test-app-summon-sidecar" \
      --set backendSecret="test-app-backend-secret"
      
popd > /dev/null

echo "Test app/sidecar deployed."
