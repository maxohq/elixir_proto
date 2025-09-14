# Changelog

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

