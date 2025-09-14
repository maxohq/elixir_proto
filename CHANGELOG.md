# Changelog

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

