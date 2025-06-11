#!/bin/sh

# Semantic Caching: Redis Datastore
kubectl apply -f redis/redis-semantic-cache.yaml
kubectl -n gloo-system rollout status deploy redis-semantic-cache