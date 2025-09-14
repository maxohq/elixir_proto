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
ElixirProto.encode sparse user                232.83 K        4.30 μs   ±236.89%        3.79 μs        8.29 μs
Plain.encode sparse user                      166.98 K        5.99 μs   ±121.62%        5.21 μs       15.58 μs
ElixirProto.encode product                    124.10 K        8.06 μs    ±70.41%        7.54 μs       14.92 μs
Plain.encode product                          118.05 K        8.47 μs    ±70.67%        8.13 μs          11 μs
ElixirProto.encode large struct (sparse)      113.95 K        8.78 μs    ±56.47%        8.33 μs       16.25 μs
Plain.encode single user (full)                99.72 K       10.03 μs    ±57.29%        9.46 μs       14.96 μs
ElixirProto.encode single user (full)          99.18 K       10.08 μs    ±66.43%        9.46 μs       17.33 μs
ElixirProto.encode large struct (full)         83.06 K       12.04 μs    ±40.25%       11.33 μs       20.79 μs
Plain.encode large struct (sparse)             76.77 K       13.03 μs    ±45.36%       10.75 μs       26.38 μs
Plain.encode large struct (full)               71.33 K       14.02 μs    ±34.94%       13.50 μs       23.73 μs

Comparison: 
ElixirProto.encode sparse user                232.83 K
Plain.encode sparse user                      166.98 K - 1.39x slower +1.69 μs
ElixirProto.encode product                    124.10 K - 1.88x slower +3.76 μs
Plain.encode product                          118.05 K - 1.97x slower +4.18 μs
ElixirProto.encode large struct (sparse)      113.95 K - 2.04x slower +4.48 μs
Plain.encode single user (full)                99.72 K - 2.33x slower +5.73 μs
ElixirProto.encode single user (full)          99.18 K - 2.35x slower +5.79 μs
ElixirProto.encode large struct (full)         83.06 K - 2.80x slower +7.74 μs
Plain.encode large struct (sparse)             76.77 K - 3.03x slower +8.73 μs
Plain.encode large struct (full)               71.33 K - 3.26x slower +9.72 μs

Memory usage statistics:

Name                                        Memory usage
ElixirProto.encode sparse user                   1.79 KB
Plain.encode sparse user                         0.26 KB - 0.14x memory usage -1.53125 KB
ElixirProto.encode product                          2 KB - 1.12x memory usage +0.21 KB
Plain.encode product                             0.26 KB - 0.14x memory usage -1.53125 KB
ElixirProto.encode large struct (sparse)         9.25 KB - 5.17x memory usage +7.46 KB
Plain.encode single user (full)                  0.26 KB - 0.14x memory usage -1.53125 KB
ElixirProto.encode single user (full)            1.75 KB - 0.98x memory usage -0.03906 KB
ElixirProto.encode large struct (full)           9.37 KB - 5.24x memory usage +7.58 KB
Plain.encode large struct (sparse)               0.26 KB - 0.14x memory usage -1.53125 KB
Plain.encode large struct (full)                 0.26 KB - 0.14x memory usage -1.53125 KB

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
ElixirProto 100 sparse users              2.29 K      436.66 μs     ±8.12%      433.92 μs      479.86 μs
ElixirProto 50 products                   2.19 K      456.28 μs    ±26.64%      427.33 μs     1099.64 μs
Plain 50 products                         2.08 K      481.29 μs    ±13.76%      472.86 μs      657.19 μs
Plain 100 sparse users                    1.72 K      581.85 μs     ±9.45%      580.17 μs      649.07 μs
ElixirProto 100 users (individual)        0.97 K     1033.21 μs     ±5.26%     1025.83 μs     1198.83 μs
Plain 100 users (individual)              0.94 K     1062.03 μs     ±7.04%     1054.04 μs     1280.60 μs

Comparison: 
ElixirProto 100 sparse users              2.29 K
ElixirProto 50 products                   2.19 K - 1.04x slower +19.62 μs
Plain 50 products                         2.08 K - 1.10x slower +44.62 μs
Plain 100 sparse users                    1.72 K - 1.33x slower +145.19 μs
ElixirProto 100 users (individual)        0.97 K - 2.37x slower +596.55 μs
Plain 100 users (individual)              0.94 K - 2.43x slower +625.37 μs

Memory usage statistics:

Name                                  Memory usage
ElixirProto 100 sparse users             192.13 KB
ElixirProto 50 products                  106.81 KB - 0.56x memory usage -85.31250 KB
Plain 50 products                         12.89 KB - 0.07x memory usage -179.23438 KB
Plain 100 sparse users                    25.68 KB - 0.13x memory usage -166.44531 KB
ElixirProto 100 users (individual)       188.55 KB - 0.98x memory usage -3.57031 KB
Plain 100 users (individual)              25.78 KB - 0.13x memory usage -166.34375 KB

**All measurements for memory usage were the same**

📊 PAYLOAD SIZE ANALYSIS
================================================================================

Single User (full data):
  📦 Uncompressed: 478 bytes
  🗜️  Plain+gzip:   330 bytes (69.0% of original)
  ⚡ ElixirProto:  287 bytes (60.0% of original)
  ✅ Proto saves:   43 bytes (13.0% smaller)

Single User (sparse - only id, name):
  📦 Uncompressed: 125 bytes
  🗜️  Plain+gzip:   111 bytes (88.8% of original)
  ⚡ ElixirProto:  34 bytes (27.2% of original)
  ✅ Proto saves:   77 bytes (69.4% smaller)

Single Product:
  📦 Uncompressed: 344 bytes
  🗜️  Plain+gzip:   248 bytes (72.1% of original)
  ⚡ ElixirProto:  189 bytes (54.9% of original)
  ✅ Proto saves:   59 bytes (23.8% smaller)

Large Struct (all 50 fields):
  📦 Uncompressed: 1279 bytes
  🗜️  Plain+gzip:   301 bytes (23.5% of original)
  ⚡ ElixirProto:  136 bytes (10.6% of original)
  ✅ Proto saves:   165 bytes (54.8% smaller)

Large Struct (only 10/50 fields):
  📦 Uncompressed: 879 bytes
  🗜️  Plain+gzip:   225 bytes (25.6% of original)
  ⚡ ElixirProto:  64 bytes (7.3% of original)
  ✅ Proto saves:   161 bytes (71.6% smaller)

🗂️  COLLECTION SIZE ANALYSIS
100 Users - Individual encoding:
  ElixirProto total: 28815 bytes
  Plain total:       33097 bytes
  Savings:           4282 bytes
100 Users - Collection encoding (Plain only):
  Plain collection:  1898 bytes
  vs Individual sum: 33097 bytes
  Collection saves:  31199 bytes

📈 FIELD COUNT IMPACT ANALYSIS
================================================================================
5 fields: Proto=45b, Plain=206b, Savings=161b (78.2%)
10 fields: Proto=62b, Plain=226b, Savings=164b (72.6%)
20 fields: Proto=91b, Plain=257b, Savings=166b (64.6%)
30 fields: Proto=110b, Plain=278b, Savings=168b (60.4%)
50 fields: Proto=135b, Plain=295b, Savings=160b (54.2%)

🎯 BENCHMARK SUMMARY
ElixirProto shines when:
  ✅ Structs have many fields (field name overhead)
  ✅ Many nil/sparse fields (nil omission)
  ✅ Collections of similar structs

Plain serialization works better when:
  ✅ One-off serialization of different data types
  ✅ Very small structs (few fields)

✨ Benchmarks completed!
