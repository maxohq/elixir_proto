# Compare serialization format sizes with current ElixirProto implementation
# Run with: mix run checks/serialization_formats.exs

# Define test schemas
defmodule TestUser do
  use ElixirProto.Schema, name: "test.user", index: 1
  defschema([:id, :name, :email, :age, :active])
end

defmodule PlainUser do
  defstruct [:id, :name, :email, :age, :active]
end

defmodule SerializationComparison do
  def test_data do
    %TestUser{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
  end

  def sparse_data do
    %TestUser{id: 1, name: "Alice"}
  end

  def plain_test_data do
    %PlainUser{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
  end

  def plain_sparse_data do
    %PlainUser{id: 1, name: "Alice"}
  end

  # Current ElixirProto format: {schema_index, fixed_tuple}
  def format_elixirproto(data) do
    ElixirProto.encode(data)
  end

  # Plain Elixir struct serialization for comparison
  def format_plain_struct(plain_data) do
    plain_data |> :erlang.term_to_binary() |> :zlib.compress()
  end

  # Raw map serialization
  def format_plain_map(data) do
    map_data = Map.from_struct(data)
    map_data |> :erlang.term_to_binary() |> :zlib.compress()
  end

  # JSON-style approach (simulate)
  def format_json_style(data) do
    # Simulate JSON serialization overhead with string keys
    map_data = for {k, v} <- Map.from_struct(data), v != nil, into: %{} do
      {Atom.to_string(k), v}
    end
    map_data |> :erlang.term_to_binary() |> :zlib.compress()
  end

  def test_format(name, formatter, data) do
    try do
      encoded = formatter.(data)
      size = byte_size(encoded)

      IO.puts("#{String.pad_trailing(name, 25)} #{size} bytes")

      # Show decoded data for ElixirProto to verify round-trip
      if name == "ElixirProto" do
        decoded = ElixirProto.decode(encoded)
        IO.puts("  Round-trip: #{inspect(decoded, limit: :infinity)}")
      end
      IO.puts("")

      size
    catch
      error ->
        IO.puts("#{String.pad_trailing(name, 25)} ERROR: #{inspect(error)}")
        IO.puts("")
        999999  # Large number to show it failed
    end
  end

  def run_comparison do
    # Reset and setup schema registry
    ElixirProto.SchemaNameRegistry.reset!()
    ElixirProto.SchemaNameRegistry.force_register_index("test.user", 1)

    IO.puts("🔍 ELIXIRPROTO SERIALIZATION SIZE COMPARISON")
    IO.puts(String.duplicate("=", 70))

    # Test with full data
    IO.puts("\n📊 FULL DATA (5 fields)")
    IO.puts("ElixirProto: #{inspect(test_data(), limit: :infinity)}")
    IO.puts("Plain:       #{inspect(plain_test_data(), limit: :infinity)}")
    IO.puts(String.duplicate("-", 70))

    elixirproto_full = test_format("ElixirProto", &format_elixirproto/1, test_data())
    plain_struct_full = test_format("Plain Struct", &format_plain_struct/1, plain_test_data())
    plain_map_full = test_format("Plain Map", &format_plain_map/1, test_data())
    json_style_full = test_format("JSON-style (string keys)", &format_json_style/1, test_data())

    full_results = [
      {"ElixirProto", elixirproto_full},
      {"Plain Struct", plain_struct_full},
      {"Plain Map", plain_map_full},
      {"JSON-style", json_style_full}
    ]

    IO.puts("FULL DATA SUMMARY:")
    for {name, size} <- Enum.sort_by(full_results, &elem(&1, 1)) do
      baseline_size = plain_struct_full
      savings = baseline_size - size
      pct = if baseline_size > 0, do: Float.round(savings / baseline_size * 100, 1), else: 0
      status = if savings > 0, do: "✅", else: if savings == 0, do: "➡️", else: "❌"
      IO.puts("  #{status} #{String.pad_trailing(name, 25)} #{size}b (#{pct}% vs Plain Struct)")
    end

    # Test with sparse data
    IO.puts("\n📊 SPARSE DATA (2 fields)")
    IO.puts("ElixirProto: #{inspect(sparse_data(), limit: :infinity)}")
    IO.puts("Plain:       #{inspect(plain_sparse_data(), limit: :infinity)}")
    IO.puts(String.duplicate("-", 70))

    elixirproto_sparse = test_format("ElixirProto", &format_elixirproto/1, sparse_data())
    plain_struct_sparse = test_format("Plain Struct", &format_plain_struct/1, plain_sparse_data())
    plain_map_sparse = test_format("Plain Map", &format_plain_map/1, sparse_data())
    json_style_sparse = test_format("JSON-style (string keys)", &format_json_style/1, sparse_data())

    sparse_results = [
      {"ElixirProto", elixirproto_sparse},
      {"Plain Struct", plain_struct_sparse},
      {"Plain Map", plain_map_sparse},
      {"JSON-style", json_style_sparse}
    ]

    IO.puts("SPARSE DATA SUMMARY:")
    for {name, size} <- Enum.sort_by(sparse_results, &elem(&1, 1)) do
      baseline_size = plain_struct_sparse
      savings = baseline_size - size
      pct = if baseline_size > 0, do: Float.round(savings / baseline_size * 100, 1), else: 0
      status = if savings > 0, do: "✅", else: if savings == 0, do: "➡️", else: "❌"
      IO.puts("  #{status} #{String.pad_trailing(name, 25)} #{size}b (#{pct}% vs Plain Struct)")
    end

    # Analysis
    IO.puts("\n💡 KEY INSIGHTS:")

    full_savings = plain_struct_full - elixirproto_full
    sparse_savings = plain_struct_sparse - elixirproto_sparse

    if full_savings > 0 do
      pct = Float.round(full_savings / plain_struct_full * 100, 1)
      IO.puts("• ElixirProto saves #{full_savings} bytes (#{pct}%) on full data")
    else
      pct = Float.round(abs(full_savings) / plain_struct_full * 100, 1)
      IO.puts("• ElixirProto uses #{abs(full_savings)} bytes (#{pct}%) more on full data")
    end

    if sparse_savings > 0 do
      pct = Float.round(sparse_savings / plain_struct_sparse * 100, 1)
      IO.puts("• ElixirProto saves #{sparse_savings} bytes (#{pct}%) on sparse data")
    else
      pct = Float.round(abs(sparse_savings) / plain_struct_sparse * 100, 1)
      IO.puts("• ElixirProto uses #{abs(sparse_savings)} bytes (#{pct}%) more on sparse data")
    end

    IO.puts("• Schema index overhead: 1 byte (integer) vs ~8+ bytes (schema name string)")
    IO.puts("• Fixed tuple format: Always 5 positions vs dynamic field count")
    IO.puts("• Compression efficiency improves with larger/repeated data")

    # Show registry stats
    IO.puts("\n📋 SCHEMA REGISTRY STATS:")
    stats = ElixirProto.SchemaNameRegistry.stats()
    IO.puts("• Total schemas: #{stats.total_schemas}")
    IO.puts("• Registered schemas: #{inspect(stats.schemas)}")
  end
end

SerializationComparison.run_comparison()