# Changelog

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

