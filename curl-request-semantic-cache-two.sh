#!/bin/sh

curl -v "openai.example.com" -H content-type:application/json \
    --data '{
    "model": "gpt-4o",
    "messages": [
     {
        "role": "user",
        "content": "How many cheeses are in France?"
      }
    ]
  }'