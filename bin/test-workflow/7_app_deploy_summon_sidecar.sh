#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Deploying summon sidecar test app in $TEST_APP_NAMESPACE_NAME."

set_namespace $TEST_APP_NAMESPACE_NAME

# Deploy sidecar app
app_name="app-summon-sidecar"
pushd $(dirname "$0")/../../helm/$app_name > /dev/null
  # Deploy a given app with yet another subset of the subset of our golden configmap, allowing
  # connection to Conjur
  announce "Installing sidecar application chart"

  if [ "$(helm list -q -n $TEST_APP_NAMESPACE_NAME | grep "^$app_name$")" = "$app_name" ]; then
    helm uninstall $app_name -n "$TEST_APP_NAMESPACE_NAME"
  fi

  $cli delete --ignore-not-found pvc -l app.kubernetes.io/instance=$app_name

  helm dependency update

  helm upgrade --install $app_name . --namespace "$TEST_APP_NAMESPACE_NAME" --debug --wait \
      --set conjur.connConfigMap="conjur-connect-configmap" \
      --set conjur.authnLogin="$CONJUR_AUTHN_LOGIN_PREFIX/test-$app_name" \
      --set backendSecret="test-app-backend-secret"
      
popd > /dev/null

echo "Test app/sidecar deployed."
