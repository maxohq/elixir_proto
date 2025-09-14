🚀 Setting up benchmark data...
✅ Data prepared, starting benchmarks...
Operating System: macOS
CPU Information: Apple M3 Ultra
Number of Available Cores: 28
Available memory: 256 GB
Elixir 1.18.3
Erlang 27.3
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 3 s
memory time: 1 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 1 min

Benchmarking ElixirProto.encode large struct (full) ...
Benchmarking ElixirProto.encode large struct (sparse) ...
Benchmarking ElixirProto.encode product ...
Benchmarking ElixirProto.encode single user (full) ...
Benchmarking ElixirProto.encode sparse user ...
Benchmarking Plain.encode large struct (full) ...
Benchmarking Plain.encode large struct (sparse) ...
Benchmarking Plain.encode product ...
Benchmarking Plain.encode single user (full) ...
Benchmarking Plain.encode sparse user ...
Calculating statistics...
Formatting results...

*** 🔥 ENCODING PERFORMANCE ***

Name                                               ips        average  deviation         median         99th %
ElixirProto.encode sparse user                247.38 K        4.04 μs   ±111.29%        3.75 μs        7.29 μs
Plain.encode sparse user                      178.21 K        5.61 μs   ±139.70%        5.17 μs        9.04 μs
ElixirProto.encode large struct (sparse)      148.02 K        6.76 μs    ±64.13%        6.29 μs       12.33 μs
ElixirProto.encode product                    120.52 K        8.30 μs    ±53.59%        7.96 μs       12.92 μs
Plain.encode single user (full)               101.97 K        9.81 μs    ±41.63%        9.50 μs       12.17 μs
Plain.encode large struct (sparse)             90.96 K       10.99 μs    ±34.68%       10.58 μs       15.42 μs
ElixirProto.encode single user (full)          89.91 K       11.12 μs    ±45.22%        9.58 μs       23.38 μs
Plain.encode product                           89.34 K       11.19 μs    ±66.72%        8.25 μs       22.88 μs
Plain.encode large struct (full)               71.13 K       14.06 μs    ±23.64%       13.58 μs       22.21 μs
ElixirProto.encode large struct (full)         60.80 K       16.45 μs    ±15.61%          16 μs       25.46 μs

Comparison:
ElixirProto.encode sparse user                247.38 K
Plain.encode sparse user                      178.21 K - 1.39x slower +1.57 μs
ElixirProto.encode large struct (sparse)      148.02 K - 1.67x slower +2.71 μs
ElixirProto.encode product                    120.52 K - 2.05x slower +4.26 μs
Plain.encode single user (full)               101.97 K - 2.43x slower +5.76 μs
Plain.encode large struct (sparse)             90.96 K - 2.72x slower +6.95 μs
ElixirProto.encode single user (full)          89.91 K - 2.75x slower +7.08 μs
Plain.encode product                           89.34 K - 2.77x slower +7.15 μs
Plain.encode large struct (full)               71.13 K - 3.48x slower +10.02 μs
ElixirProto.encode large struct (full)         60.80 K - 4.07x slower +12.41 μs

Memory usage statistics:

Name                                        Memory usage
ElixirProto.encode sparse user                   1.34 KB
Plain.encode sparse user                         0.26 KB - 0.19x memory usage -1.07813 KB
ElixirProto.encode large struct (sparse)         2.55 KB - 1.91x memory usage +1.21 KB
ElixirProto.encode product                       1.66 KB - 1.25x memory usage +0.33 KB
Plain.encode single user (full)                  0.26 KB - 0.19x memory usage -1.07813 KB
Plain.encode large struct (sparse)               0.26 KB - 0.19x memory usage -1.07813 KB
ElixirProto.encode single user (full)            1.48 KB - 1.11x memory usage +0.148 KB
Plain.encode product                             0.26 KB - 0.19x memory usage -1.07813 KB
Plain.encode large struct (full)                 0.26 KB - 0.19x memory usage -1.07813 KB
ElixirProto.encode large struct (full)           5.30 KB - 3.96x memory usage +3.96 KB

**All measurements for memory usage were the same**
Operating System: macOS
CPU Information: Apple M3 Ultra
Number of Available Cores: 28
Available memory: 256 GB
Elixir 1.18.3
Erlang 27.3
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 3 s
memory time: 1 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 36 s

Benchmarking ElixirProto 100 sparse users ...
Benchmarking ElixirProto 100 users (individual) ...
Benchmarking ElixirProto 50 products ...
Benchmarking Plain 100 sparse users ...
Benchmarking Plain 100 users (individual) ...
Benchmarking Plain 50 products ...
Calculating statistics...
Formatting results...

