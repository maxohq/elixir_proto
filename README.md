[![CI](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml/badge.svg?style=flat)](https://github.com/maxohq/elixir_proto/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/elixir_proto/)
[![Total Downloads](https://img.shields.io/hexpm/dt/elixir_proto.svg?style=flat)](https://hex.pm/packages/elixir_proto)
[![Licence](https://img.shields.io/hexpm/l/elixir_proto.svg?style=flat)](https://github.com/maxohq/elixir_proto/blob/main/LICENCE)


# ElixirProto

A compact serialization library for Elixir that uses schema indices and fixed tuples for space-efficient binary serialization with schema evolution support.

Here is a short pitch: [pitch](PITCH.md)

## Concept

ElixirProto combines the robustness of Erlang's term serialization with space-efficient storage using two key optimizations:

1. **Schema Index Registry**: Maps schema names to small numeric indices (1-3 bytes vs potentially 20+ bytes for names)
2. **Fixed Tuple Format**: Stores field values in a fixed tuple structure, eliminating per-field indexing overhead

This approach provides significant space savings while maintaining full type safety and schema evolution capabilities. The library offers two schema definition approaches: the basic `Schema` for simple use cases, and the advanced `TypedSchema` for enhanced type safety and developer tooling integration.

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

# Import registry from backup
ElixirProto.SchemaRegistry.import_registry(backup)

# Get specific schema index
ElixirProto.SchemaRegistry.get_index("myapp.ctx.user")
# => 1

# Get schema name by index
ElixirProto.SchemaRegistry.get_name(1)
# => "myapp.ctx.user"
```

## TypedSchema - Enhanced Type Safety

ElixirProto provides `TypedSchema` for applications requiring enhanced type safety, explicit field control, and better developer tooling integration. TypedSchema generates identical serialization format to regular Schema while adding Dialyzer-compatible type specifications and explicit field indices.

### Basic TypedSchema Usage

```elixir
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.user", index: 1

  typedschema do
    field :id, pos_integer(), index: 1, enforce: true      # Explicitly required
    field :name, String.t(), index: 2, enforce: true       # Explicitly required
    field :email, String.t() | nil, index: 3               # Optional (default behavior)
    field :age, pos_integer(), index: 4, default: 0        # Optional with default
  end
end
```

This generates:
- A struct with optional fields by default: `%User{id: <required>, name: <required>, email: nil, age: 0}`
- Type specification: `@type t() :: %__MODULE__{id: pos_integer(), name: String.t(), email: String.t() | nil, age: pos_integer()}`
- Field index mapping for deterministic serialization order
- Full compatibility with `ElixirProto.encode/1` and `ElixirProto.decode/1`

**Note**: Following protobuf conventions, all fields are optional by default. Use `enforce: true` only when explicitly needed.

### TypedSchema Features

**Explicit Field Indices**: Fields must specify explicit indices, ensuring deterministic serialization order and safer schema evolution.

```elixir
typedschema do
  field :priority_field, String.t(), index: 1  # Always serialized first (optional)
  field :secondary_field, String.t(), index: 5  # Always serialized last (optional)
  field :middle_field, String.t(), index: 3   # Definition order doesn't matter (optional)
end
```

**Type Specifications**: Automatically generates `@type t()` for Dialyzer integration and IDE support.

```elixir
# All fields are optional by default and become nullable automatically
field :optional_field, String.t(), index: 2  # Type becomes String.t() | nil (default)

# Only explicitly enforced fields keep their original type
field :required_field, String.t(), index: 3, enforce: true  # Type stays String.t()
```

**Field Enforcement and Defaults**: Fine-grained control over optional/required fields and default values.

```elixir
# All fields optional by default (protobuf-style)
typedschema do
  field :id, pos_integer(), index: 1                    # Optional
  field :name, String.t(), index: 2                     # Optional
  field :email, String.t(), index: 3, default: "none"   # Optional with default
end

# Global enforcement (opt-in when needed)
typedschema enforce: true do
  field :id, pos_integer(), index: 1            # Enforced (global setting)
  field :name, String.t(), index: 2             # Enforced (global setting)
  field :email, String.t(), index: 3, enforce: false  # Override: not enforced
  field :created_at, DateTime.t(), index: 4, default: &DateTime.utc_now/0  # Optional with function default
end
```

**Function Defaults**: Support for function references as defaults without evaluation during struct creation.

```elixir
field :timestamp, DateTime.t(), index: 1, default: &DateTime.utc_now/0
field :uuid, String.t(), index: 2, default: &Ecto.UUID.generate/0

# Functions preserved without evaluation:
user = %User{}  # user.timestamp is still &DateTime.utc_now/0, not a DateTime
```

### TypedSchema vs Schema Comparison

| Feature | Schema | TypedSchema |
|---------|--------|-------------|
| **Definition** | `defschema [:id, :name]` | `field :id, pos_integer(), index: 1` |
| **Type Safety** | No type information | Full Dialyzer integration |
| **Field Order** | Definition order | Explicit index order |
| **IDE Support** | Basic struct completion | Rich type hints and validation |
| **Field Enforcement** | Manual `@enforce_keys` | Optional by default, `enforce: true` to require |
| **Default Behavior** | All fields nil by default | All fields optional and nullable by default |
| **Serialization** | Identical format | Identical format |
| **Performance** | Baseline | Equivalent runtime performance |

### Developer Experience Benefits

**Static Analysis**: TypedSchema integrates with Dialyzer to catch type errors during compilation.

```elixir
def process_user(%User{} = user) do
  # Dialyzer knows user.id is pos_integer(), user.email is String.t() | nil
  if user.age > 18, do: :adult, else: :minor
end
```

**IDE Integration**: Rich autocompletion and inline documentation through type specifications.

**Schema Evolution**: Explicit indices enable safer field reordering without breaking serialization compatibility.

```elixir
# Safe evolution - reorder fields by changing indices (all optional by default)
typedschema do
  field :name, String.t(), index: 1      # Was index: 2, moved up (optional)
  field :id, pos_integer(), index: 2     # Was index: 1, moved down (optional)
  field :email, String.t(), index: 3     # Unchanged (optional)
end
```

**Migration Compatibility**: TypedSchema and Schema modules are fully interoperable within the same application.

```elixir
# Mix both approaches in the same application
defmodule LegacyUser do
  use ElixirProto.Schema, name: "myapp.user.legacy", index: 1
  defschema [:id, :name]
end

defmodule ModernUser do
  use ElixirProto.TypedSchema, name: "myapp.user.modern", index: 2
  typedschema do
    field :id, pos_integer(), index: 1    # Optional by default
    field :name, String.t(), index: 2     # Optional by default
  end
end

# Both serialize to the same ElixirProto format
ElixirProto.encode(%LegacyUser{id: 1, name: "Alice"})   # Works
ElixirProto.encode(%ModernUser{id: 1, name: "Alice"})   # Works
```

## Nested Struct Serialization

ElixirProto supports automatic nested struct serialization with unlimited nesting depth. When a struct field contains another ElixirProto struct, it's automatically encoded using a special compact format.

### Basic Nested Structures

```elixir
defmodule Country do
  use ElixirProto.Schema, name: "myapp.country", index: 3
  defschema [:name, :code]
end

defmodule Address do
  use ElixirProto.Schema, name: "myapp.address", index: 4
  defschema [:street, :city, :country]  # country field will hold a Country struct
end

defmodule User do
  use ElixirProto.Schema, name: "myapp.user", index: 5
  defschema [:id, :name, :address]  # address field will hold an Address struct
end

# Create nested structure
country = %Country{name: "USA", code: "US"}
address = %Address{street: "123 Main St", city: "Portland", country: country}
user = %User{id: 1, name: "Alice", address: address}

# Serialize and deserialize - nesting handled automatically
encoded = ElixirProto.encode(user)
decoded = ElixirProto.decode(encoded)

# Access nested data
decoded.address.country.name  # => "USA"
```

### Multi-Level Nesting

ElixirProto supports unlimited nesting depth:

```elixir
defmodule Company do
  use ElixirProto.Schema, name: "myapp.company", index: 6
  defschema [:name, :address, :ceo]  # ceo field holds a User struct
end

# Three levels deep: Company -> User -> Address -> Country
company = %Company{name: "ACME Corp", address: address, ceo: user}

encoded = ElixirProto.encode(company)
decoded = ElixirProto.decode(encoded)

# Access deeply nested data
decoded.ceo.address.country.code  # => "US"
```

### Nested Encoding Format

Nested ElixirProto structs use the internal format `{:ep, schema_index, values_tuple}`:

```elixir
# When encoding this nested structure:
%User{id: 1, name: "Alice", address: %Address{street: "123 Main St", city: "Portland", country: nil}}

# The internal format becomes:
{5, {1, "Alice", {:ep, 4, {"123 Main St", "Portland", nil}}}}
#    ^user index    ^address as {:ep, address_index, address_values}
```

### Mixed Data Types

ElixirProto gracefully handles mixed scenarios:

```elixir
defmodule RegularStruct do
  defstruct [:field1, :field2]  # Regular Elixir struct (not ElixirProto)
end

defmodule MixedUser do
  use ElixirProto.Schema, name: "myapp.mixed_user", index: 7
  defschema [:id, :name, :regular_data, :proto_address]
end

# Mix regular structs and ElixirProto structs
mixed = %MixedUser{
  id: 1,
  name: "Bob",
  regular_data: %RegularStruct{field1: "value1", field2: "value2"},  # Preserved as-is
  proto_address: address  # ElixirProto struct, gets nested encoding
}

encoded = ElixirProto.encode(mixed)
decoded = ElixirProto.decode(encoded)

# Regular struct preserved unchanged
decoded.regular_data.__struct__  # => RegularStruct

# ElixirProto struct properly nested
decoded.proto_address.__struct__  # => Address
```

### Key Features

- **Automatic Detection**: ElixirProto automatically detects nested ElixirProto structs
- **Unlimited Depth**: Supports arbitrarily deep nesting
- **Mixed Compatibility**: Works alongside regular Elixir structs
- **Space Efficiency**: Nested structs use compact schema indices instead of full module names
- **Error Resilience**: Gracefully handles edge cases like literal `{:ep, index, tuple}` data

## Implementation Architecture

### Core Components

1. **ElixirProto.Schema** - Macro module that:
   - Generates struct definitions with `defschema`
   - Creates field position mappings
   - Handles explicit schema index registration with conflict detection

2. **ElixirProto.SchemaRegistry** - Index management system:
   - Maps schema names to numeric indices
   - Provides persistent storage using `:persistent_term`
   - Supports explicit index assignment with conflict detection
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

The explicit index system enables controlled schema evolution. TypedSchema provides enhanced safety through explicit field indices, while basic Schema uses positional field ordering.

### Basic Schema Evolution

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

### TypedSchema Evolution (Recommended)

TypedSchema's explicit field indices provide safer evolution with more flexibility:

```elixir
# V1 TypedSchema (protobuf-style: all optional by default)
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.ctx.user", index: 1

  typedschema do
    field :id, pos_integer(), index: 1      # Optional
    field :name, String.t(), index: 2       # Optional
    field :email, String.t(), index: 3      # Optional
  end
end

# V2 - Safe field reordering and addition
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.ctx.user", index: 1

  typedschema do
    field :id, pos_integer(), index: 1                   # Optional
    field :full_name, String.t(), index: 2               # Renamed, optional
    field :age, pos_integer(), index: 4                  # New field, optional
    field :email, String.t(), index: 3                   # Reordered in definition, optional
  end
end

# V3 - Advanced evolution with defaults and selective enforcement
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.ctx.user", index: 1

  typedschema do
    field :id, pos_integer(), index: 1, enforce: true    # Explicitly required
    field :full_name, String.t(), index: 2               # Optional
    field :email, String.t(), index: 3, default: "no-email@example.com"  # Optional with default
    field :age, pos_integer(), index: 4, default: 0      # Optional with default
    field :status, atom(), index: 5, default: :active    # Optional with default
  end
end
```

**Compatibility Rules:**
- Schema index must remain constant for backward compatibility
- **Basic Schema**: New fields must be appended to maintain position mapping
- **TypedSchema**: Fields can be added at any explicit index, enabling flexible evolution
- Field renames are safe as only indices matter for serialization
- Field removal requires careful consideration of data migration
- **TypedSchema** provides compile-time validation of index conflicts

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

**TypedSchema recommended when:**
- Type safety and Dialyzer integration are priorities
- Team uses IDEs with advanced Elixir tooling
- Schema evolution flexibility is required
- Explicit field ordering control is needed
- Application has complex domain models with many fields

**Consider alternatives when:**
- Serializing mixed data types without consistent structure
- One-off serialization tasks where setup overhead isn't justified
- Very small structs (1-2 short fields) where overhead dominates
- Applications prioritizing encoding speed over payload size
- Simple prototypes where basic Schema suffices

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

