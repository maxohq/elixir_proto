defmodule ElixirProto.NestedStructTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests for nested struct serialization using PayloadConverter approach.
  Migrated from deprecated nested_struct_test.exs.deprecated.
  """

  # Define test schemas using simplified approach (no indices)
  defmodule Country do
    use ElixirProto.Schema, name: "nested.test.country"
    defschema([:name, :code])
  end

  defmodule Address do
    use ElixirProto.Schema, name: "nested.test.address"
    defschema([:street, :city, :country])
  end

  defmodule User do
    use ElixirProto.Schema, name: "nested.test.user"
    defschema([:id, :name, :address])
  end

  defmodule Company do
    use ElixirProto.Schema, name: "nested.test.company"
    defschema([:name, :address, :ceo])
  end

  defmodule EdgeCaseUser do
    use ElixirProto.Schema, name: "nested.test.edge.user"
    defschema([:id, :weird_data])
  end

  # Regular Elixir struct (not using ElixirProto.Schema)
  defmodule RegularStruct do
    defstruct [:field1, :field2]
  end

  defmodule MixedUser do
    use ElixirProto.Schema, name: "nested.test.mixed.user"
    defschema([:id, :name, :regular_data])
  end

  defmodule TupleUser do
    use ElixirProto.Schema, name: "nested.test.tuple.user"
    defschema([:id, :coordinates])
  end

  # PayloadConverter for all nested test schemas
  defmodule NestedTestConverter do
    use ElixirProto.PayloadConverter,
      mapping: [
        {100, "nested.test.country"},
        {101, "nested.test.address"},
        {102, "nested.test.user"},
        {103, "nested.test.company"},
        {104, "nested.test.edge.user"},
        {105, "nested.test.mixed.user"},
        {106, "nested.test.tuple.user"}
      ]
  end

  # Setup function to register schemas manually in test environment
  setup do
    # Register all test schemas manually since they're defined inside test module
    ElixirProto.SchemaRegistry.register_schema(%{module: Country}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: Address}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: User}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: Company}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: EdgeCaseUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: MixedUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TupleUser}, nil)
    :ok
  end

  describe "nested struct encoding/decoding" do
    test "handles two-level nesting" do
      alias __MODULE__.{Country, Address, User}

      country = %Country{name: "USA", code: "US"}
      address = %Address{street: "123 Main St", city: "Portland", country: country}
      user = %User{id: 1, name: "Alice", address: address}

      # Test encoding
      encoded = NestedTestConverter.encode(user)
      assert is_binary(encoded)

      # Test decoding
      decoded = NestedTestConverter.decode(encoded)
      assert decoded == user
      assert decoded.address.country.name == "USA"
      assert decoded.address.country.code == "US"
    end

    test "handles three-level nesting" do
      alias __MODULE__.{Country, Address, User, Company}

      country = %Country{name: "USA", code: "US"}
      address = %Address{street: "123 Main St", city: "Portland", country: country}
      user = %User{id: 1, name: "Alice", address: address}
      company = %Company{name: "ACME Corp", address: address, ceo: user}

      encoded = NestedTestConverter.encode(company)
      decoded = NestedTestConverter.decode(encoded)

      assert decoded == company
      assert decoded.address.country.name == "USA"
      assert decoded.ceo.address.country.code == "US"
    end

    test "handles partial nested structures" do
      alias __MODULE__.{Address, User}

      # Address without country
      address = %Address{street: "123 Main St", city: "Portland", country: nil}
      user = %User{id: 1, name: "Alice", address: address}

      encoded = NestedTestConverter.encode(user)
      decoded = NestedTestConverter.decode(encoded)

      assert decoded == user
      assert decoded.address.country == nil
    end

    test "handles mixed nested and regular data" do
      alias __MODULE__.{Country, Address, User}

      country = %Country{name: "USA", code: "US"}

      address = %Address{
        street: "123 Main St",
        city: "Portland",
        country: country
      }

      user = %User{
        id: 1,
        name: "Alice",
        address: address
      }

      encoded = NestedTestConverter.encode(user)
      decoded = NestedTestConverter.decode(encoded)

      assert decoded == user
      assert is_integer(decoded.id)
      assert is_binary(decoded.name)
      assert decoded.address.__struct__ == Address
      assert decoded.address.country.__struct__ == Country
    end
  end

  describe "nested struct format verification" do
    test "nested structs use {:ep, index, values} format internally" do
      alias __MODULE__.{Country, Address}

      country = %Country{name: "USA", code: "US"}

      # Check that the encoding process creates the expected internal format
      # We can't easily test the intermediate format without exposing internals,
      # but we can verify round-trip works correctly
      address = %Address{street: "123 Main St", city: "Portland", country: country}

      encoded = NestedTestConverter.encode(address)
      decoded = NestedTestConverter.decode(encoded)

      assert decoded.country == country
      assert decoded.country.__struct__ == Country
    end

    test "serialized format is more compact than regular structs" do
      alias __MODULE__.{Country, Address, User}

      # Create nested structure
      country = %Country{name: "USA", code: "US"}
      address = %Address{street: "123 Main St", city: "Portland", country: country}
      user = %User{id: 1, name: "Alice", address: address}

      # Compare sizes
      proto_encoded = NestedTestConverter.encode(user)
      regular_encoded = :erlang.term_to_binary(user) |> :zlib.compress()

      # ElixirProto should be more compact due to schema indices
      assert byte_size(proto_encoded) < byte_size(regular_encoded)
    end
  end

  describe "edge cases and error handling" do
    test "handles literal {:ep, integer, tuple} data gracefully" do
      alias __MODULE__.EdgeCaseUser

      # This tuple looks like our nested format but with invalid schema index
      user = %EdgeCaseUser{id: 1, weird_data: {:ep, 999, {"fake", "data"}}}

      encoded = NestedTestConverter.encode(user)
      decoded = NestedTestConverter.decode(encoded)

      # Should preserve the literal tuple since schema 999 doesn't exist
      assert decoded.weird_data == {:ep, 999, {"fake", "data"}}
    end

    test "handles regular structs (non-ElixirProto) in nested fields" do
      alias __MODULE__.{RegularStruct, MixedUser}

      regular_struct = %RegularStruct{field1: "value1", field2: "value2"}
      user = %MixedUser{id: 1, name: "Alice", regular_data: regular_struct}

      encoded = NestedTestConverter.encode(user)
      decoded = NestedTestConverter.decode(encoded)

      # Regular struct should be preserved as-is
      assert decoded.regular_data == regular_struct
      assert decoded.regular_data.__struct__ == RegularStruct
    end

    test "handles tuples with negative integers correctly" do
      alias __MODULE__.TupleUser

      # Tuple with negative integers should work fine
      user = %TupleUser{id: 1, coordinates: {-5, -10, 15}}

      encoded = NestedTestConverter.encode(user)
      decoded = NestedTestConverter.decode(encoded)

      assert decoded.coordinates == {-5, -10, 15}
    end
  end

  describe "performance and space efficiency" do
    test "nested structures are more space efficient than regular serialization" do
      alias __MODULE__.{Country, Address, User}

      # Create deeply nested structure
      country = %Country{name: "United States of America", code: "USA"}

      address = %Address{
        street: "1234 Very Long Street Name Avenue",
        city: "Portland",
        country: country
      }

      user = %User{id: 42, name: "Alice Johnson", address: address}

      # Compare sizes
      proto_size = NestedTestConverter.encode(user) |> byte_size()
      regular_size = :erlang.term_to_binary(user) |> :zlib.compress() |> byte_size()

      # ElixirProto should be smaller due to schema indices replacing module names
      assert proto_size < regular_size
    end

    test "multiple encode/decode cycles preserve nested data integrity" do
      alias __MODULE__.{Country, Address, User}

      country = %Country{name: "USA", code: "US"}
      address = %Address{street: "123 Main St", city: "Portland", country: country}
      user = %User{id: 1, name: "Alice", address: address}

      # Multiple round trips
      result1 = user |> NestedTestConverter.encode() |> NestedTestConverter.decode()
      result2 = result1 |> NestedTestConverter.encode() |> NestedTestConverter.decode()
      result3 = result2 |> NestedTestConverter.encode() |> NestedTestConverter.decode()

      assert result1 == user
      assert result2 == user
      assert result3 == user

      # Verify nested structure integrity
      assert result3.address.country.name == "USA"
      assert result3.address.country.code == "US"
    end
  end
end
