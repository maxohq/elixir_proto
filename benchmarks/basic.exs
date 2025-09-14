# ElixirProto vs Plain Term Serialization Benchmarks
#
# Run with: mix run benchmarks/basic.exs

# Define test schemas
defmodule BenchUser do
  use ElixirProto.Schema, name: "bench.user"
  defschema BenchUser, [:id, :name, :email, :age, :active, :created_at, :metadata]
end

defmodule BenchProduct do
  use ElixirProto.Schema, name: "bench.product"
  defschema BenchProduct, [:id, :name, :description, :price, :category, :in_stock, :tags, :specs]
end

# Large struct with many fields (to test field name overhead)
defmodule LargeStruct do
  use ElixirProto.Schema, name: "bench.large"

  # 50 fields to simulate a real complex struct
  defschema LargeStruct, [
    :field_01, :field_02, :field_03, :field_04, :field_05,
    :field_06, :field_07, :field_08, :field_09, :field_10,
    :field_11, :field_12, :field_13, :field_14, :field_15,
    :field_16, :field_17, :field_18, :field_19, :field_20,
    :field_21, :field_22, :field_23, :field_24, :field_25,
    :field_26, :field_27, :field_28, :field_29, :field_30,
    :field_31, :field_32, :field_33, :field_34, :field_35,
    :field_36, :field_37, :field_38, :field_39, :field_40,
    :field_41, :field_42, :field_43, :field_44, :field_45,
    :field_46, :field_47, :field_48, :field_49, :field_50
  ]
end

defmodule PlainSerializer do
  @moduledoc """
  Plain Elixir term serialization with compression for comparison
  """

  def encode(data) do
    data
    |> :erlang.term_to_binary()
    |> :zlib.compress()
  end

  def decode(binary) do
    binary
    |> :zlib.uncompress()
    |> :erlang.binary_to_term()
  end
end

# Generate test data
defmodule BenchData do
  def generate_user(id) do
    %BenchUser{
      id: id,
      name: "User#{id}",
      email: "user#{id}@example.com",
      age: 20 + rem(id, 50),
      active: rem(id, 2) == 0,
      created_at: DateTime.utc_now(),
      metadata: %{
        "signup_source" => "web",
        "preferences" => %{"theme" => "dark", "notifications" => true},
        "tags" => ["premium", "verified"]
      }
    }
  end

  def generate_user_sparse(id) do
    # Only populate some fields to test nil omission
    %BenchUser{
      id: id,
      name: "User#{id}"
      # email, age, active, created_at, metadata are nil
    }
  end

  def generate_product(id) do
    %BenchProduct{
      id: id,
      name: "Product #{id}",
      description: "This is a detailed description of product #{id} with lots of text to make it realistic",
      price: :rand.uniform(1000) / 100,
      category: Enum.random(["electronics", "books", "clothing", "home", "sports"]),
      in_stock: rem(id, 3) != 0,
      tags: ["tag1", "tag2", "bestseller"],
      specs: %{
        "weight" => "#{:rand.uniform(100)}kg",
        "dimensions" => "#{:rand.uniform(100)}x#{:rand.uniform(100)}x#{:rand.uniform(100)}cm",
        "color" => Enum.random(["red", "blue", "green", "black", "white"])
      }
    }
  end

  def generate_large_struct_full(id) do
    # Populate all 50 fields
    fields = for i <- 1..50, into: %{} do
      field_name = :"field_#{String.pad_leading("#{i}", 2, "0")}"
      {field_name, "value_#{id}_#{i}"}
    end

    struct(LargeStruct, fields)
  end

  def generate_large_struct_sparse(id) do
    # Populate only 10 out of 50 fields (20% fill rate)
    fields = for i <- 1..10, into: %{} do
      field_name = :"field_#{String.pad_leading("#{i}", 2, "0")}"
      {field_name, "value_#{id}_#{i}"}
    end

    struct(LargeStruct, fields)
  end
end

# Benchmark scenarios
IO.puts("🚀 Setting up benchmark data...")

# Single struct scenarios
user_full = BenchData.generate_user(1)
user_sparse = BenchData.generate_user_sparse(1)
product = BenchData.generate_product(1)
large_full = BenchData.generate_large_struct_full(1)
large_sparse = BenchData.generate_large_struct_sparse(1)

# Collection scenarios
users_list = Enum.map(1..100, &BenchData.generate_user/1)
users_sparse_list = Enum.map(1..100, &BenchData.generate_user_sparse/1)
products_list = Enum.map(1..50, &BenchData.generate_product/1)

IO.puts("✅ Data prepared, starting benchmarks...")

# Performance benchmarks - Individual struct encoding
Benchee.run(
  %{
    "ElixirProto.encode single user (full)" => fn -> ElixirProto.encode(user_full) end,
    "Plain.encode single user (full)" => fn -> PlainSerializer.encode(user_full) end,

    "ElixirProto.encode sparse user" => fn -> ElixirProto.encode(user_sparse) end,
    "Plain.encode sparse user" => fn -> PlainSerializer.encode(user_sparse) end,

    "ElixirProto.encode product" => fn -> ElixirProto.encode(product) end,
    "Plain.encode product" => fn -> PlainSerializer.encode(product) end,

    "ElixirProto.encode large struct (full)" => fn -> ElixirProto.encode(large_full) end,
    "Plain.encode large struct (full)" => fn -> PlainSerializer.encode(large_full) end,

    "ElixirProto.encode large struct (sparse)" => fn -> ElixirProto.encode(large_sparse) end,
    "Plain.encode large struct (sparse)" => fn -> PlainSerializer.encode(large_sparse) end
  },
  time: 3,
  memory_time: 1,
  title: "🔥 ENCODING PERFORMANCE"
)

