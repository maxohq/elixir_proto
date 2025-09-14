# Compare serialization format sizes
# Run with: mix run serialization_formats.exs

defmodule SerializationComparison do
  @schema_name "myapp.ctx.user"

  def test_data do
    %{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
  end

  def sparse_data do
    %{id: 1, name: "Alice"}
  end

  def field_indices do
    %{id: 1, name: 2, email: 3, age: 4, active: 5}
  end

  # Current ElixirProto format: list of {index, value} tuples
  def format_current(data) do
    fields = for {field, value} <- data, value != nil do
      index = Map.fetch!(field_indices(), field)
      {index, value}
    end
    {@schema_name, fields}
  end

  # Fixed-size tuple (best from our test)
  def format_tuple(data) do
    values = for i <- 1..5 do
      field = Enum.find(field_indices(), fn {_k, v} -> v == i end)
      if field do
        {field_name, _} = field
        Map.get(data, field_name)
      else
        nil
      end
    end
    {@schema_name, List.to_tuple(values)}
  end

  # Map with integer keys
  def format_map(data) do
    indexed = for {field, value} <- data, value != nil, into: %{} do
      index = Map.fetch!(field_indices(), field)
      {index, value}
    end
    {@schema_name, indexed}
  end

  # Binary format: indices as bytes + values list
  def format_binary(data) do
    non_nil = for {field, value} <- data, value != nil do
      index = Map.fetch!(field_indices(), field)
      {index, value}
    end

    {indices, values} = Enum.unzip(non_nil)
    indices_binary = :erlang.list_to_binary(indices)
    {@schema_name, {indices_binary, values}}
  end

  # Bitset format: one bit per possible field + values
  def format_bitset(data) do
    max_fields = 5
    {bits, values} = for i <- 1..max_fields, reduce: {<<>>, []} do
      {bit_acc, val_acc} ->
        field = Enum.find(field_indices(), fn {_k, v} -> v == i end)
        if field do
          {field_name, _} = field
          value = Map.get(data, field_name)
          if value != nil do
            {<<bit_acc::bitstring, 1::1>>, [value | val_acc]}
          else
            {<<bit_acc::bitstring, 0::1>>, val_acc}
          end
        else
          {<<bit_acc::bitstring, 0::1>>, val_acc}
        end
    end

    # Pad to byte boundary
    padding = 8 - rem(bit_size(bits), 8)
    padded = if padding == 8, do: bits, else: <<bits::bitstring, 0::size(padding)>>

    {@schema_name, {padded, Enum.reverse(values)}}
  end

  # Plain Elixir serialization for comparison
  def format_plain(data) do
    data
  end

  def test_format(name, formatter, data) do
    formatted = formatter.(data)
    encoded = formatted |> :erlang.term_to_binary() |> :zlib.compress()
    size = byte_size(encoded)

    IO.puts("#{String.pad_trailing(name, 20)} #{size} bytes")
    IO.puts("  Data: #{inspect(formatted, limit: :infinity)}")
    IO.puts("")

    size
  end

  def run_comparison do
    formats = [
      {"Plain Elixir", &format_plain/1},
      {"Current (tuples)", &format_current/1},
      {"Fixed tuple", &format_tuple/1},
      {"Map w/ int keys", &format_map/1},
      {"Binary indices", &format_binary/1},
      {"Bitset + values", &format_bitset/1}
    ]

    IO.puts("🔍 SERIALIZATION FORMAT SIZE COMPARISON")
    IO.puts(String.duplicate("=", 60))

    # Test with full data
    IO.puts("\n📊 FULL DATA (5 fields): #{inspect(test_data())}")
    IO.puts(String.duplicate("-", 60))

    full_sizes = for {name, formatter} <- formats do
      size = test_format(name, formatter, test_data())
      {name, size}
    end

    plain_full_size = full_sizes |> Enum.find(fn {name, _} -> name == "Plain Elixir" end) |> elem(1)

    IO.puts("FULL DATA SUMMARY:")
    for {name, size} <- Enum.sort_by(full_sizes, &elem(&1, 1)) do
      savings = plain_full_size - size
      pct = Float.round(savings / plain_full_size * 100, 1)
      status = if savings > 0, do: "✅", else: "❌"
      IO.puts("  #{status} #{String.pad_trailing(name, 18)} #{size}b (#{pct}% vs plain)")
    end

    # Test with sparse data
    IO.puts("\n📊 SPARSE DATA (2 fields): #{inspect(sparse_data())}")
    IO.puts(String.duplicate("-", 60))

    sparse_sizes = for {name, formatter} <- formats do
      size = test_format(name, formatter, sparse_data())
      {name, size}
    end

    plain_sparse_size = sparse_sizes |> Enum.find(fn {name, _} -> name == "Plain Elixir" end) |> elem(1)

    IO.puts("SPARSE DATA SUMMARY:")
    for {name, size} <- Enum.sort_by(sparse_sizes, &elem(&1, 1)) do
      savings = plain_sparse_size - size
      pct = Float.round(savings / plain_sparse_size * 100, 1)
      status = if savings > 0, do: "✅", else: "❌"
      IO.puts("  #{status} #{String.pad_trailing(name, 18)} #{size}b (#{pct}% vs plain)")
    end

    IO.puts("\n💡 KEY INSIGHTS:")

    best_full = Enum.min_by(full_sizes, &elem(&1, 1))
    best_sparse = Enum.min_by(sparse_sizes, &elem(&1, 1))

    IO.puts("• Best for full data: #{elem(best_full, 0)} (#{elem(best_full, 1)} bytes)")
    IO.puts("• Best for sparse data: #{elem(best_sparse, 0)} (#{elem(best_sparse, 1)} bytes)")

    # Check if any format beats plain for both
    winners_full = Enum.filter(full_sizes, fn {_, size} -> size < plain_full_size end)
    winners_sparse = Enum.filter(sparse_sizes, fn {_, size} -> size < plain_sparse_size end)

    if winners_full != [] do
      IO.puts("• Formats beating plain (full): #{winners_full |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")}")
    else
      IO.puts("• No formats beat plain Elixir for full data")
    end

    if winners_sparse != [] do
      IO.puts("• Formats beating plain (sparse): #{winners_sparse |> Enum.map(&elem(&1, 0)) |> Enum.join(", ")}")
    else
      IO.puts("• No formats beat plain Elixir for sparse data")
    end

    # Find schema name overhead
    schema_overhead = byte_size(@schema_name) + 3  # rough estimate for tuple wrapper
    IO.puts("• Estimated schema overhead: ~#{schema_overhead} bytes")
    IO.puts("• This explains why small/sparse data shows ElixirProto as larger!")
  end
end

SerializationComparison.run_comparison()