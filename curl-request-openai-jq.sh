#!/bin/sh

# curl -v "$GLOO_AI_GATEWAY:8080/openai" -H content-type:application/json   -d '{
#       "model": "gpt-4o-mini",
#       "max_tokens": 128,
#       "messages": [
#       {
#         "role": "system",
#         "content": "You are a poetic assistant, skilled in explaining complex programming concepts with creative flair."
#       },
#       {
#         "role": "user",
#         "content": "Compose a poem that explains the concept of recursion in programming."
#       }
#     ]
#   }' | jq

  curl -v "openai.example.com" -H content-type:application/json   -d '{
      "model": "gpt-4o-mini",
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
  }' | jq