# ElixirProto

A compact serialization library for Elixir that stores field indices instead of field names, enabling space-efficient binary serialization and schema evolution.

## Concept

ElixirProto combines the robustness of Erlang's term serialization with the space efficiency of index-based field storage. Instead of serializing field names repeatedly, it stores only field indices and uses schema information during deserialization.

## How It Works

### 1. Schema Definition
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user"
  
  defschema User, [:id, :name, :email, :age, :active]
end
```

This creates:
- A struct definition: `%User{id: nil, name: nil, email: nil, age: nil, active: nil}`
- A schema mapping: `[:id, :name, :email, :age, :active]` → `[1, 2, 3, 4, 5]`
- A unique schema identifier: `"myapp.ctx.user"`

### 2. Serialization Process
```elixir
user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
encoded = ElixirProto.encode(user)
```

**Step by step:**
1. `%User{id: 1, name: "Alice", ...}` → Extract struct module and fields
2. Convert to indexed format: `{"myapp.ctx.user", [{1, 1}, {2, "Alice"}, {3, "alice@example.com"}, {4, 30}, {5, true}]}`
3. Skip `nil` fields for space efficiency
4. Serialize with Erlang terms: `:erlang.term_to_binary(indexed_data)`
5. Compress: `:zlib.compress(binary_data)`

### 3. Deserialization Process
```elixir
decoded = ElixirProto.decode(encoded)
```

**Step by step:**
1. Decompress: `:zlib.uncompress(encoded)`
2. Convert to terms: `:erlang.binary_to_term(binary_data)`
3. Extract schema name: `"myapp.ctx.user"`
4. Look up schema: `[1 → :id, 2 → :name, 3 → :email, 4 → :age, 5 → :active]`
5. Reconstruct struct: `%User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}`

## API Usage

### Define Schemas
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.ctx.user"
  
  defschema User, [:id, :name, :email, :age, :active]
end

defmodule Post do
  use ElixirProto.Schema, name: "myapp.ctx.post"
  
  defschema Post, [:id, :title, :content, :author_id, :created_at]
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

## Implementation Architecture

### Core Components

1. **ElixirProto.Schema** - Macro module that:
   - Generates struct definitions
   - Creates field index mappings
   - Registers schemas in a global registry

2. **ElixirProto** - Main API module with:
   - `encode/1` - Converts structs to compressed binary
   - `decode/1` - Reconstructs structs from binary

3. **Schema Registry** - Global storage for:
   - Schema name → Module mapping
   - Module → Field index mapping
   - Field index → Field name mapping

### Data Format

**Serialized format:**
```elixir
{schema_name :: binary(), fields :: [{index :: pos_integer(), value :: term()}]}
```

**Example:**
```elixir
# Original struct
%User{id: 1, name: "Alice", email: nil, age: 30, active: true}

# Indexed format (before term_to_binary + compress)
{"myapp.ctx.user", [{1, 1}, {2, "Alice"}, {4, 30}, {5, true}]}
# Note: email (index 3) skipped because it's nil
```

## Benefits

### Space Efficiency
- Field names stored once in schema, not per record
- `nil` fields omitted from serialization
- Compression further reduces size

### Schema Evolution
```elixir
# V1 Schema
defschema User, [:id, :name, :email]

# V2 Schema - rename field but keep index
defschema User, [:id, :full_name, :email] # :name → :full_name

# V3 Schema - add new field
defschema User, [:id, :full_name, :email, :age] # New field gets index 4
```

Old serialized data remains compatible as long as indices are preserved.

### Type Safety
- Leverages Erlang's robust term serialization
- Preserves all Elixir data types (atoms, tuples, maps, etc.)
- Struct validation during deserialization

## Use Cases

- **High-volume data storage** where field names create significant overhead
- **Microservices communication** with evolving schemas
- **Caching systems** requiring compact serialization
- **Data pipelines** with schema migration requirements

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

