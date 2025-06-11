#!/bin/sh

# Upstream pointing to the custom OpenAI model-failover deployment customHost instead of the real OpenAI endpoint.
kubectl apply -f upstreams/openai-upstream-model-failover.yaml