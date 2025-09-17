# ElixirProto

[![CI](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml/badge.svg?style=flat)](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/elixir_proto/)

A compact serialization library for Elixir using context-scoped schema registries with centralized index mapping. Eliminates global index collisions while maintaining wire format compatibility and enabling domain-driven schema organization.

Here is a short pitch: [PITCH](PITCH.md)


## Quick Start

### 1. Define Your Schemas (No Global Indices!)
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.user"
  defschema [:id, :name, :email, :age]
end

defmodule Product do
  use ElixirProto.Schema, name: "myapp.product"  
  defschema [:id, :sku, :price, :category]
end
```

### 2. Create a PayloadConverter for Your Context
```elixir
defmodule MyApp.UserManagement.PayloadConverter do
  use ElixirProto.PayloadConverter,
    mapping: [
      {1, "myapp.user"},
      {2, "myapp.user.profile"},
      {3, "myapp.user.session"}
    ]
end

defmodule MyApp.Inventory.PayloadConverter do
  use ElixirProto.PayloadConverter,
    mapping: [
      {1, "myapp.product"},        # Same index, different context!
      {2, "myapp.product.variant"},
      {3, "myapp.inventory.stock"}
    ]
end
```

### 3. Encode/Decode with Context Isolation
```elixir
user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30}
product = %Product{id: 1, sku: "ABC123", price: 29.99, category: "electronics"}

# Each context manages its own indices independently
user_data = MyApp.UserManagement.PayloadConverter.encode(user)
product_data = MyApp.Inventory.PayloadConverter.encode(product)

# Decode with the correct context
decoded_user = MyApp.UserManagement.PayloadConverter.decode(user_data)
decoded_product = MyApp.Inventory.PayloadConverter.decode(product_data)
```

### Enhanced TypedSchema Support
```elixir
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.user"
  
  typedschema do
    field :id, pos_integer(), index: 1, enforce: true
    field :name, String.t(), index: 2
    field :email, String.t() | nil, index: 3
    field :age, pos_integer(), index: 4, default: 0
  end
end
```

## How It Works
- **Context-Scoped Registries**: Each PayloadConverter manages its own index namespace
- **Centralized Index Mapping**: All indices for a context visible in single location
- **Index Collision Elimination**: Same indices can be safely used across different contexts
- **Wire Format Preservation**: Context information is compile-time only, not stored in binary
- **Fixed Tuples**: Eliminates per-field overhead (1-3 bytes vs 20+ bytes for module names)
- **Space Savings**: 34-56% smaller than standard serialization

## Key Features
- **🎯 Context Isolation**: No more global index collisions between teams/domains
- **📋 Centralized Management**: All context indices managed in single PayloadConverter mapping
- **🔄 Wire Compatibility**: Maintains `{schema_index, payload_tuple}` format
- **🏗️ Domain Organization**: Organize schemas by business context following DDD principles
- **Two Schema Approaches**: Simple Schema or TypedSchema with compile-time type safety
- **🔗 Nested Structs**: Automatic deep serialization with context awareness
- **📈 Schema Evolution**: Safe field additions and renaming within contexts
- **🗜️ Built-in Compression**: Automatic zlib compression for optimal storage

## Performance
| Struct Type | Standard | ElixirProto | Savings |
|-------------|----------|-------------|---------|
| User (5 fields) | 79 bytes | 52 bytes | 34.2% |
| Complex (50 fields) | 229 bytes | 101 bytes | 55.9% |

## Schema Evolution

### Context-Safe Operations
```elixir
# ✅ Safe operations within a PayloadConverter context:
- Add new schemas with new indices to mapping
- Add new fields to existing schemas (with new field indices)  
- Rename fields (keep same field index)
- Reorder field definitions in schemas
- Remove unused schemas from mapping (if no legacy data)

# ❌ Never change within a context:
- Existing schema indices in PayloadConverter mapping
- Existing field indices within schemas
- Schema names once in production

# ✅ Context isolation allows:
- Same schema indices across different PayloadConverters
- Independent evolution of different domain contexts
- Team autonomy without coordination overhead
```

### Example: Safe Schema Evolution
```elixir
# Before: Initial PayloadConverter
defmodule MyApp.Users.PayloadConverter do
  use ElixirProto.PayloadConverter,
    mapping: [
      {1, "myapp.user"},
      {2, "myapp.user.profile"}
    ]
end

# After: Adding new schemas safely
defmodule MyApp.Users.PayloadConverter do
  use ElixirProto.PayloadConverter,
    mapping: [
      {1, "myapp.user"},           # ✅ Keep existing
      {2, "myapp.user.profile"},   # ✅ Keep existing  
      {3, "myapp.user.session"},   # ✅ Add new schema
      {4, "myapp.user.preferences"} # ✅ Add new schema
    ]
end
```

## Benchmark Results
- [BENCHMARK_RESULTS](BENCHMARK_RESULTS.md)
- [benchmark_output_latest.txt](benchmark_output_latest.txt)

## Installation
```elixir
def deps do
  [{:elixir_proto, "~> 0.1.0"}]
end
```