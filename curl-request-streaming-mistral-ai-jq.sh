#!/bin/sh

curl --location "mistralai.example.com" -H content-type:application/json \
     --data '{
    "model": "open-mistral-nemo",
    "max_tokens": 128,
    "messages": [
     {
        "role": "user",
        "content": "What is the best French cheese?"
      }
    ],
    "stream": true
  }'