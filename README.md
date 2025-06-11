#

## Deploy Gloo AI Gateway

```
export GLOO_GATEWAY_LICENSE_KEY={your-gloo-gateway-license}
cd install
./install-gloo-gateway-enterprise-with-helm.sh
```



## Credentials and Access Control

**Automate Authorization with Gloo AI Gateway**

Automate authz management for LLM APIs with Gloo AI Gateway
Securely set up API keys using Kubernetes secrets

```
export OPENAI_API_KEY=<your Open AI API Key>
export MISTRAL_API_KEY=<your Mistral AI API Key>
```

```
kubectl create secret generic openai-secret -n gloo-system \
    --from-literal="Authorization=Bearer $OPENAI_API_KEY" \
    --dry-run=client -oyaml | kubectl apply -f -
```

```
kubectl create secret generic mistralai-secret -n gloo-system \
    --from-literal="Authorization=Bearer $MISTRAL_API_KEY" \
    --dry-run=client -oyaml | kubectl apply -f -
```

Next, setup the `Upstreams` and `HTTPRoute`.

Test
```
export GLOO_AI_GATEWAY=$(kubectl --context $CLUSTER1 get svc -n gloo-system gloo-proxy-ai-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```
curl -v "$GLOO_AI_GATEWAY:8080/openai" -H content-type:application/json   -d '{
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
  ```


### Streaming

We can also enable streaming responses by setting the stream field to true in the request. You can press CTRL+C to stop the streaming:

**Secure Access to LLM Providers**

Define a JWT provider in VirtualHostOption to validate tokens and grant access based on roles and claims
Configure RBAC with JWTs and RouteOption resource and ensure secure API interactions and robust access control


Deploy the VirtualHostOption with the JWT provider configuration:

```
kubectl apply -f policies/jwt-provider-vho.yaml
```


If you try to send the same request as before, without a JWT, you'll get an HTTP 401 Unauthorized response that says the request is missing a JWT:

```
curl -v "$GLOO_AI_GATEWAY:8080/openai" -H content-type:application/json -d '{
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
  }'
```

```
# Alice works in the "dev" team and we're going to give her access to the Open AI API (specifically the GPT-4o-mini model)
export ALICE_TOKEN=$(./install/create-jwt.sh ./install/private-key.pem alice dev openai gpt-4o-mini)

# Bob works in the "ops" team and we're going to give him access to the Mistral AI API (specifically the open-mistral-nemo model)
export BOB_TOKEN=$(./install/create-jwt.sh ./install/private-key.pem bob ops mistralai open-mistral-nemo)
```


```
curl "$GLOO_AI_GATEWAY:8080/openai" --header "Authorization: Bearer $ALICE_TOKEN" -H content-type:application/json -d '{
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
  }'
```

Let's create the RouteOption resource where we extract the claims from the JWT and check whether the user has access to the open-mistral-nemo model:

```
kubectl apply -f policies/mistralai-routeoption.yaml
```

```
curl "$GLOO_AI_GATEWAY:8080/mistralai" --header "Authorization: Bearer $BOB_TOKEN" -H content-type:application/json -d '{
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
  }' | jq
