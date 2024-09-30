#!/bin/sh

curl "openai.example.com" -H content-type:application/json -d '{
    "model": "gpt-4o-mini",
    "max_tokens": 128,
    "messages": [
      {
        "role": "system",
        "content": "Parse the unstructured text into CSV format and respond only with the CSV data."
      },
      {
        "role": "user",
        "content": "Seattle, Los Angeles, and Chicago are cities in the United States. London, Paris, and Berlin are cities in Europe."
      }
    ]
  }' | jq -r '.choices[].message.content'