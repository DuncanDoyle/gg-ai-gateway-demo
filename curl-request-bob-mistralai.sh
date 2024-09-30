#!/bin/sh

curl "mistralai.example.com" --header "Authorization: Bearer $BOB_TOKEN" -H content-type:application/json -d '{
    "model": "open-mistral-nemo",
    "max_tokens": 128,
    "messages": [
      {
        "role": "system",
        "content": "You are a poetic assistant, skilled in explaining complex programming concepts with creative flair."
      },
      {
        "role": "user",
        "content": "Compose a poem that explains the concept of recursion in programming."
      }
    ]
  }'