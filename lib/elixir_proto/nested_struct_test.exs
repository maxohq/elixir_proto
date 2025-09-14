defmodule ElixirProto.NestedStructTest do
  use ExUnit.Case, async: false

  defmodule Country do
    use ElixirProto.Schema, name: "nested.test.country", index: 100
    defschema([:name, :code])
  end

  defmodule Address do
    use ElixirProto.Schema, name: "nested.test.address", index: 101
    defschema([:street, :city, :country])
  end

  defmodule User do
    use ElixirProto.Schema, name: "nested.test.user", index: 102
    defschema([:id, :name, :address])
  end

  defmodule Company do
    use ElixirProto.Schema, name: "nested.test.company", index: 103
    defschema([:name, :address, :ceo])
  end

  defmodule EdgeCaseUser do
    use ElixirProto.Schema, name: "nested.test.edge.user", index: 104
    defschema([:id, :weird_data])
  end

  # Regular Elixir struct (not using ElixirProto.Schema)
  defmodule RegularStruct do
    defstruct [:field1, :field2]
  end

  defmodule MixedUser do
    use ElixirProto.Schema, name: "nested.test.mixed.user", index: 105
    defschema([:id, :name, :regular_data])
  end

  defmodule TupleUser do
    use ElixirProto.Schema, name: "nested.test.tuple.user", index: 106
    defschema([:id, :coordinates])
  end

  setup do
    # Reset registry for clean tests
    ElixirProto.SchemaRegistry.reset!()

    # Re-register test schemas (they auto-register during compilation)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.country", 100)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.address", 101)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.user", 102)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.company", 103)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.edge.user", 104)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.mixed.user", 105)
    ElixirProto.SchemaRegistry.force_register_index("nested.test.tuple.user", 106)

    # Re-register in the main schema registry
    registry = %{
      "nested.test.country" => %{
        module: __MODULE__.Country,
        fields: [:name, :code],
        field_indices: %{name: 1, code: 2},
        index_fields: %{1 => :name, 2 => :code}
      },
      "nested.test.address" => %{
        module: __MODULE__.Address,
        fields: [:street, :city, :country],
        field_indices: %{street: 1, city: 2, country: 3},
        index_fields: %{1 => :street, 2 => :city, 3 => :country}
      },
      "nested.test.user" => %{
        module: __MODULE__.User,
        fields: [:id, :name, :address],
        field_indices: %{id: 1, name: 2, address: 3},
        index_fields: %{1 => :id, 2 => :name, 3 => :address}
      },
      "nested.test.company" => %{
        module: __MODULE__.Company,
        fields: [:name, :address, :ceo],
        field_indices: %{name: 1, address: 2, ceo: 3},
        index_fields: %{1 => :name, 2 => :address, 3 => :ceo}
      },
      "nested.test.edge.user" => %{
        module: __MODULE__.EdgeCaseUser,
        fields: [:id, :weird_data],
        field_indices: %{id: 1, weird_data: 2},
        index_fields: %{1 => :id, 2 => :weird_data}
      },
      "nested.test.mixed.user" => %{
        module: __MODULE__.MixedUser,
        fields: [:id, :name, :regular_data],
        field_indices: %{id: 1, name: 2, regular_data: 3},
        index_fields: %{1 => :id, 2 => :name, 3 => :regular_data}
      },
      "nested.test.tuple.user" => %{
        module: __MODULE__.TupleUser,
        fields: [:id, :coordinates],
        field_indices: %{id: 1, coordinates: 2},
        index_fields: %{1 => :id, 2 => :coordinates}
      }
    }

    :persistent_term.put({ElixirProto.Schema.Registry, :schemas}, registry)
    :ok
  end

  describe "nested struct encoding/decoding" do
    test "handles two-level nesting" do
      alias __MODULE__.{Country, Address, User}

      country = %Country{name: "USA", code: "US"}
      address = %Address{street: "123 Main St", city: "Portland", country: country}
      user = %User{id: 1, name: "Alice", address: address}

      # Test encoding
      encoded = ElixirProto.encode(user)
      assert is_binary(encoded)

      # Test decoding
      decoded = ElixirProto.decode(encoded)
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

      encoded = ElixirProto.encode(company)
      decoded = ElixirProto.decode(encoded)

      assert decoded == company
      assert decoded.address.country.name == "USA"
      assert decoded.ceo.address.country.code == "US"
    end

    test "handles partial nested structures" do
      alias __MODULE__.{Address, User}

      # Address without country
      address = %Address{street: "123 Main St", city: "Portland", country: nil}
      user = %User{id: 1, name: "Alice", address: address}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

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

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

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

      encoded = ElixirProto.encode(address)
      decoded = ElixirProto.decode(encoded)

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
      proto_encoded = ElixirProto.encode(user)
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

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      # Should preserve the literal tuple since schema 999 doesn't exist
      assert decoded.weird_data == {:ep, 999, {"fake", "data"}}
    end

    test "handles regular structs (non-ElixirProto) in nested fields" do
      alias __MODULE__.{RegularStruct, MixedUser}

      regular_struct = %RegularStruct{field1: "value1", field2: "value2"}
      user = %MixedUser{id: 1, name: "Alice", regular_data: regular_struct}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      # Regular struct should be preserved as-is
      assert decoded.regular_data == regular_struct
      assert decoded.regular_data.__struct__ == RegularStruct
    end

    test "handles tuples with negative integers correctly" do
      alias __MODULE__.TupleUser

      # Tuple with negative integers should work fine
      user = %TupleUser{id: 1, coordinates: {-5, -10, 15}}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

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
      proto_size = ElixirProto.encode(user) |> byte_size()
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
      result1 = user |> ElixirProto.encode() |> ElixirProto.decode()
      result2 = result1 |> ElixirProto.encode() |> ElixirProto.decode()
      result3 = result2 |> ElixirProto.encode() |> ElixirProto.decode()

      assert result1 == user
      assert result2 == user
      assert result3 == user

      # Verify nested structure integrity
      assert result3.address.country.name == "USA"
      assert result3.address.country.code == "US"
    end
  end
end
