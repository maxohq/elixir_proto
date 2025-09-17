# ADR: Context-Scoped Schema Registries with PayloadConverters

## Status
Proposed

## Context

### Problem
ElixirProto's current architecture uses an implicit app-global registry without explicit opt-in into a context. This prevents meaningful co-existence of different payload converters.

The current approach forces all schemas into a single global namespace where index collisions become inevitable as the codebase grows. There's no way to have multiple independent payload conversion systems within the same application.

### Analysis of Protobuf Comparison
Protobuf solves similar problems by NOT storing message type names in wire format (only field numbers) and using external .proto files for schema definitions with namespace isolation through packages.

ElixirProto's approach of embedding schema indices in wire format provides self-describing data, which is valuable for dynamic systems.

## Decision

Implement context-scoped schema registries with centralized index mapping in PayloadConverter modules:

### Centralized Index Mapping Per Context
```elixir
defmodule Myapp.Inventory.PayloadConverter do
  @mapping [
    {1, "myapp.user"},
    {2, "myapp.product"},
    {3, "myapp.order"},
    {4, "myapp.invoice"},
    {5, "myapp.payment"}
  ]
  
  use ElixirProto.PayloadConverter, ctx: "myapp.inventory", mapping: @mapping
end
```

### Simplified Schema Definition
```elixir
defmodule User do
  use ElixirProto.Schema, name: "myapp.user"
  defschema [:id, :name, :email, :age]
end

defmodule Product do  
  use ElixirProto.Schema, name: "myapp.product"
  defschema [:id, :title, :price]
end
```

### Wire Format Remains Simple
```elixir
# Wire format: {schema_index, payload}
# Context information is NOT encoded - purely compile-time organization
```

## Consequences

### Benefits
1. Index Collision Isolation: Different contexts can safely use the same indices without conflicts
2. Centralized Index Management: All indices for a context visible in single location
3. Single Source of Truth: PayloadConverter mapping serves as definitive index registry
4. Easy Auditing: Can immediately see which indices are taken/available
5. Gap Detection: Easy to spot missing indices in sequence
6. Conflict Prevention: Compile-time detection of duplicate indices in mapping
7. Simplified Schema Definition: Schemas only declare names, not indices
8. Domain Boundaries: Clear organizational structure following domain-driven design principles

### Drawbacks
1. Multiple Converters: Applications using multiple contexts need to know which converter to use
2. Context Management: Need to establish conventions for context naming and ownership
3. Cross-Context Communication: Sharing data between contexts requires explicit converter selection

## Implementation Notes

- Context is purely compile-time metadata, not stored in wire format
- Each PayloadConverter contains centralized index→schema_name mapping for its context
- Index validation occurs at compile time within each context scope
- Schema definitions no longer contain index information
- Wire format remains backward compatible with current implementation

## Alternatives Considered

1. Global Index Registry with Collision Detection: Would solve collision detection but not organizational scalability
2. Distributed Index Management: Scattering indices across individual schema definitions makes auditing difficult
3. Hash-Based Indices: Risk of runtime collisions and non-deterministic behavior
4. Full Context in Wire Format: Would bloat serialized data size significantly
5. Protobuf-style External Schema: Would require complete architectural rewrite

The chosen solution provides the best balance of safety, organization, and wire format efficiency.