# Collection simulation - encode many individual structs
Benchee.run(
  %{
    "ElixirProto 100 users (individual)" => fn ->
      Enum.each(users_list, &ElixirProto.encode/1)
    end,
    "Plain 100 users (individual)" => fn ->
      Enum.each(users_list, &PlainSerializer.encode/1)
    end,

    "ElixirProto 100 sparse users" => fn ->
      Enum.each(users_sparse_list, &ElixirProto.encode/1)
    end,
    "Plain 100 sparse users" => fn ->
      Enum.each(users_sparse_list, &PlainSerializer.encode/1)
    end,

    "ElixirProto 50 products" => fn ->
      Enum.each(products_list, &ElixirProto.encode/1)
    end,
    "Plain 50 products" => fn ->
      Enum.each(products_list, &PlainSerializer.encode/1)
    end
  },
  time: 3,
  memory_time: 1,
  title: "📦 COLLECTION ENCODING (Individual Structs)"
)

# Payload size analysis
IO.puts("\n📊 PAYLOAD SIZE ANALYSIS")
IO.puts(String.duplicate("=", 80))

defmodule SizeAnalyzer do
  def analyze(name, data) do
    proto_encoded = ElixirProto.encode(data)
    plain_encoded = PlainSerializer.encode(data)
    uncompressed = :erlang.term_to_binary(data)

    proto_size = byte_size(proto_encoded)
    plain_size = byte_size(plain_encoded)
    uncompressed_size = byte_size(uncompressed)

    savings = plain_size - proto_size
    savings_pct = if plain_size > 0, do: Float.round(savings / plain_size * 100, 1), else: 0

    compression_ratio = if uncompressed_size > 0, do: Float.round(plain_size / uncompressed_size * 100, 1), else: 0
    proto_compression_ratio = if uncompressed_size > 0, do: Float.round(proto_size / uncompressed_size * 100, 1), else: 0

    IO.puts("\n#{name}:")
    IO.puts("  📦 Uncompressed: #{uncompressed_size} bytes")
    IO.puts("  🗜️  Plain+gzip:   #{plain_size} bytes (#{compression_ratio}% of original)")
    IO.puts("  ⚡ ElixirProto:  #{proto_size} bytes (#{proto_compression_ratio}% of original)")
    if savings > 0 do
      IO.puts("  ✅ Proto saves:   #{savings} bytes (#{savings_pct}% smaller)")
    else
      IO.puts("  ❌ Proto costs:   #{-savings} bytes (#{-savings_pct}% larger)")
    end

    {proto_size, plain_size, savings, savings_pct}
  end
end

SizeAnalyzer.analyze("Single User (full data)", user_full)
SizeAnalyzer.analyze("Single User (sparse - only id, name)", user_sparse)
SizeAnalyzer.analyze("Single Product", product)
SizeAnalyzer.analyze("Large Struct (all 50 fields)", large_full)
SizeAnalyzer.analyze("Large Struct (only 10/50 fields)", large_sparse)

# Collection size analysis (using plain serialization for collections)
IO.puts("\n🗂️  COLLECTION SIZE ANALYSIS")
users_list_proto_sizes = Enum.map(users_list, fn user ->
  user |> ElixirProto.encode() |> byte_size()
end)
users_list_plain_sizes = Enum.map(users_list, fn user ->
  user |> PlainSerializer.encode() |> byte_size()
end)

total_proto = Enum.sum(users_list_proto_sizes)
total_plain = Enum.sum(users_list_plain_sizes)
plain_collection_size = users_list |> PlainSerializer.encode() |> byte_size()

IO.puts("100 Users - Individual encoding:")
IO.puts("  ElixirProto total: #{total_proto} bytes")
IO.puts("  Plain total:       #{total_plain} bytes")
IO.puts("  Savings:           #{total_plain - total_proto} bytes")
IO.puts("100 Users - Collection encoding (Plain only):")
IO.puts("  Plain collection:  #{plain_collection_size} bytes")
IO.puts("  vs Individual sum: #{total_plain} bytes")
IO.puts("  Collection saves:  #{total_plain - plain_collection_size} bytes")

# Field count impact analysis
IO.puts("\n📈 FIELD COUNT IMPACT ANALYSIS")
IO.puts(String.duplicate("=", 80))

field_counts = [5, 10, 20, 30, 50]

Enum.each(field_counts, fn count ->
  # Create a struct with `count` fields filled
  fields = for i <- 1..count, into: %{} do
    field_name = :"field_#{String.pad_leading("#{i}", 2, "0")}"
    {field_name, "value_#{i}"}
  end

  test_struct = struct(LargeStruct, fields)

  proto_size = test_struct |> ElixirProto.encode() |> byte_size()
  plain_size = test_struct |> PlainSerializer.encode() |> byte_size()

  savings = plain_size - proto_size
  savings_pct = if plain_size > 0, do: Float.round(savings / plain_size * 100, 1), else: 0

  IO.puts("#{count} fields: Proto=#{proto_size}b, Plain=#{plain_size}b, Savings=#{savings}b (#{savings_pct}%)")
end)

IO.puts("\n🎯 BENCHMARK SUMMARY")
IO.puts("ElixirProto shines when:")
IO.puts("  ✅ Structs have many fields (field name overhead)")
IO.puts("  ✅ Many nil/sparse fields (nil omission)")
IO.puts("  ✅ Collections of similar structs")
IO.puts("\nPlain serialization works better when:")
IO.puts("  ✅ One-off serialization of different data types")
IO.puts("  ✅ Very small structs (few fields)")

IO.puts("\n✨ Benchmarks completed!")