```

As expected, we get a response from the Mistral AI API because Bob has access to the open-mistral-nemo model.

If we try the same request with Alice's JWT, we'll get an HTTP 403 Forbidden response because Alice doesn't have access to the open-mistral-nemo model:

```
curl -v "$GLOO_AI_GATEWAY:8080/mistralai"  -H "Authorization: Bearer $ALICE_TOKEN" -H content-type:application/json -d '{
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
  ```

## Rate limit traffic sent to LLM providers

Rate limiting on LLM provider token usage is primarily related to cost management, security and service stability. LLM providers charge based on the number of input (user prompts and system prompts) and output (responses from the model) tokens, which can make uncontrolled usage very expensive.

With Gloo AI Gateway, you can configure rate limiting based on LLM usage so that organizations can enforce budget constraints across groups, teams, departments, and individuals, and ensure that their usage remains within predictable bounds. That way, you can avoid unexpected costs and prevent malicious attacks to your LLM provider.


> [!NOTE]
> Token is a unit of text that LLM provider models process.

### Rate Limiting on Token Usage

Let's come up with the rate limit configuration based on the claims in the JWT token. The first configuration will create a per-user limit that's based on the sub claim in the JWT token:

```
kubectl apply -f policies/ratelimitconfig.yaml
```

The rate limit we're setting (70 tokens per hour) is the number of input tokens to the LLM provider. This is a very low limit and is just for demonstration purposes. In a real-world scenario, you would set this limit based on the expected usage of the LLM provider.

The second part of the configuration is create the RouteOption resource where we add the rate limit configuration for the specific route (OpenAI in this case):

```
kubectl apply -f policies/rl-openai-routeoption.yaml
```

Send requests. Notice that after a couple of requests, you will get rate-limited.

```
./curl-request-alice-openai.sh
```


### Viewing Usage Metrics
Update the Grafana dashboard to visualize the rate limiting metrics:

```
kubectl apply -f dashboards/grafana-dash.yaml
```

In addition using the tokens to rate limit, the Gloo AI Gateway can also be configured to collect usage metrics. These metrics can be used to monitor the actual usage for specific LLM providers and serve as a basis for cost allocation and optimization.

Click the Grafana tab. When prompted for username and password enter admin for both. You can Skip when prompted to create a new password.

Next, click the Search icon, search for "Prompt Usage" and click on the dashboard.

This dashboard shows the input and output usage broken down by the provider and models.


### AI Model Failover

Model failover is critical to ensure the reliability of your AI services. When LLM providers receive more traffic than allocated to a specific model, it can lead to slow responses or even service outages. By implementing model failover in Gloo AI Gateway, you can automatically redirect traffic to alternative models when the primary model is overwhelmed.

This helps distribute the load and maintain the performance and availability of your AI services.

In this example, we will use a custom (fake) model we deployed on the cluster called model-failover. This allows us to simulate failure scenarios and demonstrate how the failover mechanism works in the Gloo AI Gateway.

```
kubectl apply -f apis/model-failover/model-failover.yaml
```

```
kubectl -n gloo-system rollout status deploy model-failover
```

Let's re-configure the openai upstream to use the custom model model-failover instead of the actual OpenAI API and Mistral AI API:

```
kubectl apply -f upstreams/openai-upstream-model-failover.yaml
```

The backup models are configured in the RouteOption resource under the backupModels field. In this example, we'll configure the backup models to be gpt-4.0-turbo and gpt-3.5-turbo:

```
kubectl apply -f policies/model-failover-openai-routeoption.yaml
```

The `model-failover` will always return a 429 on every request (to force the failover). Observe the logs of the `model-failover` deployment to see the requests that were sent by the AI Gateway:

```
{"time":"2024-09-30T09:55:04.760783637Z","level":"INFO","msg":"Request received","msg":"{\"messages\":[{\"content\":\"You are a poetic assistant, skilled in explaining complex programming concepts with c │
│ reative flair.\",\"role\":\"system\"},{\"content\":\"Compose a poem that explains the concept of recursion in programming.\",\"role\":\"user\"}], "model\":\"gpt-4o\"}"}                                    │
│ {"time":"2024-09-30T09:55:04.771778512Z","level":"INFO","msg":"Request received","msg":"{\"messages\":[{\"content\":\"You are a poetic assistant, skilled in explaining complex programming concepts with c │
│ reative flair.\",\"role\":\"system\"},{\"content\":\"Compose a poem that explains the concept of recursion in programming.\",\"role\":\"user\"}], "model\":\"gpt-4.0-turbo\"}"}                             │
│ {"time":"2024-09-30T09:55:04.781421262Z","level":"INFO","msg":"Request received","msg":"{\"messages\":[{\"content\":\"You are a poetic assistant, skilled in explaining complex programming concepts with c │
│ reative flair.\",\"role\":\"system\"},{\"content\":\"Compose a poem that explains the concept of recursion in programming.\",\"role\":\"user\"}], "model\":\"gpt-3.5-turbo\"}"}
```

See that the originally requested model was tried first, after which the backup models were tried as well.


## Promt Management and Guards

### Prompt Management

Prompts are basic building blocks for guiding LLMs to produce relevant and accurate responses. By effectively managing both system prompts, which set initial guidelines, and user prompts, which provide specific context, you can significantly enhance the quality and coherence of the model’s outputs.

### Prompt Guards

Prompt guards are mechanisms that ensure that prompt-based interactions with a language model are secure, appropriate, and aligned with the intended use. These mechanisms help to filter, block, monitor, and control LLM inputs and outputs to filter offensive content, prevent misuse, and ensure ethical and responsible AI usage.

By effectively managing both system prompts, which set initial guidelines, and user prompts, which provide specific context, we can significantly enhance the quality and coherence of the model's outputs.

System prompts include initialization instructions, behavior guidelines, and background information, setting the foundation for the model's behavior.

User prompts encompass direct queries, sequential inputs, and task-oriented instructions, ensuring the model responds accurately to specific user needs.

### Managing System Prompts

Let's take a look an example where we use system prompts to guide the model in parsing unstructured text into CSV format.

We'll start with the following prompt:

```
Parse the unstructured text into CSV format: Seattle, Los Angeles, and Chicago are cities in the United States. London, Paris, and Berlin are cities in Europe. Respond only with the CSV data.
```

```
./curl-request-prompt-one.sh
```

The results look good - note that there might be cases where you'd want to further adjust the prompt or other configuration settings to improve the output quality.

Notice the prompt we're sending to the model includes the instructions on what to do as well as the unstructured text to parse.

We can extract the instruction part of the prompt into a system prompt:

```
./curl-request-prompt-two.sh
```

The response will still be the same, however, we have refactored the initial prompt, so it's easier to read and manage. However, how could we share this system prompt and make it available to others without copy/pasting text around and hardcoding prompts into code?

The Gloo AI Gateway allows us to define the system prompt at the gateway level! The promptEnrichment field in the RouteOption resource allows us to enrich the prompts by appending or prepending system or user prompts to the requests:

```
kubectl apply -f policies/prompt-enrichment-openai-routeoption.yaml
```

If we send a request now, the system prompt will be automatically included by the Gloo AI Gateway, before it's sent to the LLM provider:

```
./curl-request-prompt-three.sh
```


### Content Safety with Prompt Guard

Content safety refers to the secure handling of data interactions within an API, particularly in preventing unintended consequences such as data leaks, injection attacks, and unauthorized access.

LLM provider APIs, given their ability to process and generate human-like text, are especially susceptible to subtle and sophisticated attacks. For instance, an attacker could craft specific input to extract sensitive information or manipulate the output in a harmful way. Ensuring content safety means implementing robust measures to protect the integrity, confidentiality, and availability of the data processed by these APIs.

We'll start with an example prompt that asks for examples of credit card numbers:

```
./curl-request-prompt-guard-one.sh
```

Note the response contains the explanation of how the Master Card credit card numbers are created.

We can use the prompt guard and reject the requests if they match a specific pattern. The field supports regular expressions, but in this case, we'll check whether the prompt includes the string "credit card" and return a custom response message if it does. Let's create the RouteOption resource and configure the prompt guard:

```
kubectl apply -f policies/prompt-guard-mistralai-routeoption.yaml
```

Fire the same request again and notice that the request gets blocked by the AI Gateway and a `403 - Forbidden` is returned:

```
./curl-request-prompt-guard-one.sh
```

The request was blocked because it contained the string "credit card". But what happens if we try to send a request without the string "credit card" to circumvent prompt guard?

```
./curl-request-prompt-guard-two.sh
```

You'll notice the response will be similar to the initial one, it will not be blocked and it will contain examples of credit card numbers. This is where we can use prompt guard on responses and censor specific content that we want to prevent from being logged or returned to the user. Let's update the RouteOption resource and include a prompt guard on response as well - this time, we'll use regular expression that matches on Mastercard credit card numbers:

```
kubectl apply -f policies/prompt-guard-responses-mistralai-routeoption.yaml
```

```
./curl-request-prompt-guard-two.sh
```

The response is similar to the previous one, however, this time any strings matching the regular expression are replaced with X. This way, we can ensure that sensitive information is not logged or returned to the user.

## RAG and Semantic Caching
### RAG
 
Retrieval augmented generation (RAG) is a technique of providing relevant context by retrieving relevant data from one or more datasets and augmenting the prompt with the retrieved information. This approach helps LLMs to generate more accurate and relevant responses and to a certain point prevent hallucinations.

### Semantic Caching

Semantic caching stores the data based on its meaning. If two prompts sent to the LLM provider are semantically similar, the LLM response from the first prompt can be reused for the second prompt, without sending a request to the LLM. This reduces the number of requests to the LLM provider, improves the response time, and reduces the cost.

### RAG
Retrieval augmented generation or RAG is a technique of providing relevant context by retrieving relevant data from one or more datasets and augmenting the prompt with the retrieved information. This approach helps LLMs to generate more accurate and relevant responses and to a certain point prevent hallucinations.

Gloo AI Gateway's RAG feature allows you to configure the system to retrieve data from a specified datastore and use it to augment the prompt before sending it to the model. This can be particularly useful in scenarios where the model requires additional context to generate accurate responses.

Configure the RAG Feature
Let's try sending a request to the Gloo AI Gateway without the RAG enabled, so we can compare the responses:

```
./curl-request-rag-one.sh
```

The response from the LLM can be made more accurate and relevant using RAG.

We've prepared a vector database (vector-db pod in the cluster) with the embeddings created from a website that talks about French cheeses and explicitly mentions "1,000-1,600 varieties of cheeses" in France.

Let's configure the RAG feature to retrieve the relevant data from the database and see how the response changes.

Deploy the vector DB:

```
kubectl vectordb/vectordb-deployment.yaml

