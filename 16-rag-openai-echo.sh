#!/bin/sh

# OpenAI Echo Service
kubectl apply -f apis/echo/echo.yaml

kubectl apply -f upstreams/openai-upstream-echo.yaml