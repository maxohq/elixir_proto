# ElixirProto TypedSchema Specification

## Overview

This document specifies the design and implementation of `ElixirProto.TypedSchema`, a TypedStruct-inspired macro system that adds explicit field indices and type safety to ElixirProto schemas.

## Motivation

The current `ElixirProto.Schema` provides compact serialization but lacks:
- Compile-time type checking (Dialyzer integration)
- Explicit field ordering control
- Rich development tooling support

TypedSchema addresses these limitations while maintaining full compatibility with ElixirProto's serialization format.

## Design Goals

1. **Type Safety**: Full Dialyzer integration with proper type specifications
2. **Explicit Indices**: Mandatory field indices for deterministic serialization order
3. **Schema Evolution**: Safe field addition/removal with index-based compatibility
4. **Development Experience**: Rich IDE support, clear error messages, documentation
5. **Backward Compatibility**: Full interoperability with existing ElixirProto schemas

## API Design

### Basic Usage

```elixir
defmodule User do
  use ElixirProto.TypedSchema, name: "myapp.user", index: 42

  typedschema do
    field :id, pos_integer(), index: 1, enforce: true
    field :name, String.t(), index: 2, enforce: true
    field :email, String.t() | nil, index: 3, default: nil
    field :age, non_neg_integer() | nil, index: 4
    field :active, boolean(), index: 5, default: true
  end
end
```

**Generated Output:**
```elixir
defmodule User do
  @enforce_keys [:id, :name]
  defstruct id: nil, name: nil, email: nil, age: nil, active: true

  # Clean, transparent typespec for Dialyzer
  @type t() :: %__MODULE__{
    id: pos_integer(),
    name: String.t(),
    email: String.t() | nil,
    age: non_neg_integer() | nil,
    active: boolean()
  }

  # Schema registry integration
  def __schema__(:name), do: "myapp.user"
  def __schema__(:index), do: 42
  def __schema__(:fields), do: [:id, :name, :email, :age, :active]
  def __schema__(:field_indices), do: %{id: 1, name: 2, email: 3, age: 4, active: 5}
  def __schema__(:index_fields), do: %{1 => :id, 2 => :name, 3 => :email, 4 => :age, 5 => :active}
end
```

### Advanced Features

```elixir
defmodule Product do
  use ElixirProto.TypedSchema,
    name: "myapp.product",
    index: 43

  typedschema enforce: true do  # All fields enforced by default
    field :sku, String.t(), index: 1
    field :name, String.t(), index: 2
    field :price, Decimal.t(), index: 3
    field :description, String.t() | nil, index: 4, enforce: false
    field :created_at, DateTime.t(), index: 5, default: &DateTime.utc_now/0
  end
end
```

## Implementation Architecture

### Module Structure

```
lib/elixir_proto/
├── typed_schema.ex          # Main macro module (~200-300 lines)
└── typed_schema/
    ├── field.ex             # Field definition struct
    └── generator.ex         # Code generation helpers
```

### Core Components

#### 1. ElixirProto.TypedSchema (Main Module)

**Primary Responsibilities:**
- Export `typedschema/1` macro
- Coordinate field parsing and validation
- Generate final struct and type definitions
- Integrate with schema registry

**Module Attributes:**
```elixir
@ts_fields          # Accumulator for field definitions
@ts_field_indices   # Accumulator for index mappings
@ts_types          # Accumulator for type specs
@ts_enforce_keys   # Accumulator for enforced fields
@ts_schema_name    # Schema name from use options
@ts_schema_index   # Schema index from use options
@ts_options        # Global options (validate, visibility, etc.)
```

#### 2. ElixirProto.TypedSchema.Field

**Field Definition Struct:**
```elixir
defstruct [
  :name,           # Field name (atom)
  :type,           # Type specification
  :index,          # Field index (pos_integer)
  :default,        # Default value
  :enforce,        # Enforcement flag
  :validator,      # Runtime validator function
  :opts            # Additional options
]
```

#### 3. ElixirProto.TypedSchema.Generator

**Code Generation Helpers:**
```elixir
@spec generate_struct_def(fields :: [Field.t()]) :: Macro.t()
@spec generate_type_spec(fields :: [Field.t()]) :: Macro.t()
@spec generate_schema_functions(name :: String.t(), index :: pos_integer(), fields :: [Field.t()]) :: Macro.t()
```

## Implementation Phases

### Phase 1: Core Implementation (2-3 days)
- Basic `typedschema` macro structure
- Field parsing and storage in module attributes
- Index validation and conflict detection
- Struct and typespec generation
- Schema registry integration

