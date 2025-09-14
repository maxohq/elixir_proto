# ElixirProto Benchmark Results

## 🎯 Executive Summary

**ElixirProto excels at space efficiency, especially for sparse data, while plain serialization wins on performance and memory usage.**

## 🔥 Performance Results

### Encoding Performance (operations per second)
- **Sparse user**: ElixirProto **39% faster** (245K ops/s vs 176K ops/s)
- **Full user**: Plain slightly faster (102K ops/s vs 100K ops/s)
- **Large sparse struct**: ElixirProto **61% faster** (147K ops/s vs 91K ops/s)
- **Large full struct**: Plain **26% faster** (71K ops/s vs 57K ops/s)

### Memory Usage
- **Plain serialization**: ~0.26 KB per operation
- **ElixirProto**: 1.34-5.30 KB per operation (**5-20x more memory**)

## 📦 Payload Size Analysis - ElixirProto's Strength

| Scenario | Plain Size | Proto Size | Savings | % Savings |
|----------|------------|------------|---------|-----------|
| **Sparse User** (2/7 fields) | 111 bytes | **45 bytes** | 66 bytes | **59.5%** ✅ |
| **Large Sparse** (10/50 fields) | 229 bytes | **101 bytes** | 128 bytes | **55.9%** ✅ |
| Full User | 331 bytes | **314 bytes** | 17 bytes | **5.1%** |
| Full Product | 254 bytes | **226 bytes** | 28 bytes | **11.0%** |
| Large Full Struct | 301 bytes | **274 bytes** | 27 bytes | **9.0%** |

## 📈 Field Count Impact

**ElixirProto space savings decrease as field density increases:**

- **5 fields**: 67.3% savings (140 bytes saved)
- **10 fields**: 57.5% savings (131 bytes saved)
- **20 fields**: 42.1% savings (107 bytes saved)
- **30 fields**: 32.4% savings (90 bytes saved)
- **50 fields**: 8.7% savings (26 bytes saved)

**Key Insight**: ElixirProto's nil field omission provides exponential benefits as sparsity increases.

## 🗂️ Collection Analysis

### Individual Struct Encoding (100 users)
- **ElixirProto total**: 31,251 bytes
- **Plain total**: 33,156 bytes
- **Savings**: 1,905 bytes (5.7%)

### Collection vs Individual
- **Plain collection encoding**: 1,892 bytes
- **Individual sum**: 33,156 bytes
- **Collection advantage**: 94% space savings!

**Insight**: For collections, plain Elixir's collection serialization is extremely efficient compared to individual struct encoding.

## ⚡ When to Use Each Approach

### 🏆 ElixirProto Wins When:
- ✅ **Sparse data** (many nil fields) - **Up to 60% space savings**
- ✅ **Schema evolution** requirements
- ✅ **Bandwidth-limited** scenarios
- ✅ **Storage cost** is critical
- ✅ **Large structs** with variable field usage

### 🏆 Plain Serialization Wins When:
- ✅ **Performance** is critical (**5-20x less memory**)
- ✅ **Collections** of mixed data types
- ✅ **Full structs** (all fields populated)
- ✅ **One-off** serialization
- ✅ **Small structs** (< 10 fields)

## 🎯 Real-World Scenarios

### 💰 Use ElixirProto For:
- **API responses** with optional fields
- **Database records** with sparse columns
- **Event sourcing** with evolving schemas
- **Message queues** with size limits
- **Mobile apps** with bandwidth constraints

### 💨 Use Plain Serialization For:
- **Hot path** encoding/decoding
- **In-memory** caching
- **Full configuration** objects
- **Temporary** data structures
- **Development/debugging**

## 🧪 Test Setup Details

**Hardware**: Apple M3 Ultra, 28 cores, 256GB RAM
**Software**: Elixir 1.18.3, Erlang 27.3, JIT enabled
**Compression**: zlib for both approaches
**Benchmark Tool**: Benchee 1.4.0
**Test Duration**: 3 seconds per benchmark + 2s warmup

## 📊 Raw Benchmark Data

Run `mix run benchmarks/basic.exs` to reproduce these results in your environment.

### Sample Data Structures:
- **User**: 7 fields (id, name, email, age, active, created_at, metadata)
- **Product**: 8 fields (id, name, description, price, category, in_stock, tags, specs)
- **LargeStruct**: 50 fields (field_01 through field_50)

**Conclusion**: ElixirProto is a specialized tool that excels at space-efficient serialization of sparse structured data, while plain serialization remains the better general-purpose choice for performance-critical applications.