*** 📦 COLLECTION ENCODING (Individual Structs) ***

Name                                         ips        average  deviation         median         99th %
ElixirProto 100 sparse users              2.25 K      443.88 μs     ±4.36%      442.25 μs      473.46 μs
ElixirProto 50 products                   2.18 K      459.38 μs     ±3.39%      457.29 μs      508.65 μs
Plain 50 products                         2.17 K      460.09 μs     ±4.49%      455.82 μs      529.22 μs
Plain 100 sparse users                    1.71 K      583.40 μs     ±4.77%      582.92 μs      645.04 μs
Plain 100 users (individual)              0.97 K     1035.23 μs     ±4.91%     1035.79 μs     1137.94 μs
ElixirProto 100 users (individual)        0.95 K     1051.25 μs     ±3.85%     1046.60 μs     1187.01 μs

Comparison:
ElixirProto 100 sparse users              2.25 K
ElixirProto 50 products                   2.18 K - 1.03x slower +15.50 μs
Plain 50 products                         2.17 K - 1.04x slower +16.21 μs
Plain 100 sparse users                    1.71 K - 1.31x slower +139.53 μs
Plain 100 users (individual)              0.97 K - 2.33x slower +591.35 μs
ElixirProto 100 users (individual)        0.95 K - 2.37x slower +607.37 μs

Memory usage statistics:

Name                                  Memory usage
ElixirProto 100 sparse users             133.47 KB
ElixirProto 50 products                   83.05 KB - 0.62x memory usage -50.42188 KB
Plain 50 products                         12.89 KB - 0.10x memory usage -120.57813 KB
Plain 100 sparse users                    25.68 KB - 0.19x memory usage -107.78906 KB
Plain 100 users (individual)              25.78 KB - 0.19x memory usage -107.68750 KB
ElixirProto 100 users (individual)       155.79 KB - 1.17x memory usage +22.32 KB

**All measurements for memory usage were the same**

📊 PAYLOAD SIZE ANALYSIS
================================================================================

Single User (full data):
  📦 Uncompressed: 478 bytes
  🗜  Plain+gzip:   331 bytes (69.2% of original)
  ⚡ ElixirProto:  313 bytes (65.5% of original)
  ✅ Proto saves:   18 bytes (5.4% smaller)

Single User (sparse - only id, name):
  📦 Uncompressed: 125 bytes
  🗜  Plain+gzip:   111 bytes (88.8% of original)
  ⚡ ElixirProto:  45 bytes (36.0% of original)
  ✅ Proto saves:   66 bytes (59.5% smaller)

Single Product:
  📦 Uncompressed: 347 bytes
  🗜  Plain+gzip:   252 bytes (72.6% of original)
  ⚡ ElixirProto:  223 bytes (64.3% of original)
  ✅ Proto saves:   29 bytes (11.5% smaller)

Large Struct (all 50 fields):
  📦 Uncompressed: 1279 bytes
  🗜  Plain+gzip:   301 bytes (23.5% of original)
  ⚡ ElixirProto:  274 bytes (21.4% of original)
  ✅ Proto saves:   27 bytes (9.0% smaller)

Large Struct (only 10/50 fields):
  📦 Uncompressed: 879 bytes
  🗜  Plain+gzip:   229 bytes (26.1% of original)
  ⚡ ElixirProto:  101 bytes (11.5% of original)
  ✅ Proto saves:   128 bytes (55.9% smaller)

🗂  COLLECTION SIZE ANALYSIS
100 Users - Individual encoding:
  ElixirProto total: 31278 bytes
  Plain total:       33208 bytes
  Savings:           1930 bytes
100 Users - Collection encoding (Plain only):
  Plain collection:  1927 bytes
  vs Individual sum: 33208 bytes
  Collection saves:  31281 bytes

📈 FIELD COUNT IMPACT ANALYSIS
================================================================================
5 fields: Proto=68b, Plain=208b, Savings=140b (67.3%)
10 fields: Proto=97b, Plain=228b, Savings=131b (57.5%)
20 fields: Proto=147b, Plain=254b, Savings=107b (42.1%)
30 fields: Proto=188b, Plain=278b, Savings=90b (32.4%)
50 fields: Proto=272b, Plain=298b, Savings=26b (8.7%)

🎯 BENCHMARK SUMMARY
ElixirProto shines when:
  ✅ Structs have many fields (field name overhead)
  ✅ Many nil/sparse fields (nil omission)
  ✅ Collections of similar structs

Plain serialization works better when:
  ✅ One-off serialization of different data types
  ✅ Very small structs (few fields)

✨ Benchmarks completed!