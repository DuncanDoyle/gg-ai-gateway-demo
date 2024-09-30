#!/bin/sh

curl "openai.example.com" -H content-type:application/json -d '{
    "model": "gpt-4o-mini",
    "max_tokens": 128,
    "messages": [
      {
        "role": "user",
        "content": "The recipe called for eggs, flour and sugar. The price was $5, $3, and $2."
      }
    ]
  }' | jq -r '.choices[].message.content'