kubectl -n gloo-system rollout status deploy vector-db
```

We'll use the RouteOption and configure point the data store to the Postgres database (with embeddings) that's running inside the cluster:

```
kubectl apply -f policies/rag-openai-routeoption.yaml 
```

This configuration tells the Gloo AI Gateway to embed the original prompt we'll be sending and then use it to retrieve the similar embeddings from the database and finally augment the prompt with the retrieved data before sending it to the model.

Let's send the same prompt again and see how the response changes:

```
./curl-request-rag-one.sh
```

This time, the response is accurate and concise, providing a definitive answer that can be found on the website that was used to create the embeddings.

To see the request that is actually being sent to OpenAI, we can deploy and "echo" service and route the request to that service instread of OpenAI to inspect the request:

```
kubectl apply -f apis/echo/echo.yaml

kubectl apply -f upstreams/openai-upstream-echo.yaml
```

Next, send the request again and observe that the request that is being generated by the AI Gateway contains additional info added by our RAG module from our vector database:

```
./curl-request-rag-one.sh
```

Next, reset the OpenAI upstream:

```
kubectl apply -f upstreams/openai-upstream.yaml
```

### Semantic Caching

Semantic caching is a feature in Gloo AI Gateway that caches semantically similar queries. This means that if two prompts are semantically similar, the LLM response from the first prompt can be reused for the second prompt, without sending a request to the LLM. This reduces the number of requests made to the LLM provider, improves the response time, and reduces the cost.

For caching the responses, we'll use Redis as the caching datastore:

```
kubectl apply -f redis/redis-semantic-cache.yaml
kubectl -n gloo-system rollout status deploy redis-semantic-cache
```

Let's configure the Gloo AI Gateway to use Redis for semantic caching by deploying a RouteOption resource:

```
kubectl apply -f policies/semantic-caching-openai-routeoption.yaml 
```

This configuration tells the Gloo AI Gateway to use a Redis instance (`redis://redis-semantic-cache.gloo-system.svc.cluster.local:6379`) to cache the responses for semantically similar queries in Redis. Let's try sending the same prompt multiple times and see how the response time changes

```
./curl-request-semantic-cache-one.sh
```

Notice the response time returned in `x-envoy-upstream-service-time`. Now send the request again and see how the response time changes:

```
./curl-request-semantic-cache-one.sh
```

The response should be significantly faster this time because the response is cached in Redis and the Gloo AI Gateway is reusing the cached response for the same prompt. We know the response was cached because the `x-gloo-semantic-cache: hit` header is present in the response.

If you modify the prompt so it's still semantically similar but not exactly the same, the Gloo AI Gateway will still use the cached response. Let's try sending a slightly modified prompt and see we get a cached response:

```
./curl-request-semantic-cache-two.sh
```

You should again get the cached response as the question is semantically equivalent to the previous question.

Finally, let's try another question that is semantically equivalent to the first two:

```
./curl-request-semantic-cache-three.sh
```

And again, we see that we get a cached response.