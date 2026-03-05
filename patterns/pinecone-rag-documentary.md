# Pinecone RAG for Documentary Filmmaking

## Architecture

A documentary project accumulates thousands of pages: interviews, correspondence, legal documents, research, online posts. Claude Code's context window can't hold all of it. RAG (Retrieval-Augmented Generation) solves this.

```
Sources (markdown + JSON)
    ↓ chunking + metadata
Pinecone Index (multilingual-e5-large, 1024 dims)
    ↓ semantic search
Claude Code queries → contextual results → informed analysis
```

## Setup

### Index configuration

```
Model: multilingual-e5-large (1024 dimensions)
Cloud: AWS us-east-1
Metric: cosine
```

Why multilingual-e5-large:
- Handles mixed-language sources (French interviews + English documents)
- 1024 dims = good balance of precision vs cost
- Integrated inference in Pinecone (no external embedding step)

### Namespace strategy

| Namespace | Content | Records |
|---|---|---|
| `sources` | Markdown files (interviews, correspondence, bible, research) | ~60K vectors |
| `posts` | Subject's online posts (JSON) | ~35K vectors |

Separate namespaces = separate search scopes. You can query just interviews, or just posts, or both.

### Chunking strategy

```python
MAX_CHUNK_CHARS = 2000
OVERLAP_CHARS = 200
```

- **Section-aware splitting**: Split on `## ` headers first, then by character limit
- **Overlap**: 200 chars between chunks prevents losing context at boundaries
- **Minimum size**: Skip chunks < 50 chars (headers, empty sections)
- **Metadata per chunk**: file path, document type, folder, chunk index

### Metadata fields

```python
record = {
    "_id": "deterministic-hash-0001",
    "content": "chunk text...",          # the actual text (searchable)
    "file": "sources/interviews/mike.md", # source file path
    "type": "interview",                  # document type
    "folder": "sources",                  # top-level folder
    "chunk_index": 3                      # position in source file
}
```

Important: the text field is `content`, not `text`. Pinecone's integrated inference uses this for embedding.

### Skip directories

Conversation exports (ChatGPT, Claude) are too voluminous and low-signal for RAG. Skip them:

```python
SKIP_DIRS = {
    "chatgpt-conversations-readable",
    "claude-conversations-readable",
    # ... etc
}
```

## Querying

### From Claude Code (via MCP)

```
Pinecone MCP → search-records tool
  index: your-index-name
  namespace: sources
  query: "what did the subject say about X?"
  top_k: 10
  fields: ["content", "file", "type"]
```

### From Python

```python
from pinecone import Pinecone

pc = Pinecone(api_key=API_KEY)
idx = pc.Index("your-index")

results = idx.search(
    namespace="sources",
    query={"inputs": {"text": "search query"}, "top_k": 10},
    fields=["content", "file", "type"]
)

for hit in results.result.hits:
    print(f"[{hit['fields']['type']}] {hit['fields']['file']}")
    print(f"Score: {hit['_score']:.3f}")
    print(hit['fields']['content'][:200])
```

### Indexing script pattern

```python
# Upsert with rate limiting
for batch_start in range(0, len(records), 48):
    batch = records[batch_start:batch_start + 48]
    for attempt in range(3):
        try:
            index.upsert_records(namespace=namespace, records=batch)
            break
        except Exception as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                time.sleep(15 * (attempt + 1))
            else:
                raise
    time.sleep(2)  # throttle between batches
```

Key points:
- Batch size 48 (under Pinecone's 100 limit, leaves room)
- Retry with exponential backoff on 429s
- 2s sleep between batches to avoid rate limits
- Deterministic IDs = re-running is idempotent (updates, doesn't duplicate)

## Cost

- Free tier: 5M vector reads/month, 20K vector writes/month
- For ~95K vectors: stays within free tier for querying
- Initial indexing: may need to spread over 2-3 days on free tier

## Lessons learned

1. **Field names matter**: `content` not `text`. The query returns empty if you request wrong fields.
2. **Multilingual model is essential**: Documentary sources are rarely monolingual.
3. **Namespace separation pays off**: Querying 35K posts separately from 60K research docs gives much better results.
4. **Metadata is cheap, missing metadata is expensive**: Always store file path, type, and chunk index. You'll need them for attribution.
5. **Deterministic IDs**: Hash the filepath + chunk number. This makes re-indexing safe.

## Status

Production-tested on a feature documentary with ~95K vectors across 2 namespaces. Query scores consistently above 0.85 for relevant results.
