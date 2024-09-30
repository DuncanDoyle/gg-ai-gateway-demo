#!/bin/sh

curl "openai.example.com" -H content-type:application/json -d '{
    "model": "gpt-4o-mini",
    "max_tokens": 128,
    "temperature": 0.2,
    "messages": [
      {
        "role": "user",
        "content": "Parse the unstructured text into CSV format: Seattle, Los Angeles, and Chicago are cities in the United States. London, Paris, and Berlin are cities in Europe. Respond only with the CSV data."
      }
    ]
  }' | jq -r '.choices[].message.content'