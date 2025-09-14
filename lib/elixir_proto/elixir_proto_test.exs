defmodule ElixirProtoTest do
  use ExUnit.Case, async: false

  setup do
    # Reset registry for clean tests but re-register test modules
    ElixirProto.SchemaNameRegistry.reset!()

    # Manually register test schemas since @after_compile already ran
    ElixirProto.SchemaNameRegistry.force_register_index("myapp.ctx.user", 1)
    ElixirProto.SchemaNameRegistry.force_register_index("myapp.ctx.post", 2)

    # Re-register in the main schema registry too
    registry = %{
      "myapp.ctx.user" => %{
        module: ElixirProtoTest.User,
        fields: [:id, :name, :email, :age, :active],
        field_indices: %{id: 1, name: 2, email: 3, age: 4, active: 5},
        index_fields: %{1 => :id, 2 => :name, 3 => :email, 4 => :age, 5 => :active}
      },
      "myapp.ctx.post" => %{
        module: ElixirProtoTest.Post,
        fields: [:id, :title, :content, :author_id, :created_at],
        field_indices: %{id: 1, title: 2, content: 3, author_id: 4, created_at: 5},
        index_fields: %{1 => :id, 2 => :title, 3 => :content, 4 => :author_id, 5 => :created_at}
      }
    }

    :persistent_term.put({ElixirProto.SchemaRegistry, :schemas}, registry)

    :ok
  end

  # Test schemas
  defmodule User do
    use ElixirProto.Schema, name: "myapp.ctx.user", index: 1
    defschema([:id, :name, :email, :age, :active])
  end

  defmodule Post do
    use ElixirProto.Schema, name: "myapp.ctx.post", index: 2
    defschema([:id, :title, :content, :author_id, :created_at])
  end

  # Regular struct without ElixirProto schema (for testing error cases)
  defmodule UnknownStruct do
    defstruct [:field]
  end

  describe "encode/1" do
    test "encodes struct to binary" do
      user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
      encoded = ElixirProto.encode(user)

      assert is_binary(encoded)
      assert byte_size(encoded) > 0
    end

    test "skips nil fields for space efficiency" do
      user_full = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
      user_partial = %User{id: 1, name: "Alice"}

      encoded_full = ElixirProto.encode(user_full)
      encoded_partial = ElixirProto.encode(user_partial)

      # Partial should be smaller since it skips nil fields
      assert byte_size(encoded_partial) < byte_size(encoded_full)
    end

    test "raises error for unknown schema" do
      unknown = %UnknownStruct{field: "value"}

      assert_raise ArgumentError, ~r/Schema not found for module/, fn ->
        ElixirProto.encode(unknown)
      end
    end

    test "handles various data types" do
      post = %Post{
        id: 42,
        title: "Test Post",
        content: "This is a test post with various data types",
        author_id: 1,
        created_at: ~D[2023-01-01]
      }

      encoded = ElixirProto.encode(post)
      assert is_binary(encoded)
    end
  end

  describe "decode/1" do
    test "decodes binary back to original struct" do
      original = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
      encoded = ElixirProto.encode(original)
      decoded = ElixirProto.decode(encoded)

      assert decoded == original
      assert decoded.id == 1
      assert decoded.name == "Alice"
      assert decoded.email == "alice@example.com"
      assert decoded.age == 30
      assert decoded.active == true
    end

    test "handles partial structs with nil fields" do
      original = %User{id: 1, name: "Alice"}
      encoded = ElixirProto.encode(original)
      decoded = ElixirProto.decode(encoded)

      assert decoded.id == 1
      assert decoded.name == "Alice"
      assert decoded.email == nil
      assert decoded.age == nil
      assert decoded.active == nil
    end

    test "raises error for unknown schema in encoded data" do
      # Manually create encoded data with unknown schema index
      # Use invalid schema index
      fake_data = {999, {"test"}}
      encoded = fake_data |> :erlang.term_to_binary() |> :zlib.compress()

      assert_raise ArgumentError, ~r/Schema index 999 not found/, fn ->
        ElixirProto.decode(encoded)
      end
    end

    test "handles various data types correctly" do
      original = %Post{
        id: 42,
        title: "Test Post",
        content: "This is a test post",
        author_id: 1,
        created_at: ~D[2023-01-01]
      }

      encoded = ElixirProto.encode(original)
      decoded = ElixirProto.decode(encoded)

      assert decoded == original
      assert decoded.id == 42
      assert decoded.title == "Test Post"
      assert decoded.content == "This is a test post"
      assert decoded.author_id == 1
      assert decoded.created_at == ~D[2023-01-01]
    end
  end

  describe "round-trip encoding" do
    test "multiple encode/decode cycles preserve data" do
      original = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}

      # Multiple round trips
      result1 = original |> ElixirProto.encode() |> ElixirProto.decode()
      result2 = result1 |> ElixirProto.encode() |> ElixirProto.decode()
      result3 = result2 |> ElixirProto.encode() |> ElixirProto.decode()

      assert result1 == original
      assert result2 == original
      assert result3 == original
    end

    test "works with complex nested data" do
      post = %Post{
        id: 1,
        title: "Complex Post",
        content: %{
          "text" => "Hello world",
          "metadata" => %{"tags" => ["elixir", "proto"], "count" => 42}
        },
        author_id: 123,
        created_at: DateTime.utc_now()
      }

      encoded = ElixirProto.encode(post)
      decoded = ElixirProto.decode(encoded)

      assert decoded == post
      assert decoded.content["text"] == "Hello world"
      assert decoded.content["metadata"]["tags"] == ["elixir", "proto"]
    end
  end

  describe "space efficiency" do
    test "encoded size is reasonable" do
      user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}

      # Compare with raw term_to_binary
      proto_encoded = ElixirProto.encode(user)
      raw_encoded = :erlang.term_to_binary(user)

      # ElixirProto should be reasonably sized (compression helps)
      assert byte_size(proto_encoded) > 0
      # Just ensure both work
      assert byte_size(raw_encoded) > 0
    end

    test "nil field omission saves space" do
      # email, age, active are nil
      user_with_nils = %User{id: 1, name: "Alice"}
      user_without_nils = %User{id: 1, name: "Alice", email: "", age: 0, active: false}

      encoded_with_nils = ElixirProto.encode(user_with_nils)
      encoded_without_nils = ElixirProto.encode(user_without_nils)

      # Version with nils should be smaller
      assert byte_size(encoded_with_nils) < byte_size(encoded_without_nils)
    end
  end

  describe "demonstration" do
    test "README example usage works correctly" do
      # Create test data as shown in README
      user = %User{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}

      # Serialize
      encoded = ElixirProto.encode(user)
      assert is_binary(encoded)
      assert byte_size(encoded) > 0

      # Deserialize
      decoded = ElixirProto.decode(encoded)
      assert decoded == user

      # Test the specific example from README
      assert decoded.id == 1
      assert decoded.name == "Alice"
      assert decoded.email == "alice@example.com"
      assert decoded.age == 30
      assert decoded.active == true

      # Demonstrate space efficiency with nil omission
      # Only id and name set
      user_partial = %User{id: 1, name: "Alice"}
      encoded_partial = ElixirProto.encode(user_partial)
      decoded_partial = ElixirProto.decode(encoded_partial)

      # Partial user should decode correctly with nil for missing fields
      assert decoded_partial.id == 1
      assert decoded_partial.name == "Alice"
      assert decoded_partial.email == nil
      assert decoded_partial.age == nil
      assert decoded_partial.active == nil

      # Partial encoding should be smaller
      assert byte_size(encoded_partial) < byte_size(encoded)
    end
  end
end
