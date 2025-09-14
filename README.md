[![CI](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml/badge.svg?style=flat)](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/elixir_proto/)
[![Total Downloads](https://img.shields.io/hexpm/dt/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Licence](https://img.shields.io/hexpm/l/elixir_proto.svg?style=flat)](https://github.com/maxohq/elixir_proto/blob/main/LICENCE)


# ElixirProto

A compact serialization library for Elixir that uses schema indices and fixed tuples for space-efficient binary serialization with schema evolution support.

## Concept

ElixirProto combines the robustness of Erlang's term serialization with space-efficient storage using two key optimizations:

1. **Schema Index Registry**: Maps schema names to small numeric indices (1-3 bytes vs potentially 20+ bytes for names)
2. **Fixed Tuple Format**: Stores field values in a fixed tuple structure, eliminating per-field indexing overhead

This approach provides significant space savings while maintaining full type safety and schema evolution capabilities.

## How It Works

### 1. Schema Definition
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user", index: 1

  defschema [:id, :name, :email, :age, :active]
end
```

This creates:
- A struct definition: `%User{id: nil, name: nil, email: nil, age: nil, active: nil}`
- A field mapping: `[:id, :name, :email, :age, :active]` → positions `[1, 2, 3, 4, 5]` in tuple
- A schema index registration: `"myapp.ctx.user"` → `1`
- Conflict detection: raises error if index `1` is already assigned to another schema

### 2. Serialization Process
```elixir
user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
encoded = ElixirProto.encode(user)
```

**Step by step:**
1. `%User{id: 1, name: "Alice", ...}` → Extract struct module and fields
2. Look up schema index: `"myapp.ctx.user"` → `1`
3. Convert to fixed tuple format: `{1, {1, "Alice", "alice@example.com", 30, true}}`
4. Serialize with Erlang terms: `:erlang.term_to_binary(data)`
5. Compress: `:zlib.compress(binary_data)`

### 3. Deserialization Process
```elixir
decoded = ElixirProto.decode(encoded)
```

**Step by step:**
1. Decompress: `:zlib.uncompress(encoded)`
2. Convert to terms: `:erlang.binary_to_term(binary_data)`
3. Extract schema index: `1` → look up schema name `"myapp.ctx.user"`
4. Convert tuple back to field map: `{1, "Alice", "alice@example.com", 30, true}` → field positions
5. Reconstruct struct: `%User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}`

## API Usage

### Define Schemas
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user", index: 1

  defschema [:id, :name, :email, :age, :active]
end

defmodule Post do
  use ElixirProto.Schema, name: "myapp.ctx.post", index: 2

  defschema [:id, :title, :content, :author_id, :created_at]
end
```

### Serialize and Deserialize
```elixir
user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}

# Serialize
encoded = ElixirProto.encode(user)
IO.inspect(encoded, label: "Encoded binary")
IO.inspect(byte_size(encoded), label: "Size in bytes")

# Deserialize
decoded = ElixirProto.decode(encoded)
IO.inspect(decoded, label: "Decoded struct")
```

### Schema Registry Management

```elixir
# Check current registry state
ElixirProto.SchemaRegistry.list_schemas()
# => %{"myapp.ctx.user" => 1, "myapp.ctx.post" => 2}

# Get registry statistics
ElixirProto.SchemaRegistry.stats()
# => %{total_schemas: 2, next_available_id: 3, schemas: %{...}}

# Export registry for backup
backup = ElixirProto.SchemaRegistry.export_registry()

# Initialize registry with predefined mappings
ElixirProto.SchemaRegistry.initialize_with_mappings(%{
  "stable.user" => 1,
  "stable.post" => 2
})
```

## Implementation Architecture

### Core Components

1. **ElixirProto.Schema** - Macro module that:
   - Generates struct definitions with `defschema`
   - Creates field position mappings
   - Handles explicit schema index registration with conflict detection

2. **ElixirProto.SchemaRegistry** - Index management system:
   - Maps schema names to numeric indices
   - Provides persistent storage using `:persistent_term`
   - Supports explicit index assignment and auto-increment
   - Enables registry export/import for backup and migration

3. **ElixirProto** - Main API module with:
   - `encode/1` - Converts structs to ultra-compact binary format
   - `decode/1` - Reconstructs structs from binary data

### Data Format

**Ultra-compact serialized format:**
```elixir
{schema_index :: pos_integer(), values :: tuple()}
```

**Examples:**
```elixir
# Original struct
%User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}

# Ultra-compact format (before term_to_binary + compress)
{1, {1, "Alice", "alice@example.com", 30, true}}

# Sparse data example
%User{id: 1, name: "Alice", email: nil, age: nil, active: nil}

# Still uses fixed tuple (nil for missing values)
{1, {1, "Alice", nil, nil, nil}}
```

### Schema Registry Storage

The schema registry uses `:persistent_term` for fast, persistent storage:

```elixir
# Registry maps schema names to indices
%{
  "myapp.ctx.user" => 1,
  "myapp.ctx.post" => 2,
  "myapp.ctx.comment" => 3
}
```

## Performance and Size Comparison

Benchmark results comparing ElixirProto against plain Elixir term serialization (both using zlib compression):

### Space Efficiency

| Data Type | Plain Elixir | ElixirProto | Savings |
|-----------|--------------|-------------|---------|
| Full User (5 fields) | 79 bytes | 52 bytes | 27 bytes (34.2%) |
| Sparse User (2 fields) | 35 bytes | 33 bytes | 2 bytes (5.7%) |
| Complex Struct (50 fields, 10 populated) | 229 bytes | 101 bytes | 128 bytes (55.9%) |

### Key Advantages

**Schema Index Optimization**: Schema names like `"myapp.ctx.user"` (14+ bytes) are replaced with small indices (1-3 bytes), providing immediate savings.

**Fixed Tuple Format**: Eliminates per-field indexing overhead by storing values in fixed positions, reducing serialization complexity.

**Compression Benefits**: The structured format compresses more efficiently than variable map structures.

### Performance Characteristics

- **Encoding**: Comparable to plain serialization for dense data, faster for sparse data due to simplified structure
- **Decoding**: Faster than plain serialization due to fixed field positions
- **Memory Usage**: Higher during encoding due to schema lookups, comparable during decoding

## Schema Evolution

The explicit index system enables controlled schema evolution:

```elixir
# V1 Schema
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user", index: 1
  defschema [:id, :name, :email]
end

# V2 Schema - field rename (safe)
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user", index: 1
  defschema [:id, :full_name, :email] # :name → :full_name
end

# V3 Schema - field addition (safe)
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user", index: 1
  defschema [:id, :full_name, :email, :age] # New field appended
end
```

**Compatibility Rules:**
- Schema index must remain constant for backward compatibility
- New fields should be appended (not inserted) to maintain position mapping
- Field renames are safe as only positions matter
- Field removal requires careful consideration of data migration

### Type Safety
- Leverages Erlang's robust term serialization
- Preserves all Elixir data types (atoms, tuples, maps, etc.)
- Struct validation during deserialization

## Use Cases

ElixirProto is particularly effective for:

- **Structured data with consistent schemas** where space efficiency matters
- **High-volume serialization** where schema name overhead is significant
- **Microservices communication** requiring compact payloads and schema evolution
- **Caching systems** where serialization size impacts memory usage
- **Data export/import** with long-term compatibility requirements
- **Network protocols** where bandwidth optimization is critical

### When to Use ElixirProto

**Ideal scenarios:**
- Structs with 3+ fields where space efficiency is important
- Long schema names (domain.context.entity patterns)
- Applications requiring schema evolution without breaking changes
- Systems serializing many instances of the same struct types

**Consider alternatives when:**
- Serializing mixed data types without consistent structure
- One-off serialization tasks where setup overhead isn't justified
- Very small structs (1-2 short fields) where overhead dominates
- Applications prioritizing encoding speed over payload size

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_proto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_proto, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/elixir_proto>.

