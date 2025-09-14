# Debug ElixirProto serialization format and sizes
#
# Run with: mix run benchmarks/debug_sizes.exs

defmodule DebugUser do
  use ElixirProto.Schema, name: "debug.user", index: 1
  defschema [:id, :name, :email]
end

defmodule PlainSerializer do
  def encode(data) do
    data
    |> :erlang.term_to_binary()
    |> :zlib.compress()
  end
end

# Real-world scenario: what if we had longer field names?
defmodule LongFieldUser do
  use ElixirProto.Schema, name: "debug.long.field.user", index: 2
  defschema [:user_identification_number, :user_full_display_name, :user_email_address]
end

# Module with functions that create test data
defmodule DebugTester do
  def run do
    # Create test data
    full_user = %DebugUser{id: 1, name: "Alice", email: "alice@example.com"}
    sparse_user = %DebugUser{id: 1, name: "Alice"}  # email is nil

IO.puts("🔍 DEBUGGING ELIXIRPROTO SERIALIZATION")
IO.puts(String.duplicate("=", 60))

# Debug the serialization process step by step
IO.puts("\n📊 FULL USER ANALYSIS")
IO.inspect(full_user, label: "Original struct")

# ElixirProto process
schema = ElixirProto.SchemaRegistry.get_schema_by_module(DebugUser)
IO.inspect(schema.field_indices, label: "Field indices")

# Manual ElixirProto process to see intermediate steps
schema_name = schema.module.__schema__(:name)
field_indices = schema.field_indices

indexed_fields =
  full_user
  |> Map.from_struct()
  |> Enum.reduce([], fn {field, value}, acc ->
    if value != nil do
      index = Map.fetch!(field_indices, field)
      [{index, value} | acc]
    else
      acc
    end
  end)
  |> Enum.reverse()

serializable_data = {schema_name, indexed_fields}

IO.inspect(serializable_data, label: "Serializable data")

# Size breakdown
uncompressed_proto_data = :erlang.term_to_binary(serializable_data)
compressed_proto_data = :zlib.compress(uncompressed_proto_data)

uncompressed_plain_data = :erlang.term_to_binary(full_user)
compressed_plain_data = :zlib.compress(uncompressed_plain_data)

IO.puts("\n📏 SIZE BREAKDOWN (Full User):")
IO.puts("ElixirProto uncompressed: #{byte_size(uncompressed_proto_data)} bytes")
IO.puts("ElixirProto compressed:   #{byte_size(compressed_proto_data)} bytes")
IO.puts("Plain uncompressed:       #{byte_size(uncompressed_plain_data)} bytes")
IO.puts("Plain compressed:         #{byte_size(compressed_plain_data)} bytes")

IO.puts("\n🔍 WHAT'S IN THE SERIALIZED DATA?")
IO.puts("ElixirProto data structure:")
IO.inspect(:erlang.binary_to_term(uncompressed_proto_data), pretty: true, limit: :infinity)

IO.puts("\nPlain data structure:")
IO.inspect(:erlang.binary_to_term(uncompressed_plain_data), pretty: true, limit: :infinity)

# Now analyze sparse user
IO.puts("\n\n📊 SPARSE USER ANALYSIS")
IO.inspect(sparse_user, label: "Sparse struct")

sparse_indexed_fields =
  sparse_user
  |> Map.from_struct()
  |> Enum.reduce([], fn {field, value}, acc ->
    if value != nil do
      index = Map.fetch!(field_indices, field)
      [{index, value} | acc]
    else
      acc
    end
  end)
  |> Enum.reverse()

sparse_serializable_data = {schema_name, sparse_indexed_fields}
IO.inspect(sparse_serializable_data, label: "Sparse serializable data")

uncompressed_sparse_proto = :erlang.term_to_binary(sparse_serializable_data)
compressed_sparse_proto = :zlib.compress(uncompressed_sparse_proto)

uncompressed_sparse_plain = :erlang.term_to_binary(sparse_user)
compressed_sparse_plain = :zlib.compress(uncompressed_sparse_plain)

IO.puts("\n📏 SIZE BREAKDOWN (Sparse User):")
IO.puts("ElixirProto uncompressed: #{byte_size(uncompressed_sparse_proto)} bytes")
IO.puts("ElixirProto compressed:   #{byte_size(compressed_sparse_proto)} bytes")
IO.puts("Plain uncompressed:       #{byte_size(uncompressed_sparse_plain)} bytes")
IO.puts("Plain compressed:         #{byte_size(compressed_sparse_plain)} bytes")

# The key insight: where does ElixirProto overhead come from?
schema_name_size = byte_size(schema_name)
IO.puts("\n🎯 OVERHEAD ANALYSIS:")
IO.puts("Schema name: '#{schema_name}' = #{schema_name_size} bytes")
IO.puts("Tuple overhead: ~3 bytes")
IO.puts("Index overhead per field: ~2 bytes each")

# Compare field name vs index sizes
IO.puts("\n⚖️  FIELD REPRESENTATION COMPARISON:")
for {field, index} <- field_indices do
  field_name_size = field |> Atom.to_string() |> byte_size()
  index_size = :erlang.term_to_binary(index) |> byte_size()
  IO.puts("#{field}: atom=#{field_name_size}b vs index=#{index_size}b")
end

IO.puts("\n💡 INSIGHTS:")
IO.puts("1. ElixirProto adds schema name overhead (~#{schema_name_size} bytes)")
IO.puts("2. Field names become integers (saves space for long field names)")
IO.puts("3. Nil field omission is the main space saver")
IO.puts("4. Compression is very effective on both approaches")

# Real-world scenario: what if we had longer field names?
    long_user = %LongFieldUser{
      user_identification_number: 1,
      user_full_display_name: "Alice",
      user_email_address: "alice@example.com"
    }

    proto_long = ElixirProto.encode(long_user)
    plain_long = PlainSerializer.encode(long_user)

    IO.puts("\n🏷️  LONG FIELD NAMES TEST:")
    IO.puts("ElixirProto: #{byte_size(proto_long)} bytes")
    IO.puts("Plain:       #{byte_size(plain_long)} bytes")
    IO.puts("Savings:     #{byte_size(plain_long) - byte_size(proto_long)} bytes")
  end
end

# Run the debug analysis
DebugTester.run()
