#!/bin/sh

curl -v "openai.example.com" -H content-type:application/json -d '{
  "model": "gpt-4o",
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