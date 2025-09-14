# Test different serialization formats for ElixirProto
# Run with: mix run benchmarks/format_comparison.exs

defmodule FormatTester do
  @schema_name "myapp.ctx.user"
  @test_data %{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
  @field_indices %{id: 1, name: 2, email: 3, age: 4, active: 5}

  def plain_serialize(data) do
    data |> :erlang.term_to_binary() |> :zlib.compress()
  end

  # Current format: keyword list with tuples
  def format_keyword_list(data) do
    indexed_fields = Enum.reduce(data, [], fn {field, value}, acc ->
      if value != nil do
        index = Map.fetch!(@field_indices, field)
        [{index, value} | acc]
      else
        acc
      end
    end) |> Enum.reverse()

    {@schema_name, indexed_fields}
  end

  # Format 1: Simple list alternating index/value
  def format_flat_list(data) do
    indexed_fields = Enum.reduce(data, [], fn {field, value}, acc ->
      if value != nil do
        index = Map.fetch!(@field_indices, field)
        [value, index | acc]  # index first, then value
      else
        acc
      end
    end) |> Enum.reverse()

    {@schema_name, indexed_fields}
  end

  # Format 2: Two separate lists - indices and values
  def format_dual_lists(data) do
    {indices, values} = Enum.reduce(data, {[], []}, fn {field, value}, {idx_acc, val_acc} ->
      if value != nil do
        index = Map.fetch!(@field_indices, field)
        {[index | idx_acc], [value | val_acc]}
      else
        {idx_acc, val_acc}
      end
    end)

    {@schema_name, {Enum.reverse(indices), Enum.reverse(values)}}
  end

  # Format 3: Binary format with custom encoding
  def format_binary(data) do
    # Create a binary with field indices as bytes + values as terms
    {binary_data, values} = Enum.reduce(data, {<<>>, []}, fn {field, value}, {bin_acc, val_acc} ->
      if value != nil do
        index = Map.fetch!(@field_indices, field)
        {<<bin_acc::binary, index::8>>, [value | val_acc]}
      else
        {bin_acc, val_acc}
      end
    end)

    {@schema_name, {binary_data, Enum.reverse(values)}}
  end

  # Format 4: Map with integer keys
  def format_map(data) do
    indexed_fields = Enum.reduce(data, %{}, fn {field, value}, acc ->
      if value != nil do
        index = Map.fetch!(@field_indices, field)
        Map.put(acc, index, value)
      else
        acc
      end
    end)

    {@schema_name, indexed_fields}
  end

  # Format 5: Erlang array/tuple (fixed size, nils as :undefined)
  def format_array(data) do
    # Create array with max_index size, fill with values or :undefined
    max_index = 5
    array = Enum.reduce(1..max_index, [], fn i, acc ->
      field = Enum.find(@field_indices, fn {_k, v} -> v == i end)
      if field do
        {field_name, _} = field
        value = Map.get(data, field_name)
        [value | acc]
      else
        [:undefined | acc]
      end
    end) |> Enum.reverse() |> List.to_tuple()

    {@schema_name, array}
  end

  # Format 6: Bitstring for present fields + values list
  def format_bitstring(data) do
    max_index = 5
    {bitstring, values} = Enum.reduce(1..max_index, {<<>>, []}, fn i, {bits_acc, vals_acc} ->
      field = Enum.find(@field_indices, fn {_k, v} -> v == i end)
      if field do
        {field_name, _} = field
        value = Map.get(data, field_name)
        if value != nil do
          {<<bits_acc::bitstring, 1::1>>, [value | vals_acc]}
        else
          {<<bits_acc::bitstring, 0::1>>, vals_acc}
        end
      else
        {<<bits_acc::bitstring, 0::1>>, vals_acc}
      end
    end)

    # Pad bitstring to byte boundary
    bit_count = bit_size(bitstring)
    padding = 8 - rem(bit_count, 8)
    padded_bits = if padding == 8, do: bitstring, else: <<bitstring::bitstring, 0::size(padding)>>

    {@schema_name, {padded_bits, Enum.reverse(values)}}
  end

  def test_all_formats(data) do
    formats = %{
      "Current (keyword list)" => &format_keyword_list/1,
      "Flat list" => &format_flat_list/1,
      "Dual lists" => &format_dual_lists/1,
      "Binary indices" => &format_binary/1,
      "Map with int keys" => &format_map/1,
      "Fixed array" => &format_array/1,
      "Bitstring + values" => &format_bitstring/1
    }

    plain_data = plain_serialize(data)
    plain_size = byte_size(plain_data)

    IO.puts("🧪 SERIALIZATION FORMAT COMPARISON")
    IO.puts("Test data: #{inspect(data)}")
    IO.puts("Plain serialization: #{plain_size} bytes")
    IO.puts(String.duplicate("-", 60))

    results = Enum.map(formats, fn {name, formatter} ->
      formatted_data = formatter.(data)

      # Show what the format looks like
      IO.puts("\n#{name}:")
      IO.inspect(formatted_data, limit: :infinity)

      serialized = formatted_data |> :erlang.term_to_binary() |> :zlib.compress()
      size = byte_size(serialized)
      savings = plain_size - size
      savings_pct = if plain_size > 0, do: Float.round(savings / plain_size * 100, 1), else: 0

      IO.puts("Size: #{size} bytes, Savings: #{savings} bytes (#{savings_pct}%)")

      {name, size, savings, savings_pct}
    end)

    IO.puts("\n📊 SUMMARY (sorted by size):")
    results
    |> Enum.sort_by(fn {_, size, _, _} -> size end)
    |> Enum.each(fn {name, size, savings, pct} ->
      status = if savings > 0, do: "✅", else: "❌"
      IO.puts("#{status} #{String.pad_trailing(name, 25)} #{size}b (#{pct}% savings)")
    end)

    results
  end
end

# Test with full data
IO.puts(String.duplicate("=", 70))
IO.puts("FULL DATA TEST (5 fields populated)")
IO.puts(String.duplicate("=", 70))
test_data = %{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
full_results = FormatTester.test_all_formats(test_data)

# Test with sparse data
sparse_data = %{id: 1, name: "Alice"}
IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("SPARSE DATA TEST (2 fields populated)")
IO.puts(String.duplicate("=", 70))
sparse_results = FormatTester.test_all_formats(sparse_data)

# Performance test on best formats
IO.puts("\n🚀 PERFORMANCE TEST")
best_formats = [
  {"Current", &FormatTester.format_keyword_list/1},
  {"Bitstring", &FormatTester.format_bitstring/1},
  {"Map", &FormatTester.format_map/1}
]

Benchee.run(
  Enum.reduce(best_formats, %{}, fn {name, formatter}, acc ->
    Map.put(acc, "#{name} format", fn ->
      formatter.(test_data) |> :erlang.term_to_binary() |> :zlib.compress()
    end)
  end),
  time: 2
)