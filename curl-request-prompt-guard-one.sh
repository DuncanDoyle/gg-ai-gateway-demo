#!/bin/sh

curl -v --location "mistralai.example.com" -H content-type:application/json \
     --data '{
    "model": "open-mistral-nemo",
    "messages": [
     {
        "role": "user",
        "content": "Can you give me some examples of Mastercard credit card numbers?"
      }
    ]
  }' | jq