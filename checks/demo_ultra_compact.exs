# Demo of ultra-compact ElixirProto format
# Schema Index + Fixed Tuple = Maximum Efficiency

# Define test schemas with explicit indices
defmodule UltraUser do
  use ElixirProto.Schema, name: "ultra.user", index: 1
  defschema UltraUser, [:id, :name, :email, :age, :active]
end

defmodule UltraPost do
  use ElixirProto.Schema, name: "ultra.post", index: 2
  defschema UltraPost, [:id, :title, :content, :author_id]
end

# Reset registry
ElixirProto.SchemaNameRegistry.reset!()

# Create test data
full_user = %UltraUser{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
sparse_user = %UltraUser{id: 1, name: "Alice"}  # Only 2/5 fields
post = %UltraPost{id: 1, title: "Hello World", content: "This is my first post!"}

IO.puts("🚀 ULTRA-COMPACT ELIXIRPROTO DEMO")
IO.puts("Format: {schema_index, values_tuple}")
IO.puts(String.duplicate("=", 50))

# Test the new format
IO.puts("\n📊 SIZE COMPARISON")

# Helper function
defmodule Sizer do
  def compare(name, data) do
    # New ElixirProto format
    proto_new = ElixirProto.encode(data)

    # Simulate old ElixirProto format
    schema_name = case data.__struct__ do
      UltraUser -> "ultra.user"
      UltraPost -> "ultra.post"
    end

    # Old format: keyword list
    old_format_data = data
    |> Map.from_struct()
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {{field, value}, index}, acc ->
      if value != nil do
        [{index, value} | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()

    old_format = {schema_name, old_format_data}
    proto_old = old_format |> :erlang.term_to_binary() |> :zlib.compress()

    # Plain Elixir
    plain = data |> :erlang.term_to_binary() |> :zlib.compress()

    new_size = byte_size(proto_new)
    old_size = byte_size(proto_old)
    plain_size = byte_size(plain)

    IO.puts("\n#{name}:")
    IO.puts("  Plain Elixir:     #{plain_size} bytes")
    IO.puts("  Old ElixirProto:  #{old_size} bytes")
    IO.puts("  NEW ElixirProto:  #{new_size} bytes")

    new_vs_plain = plain_size - new_size
    new_vs_old = old_size - new_size

    IO.puts("  NEW vs Plain:     #{new_vs_plain} bytes (#{Float.round(new_vs_plain/plain_size*100, 1)}%)")
    IO.puts("  NEW vs Old:       #{new_vs_old} bytes (#{Float.round(new_vs_old/old_size*100, 1)}%)")

    {new_size, old_size, plain_size}
  end
end

# Test all scenarios
{full_new, full_old, full_plain} = Sizer.compare("Full User (5 fields)", full_user)
{sparse_new, sparse_old, sparse_plain} = Sizer.compare("Sparse User (2 fields)", sparse_user)
{post_new, post_old, post_plain} = Sizer.compare("Post (3 fields)", post)

IO.puts("\n🎯 SUMMARY TABLE")
IO.puts("Scenario           | Plain | Old   | NEW   | Savings")
IO.puts("Full User          | #{String.pad_leading("#{full_plain}", 4)}b | #{String.pad_leading("#{full_old}", 4)}b | #{String.pad_leading("#{full_new}", 4)}b | #{String.pad_leading("#{full_plain - full_new}", 4)}b")
IO.puts("Sparse User        | #{String.pad_leading("#{sparse_plain}", 4)}b | #{String.pad_leading("#{sparse_old}", 4)}b | #{String.pad_leading("#{sparse_new}", 4)}b | #{String.pad_leading("#{sparse_plain - sparse_new}", 4)}b")
IO.puts("Post               | #{String.pad_leading("#{post_plain}", 4)}b | #{String.pad_leading("#{post_old}", 4)}b | #{String.pad_leading("#{post_new}", 4)}b | #{String.pad_leading("#{post_plain - post_new}", 4)}b")

# Show the actual format
IO.puts("\n🔍 WHAT'S STORED IN THE NEW FORMAT:")

encoded = ElixirProto.encode(full_user)
{schema_index, values_tuple} = encoded |> :zlib.uncompress() |> :erlang.binary_to_term()

IO.puts("Schema Index: #{schema_index} (instead of '#{UltraUser.__schema__(:name)}')")
IO.puts("Values Tuple: #{inspect(values_tuple)}")
IO.puts("Total overhead: 2 elements (schema_index + tuple)")

# Verify round-trip works
decoded = ElixirProto.decode(encoded)
IO.puts("\n✅ ROUND-TRIP VERIFICATION:")
IO.puts("Original: #{inspect(full_user)}")
IO.puts("Decoded:  #{inspect(decoded)}")
IO.puts("Match: #{full_user == decoded}")

# Show registry state
IO.puts("\n📋 SCHEMA REGISTRY:")
registry = ElixirProto.SchemaNameRegistry.list_schemas()
Enum.each(registry, fn {name, index} ->
  IO.puts("  #{name} → #{index}")
end)

IO.puts("\n💡 KEY IMPROVEMENTS:")
IO.puts("1. Schema names replaced with 1-2 byte indices")
IO.puts("2. Field {index, value} tuples replaced with fixed tuple")
IO.puts("3. Explicit index assignment prevents conflicts")
IO.puts("4. Ultra-compact format: {schema_index, values_tuple}")
IO.puts("5. Space savings scale with schema name length and field count")

total_savings = (full_plain + sparse_plain + post_plain) - (full_new + sparse_new + post_new)
IO.puts("\n🏆 TOTAL SAVINGS IN TEST: #{total_savings} bytes!")

# Test conflict detection
IO.puts("\n⚠️  CONFLICT DETECTION TEST:")
try do
  defmodule ConflictUser do
    use ElixirProto.Schema, name: "conflict.user", index: 1  # Same index as UltraUser
    defschema ConflictUser, [:field]
  end
  IO.puts("❌ Conflict detection failed - should have raised error!")
rescue
  error ->
    IO.puts("✅ Conflict detected: #{inspect(error)}")
end