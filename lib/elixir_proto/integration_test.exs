defmodule ElixirProto.IntegrationTest do
  use ExUnit.Case, async: false

  @moduledoc """
  EXP002_3A_T1: Test cross-context isolation (same indices, different contexts)
  EXP002_3A_T2: Test wire format compatibility with old data
  EXP002_3A_T3: Test complete migration of all existing tests
  """

  # Define test schemas using simplified approach (no indices)
  defmodule SimpleTypedUser do
    use ElixirProto.TypedSchema, name: "integration.typed.user"

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, enforce: true)
      field(:email, String.t() | nil, index: 3)
    end
  end

  defmodule SimpleSchemaUser do
    use ElixirProto.Schema, name: "integration.schema.user"
    defschema([:id, :name, :email])
  end

  defmodule TypedAddress do
    use ElixirProto.TypedSchema, name: "integration.typed.address"

    typedschema do
      field(:street, String.t(), index: 1, enforce: true)
      field(:city, String.t(), index: 2, enforce: true)
      field(:country, String.t(), index: 3, default: "USA")
    end
  end

  defmodule TypedUserWithAddress do
    use ElixirProto.TypedSchema, name: "integration.typed.user.address"

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, enforce: true)
      field(:address, TypedAddress.t(), index: 3)
    end
  end

  defmodule TypedDataTypes do
    use ElixirProto.TypedSchema, name: "integration.data.types"

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

  # Regular struct without ElixirProto schema (for testing error cases)
  defmodule UnknownStruct do
    defstruct [:field]
  end

  # Context 1: User Management PayloadConverter
  defmodule UserManagementConverter do
    use ElixirProto.PayloadConverter,
      mapping: [
        {1, "integration.typed.user"},
        {2, "integration.schema.user"},
        {3, "integration.data.types"}
      ]
  end

  # Context 2: Location Management PayloadConverter  
  defmodule LocationManagementConverter do
    use ElixirProto.PayloadConverter,
      mapping: [
        # Same index as users context, different schema!
        {1, "integration.typed.address"},
        {2, "integration.typed.user.address"}
      ]
  end

  # Context 3: Cross-Context PayloadConverter for testing isolation
  defmodule CrossContextConverter do
    use ElixirProto.PayloadConverter,
      mapping: [
        # Same index as other contexts
        {1, "integration.typed.user"},
        # Same index as other contexts  
        {2, "integration.typed.address"},
        {3, "integration.typed.user.address"}
      ]
  end

  # Setup function to register schemas manually in test environment
  setup do
    # Register all test schemas manually since they're defined inside test module
    ElixirProto.SchemaRegistry.register_schema(%{module: SimpleTypedUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: SimpleSchemaUser}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedAddress}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedUserWithAddress}, nil)
    ElixirProto.SchemaRegistry.register_schema(%{module: TypedDataTypes}, nil)
    :ok
  end

  describe "EXP002_3A_T1: Test cross-context isolation (same indices, different contexts)" do
    test "same indices work in different contexts without collision" do
      # Create identical structs for testing
      user = %SimpleTypedUser{id: 42, name: "Alice", email: "alice@example.com"}
      address = %TypedAddress{street: "123 Main St", city: "Portland", country: "USA"}

      # Encode with different converters using same index (1)
      user_encoded = UserManagementConverter.encode(user)
      address_encoded = LocationManagementConverter.encode(address)
      cross_user_encoded = CrossContextConverter.encode(user)

      # user_encoded and cross_user_encoded should be identical (same schema, same index)
      # address_encoded should be different (different schema)
      assert user_encoded != address_encoded
      assert user_encoded == cross_user_encoded

      # Each context should decode correctly to their respective schemas
      decoded_user = UserManagementConverter.decode(user_encoded)
      decoded_address = LocationManagementConverter.decode(address_encoded)
      decoded_cross_user = CrossContextConverter.decode(cross_user_encoded)

      assert decoded_user == user
      assert decoded_user.__struct__ == SimpleTypedUser

      assert decoded_address == address
      assert decoded_address.__struct__ == TypedAddress

      assert decoded_cross_user == user
      assert decoded_cross_user.__struct__ == SimpleTypedUser
    end

    test "context isolation can cause incorrect decoding when indices are reused" do
      user = %SimpleTypedUser{id: 1, name: "Test User", email: "test@example.com"}

      # Encode with UserManagementConverter (index 1 = user)
      encoded = UserManagementConverter.encode(user)

      # Decode with LocationManagementConverter (index 1 = address)
      # This will succeed but create an incorrect struct with user data mapped to address fields
      decoded_as_address = LocationManagementConverter.decode(encoded)

      # The decoded struct should be a TypedAddress but with user data in wrong fields
      assert decoded_as_address.__struct__ == TypedAddress
      # user.id
      assert decoded_as_address.street == 1
      # user.name  
      assert decoded_as_address.city == "Test User"
      # user.email
      assert decoded_as_address.country == "test@example.com"

      # This demonstrates why context isolation is important for data integrity
      assert decoded_as_address != user
    end

    test "same schema can be used in multiple contexts with different indices" do
      user = %SimpleTypedUser{id: 1, name: "Shared User", email: "shared@example.com"}

      # Same schema, different indices in different contexts
      # Index 1
      user_context_encoded = UserManagementConverter.encode(user)
      # Index 1
      cross_context_encoded = CrossContextConverter.encode(user)

      # Both should decode correctly in their respective contexts
      user_context_decoded = UserManagementConverter.decode(user_context_encoded)
      cross_context_decoded = CrossContextConverter.decode(cross_context_encoded)

      assert user_context_decoded == user
      assert cross_context_decoded == user
    end
  end

  describe "EXP002_3A_T2: Test wire format compatibility with old data" do
    test "wire format remains {schema_index, payload_tuple}" do
      user = %SimpleTypedUser{id: 42, name: "Alice", email: "alice@example.com"}

      encoded = UserManagementConverter.encode(user)

      # Decode manually to verify format
      {index, payload} = encoded |> :zlib.uncompress() |> :erlang.binary_to_term()

      # From mapping
      assert index == 1
      assert is_tuple(payload)
      # id, name, email
      assert tuple_size(payload) == 3
      # id
      assert elem(payload, 0) == 42
      # name
      assert elem(payload, 1) == "Alice"
      # email
      assert elem(payload, 2) == "alice@example.com"
    end

    test "context information is not stored in wire format" do
      user = %SimpleTypedUser{id: 1, name: "Context Test", email: "context@test.com"}

      # Encode with different converters
      user_encoded = UserManagementConverter.encode(user)
      cross_encoded = CrossContextConverter.encode(user)

      # Both should have identical wire format (same schema, same index)
      {index1, payload1} = user_encoded |> :zlib.uncompress() |> :erlang.binary_to_term()
      {index2, payload2} = cross_encoded |> :zlib.uncompress() |> :erlang.binary_to_term()

      # Both use index 1 for this schema
      assert index1 == index2
      # Same payload data
      assert payload1 == payload2
    end

    test "manually created old format data can be decoded" do
      # Simulate old encoded data format
      payload_data = {42, "Alice", "alice@example.com"}
      old_format_binary = {1, payload_data} |> :erlang.term_to_binary() |> :zlib.compress()

      # Should decode correctly with new PayloadConverter
      decoded = UserManagementConverter.decode(old_format_binary)

      assert decoded.__struct__ == SimpleTypedUser
      assert decoded.id == 42
      assert decoded.name == "Alice"
      assert decoded.email == "alice@example.com"
    end
  end

  describe "EXP002_3A_T3: Test complete migration of all existing tests" do
    test "TypedSchema structs serialize and deserialize correctly" do
      user = %SimpleTypedUser{id: 42, name: "Alice", email: "alice@example.com"}

      # Test encoding
      encoded = UserManagementConverter.encode(user)
      assert is_binary(encoded)

      # Test decoding
      decoded = UserManagementConverter.decode(encoded)
      assert decoded == user
      assert decoded.__struct__ == SimpleTypedUser
      assert decoded.id == 42
      assert decoded.name == "Alice"
      assert decoded.email == "alice@example.com"
    end

    test "TypedSchema works with nil optional fields" do
      user = %SimpleTypedUser{id: 1, name: "Bob", email: nil}

      encoded = UserManagementConverter.encode(user)
      decoded = UserManagementConverter.decode(encoded)

      assert decoded.email == nil
      assert decoded == user
    end

    test "TypedSchema with defaults works correctly in serialization" do
      address = %TypedAddress{street: "123 Main St", city: "Portland"}

      encoded = LocationManagementConverter.encode(address)
      decoded = LocationManagementConverter.decode(encoded)

      assert decoded.street == "123 Main St"
      assert decoded.city == "Portland"
      # Default value
      assert decoded.country == "USA"
      assert decoded == address
    end

    test "nested TypedSchema structs serialize correctly" do
      address = %TypedAddress{street: "456 Oak Ave", city: "Seattle", country: "Canada"}
      user = %TypedUserWithAddress{id: 100, name: "Charlie", address: address}

      encoded = LocationManagementConverter.encode(user)
      decoded = LocationManagementConverter.decode(encoded)

      assert decoded.id == 100
      assert decoded.name == "Charlie"
      assert decoded.address.__struct__ == TypedAddress
      assert decoded.address.street == "456 Oak Ave"
      assert decoded.address.city == "Seattle"
      assert decoded.address.country == "Canada"
      assert decoded == user
    end

    test "various data types work correctly" do
      data = %TypedDataTypes{
        string_field: "test string",
        integer_field: 42,
        float_field: 3.14,
        boolean_field: true,
        atom_field: :test_atom,
        list_field: [1, 2, 3],
        map_field: %{key: "value"}
      }

      encoded = UserManagementConverter.encode(data)
      decoded = UserManagementConverter.decode(encoded)

      assert decoded == data
      assert decoded.string_field == "test string"
      assert decoded.integer_field == 42
      assert decoded.float_field == 3.14
      assert decoded.boolean_field == true
      assert decoded.atom_field == :test_atom
      assert decoded.list_field == [1, 2, 3]
      assert decoded.map_field == %{key: "value"}
    end

    test "unknown module error handling" do
      # Create a struct not in any PayloadConverter mapping
      unknown = %UnknownStruct{field: "value"}

      assert_raise ArgumentError, ~r/Schema not found for module/, fn ->
        UserManagementConverter.encode(unknown)
      end
    end

    test "unknown index error handling" do
      # Create manually encoded data with unknown index
      fake_data = {999, {"test"}}
      encoded = fake_data |> :erlang.term_to_binary() |> :zlib.compress()

      assert_raise ArgumentError, ~r/Unknown index 999/, fn ->
        UserManagementConverter.decode(encoded)
      end
    end

    test "multiple encode/decode cycles preserve data" do
      user = %SimpleTypedUser{id: 1, name: "Alice", email: "alice@example.com"}

      # Multiple round trips
      result1 = user |> UserManagementConverter.encode() |> UserManagementConverter.decode()
      result2 = result1 |> UserManagementConverter.encode() |> UserManagementConverter.decode()
      result3 = result2 |> UserManagementConverter.encode() |> UserManagementConverter.decode()

      assert result1 == user
      assert result2 == user
      assert result3 == user
    end

    test "serialized output is compact" do
      user = %SimpleTypedUser{id: 1, name: "Compact Test", email: "compact@test.com"}

      encoded = UserManagementConverter.encode(user)

      # Should be reasonably compact (less than 200 bytes for this simple struct)
      assert byte_size(encoded) < 200

      # Should be smaller than text representation
      text_size = inspect(user) |> byte_size()
      assert byte_size(encoded) < text_size
    end

    test "encoding is deterministic" do
      # Create the same struct multiple times
      user1 = %SimpleTypedUser{id: 42, name: "Stable", email: "stable@test.com"}
      user2 = %SimpleTypedUser{id: 42, name: "Stable", email: "stable@test.com"}

      encoded1 = UserManagementConverter.encode(user1)
      encoded2 = UserManagementConverter.encode(user2)

      # Should produce identical encoded output
      assert encoded1 == encoded2

      # Both should decode to identical structs
      decoded1 = UserManagementConverter.decode(encoded1)
      decoded2 = UserManagementConverter.decode(encoded2)

      assert decoded1 == decoded2
      assert decoded1 == user1
      assert decoded2 == user2
    end
  end
end
