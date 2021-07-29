#!/bin/sh

# exit when any command fails
set -e

function _deploy() {

  # Apply non-image specific config
  kubectl apply \
    -f ./kubernetes/deployment.yaml \
    -f ./kubernetes/service.yaml \
    -f ./kubernetes/ingress.yaml \
    -n dex-mi-production

}

_deploy $@
