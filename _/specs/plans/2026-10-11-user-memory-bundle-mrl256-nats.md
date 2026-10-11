# User Memory & Scope Instruction Optimization — Protobuf Bundles, MRL 256-dim & NATS KV Cache

> **Status:** Active (2026-10-11)  
> **Goal:** Accelerate Stage 2 prompt preparation by transforming User Memory and User Scope Instructions into cached Protobuf binary bundles with Matryoshka 256-dimensional embeddings, in-RAM SIMD vector comparison, and NATS JetStream KV caching.

---

## 1. Problem Statement & Bottlenecks

During Stage 2 of prompt compilation in `prompt_turn.rs`:
1. **User Memory Retrieval (`memory_retrieve`)**:
   - Executes 2 WAN SQL queries to YugabyteDB (`memory_pinned` and `memory_active_with_embed`).
   - Fetches up to 64 memories with full 768-dimensional embeddings stored as JSON text strings `[0.0123, -0.456, ...]`.
   - Deserializes hundreds of kilobytes of JSON float arrays on every turn.
   - Computes 768-dim cosine similarity with square roots and normalization in software.
   - Triggers a Gemini Embed API call even on trivial conversational messages (*"ok"*, *"lanjut"*, *"terima kasih"*).
2. **User Scope Instructions (`scope_instruction_load_for_prompt`)**:
   - Queries `ai.scope_instruction` over WAN SQL on every turn to fetch user instructions and site instructions.

---

## 2. Architectural Design

### A. Matryoshka Representation Learning (MRL) 256-dim Embeddings
- `gemini-embedding-2` / `text-embedding-004` natively support output dimension truncation via `"outputDimensionality": 256`.
- First 256 dimensions retain **~98% of the retrieval accuracy/variance** of the full 768 dimensions.
- **Wire Size:** 256 floats $\times$ 4 bytes = **1,024 bytes (1 KB)** per memory item, an exact **3x reduction** from 768-dim (3,072 bytes) and **~85% smaller** than JSON text.
- **Pure Dot Product in RAM:** Vectors are pre-L2-normalized at write time. Cosine similarity reduces to a pure multiply-add dot product without square roots or division:
  $$\text{sim}(u, v) = \sum_{i=1}^{256} u_i \cdot v_i$$
  In Rust AVX2 / NEON SIMD, comparing 64 memories executes in **< 5 microseconds** (0.005 ms).

### B. Protobuf Packed Binary Schema
```protobuf
message UserMemoryBundleItem {
  int64 id = 1;
  string key = 2;
  string content = 3;
  bool is_pinned = 4;
  repeated float embedding = 5; // Packed 4-byte IEEE 754 floats (256 dims)
}

message UserMemoryBundle {
  int64 owner_iid = 1;
  int64 bot_iid = 2;
  int64 updated_ts_ms = 3;
  repeated UserMemoryBundleItem items = 4;
}

message ScopeInstructionBundle {
  int64 owner_iid = 1;
  int64 updated_ts_ms = 2;
  repeated ScopeInstruction items = 3;
}
```

### C. NATS JetStream KV Caching
- **Buckets:**
  - `c35_user_memory_cache` (TTL = 1 hour)
  - `c35_scope_inst_cache` (TTL = 1 hour)
- **Keys:**
  - `mem_{owner_iid}_{bot_iid}`
  - `scope_inst_{owner_iid}`
- **Lifecycle:**
  - Write time (`memory_upsert`, `scope_instruction_put`): recompile bundle, write to DB/storage, and update NATS KV.
  - Read time (prompt turn): 1 NATS cluster read (~1 ms) $\rightarrow$ decode protobuf directly in RAM.
  - Invalidate on delete/update.

### D. Trivial Turn Shortcut (Zero Embed Latency & Zero API Cost)
- For short queries, acknowledgments, or single-word turns (*"ok"*, *"siap"*, *"terima kasih"*, *"lanjut"*):
  - Skip calling Gemini Embed API entirely.
  - Directly inject the top pinned memories from the cached bundle.
  - Shaves **50–100 ms** and eliminates API embedding token cost.

### E. In-RAM Query Embedding Cache (LRU)
- Local LRU on the node for frequent or repeated query strings (`query_text -> Vec<f32>`).
- Hits return in **< 0.001 ms**.

---

## 3. Implementation Steps

1. **Protobuf Definitions** (`_/schemas/proto/c35/chat.proto`):
   - Add `UserMemoryBundleItem` and `UserMemoryBundle`.
   - Add `ScopeInstructionBundle`.
2. **NATS KV Stores** (`servers/crates/system/nats/src/memory_kv.rs`):
   - Ensure `c35_user_memory_cache` and `c35_scope_inst_cache` buckets.
   - Provide binary `get`, `put`, `delete` operations.
3. **MRL 256-dim Dot Product Engine** (`servers/crates/mod_chat/src/memory.rs`):
   - Implement SIMD-friendly dot product over 256 dims.
   - Add trivial query bypass for pinned memories.
   - Add query embedding RAM cache.
   - Integrate NATS KV bundle lookup before DB queries.
4. **Scope Instruction Cache** (`servers/crates/mod_chat/src/scope_instruction.rs`):
   - Add NATS KV cache lookup for user & site scope instructions.
5. **Verification & Benchmarking**:
   - Run unit tests, verify latency and memory footprint.
