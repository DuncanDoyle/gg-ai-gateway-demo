#!/bin/sh

# export GLOO_GATEWAY_VERSION="1.17.0-rc2"
# GLOO_GATEWAY_VERSION="1.18.0-beta1-bmain-cd58f97"
export GLOO_GATEWAY_VERSION="1.19.1"
export K8S_GW_API_VERSION="v1.2.1"

export GLOO_GATEWAY_HELM_VALUES_FILE="gloo-gateway-helm-values-ai-gateway.yaml"

if [ -z "$GLOO_GATEWAY_LICENSE_KEY" ]
then
   echo "Gloo Gateway License Key not specified. Please configure the environment variable 'GLOO_GATEWAY_LICENSE_KEY' with your Gloo Gateway icense Key."
   exit 1
fi

#----------------------------------------- Install Gloo Gateway with K8S Gateway API support -----------------------------------------

printf "\nApply K8S Gateway CRDs ....\n"
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$K8S_GW_API_VERSION/standard-install.yaml

printf "\nInstalling Gloo Gateway $GLOO_GATEWAY_VERSION ...\n"
helm upgrade --install gloo glooe/gloo-ee  --namespace gloo-system --create-namespace --set-string license_key=$GLOO_GATEWAY_LICENSE_KEY -f $GLOO_GATEWAY_HELM_VALUES_FILE --version $GLOO_GATEWAY_VERSION
# helm upgrade --install gloo-gateway gloo-ee-test/gloo-ee --namespace gloo-system --create-namespace --set-string license_key=$GLOO_GATEWAY_LICENSE_KEY -f $GLOO_GATEWAY_HELM_VALUES_FILE --version $GLOO_GATEWAY_VERSION
printf "\n"

pushd ../
#----------------------------------------- Deploy the Gateway -----------------------------------------


printf "\Deploy the GatewayParams for AI Gateway ...\n"
kubectl apply -f gateways/gwparams-ai.yaml

printf "\nDeploy the AI Gateway ...\n"
kubectl apply -f gateways/gw-ai.yaml

popd