**Key Features:**
- Parse `field/3` macro calls with indices
- Validate unique field indices
- Generate `defstruct` with proper defaults and enforcement
- Generate `@type t()` with nullable types for optional fields
- Create `__schema__/1` functions for ElixirProto compatibility

### Phase 2: Advanced Options (1-2 days)
- Default value processing (including functions)
- Enforcement by default option
- Error handling and messages

**Key Features:**
- Support for function-based defaults like `&DateTime.utc_now/0`
- Global enforcement with per-field override
- Clear, actionable error messages

**Total Implementation Time: 3-5 days** (vs original 8-12 days)

## Technical Challenges & Solutions

### 1. Index Management

**Challenge**: Ensuring field indices are unique and properly ordered during serialization.

**Solution**:
- Validate index uniqueness during compilation
- Sort fields by index during struct generation
- Provide clear error messages for conflicts

```elixir
defp validate_field_indices(fields) do
  indices = Enum.map(fields, & &1.index)
  duplicates = indices -- Enum.uniq(indices)

  if duplicates != [] do
    raise ArgumentError, "Duplicate field indices: #{inspect(duplicates)}"
  end
end
```

### 2. Type Nullability

**Challenge**: Determining when to make types nullable based on defaults and enforcement.

**Solution**:
- Non-enforced fields without defaults become nullable
- Fields with defaults (including nil) are not nullable in type spec
- Enforced fields are never nullable

```elixir
defp make_nullable_type(type, field) do
  if field.enforce || field.default != :__no_default__ do
    type
  else
    quote(do: unquote(type) | nil)
  end
end
```

### 3. Schema Evolution

**Challenge**: Maintaining compatibility when fields are added/removed.

**Solution**:
- Field indices must never change for existing fields
- New fields should use higher indices than existing ones
- Provide tooling to detect breaking changes

```elixir
# Safe evolution
defmodule User do
  use ElixirProto.TypedSchema, name: "user", index: 1

  typedschema do
    field :id, pos_integer(), index: 1, enforce: true    # Unchanged
    field :name, String.t(), index: 2, enforce: true     # Unchanged
    field :email, String.t() | nil, index: 3             # Unchanged
    field :created_at, DateTime.t(), index: 4            # New field - safe
  end
end
```


## Migration Strategy

### From ElixirProto.Schema to TypedSchema

**Current Schema:**
```elixir
defmodule User do
  use ElixirProto.Schema, name: "user", index: 1
  defschema [:id, :name, :email, :age, :active]
end
```

**Migrated TypedSchema:**
```elixir
defmodule User do
  use ElixirProto.TypedSchema, name: "user", index: 1

  typedschema do
    field :id, term(), index: 1
    field :name, term(), index: 2
    field :email, term(), index: 3
    field :age, term(), index: 4
    field :active, term(), index: 5
  end
end
```

**Migration Tools:**
- Automated conversion script
- Compatibility checker
- Performance comparison utilities

## Performance Considerations

### Compilation Time
- **Impact**: TypedSchema adds ~5-10% compilation overhead vs Schema
- **Mitigation**: Efficient macro expansion, minimal runtime overhead

### Runtime Performance
- **Serialization**: Identical performance (same underlying format)
- **Deserialization**: Identical performance
- **No validation overhead**: Types are compile-time only

### Memory Usage
- **Schema Definition**: ~1.5x memory during compilation (type metadata)
- **Runtime**: Identical (same struct format, no validation code)

## Testing Strategy

### Unit Tests
- Field parsing and validation
- Type generation correctness
- Error message clarity
- Schema registry integration

### Integration Tests
- Serialization compatibility with existing schemas
- Round-trip encoding/decoding
- Migration scenarios
- Dialyzer integration testing

### Performance Tests
- Compilation time benchmarks
- Runtime performance comparisons (should be identical)
- Memory usage profiling

## Documentation Plan

### API Documentation
- Comprehensive module docs with examples
- Function-level documentation
- Type specifications for all public functions

### Guides
- Getting started guide
- Migration from Schema to TypedSchema
- Advanced features and customization
- Performance tuning

### Examples
- Common patterns and use cases
- Schema evolution examples
- Integration with existing codebases

## Future Enhancements

### Plugin System
Following TypedStruct's plugin architecture for extensibility:
- Documentation generators
- Custom serialization formats
- Schema evolution helpers

### Development Tooling
- Schema linting
- Migration assistance
- Documentation generation
- Dialyzer integration helpers

## Conclusion

ElixirProto.TypedSchema represents a significant enhancement to ElixirProto, bringing type safety and developer experience improvements while maintaining the compact serialization format. The phased implementation approach ensures a stable foundation with incremental feature additions.

The design balances compile-time safety, runtime performance, and developer ergonomics, making it suitable for production use in type-conscious applications while preserving ElixirProto's core strengths.