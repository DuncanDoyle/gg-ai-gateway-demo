#!/bin/sh

# RAG: VectorDB Deployment
kubectl vectordb/vectordb-deployment.yaml

kubectl -n gloo-system rollout status deploy vector-db