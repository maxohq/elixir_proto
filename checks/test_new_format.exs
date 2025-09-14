# Test the new ultra-compact schema index + fixed tuple format
# Run with: mix run test_new_format.exs

# Use existing test modules
alias ElixirProtoTest.User

# Reset schema registry for clean test
ElixirProto.SchemaRegistry.reset!()

# Create test data
full_user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
sparse_user = %User{id: 1, name: "Alice"}  # Only 2 out of 5 fields

IO.puts("🚀 TESTING NEW ULTRA-COMPACT FORMAT")
IO.puts("Schema Index + Fixed Tuple Format")
IO.puts(String.duplicate("=", 50))

# Test encoding
IO.puts("\n📊 ENCODING TEST")
IO.puts("Full user: #{inspect(full_user)}")

try do
  encoded_full = ElixirProto.encode(full_user)
  encoded_sparse = ElixirProto.encode(sparse_user)

  IO.puts("✅ Encoding successful!")
  IO.puts("Full user encoded size: #{byte_size(encoded_full)} bytes")
  IO.puts("Sparse user encoded size: #{byte_size(encoded_sparse)} bytes")

  # Check what the registry assigned
  registry_stats = ElixirProto.SchemaRegistry.stats()
  IO.puts("\n📋 Schema Registry:")
  IO.inspect(registry_stats.schemas)

  # Test decoding
  IO.puts("\n📊 DECODING TEST")
  decoded_full = ElixirProto.decode(encoded_full)
  decoded_sparse = ElixirProto.decode(encoded_sparse)

  IO.puts("Full user decoded: #{inspect(decoded_full)}")
  IO.puts("Sparse user decoded: #{inspect(decoded_sparse)}")

  # Verify integrity
  full_match = (full_user == decoded_full)
  sparse_match = (sparse_user == decoded_sparse)

  IO.puts("\n✅ INTEGRITY CHECK")
  IO.puts("Full user match: #{full_match}")
  IO.puts("Sparse user match: #{sparse_match}")

  if full_match and sparse_match do
    IO.puts("🎉 All tests passed!")

    # Compare with old format (manual)
    IO.puts("\n📏 SIZE COMPARISON")

    # Simulate old format
    old_format_full = {"myapp.ctx.user", [{1, 1}, {2, "Alice"}, {3, "alice@example.com"}, {4, 30}, {5, true}]}
    old_format_sparse = {"myapp.ctx.user", [{1, 1}, {2, "Alice"}]}

    old_encoded_full = old_format_full |> :erlang.term_to_binary() |> :zlib.compress()
    old_encoded_sparse = old_format_sparse |> :erlang.term_to_binary() |> :zlib.compress()

    # Plain Elixir for comparison
    plain_full = full_user |> :erlang.term_to_binary() |> :zlib.compress()
    plain_sparse = sparse_user |> :erlang.term_to_binary() |> :zlib.compress()

    IO.puts("                    | Full    | Sparse")
    IO.puts("Plain Elixir        | #{String.pad_leading("#{byte_size(plain_full)}", 4)}b   | #{String.pad_leading("#{byte_size(plain_sparse)}", 4)}b")
    IO.puts("Old ElixirProto     | #{String.pad_leading("#{byte_size(old_encoded_full)}", 4)}b   | #{String.pad_leading("#{byte_size(old_encoded_sparse)}", 4)}b")
    IO.puts("NEW ElixirProto     | #{String.pad_leading("#{byte_size(encoded_full)}", 4)}b   | #{String.pad_leading("#{byte_size(encoded_sparse)}", 4)}b")

    full_savings_vs_plain = byte_size(plain_full) - byte_size(encoded_full)
    sparse_savings_vs_plain = byte_size(plain_sparse) - byte_size(encoded_sparse)
    full_savings_vs_old = byte_size(old_encoded_full) - byte_size(encoded_full)
    sparse_savings_vs_old = byte_size(old_encoded_sparse) - byte_size(encoded_sparse)

    IO.puts("\n💰 SAVINGS:")
    IO.puts("NEW vs Plain:       | #{String.pad_leading("#{full_savings_vs_plain}", 4)}b   | #{String.pad_leading("#{sparse_savings_vs_plain}", 4)}b")
    IO.puts("NEW vs Old:         | #{String.pad_leading("#{full_savings_vs_old}", 4)}b   | #{String.pad_leading("#{sparse_savings_vs_old}", 4)}b")

    # Show the actual serialized format
    IO.puts("\n🔍 SERIALIZED FORMAT INSPECTION:")

    # Decode without compression to see the actual structure
    {schema_index, values_tuple} = encoded_full |> :zlib.uncompress() |> :erlang.binary_to_term()

    IO.puts("Schema index: #{schema_index}")
    IO.puts("Values tuple: #{inspect(values_tuple)}")
    IO.puts("Total elements: 1 (schema_index) + 1 (tuple) = 2 top-level elements")
    IO.puts("vs old format: 1 (schema_name) + #{length(elem(old_format_full, 1))} (field tuples) = #{1 + length(elem(old_format_full, 1))} elements")

  else
    IO.puts("❌ Integrity check failed!")
  end

rescue
  error ->
    IO.puts("❌ Error during testing: #{inspect(error)}")
    IO.puts("Stacktrace:")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
end