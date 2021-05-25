#!/bin/bash

set -euo pipefail

echo "$(kubectl exec \
        -n "$CONJUR_NAMESPACE" \
        deploy/conjur-oss \
        -- conjurctl role retrieve-key "$CONJUR_ACCOUNT":user:admin | tail -1)"
