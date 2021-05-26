#!/usr/bin/env bash
set -euo pipefail

. utils.sh

init_bash_lib

RETRIES=150
# Seconds
RETRY_WAIT=2

# Dump some kubernetes resources and Conjur authentication policy if this
# script exits prematurely
DETAILED_DUMP_ON_EXIT=true

function finish {
  readonly PIDS=(
    "SIDECAR_PORT_FORWARD_PID"
  )

  if [[ "$DETAILED_DUMP_ON_EXIT" == "true" ]]; then
    dump_kubernetes_resources
    dump_authentication_policy
  fi

  set +u

  echo -e "\n\nStopping all port-forwarding"
  for pid in "${PIDS[@]}"; do
    if [ -n "${!pid}" ]; then
      # Kill process, and swallow any errors
      kill "${!pid}" > /dev/null 2>&1
    fi
  done
}
trap finish EXIT

announce "Validating that the deployments are functioning as expected."

set_namespace "$TEST_APP_NAMESPACE_NAME"

deploy_test_curl() {
  $cli delete --ignore-not-found pod/test-curl
  $cli create -f ./$PLATFORM/test-curl.yml
}

check_test_curl() {
  pods_ready "test-curl"
}

pod_curl() {
  kubectl exec test-curl -- curl "$@"
}

echo "Deploying a test curl pod"
deploy_test_curl
echo "Waiting for test curl pod to become available"
bl_retry_constant "${RETRIES}" "${RETRY_WAIT}"  check_test_curl
  
echo "Waiting for pods to become available"

check_pods(){
  pods_ready "test-app-summon-sidecar"
}

bl_retry_constant "${RETRIES}" "${RETRY_WAIT}"  check_pods

# Apps don't have loadbalancer services, so test by curling from
# a pod that is inside the KinD cluster.
curl_cmd=pod_curl
sidecar_url="test-app-summon-sidecar.$TEST_APP_NAMESPACE_NAME.svc.cluster.local:8080"

echo "Waiting for urls to be ready"

check_urls(){
  $curl_cmd -sS --connect-timeout 3 "$sidecar_url" > /dev/null
}

bl_retry_constant "${RETRIES}" "${RETRY_WAIT}" check_urls

echo -e "Adding entry to the sidecar app\n"
$curl_cmd \
  -d '{"name": "Mr. Sidecar"}' \
  -H "Content-Type: application/json" \
  "$sidecar_url"/pet

echo -e "\n\nQuerying sidecar app\n"
$curl_cmd "$sidecar_url"/pets

DETAILED_DUMP_ON_EXIT=false
