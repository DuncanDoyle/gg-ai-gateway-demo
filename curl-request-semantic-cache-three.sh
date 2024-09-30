#!/bin/sh

curl -v "openai.example.com" -H content-type:application/json \
    --data '{
    "model": "gpt-4o",
    "messages": [
     {
        "role": "user",
        "content": "Please tell how many different types of cheeses there are in France?"
      }
    ]
  }'