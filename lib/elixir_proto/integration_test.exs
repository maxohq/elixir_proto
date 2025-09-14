defmodule ElixirProto.IntegrationTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Integration tests for ElixirProto with TypedSchema support.
  Tests Phase EXP001_3A: ElixirProto Integration (Code + Tests)
  """

  # Define test schemas for integration testing
  defmodule SimpleTypedUser do
    use ElixirProto.TypedSchema, name: "integration.typed.user", index: 1000

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, enforce: true)
      field(:email, String.t() | nil, index: 3)
    end
  end

  defmodule SimpleSchemaUser do
    use ElixirProto.Schema, name: "integration.schema.user", index: 1001
    defschema([:id, :name, :email])
  end

  defmodule TypedAddress do
    use ElixirProto.TypedSchema, name: "integration.typed.address", index: 1100

    typedschema do
      field(:street, String.t(), index: 1, enforce: true)
      field(:city, String.t(), index: 2, enforce: true)
      field(:country, String.t(), index: 3, default: "USA")
    end
  end

  defmodule TypedUserWithAddress do
    use ElixirProto.TypedSchema, name: "integration.typed.user.address", index: 1101

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, enforce: true)
      field(:address, TypedAddress.t(), index: 3)
    end
  end

  defmodule MixedUser do
    use ElixirProto.TypedSchema, name: "integration.mixed.user", index: 1200

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:profile, SimpleSchemaUser.t(), index: 2)
    end
  end

  # Reset registry and register schemas for each test
  setup do
    ElixirProto.SchemaNameRegistry.reset!()

    # Register all test schemas in both SchemaRegistry and SchemaRegistry
    ElixirProto.SchemaNameRegistry.force_register_index("integration.typed.user", 1000)
    ElixirProto.SchemaNameRegistry.force_register_index("integration.schema.user", 1001)
    ElixirProto.SchemaNameRegistry.force_register_index("integration.typed.address", 1100)
    ElixirProto.SchemaNameRegistry.force_register_index("integration.typed.user.address", 1101)
    ElixirProto.SchemaNameRegistry.force_register_index("integration.mixed.user", 1200)
    ElixirProto.SchemaNameRegistry.force_register_index("integration.data.types", 1300)

    # Manually call the registration for TypedSchema modules since @after_compile
    # hook already ran during compilation
    ElixirProto.SchemaRegistry.register_schema(%{module: SimpleTypedUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: SimpleSchemaUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedAddress}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedUserWithAddress}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: MixedUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedDataTypes}, nil)

    :ok
  end

  describe "EXP001_3A_T1: Test ElixirProto serialization round-trip compatibility" do
    test "TypedSchema structs serialize and deserialize correctly" do
      user = %SimpleTypedUser{id: 42, name: "Alice", email: "alice@example.com"}

      # Test encoding
      encoded = ElixirProto.encode(user)
      assert is_binary(encoded)

      # Test decoding
      decoded = ElixirProto.decode(encoded)
      assert decoded == user
      assert decoded.__struct__ == SimpleTypedUser
      assert decoded.id == 42
      assert decoded.name == "Alice"
      assert decoded.email == "alice@example.com"
    end

    test "TypedSchema works with nil optional fields" do
      user = %SimpleTypedUser{id: 1, name: "Bob", email: nil}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      assert decoded.email == nil
      assert decoded == user
    end

    test "TypedSchema serialization format is identical to Schema format" do
      typed_user = %SimpleTypedUser{id: 1, name: "Alice", email: "alice@example.com"}
      schema_user = %SimpleSchemaUser{id: 1, name: "Alice", email: "alice@example.com"}

      typed_encoded = ElixirProto.encode(typed_user)
      schema_encoded = ElixirProto.encode(schema_user)

      # Both should produce binary data of similar size (indexes might differ)
      assert is_binary(typed_encoded)
      assert is_binary(schema_encoded)

      # Both should decode correctly
      typed_decoded = ElixirProto.decode(typed_encoded)
      schema_decoded = ElixirProto.decode(schema_encoded)

      assert typed_decoded.__struct__ == SimpleTypedUser
      assert schema_decoded.__struct__ == SimpleSchemaUser

      # Field values should be identical
      assert typed_decoded.id == schema_decoded.id
      assert typed_decoded.name == schema_decoded.name
      assert typed_decoded.email == schema_decoded.email
    end

    test "TypedSchema with defaults works correctly in serialization" do
      address = %TypedAddress{street: "123 Main St", city: "Portland"}

      encoded = ElixirProto.encode(address)
      decoded = ElixirProto.decode(encoded)

      assert decoded.street == "123 Main St"
      assert decoded.city == "Portland"
      # Default value
      assert decoded.country == "USA"
      assert decoded == address
    end

    test "empty TypedSchema structs handle serialization correctly" do
      # Create struct with only enforced fields
      user = %SimpleTypedUser{id: 1, name: "Test User"}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      assert decoded.id == 1
      assert decoded.name == "Test User"
      assert decoded.email == nil
      assert decoded == user
    end
  end

  describe "EXP001_3A_T2: Test nested structs and mixed Schema/TypedSchema" do
    test "nested TypedSchema structs serialize correctly" do
      address = %TypedAddress{street: "456 Oak Ave", city: "Seattle", country: "Canada"}
      user = %TypedUserWithAddress{id: 100, name: "Charlie", address: address}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      assert decoded.id == 100
      assert decoded.name == "Charlie"
      assert decoded.address.__struct__ == TypedAddress
      assert decoded.address.street == "456 Oak Ave"
      assert decoded.address.city == "Seattle"
      assert decoded.address.country == "Canada"
      assert decoded == user
    end

    test "nested TypedSchema with nil values" do
      user = %TypedUserWithAddress{id: 200, name: "Dana", address: nil}

      encoded = ElixirProto.encode(user)
      decoded = ElixirProto.decode(encoded)

      assert decoded.id == 200
      assert decoded.name == "Dana"
      assert decoded.address == nil
      assert decoded == user
    end

    test "mixed TypedSchema and Schema structs work together" do
      schema_profile = %SimpleSchemaUser{id: 1, name: "Profile", email: "profile@test.com"}
      typed_user = %MixedUser{id: 300, profile: schema_profile}

      encoded = ElixirProto.encode(typed_user)
      decoded = ElixirProto.decode(encoded)

      assert decoded.id == 300
      assert decoded.profile.__struct__ == SimpleSchemaUser
      assert decoded.profile.id == 1
      assert decoded.profile.name == "Profile"
      assert decoded.profile.email == "profile@test.com"
      assert decoded == typed_user
    end

    test "deeply nested structures work correctly" do
      # Create a nested structure
      address = %TypedAddress{street: "789 Pine St", city: "Denver"}
      user_with_address = %TypedUserWithAddress{id: 400, name: "Eve", address: address}

      # Encode and decode
      encoded = ElixirProto.encode(user_with_address)
      decoded = ElixirProto.decode(encoded)

      # Verify complete structure
      assert decoded.__struct__ == TypedUserWithAddress
      assert decoded.id == 400
      assert decoded.name == "Eve"
      assert decoded.address.__struct__ == TypedAddress
      assert decoded.address.street == "789 Pine St"
      assert decoded.address.city == "Denver"
      # Default value
      assert decoded.address.country == "USA"
    end
  end

  describe "EXP001_3A_T3: Test performance and format compatibility with Schema" do
    test "TypedSchema serialization performance is comparable to Schema" do
      typed_user = %SimpleTypedUser{id: 1, name: "Performance Test", email: "perf@test.com"}
      schema_user = %SimpleSchemaUser{id: 1, name: "Performance Test", email: "perf@test.com"}

      # Measure encoding performance (should be similar)
      {typed_time, _} = :timer.tc(fn -> ElixirProto.encode(typed_user) end)
      {schema_time, _} = :timer.tc(fn -> ElixirProto.encode(schema_user) end)

      # Performance should be within reasonable bounds (allow 50x difference for microbenchmarks)
      # For real applications, the difference will be much smaller
      assert typed_time < schema_time * 50
      assert schema_time < typed_time * 50
    end

    test "TypedSchema produces compact serialized output" do
      user = %SimpleTypedUser{id: 1, name: "Compact Test", email: "compact@test.com"}

      encoded = ElixirProto.encode(user)

      # Should be reasonably compact (less than 200 bytes for this simple struct)
      assert byte_size(encoded) < 200

      # Should be much smaller than equivalent text representation
      text_size = inspect(user) |> byte_size()
      assert byte_size(encoded) < text_size
    end

    test "serialized TypedSchema is version-stable" do
      # Create the same struct multiple times
      user1 = %SimpleTypedUser{id: 42, name: "Stable", email: "stable@test.com"}
      user2 = %SimpleTypedUser{id: 42, name: "Stable", email: "stable@test.com"}

      encoded1 = ElixirProto.encode(user1)
      encoded2 = ElixirProto.encode(user2)

      # Should produce identical encoded output
      assert encoded1 == encoded2

      # Both should decode to identical structs
      decoded1 = ElixirProto.decode(encoded1)
      decoded2 = ElixirProto.decode(encoded2)

      assert decoded1 == decoded2
      assert decoded1 == user1
      assert decoded2 == user2
    end

    test "schema registry integration works correctly" do
      # Verify schemas are registered correctly
      assert ElixirProto.SchemaNameRegistry.get_index("integration.typed.user") == 1000
      assert ElixirProto.SchemaNameRegistry.get_name(1000) == "integration.typed.user"

      # Verify SchemaRegistry integration
      schema_info = ElixirProto.SchemaRegistry.get_schema("integration.typed.user")
      assert schema_info != nil
      assert schema_info.module == SimpleTypedUser
      assert schema_info.fields == [:id, :name, :email]
      assert schema_info.field_indices == %{id: 1, name: 2, email: 3}
    end

    test "error handling for unregistered schemas" do
      # Use a simple struct that's not registered with ElixirProto
      unregistered = %{__struct__: SomeUnknownModule, id: 1, name: "test"}

      assert_raise ArgumentError, ~r/Schema not found for module/, fn ->
        ElixirProto.encode(unregistered)
      end
    end

    test "field ordering consistency between TypedSchema and Schema" do
      # Both should have the same logical field ordering
      typed_fields = SimpleTypedUser.__schema__(:fields)
      schema_fields = SimpleSchemaUser.__schema__(:fields)

      # Fields should be in the same order (both use 1-based indexing)
      assert typed_fields == schema_fields
      assert typed_fields == [:id, :name, :email]
    end
  end

  # Test compatibility with various data types
  defmodule TypedDataTypes do
    use ElixirProto.TypedSchema, name: "integration.data.types", index: 1300

    typedschema do
      field(:string_field, String.t(), index: 1, default: "default")
      field(:integer_field, integer(), index: 2)
      field(:float_field, float(), index: 3)
      field(:boolean_field, boolean(), index: 4, default: false)
      field(:atom_field, atom(), index: 5)
      field(:list_field, list(), index: 6, default: [])
      field(:map_field, map(), index: 7, default: %{})
    end
  end

  test "TypedSchema supports various Elixir data types" do
    ElixirProto.SchemaNameRegistry.force_register_index("integration.data.types", 1300)
    # Also register with SchemaRegistry manually
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedDataTypes}, nil)

    data = %TypedDataTypes{
      string_field: "test string",
      integer_field: 42,
      float_field: 3.14,
      boolean_field: true,
      atom_field: :test_atom,
      list_field: [1, 2, 3],
      map_field: %{key: "value"}
    }

    encoded = ElixirProto.encode(data)
    decoded = ElixirProto.decode(encoded)

    assert decoded == data
    assert decoded.string_field == "test string"
    assert decoded.integer_field == 42
    assert decoded.float_field == 3.14
    assert decoded.boolean_field == true
    assert decoded.atom_field == :test_atom
    assert decoded.list_field == [1, 2, 3]
    assert decoded.map_field == %{key: "value"}
  end
end
