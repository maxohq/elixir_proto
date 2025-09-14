# ElixirProto

[![CI](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml/badge.svg?style=flat)](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/elixir_proto/)

A compact serialization library for Elixir using schema indices and fixed tuples for space-efficient binary storage with schema evolution. Inspired by Protobuf, but in pure Elixir.
Here is a short pitch: [PITCH](PITCH.md)


## Quick Start

### Basic Schema
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.user", index: 1
  defschema [:id, :name, :email, :age]
end

user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30}
encoded = ElixirProto.encode(user)  # Compact binary
decoded = ElixirProto.decode(encoded)  # Back to struct
```

### TypedSchema (Enhanced)
```elixir
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.user", index: 1
  
  typedschema do
    field :id, pos_integer(), index: 1, enforce: true
    field :name, String.t(), index: 2
    field :email, String.t() | nil, index: 3
    field :age, pos_integer(), index: 4, default: 0
  end
end
```

## How It Works
- **Schema Registry**: Maps names to numeric indices (1-3 bytes vs 20+ bytes)
- **Fixed Tuples**: Eliminates per-field overhead
- **Space Savings**: 34-56% smaller than standard serialization

## Key Features
- **Two Approaches**: Simple Schema or TypedSchema with type safety
- **Nested Structs**: Automatic deep serialization
- **Schema Evolution**: Safe field additions and renaming
- **Compression**: Built-in zlib compression

## Performance
| Struct Type | Standard | ElixirProto | Savings |
|-------------|----------|-------------|---------|
| User (5 fields) | 79 bytes | 52 bytes | 34.2% |
| Complex (50 fields) | 229 bytes | 101 bytes | 55.9% |

## Schema Evolution
```elixir
# Safe operations:
- Add new fields with new indices
- Rename fields (keep same index)  
- Reorder field definitions

# Never change:
- Existing field indices
- Schema indices
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