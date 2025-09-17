# Changelog

## [0.2.0] - 2025-01-18

### Breaking Changes
- Replaced global schema index management with context-scoped PayloadConverter approach
- Removed index parameters from Schema and TypedSchema (schemas now use name only)
- Eliminated ElixirProto.encode/decode global functions
- Deleted SchemaNameRegistry module (global index management removed)

### Added
- PayloadConverter modules with context-scoped schema registries
- Centralized index mapping in single location per context
- Context isolation preventing index collisions between domains
- Cross-context compatibility testing and examples

### Changed
- Schema definitions simplified to name-only approach
- Wire format preserved for backward compatibility
- All tests migrated to PayloadConverter approach
- Updated benchmarks and documentation

## [0.1.6] - 2025-09-14

### Added
- support for lists


## [0.1.5] - 2025-09-14

### Changed
- **Schema Registry Refactoring**: Renamed `Schema.Registry` module to `SchemaRegistry` for better consistency
- **Schema Name Registry**: Renamed `ElixirProto.SchemaRegistry` to `ElixirProto.SchemaNameRegistry` for clearer naming
- **Test Organization**: Extracted and reorganized test files for better maintainability
- **Documentation Improvements**: Enhanced documentation files and simplified README structure

### Internal
- Updated benchmarks and examples to use new module names
- Improved code organization and test structure
- Better module naming consistency across the codebase

## [0.1.4] - 2025-09-14

### Added
- **TypedSchema - Enhanced Type Safety**: New `ElixirProto.TypedSchema` module providing TypedStruct-inspired macro system with explicit field indices
- **Dialyzer Integration**: Automatic `@type t()` generation for full static analysis support and IDE integration
- **Explicit Field Indices**: Mandatory field indices for deterministic serialization order and safer schema evolution
- **Advanced Field Control**: Fine-grained field enforcement, defaults, and nullability handling
- **Function Defaults**: Support for function references as defaults (e.g., `&DateTime.utc_now/0`) without evaluation during struct creation
- **Global Enforcement Options**: Optional `enforce: true` at schema level with per-field overrides
- **Comprehensive Integration Tests**: 16 integration tests validating ElixirProto serialization compatibility
- **Schema Evolution Safety**: Safe field management through explicit indices - field names can change, code can be reordered, but indices must remain stable
- **Developer Experience**: Rich IDE autocompletion, type hints, and compile-time validation

### Features
- **Two Schema Approaches**: Basic `Schema` for simple use cases, advanced `TypedSchema` for enhanced type safety
- **Full Backward Compatibility**: TypedSchema generates identical serialization format to regular Schema
- **Protobuf-Style Conventions**: All fields optional by default, enforcement opt-in only (aligns with protobuf standards)
- **Mixed Schema Support**: TypedSchema and Schema modules fully interoperable within same application
- **Zero Runtime Overhead**: Type specifications are compile-time only, no performance impact

### Documentation
- **Comprehensive README Updates**: Added TypedSchema section with usage examples, comparison table, and migration guide
- **Clear Field Behavior**: Documentation emphasizes optional-by-default field behavior following protobuf conventions
- **Developer Experience Benefits**: Detailed explanation of static analysis, IDE integration, and schema evolution advantages

## [0.1.3] - 2025-09-14

### Added
- **Nested struct serialization support** with unlimited nesting depth
- Automatic detection and encoding of nested ElixirProto structs using `{:ep, schema_index, values_tuple}` format
- Recursive encoding/decoding with `encode_field_value/1` and `decode_field_value/1` helper functions
- Graceful handling of mixed data types (ElixirProto structs alongside regular Elixir structs)
- Comprehensive test suite with 11 test cases covering 2-level nesting, 3-level nesting, edge cases, and performance validation
- Error resilience for edge cases including literal `{:ep, index, tuple}` data that looks like nested format

### Changed
- Enhanced `ElixirProto.encode/1` to recursively detect and encode nested ElixirProto structs
- Enhanced `ElixirProto.decode/1` to recursively reconstruct nested struct hierarchies
- Test modules moved into test module scope to avoid global namespace pollution

## [0.1.2] - 2025-09-14

### Breaking Changes
- Removed `SchemaRegistry.get_or_create_index/1` function - all schema indices must be explicitly assigned
- Removed `SchemaRegistry.initialize_with_mappings/1` function - schemas auto-register during compilation
- Schema registration now strictly requires explicit index parameter - automatic index assignment removed
- `ElixirProto.encode/1` now uses read-only `get_index/1` instead of `get_or_create_index/1`

### Changed
- Schema compilation now throws clear error for missing index parameter
- Improved error messages for missing schema indices during encoding

## [0.1.1] - 2025-09-14

### Fixed
- Corrected comment and implementation to require explicit index parameter (was incorrectly marked as optional)

## [0.1.0] - 2025-09-14

- **Ultra-compact serialization format** using schema indices and fixed tuples
- **Schema Index Registry** for mapping schema names to numeric indices
- **Explicit schema index assignment** with conflict detection
- **Fixed tuple format** for consistent field positioning and optimal compression
- **Persistent schema registry** using `:persistent_term` for fast, persistent storage
- **Schema evolution support** with backward compatibility guarantees
- **Comprehensive benchmark suite** comparing against plain Elixir serialization
- **Registry management functions** for backup, export, and import operations

