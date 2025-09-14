# ElixirProto Benchmark Results

## Performance Results

### Encoding Performance (operations per second)
- **Sparse user**: ElixirProto 237K ops/s vs Plain 177K ops/s (34% faster)
- **Product**: ElixirProto 122K ops/s vs Plain 117K ops/s (4% faster)
- **Large sparse struct**: ElixirProto 116K ops/s vs Plain 91K ops/s (28% faster)
- **Single user (full)**: ElixirProto 102K ops/s vs Plain 102K ops/s (equivalent)
- **Large full struct**: ElixirProto 84K ops/s vs Plain 72K ops/s (16% faster)

### Memory Usage Per Operation
- **Plain serialization**: ~0.26 KB per operation
- **ElixirProto**: 1.75-9.37 KB per operation (7-36x more memory usage)

ElixirProto uses significantly more memory during encoding due to intermediate data structure creation.

### Collection Performance (individual encoding)
- **ElixirProto 100 sparse users**: 2.32K collections/s
- **ElixirProto 50 products**: 2.32K collections/s
- **Plain 100 sparse users**: 1.69K collections/s (38% slower)
- **Plain 50 products**: 2.12K collections/s (9% slower)

## Payload Size Analysis

| Scenario | Uncompressed | Plain+gzip | ElixirProto | Savings | % Savings |
|----------|--------------|------------|-------------|---------|-----------|
| **Single User (full)** | 478 bytes | 332 bytes | **289 bytes** | 43 bytes | **13.0%** |
| **Single User (sparse)** | 125 bytes | 111 bytes | **34 bytes** | 77 bytes | **69.4%** |
| **Single Product** | 349 bytes | 254 bytes | **196 bytes** | 58 bytes | **22.8%** |
| **Large Struct (50/50 fields)** | 1,279 bytes | 301 bytes | **136 bytes** | 165 bytes | **54.8%** |
| **Large Struct (10/50 fields)** | 879 bytes | 225 bytes | **64 bytes** | 161 bytes | **71.6%** |

ElixirProto compression ratio vs original data:
- Sparse user: 27.2% of original size
- Large sparse struct: 7.3% of original size

## Field Count Impact Analysis

ElixirProto space savings with varying field density:

- **5 fields**: 161 bytes saved (78.2% savings)
- **10 fields**: 164 bytes saved (72.6% savings)
- **20 fields**: 166 bytes saved (64.6% savings)
- **30 fields**: 168 bytes saved (60.4% savings)
- **50 fields**: 160 bytes saved (54.2% savings)

Key insight: ElixirProto maintains strong savings even as field count increases, due to index-based field representation and nil omission.

## Collection Size Analysis

### Individual Struct Encoding (100 full users)
- **ElixirProto total**: 28,949 bytes
- **Plain total**: 33,214 bytes
- **Savings**: 4,265 bytes (12.8%)

### Collection vs Individual Comparison
- **Plain collection** (100 users as list): 1,896 bytes
- **Individual sum**: 33,214 bytes
- **Collection advantage**: 31,318 bytes saved (94.3% reduction)

For bulk data, plain collection serialization is extremely space-efficient compared to individual struct encoding.

## Performance vs Payload Trade-offs

### ElixirProto Advantages
- **Sparse data**: Up to 71% space savings
- **Schema evolution**: Explicit indices enable backward compatibility
- **Bandwidth efficiency**: Smaller payloads for network transfer
- **Storage optimization**: Reduced disk/memory footprint for persistent data
- **Field omission**: Automatic nil field exclusion

### Plain Serialization Advantages
- **Memory efficiency**: 7-36x less memory usage during encoding
- **Collection handling**: Extremely efficient for bulk data
- **Simplicity**: No schema management required
- **Compatibility**: Works with any Elixir data structure
- **Development speed**: No setup overhead

## When to Use Each Approach

### Use ElixirProto For:
- Event sourcing with sparse events
- API responses with optional fields
- Database records with many nullable columns
- Message queues with payload size limits
- Mobile/IoT applications with bandwidth constraints
- Long-term data storage where compression matters

### Use Plain Serialization For:
- Hot path encoding/decoding (performance critical)
- In-memory caching
- Collections of mixed data types
- Temporary data structures
- Development and debugging
- Applications where simplicity > space optimization

## Test Environment

- **Hardware**: Apple M3 Ultra, 28 cores, 256GB RAM
- **Software**: Elixir 1.18.3, Erlang 27.3, JIT enabled
- **Compression**: zlib for both approaches
- **Benchmark Tool**: Benchee with 3s runtime + 2s warmup

## Reproducing Results

Run `mix run benchmarks/basic.exs` to generate current results.

### Sample Structures
- **User**: 7 fields (id, name, email, age, active, created_at, metadata)
- **Product**: 8 fields (id, name, description, price, category, in_stock, tags, specs)
- **LargeStruct**: 50 fields (field_01 through field_50)

## Conclusion

ElixirProto is optimized for space-efficient serialization of structured data with predictable schemas. It excels with sparse data and provides substantial space savings at the cost of higher memory usage during encoding. Plain serialization remains the better choice for performance-critical paths and mixed data types.