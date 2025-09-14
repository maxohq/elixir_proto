# Demonstrate the new ElixirProto format improvements

IO.puts("🚀 ELIXIRPROTO ULTRA-COMPACT FORMAT")
IO.puts("Schema Index + Fixed Tuple = Maximum Space Efficiency")
IO.puts(String.duplicate("=", 60))

# Manual demonstration of format improvements
schema_name_old = "myapp.ctx.user"
schema_index_new = 1

test_data = %{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
sparse_data = %{id: 1, name: "Alice"}  # Only 2 fields

IO.puts("\n📊 FORMAT COMPARISON ANALYSIS")

# OLD FORMAT: {schema_name, [{field_index, value}, ...]}
old_format_full = {schema_name_old, [{1, 1}, {2, "Alice"}, {3, "alice@example.com"}, {4, 30}, {5, true}]}
old_format_sparse = {schema_name_old, [{1, 1}, {2, "Alice"}]}

# NEW FORMAT: {schema_index, {val1, val2, val3, val4, val5}}
new_format_full = {schema_index_new, {1, "Alice", "alice@example.com", 30, true}}
new_format_sparse = {schema_index_new, {1, "Alice", nil, nil, nil}}

# Plain Elixir format
plain_full = test_data
plain_sparse = sparse_data

IO.puts("\n🔍 SERIALIZED FORMATS:")
IO.puts("Plain Full:    #{inspect(plain_full)}")
IO.puts("Old Full:      #{inspect(old_format_full)}")
IO.puts("NEW Full:      #{inspect(new_format_full)}")
IO.puts("")
IO.puts("Plain Sparse:  #{inspect(plain_sparse)}")
IO.puts("Old Sparse:    #{inspect(old_format_sparse)}")
IO.puts("NEW Sparse:    #{inspect(new_format_sparse)}")

# Size analysis
defmodule FormatAnalyzer do
  def analyze(name, plain, old, new) do
    plain_size = plain |> :erlang.term_to_binary() |> :zlib.compress() |> byte_size()
    old_size = old |> :erlang.term_to_binary() |> :zlib.compress() |> byte_size()
    new_size = new |> :erlang.term_to_binary() |> :zlib.compress() |> byte_size()

    new_vs_plain = plain_size - new_size
    new_vs_old = old_size - new_size

    IO.puts("\n#{name} (compressed sizes):")
    IO.puts("  Plain Elixir:     #{plain_size} bytes")
    IO.puts("  Old ElixirProto:  #{old_size} bytes")
    IO.puts("  NEW ElixirProto:  #{new_size} bytes")
    IO.puts("  NEW vs Plain:     #{new_vs_plain} bytes (#{Float.round(new_vs_plain/plain_size*100, 1)}% savings)")
    IO.puts("  NEW vs Old:       #{new_vs_old} bytes (#{Float.round(new_vs_old/old_size*100, 1)}% improvement)")

    {plain_size, old_size, new_size}
  end
end

# Analyze both scenarios
{pf, of, nf} = FormatAnalyzer.analyze("📊 FULL DATA (5 fields)", plain_full, old_format_full, new_format_full)
{ps, os, ns} = FormatAnalyzer.analyze("📊 SPARSE DATA (2 fields)", plain_sparse, old_format_sparse, new_format_sparse)

IO.puts("\n📈 KEY IMPROVEMENTS BREAKDOWN:")

schema_name_bytes = byte_size(schema_name_old)
schema_index_bytes = :erlang.term_to_binary(schema_index_new) |> byte_size()

IO.puts("1. Schema Name Overhead:")
IO.puts("   Old: '#{schema_name_old}' = #{schema_name_bytes} bytes")
IO.puts("   New: #{schema_index_new} = #{schema_index_bytes} bytes")
IO.puts("   Savings: #{schema_name_bytes - schema_index_bytes} bytes per struct!")

IO.puts("\n2. Field Format Overhead (per field):")
IO.puts("   Old: {field_index, value} = ~3-4 bytes overhead")
IO.puts("   New: Fixed tuple position = 0 bytes overhead")
IO.puts("   Savings: ~3 bytes × field_count")

IO.puts("\n3. Nil Field Handling:")
IO.puts("   Old: Skip nil fields (good for sparse data)")
IO.puts("   New: Fixed tuple with nil values (consistent size)")
IO.puts("   Trade-off: Consistency vs sparse data efficiency")

total_old_bytes = of + os
total_new_bytes = nf + ns
total_savings = total_old_bytes - total_new_bytes

IO.puts("\n🏆 TOTAL IMPROVEMENTS:")
IO.puts("Old format total:     #{total_old_bytes} bytes")
IO.puts("NEW format total:     #{total_new_bytes} bytes")
IO.puts("Total improvement:    #{total_savings} bytes (#{Float.round(total_savings/total_old_bytes*100, 1)}%)")

IO.puts("\n💡 WHEN NEW FORMAT EXCELS:")
IO.puts("✅ Long schema names (#{schema_name_bytes}+ bytes)")
IO.puts("✅ Multiple fields per struct")
IO.puts("✅ Dense data (most fields populated)")
IO.puts("✅ Consistent schema sizes")

IO.puts("\n⚖️  TRADE-OFFS:")
IO.puts("❌ Sparse data less efficient (stores nil values)")
IO.puts("✅ But schema index savings often compensate")
IO.puts("✅ Predictable memory usage")
IO.puts("✅ Faster deserialization (fixed positions)")

# Show the registry concept
IO.puts("\n📋 SCHEMA INDEX REGISTRY CONCEPT:")
registry_examples = %{
  "myapp.ctx.user" => 1,
  "myapp.ctx.post" => 2,
  "myapp.ctx.comment" => 3,
  "deeply.nested.schema.with.long.name" => 4
}

Enum.each(registry_examples, fn {name, index} ->
  name_size = byte_size(name)
  index_size = :erlang.term_to_binary(index) |> byte_size()
  savings = name_size - index_size
  IO.puts("  #{String.pad_trailing(name, 35)} #{index} (saves #{savings}b)")
end)

IO.puts("\n🎯 CONCLUSION:")
IO.puts("The new ultra-compact format achieves maximum space efficiency by:")
IO.puts("1. Replacing schema names with tiny indices")
IO.puts("2. Using fixed tuples instead of keyword lists")
IO.puts("3. Eliminating per-field indexing overhead")
IO.puts("4. Maintaining backwards compatibility through registry")