# Simple debug analysis using existing test modules
# Run with: mix run benchmarks/debug_simple.exs

# Define test module for benchmarks
defmodule SimpleUser do
  use ElixirProto.Schema, name: "simple.user", index: 1
  defschema [:id, :name, :email, :age, :active]
end

defmodule PlainSerializer do
  def encode(data), do: data |> :erlang.term_to_binary() |> :zlib.compress()
end

defmodule SimpleDebugger do
  def run do
    # Create test cases
    full_user = %SimpleUser{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
    sparse_user = %SimpleUser{id: 1, name: "Alice"}  # only 2 out of 5 fields

    IO.puts("🔍 WHY IS ELIXIRPROTO PAYLOAD SIZE SOMETIMES LARGER?")
    IO.puts(String.duplicate("=", 60))

# Let's break down what ElixirProto is actually storing
schema = ElixirProto.Schema.Registry.get_schema_by_module(SimpleUser)
schema_name = "simple.user"  # from our test module

IO.puts("\n📊 ANALYZING SERIALIZED DATA STRUCTURES")

# Full user - step by step
IO.puts("\nFull User Original:")
IO.inspect(full_user, limit: :infinity)

# What ElixirProto stores
indexed_fields_full = [{1, 1}, {2, "Alice"}, {3, "alice@example.com"}, {4, 30}, {5, true}]
proto_data_full = {schema_name, indexed_fields_full}
IO.puts("\nElixirProto stores:")
IO.inspect(proto_data_full, limit: :infinity)

# Sparse user
indexed_fields_sparse = [{1, 1}, {2, "Alice"}]  # only non-nil fields
proto_data_sparse = {schema_name, indexed_fields_sparse}
IO.puts("\nSparse ElixirProto stores:")
IO.inspect(proto_data_sparse, limit: :infinity)

# Size analysis
proto_full_uncompressed = :erlang.term_to_binary(proto_data_full)
proto_sparse_uncompressed = :erlang.term_to_binary(proto_data_sparse)
plain_full_uncompressed = :erlang.term_to_binary(full_user)
plain_sparse_uncompressed = :erlang.term_to_binary(sparse_user)

proto_full_compressed = :zlib.compress(proto_full_uncompressed)
proto_sparse_compressed = :zlib.compress(proto_sparse_uncompressed)
plain_full_compressed = :zlib.compress(plain_full_uncompressed)
plain_sparse_compressed = :zlib.compress(plain_sparse_uncompressed)

IO.puts("\n📏 UNCOMPRESSED SIZES:")
IO.puts("Full User - Proto:  #{byte_size(proto_full_uncompressed)} bytes")
IO.puts("Full User - Plain:  #{byte_size(plain_full_uncompressed)} bytes")
IO.puts("Sparse User - Proto: #{byte_size(proto_sparse_uncompressed)} bytes")
IO.puts("Sparse User - Plain: #{byte_size(plain_sparse_uncompressed)} bytes")

IO.puts("\n🗜️  COMPRESSED SIZES:")
IO.puts("Full User - Proto:  #{byte_size(proto_full_compressed)} bytes")
IO.puts("Full User - Plain:  #{byte_size(plain_full_compressed)} bytes")
IO.puts("Sparse User - Proto: #{byte_size(proto_sparse_compressed)} bytes")
IO.puts("Sparse User - Plain: #{byte_size(plain_sparse_uncompressed)} bytes")

# Let's examine what's taking up space
IO.puts("\n🎯 OVERHEAD BREAKDOWN:")
schema_name_bytes = byte_size(schema_name)
IO.puts("Schema name '#{schema_name}': #{schema_name_bytes} bytes")

# Field representation comparison
IO.puts("\n⚖️  FIELD STORAGE COMPARISON:")
IO.puts("Field names in plain serialization:")
IO.inspect(Map.from_struct(sparse_user), limit: :infinity)
IO.puts("Field indices in ElixirProto:")
IO.inspect(indexed_fields_sparse, limit: :infinity)

# The real test: create a scenario where ElixirProto should win big
IO.puts("\n🧪 EXTREME TEST - VERY SPARSE STRUCT:")

# Use our large struct from benchmarks - only populate 2 out of 50 fields
defmodule TestAnalysis do
  def test_large_sparse do
    # Simulate a struct with 2 populated fields out of 50
    large_struct_data = %{
      field_01: "value1",
      field_02: "value2"
      # 48 other fields are nil
    }

    # What plain serialization stores (with all nil fields)
    full_map = Enum.reduce(1..50, %{}, fn i, acc ->
      field_name = :"field_#{String.pad_leading("#{i}", 2, "0")}"
      value = Map.get(large_struct_data, field_name)
      Map.put(acc, field_name, value)
    end)

    # What ElixirProto stores (only non-nil fields)
    proto_data = {"bench.large", [{1, "value1"}, {2, "value2"}]}

    plain_size = full_map |> :erlang.term_to_binary() |> :zlib.compress() |> byte_size()
    proto_size = proto_data |> :erlang.term_to_binary() |> :zlib.compress() |> byte_size()

    IO.puts("Large struct (2/50 fields):")
    IO.puts("  Plain: #{plain_size} bytes")
    IO.puts("  Proto: #{proto_size} bytes")
    IO.puts("  Savings: #{plain_size - proto_size} bytes")

    # Show what's actually stored
    IO.puts("\nPlain stores (first 5 fields):")
    full_map |> Enum.take(5) |> IO.inspect()
    IO.puts("ElixirProto stores:")
    IO.inspect(proto_data)
  end
end

TestAnalysis.test_large_sparse()

IO.puts("\n💡 KEY INSIGHTS:")
IO.puts("1. ElixirProto has FIXED overhead: schema name (~#{schema_name_bytes} bytes)")
IO.puts("2. For small/medium structs, this overhead can make payloads LARGER")
IO.puts("3. ElixirProto wins when nil field omission > schema name overhead")
IO.puts("4. Compression helps both approaches significantly")
IO.puts("5. The 'magic threshold' is around 3-5 fields with many nils")

IO.puts("\n🎯 WHEN ELIXIRPROTO IS LARGER:")
IO.puts("- Small structs (few fields)")
IO.puts("- Dense structs (most fields populated)")
IO.puts("- Short field names (atoms compress well)")

IO.puts("\n🏆 WHEN ELIXIRPROTO WINS:")
IO.puts("- Large sparse structs (many nil fields)")
IO.puts("- Long field names")
IO.puts("- Repeated serialization of same schema")
  end
end

# Run the analysis
SimpleDebugger.run()