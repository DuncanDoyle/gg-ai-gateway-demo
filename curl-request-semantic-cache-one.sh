#!/bin/sh

curl -v "openai.example.com" -H content-type:application/json \
     --data '{
    "model": "gpt-4o-mini",
    "messages": [
     {
        "role": "user",
        "content": "How many varieties of cheeses are in France?"
      }
    ]
  }'