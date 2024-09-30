#!/bin/sh

####################################################################################
#
# Initiates the Gloo AI Gateway Demo
#
# Requires an existing Gloo Gateway 1.17+ setup.
#
####################################################################################

pushd ../


# # Label the default namespace, so the gateway will accept the HTTPRoute from that namespace.
# printf "\nLabel default namespace ...\n"
# kubectl label namespaces default --overwrite shared-gateway-access="true"

# printf "\nCreate the Tracks namespace ...\n"
# kubectl create namespace tracks --dry-run=client -o yaml | kubectl apply -f -
# kubectl label namespaces tracks --overwrite shared-gateway-access="true"


# # Create reference grants
# kubectl apply -f referencegrant/tracks-ns/portal-tracks-apiproduct-reference-grant.yaml

# # Setup ExtAuth and RateLimit configurations
# # kubectl apply -f policies/extauth/auth-config.yaml
# # kubectl apply -f policies/ratelimit/ratelimit-config.yaml

# # Create the ApiKeys for the extauth and ratelimit test-runs
# # policies/extauth/create-apikey.sh
# # policies/extauth/create-apikey-for-ratelimit.sh
# # policies/extauth/create-apikey-for-ratelimit-warmup.sh

# # Apply the VirtualService
# # kubectl apply -f virtualservices/api-example-com-vs.yaml
# # kubectl apply -f virtualservices/gloofed-example-com-vs.yaml

popd