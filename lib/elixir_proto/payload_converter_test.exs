defmodule ElixirProto.PayloadConverterTest do
  use ExUnit.Case, async: true
  doctest ElixirProto.PayloadConverter

  describe "EXP002_1A_T1: PayloadConverter mapping validation and error messages" do
    test "validates mapping has no duplicate indices" do
      assert_raise CompileError, ~r/Duplicate indices.*\[1\]/, fn ->
        defmodule TestDuplicateIndices do
          use ElixirProto.PayloadConverter,
            mapping: [
              {1, "schema.one"},
              {1, "schema.two"}
            ]
        end
      end
    end

    test "validates mapping has no duplicate schema names" do
      assert_raise CompileError, ~r/Duplicate schema names.*\["schema.same"\]/, fn ->
        defmodule TestDuplicateNames do
          use ElixirProto.PayloadConverter,
            mapping: [
              {1, "schema.same"},
              {2, "schema.same"}
            ]
        end
      end
    end

    test "validates indices are positive integers" do
      assert_raise CompileError, ~r/Invalid indices.*\[0/, fn ->
        defmodule TestInvalidIndices do
          use ElixirProto.PayloadConverter,
            mapping: [
              {0, "schema.zero"},
              {-1, "schema.negative"}
            ]
        end
      end
    end

    test "validates schema names are strings" do
      assert_raise CompileError, ~r/Invalid schema names.*\[:not_string, 123\]/, fn ->
        defmodule TestInvalidNames do
          use ElixirProto.PayloadConverter,
            mapping: [
              {1, :not_string},
              {2, 123}
            ]
        end
      end
    end

    test "accepts valid mapping" do
      defmodule TestValidMapping do
        use ElixirProto.PayloadConverter,
          mapping: [
            {1, "test.user"},
            {2, "test.product"},
            {10, "test.order"}
          ]
      end

      assert TestValidMapping.mapping() == [
               {1, "test.user"},
               {2, "test.product"},
               {10, "test.order"}
             ]
    end
  end

  describe "EXP002_1A_T2: Generated encode functions pattern match correctly" do
    # Set up test schemas
    defmodule TestUser do
      use ElixirProto.Schema, name: "test.user.pc", index: 200
      defschema([:id, :name, :email])
    end

    defmodule TestProduct do
      use ElixirProto.Schema, name: "test.product.pc", index: 201
      defschema([:id, :sku, :price])
    end

    defmodule UnknownStruct do
      defstruct([:id])
    end

    defmodule AnotherTestUser do
      use ElixirProto.Schema, name: "another.user.pc", index: 202
      defschema([:id, :name])
    end

    defmodule TestConverter do
      use ElixirProto.PayloadConverter,
        mapping: [
          {1, "test.user.pc"},
          {2, "test.product.pc"}
        ]
    end

    test "encodes known structs correctly" do
      user = %TestUser{id: 1, name: "Alice", email: "alice@example.com"}
      encoded = TestConverter.encode(user)

      # Should be compressed binary
      assert is_binary(encoded)

      # Decompress and verify format
      {index, payload} = encoded |> :zlib.uncompress() |> :erlang.binary_to_term()
      assert index == 1
      assert payload == {1, "Alice", "alice@example.com"}
    end

    test "encodes different struct types with different indices" do
      user = %TestUser{id: 1, name: "Alice", email: "alice@example.com"}
      product = %TestProduct{id: 1, sku: "ABC123", price: 99.99}

      user_encoded = TestConverter.encode(user)
      product_encoded = TestConverter.encode(product)

      # Different structs should have different indices
      {user_index, _} = user_encoded |> :zlib.uncompress() |> :erlang.binary_to_term()
      {product_index, _} = product_encoded |> :zlib.uncompress() |> :erlang.binary_to_term()

      assert user_index == 1
      assert product_index == 2
    end

    test "raises error for unknown struct" do
      unknown = %UnknownStruct{id: 1}

      assert_raise ArgumentError, ~r/Schema not found for module.*UnknownStruct/, fn ->
        TestConverter.encode(unknown)
      end
    end

    test "raises error for schema not in mapping" do
      user = %AnotherTestUser{id: 1, name: "Bob"}

      assert_raise ArgumentError,
                   ~r/Schema 'another.user.pc' not found in this PayloadConverter mapping/,
                   fn ->
                     TestConverter.encode(user)
                   end
    end
  end

  describe "EXP002_1A_T3: Generated decode functions pattern match correctly" do
    # Use the same test schemas and converter from previous test
    alias ElixirProto.PayloadConverterTest.TestUser
    alias ElixirProto.PayloadConverterTest.TestProduct
    alias ElixirProto.PayloadConverterTest.TestConverter

    test "decodes binary data back to correct struct" do
      user = %TestUser{id: 1, name: "Alice", email: "alice@example.com"}
      encoded = TestConverter.encode(user)
      decoded = TestConverter.decode(encoded)

      assert decoded == user
      assert decoded.__struct__ == TestUser
    end

    test "decodes different struct types correctly" do
      user = %TestUser{id: 1, name: "Alice", email: "alice@example.com"}
      product = %TestProduct{id: 1, sku: "ABC123", price: 99.99}

      user_encoded = TestConverter.encode(user)
      product_encoded = TestConverter.encode(product)

      user_decoded = TestConverter.decode(user_encoded)
      product_decoded = TestConverter.decode(product_encoded)

      assert user_decoded == user
      assert product_decoded == product
    end

    test "decodes index/payload tuple directly" do
      # Simulate payload as if it came from wire format
      payload = {1, "Alice", "alice@example.com"}
      decoded = TestConverter.decode(1, payload)

      expected = %TestUser{id: 1, name: "Alice", email: "alice@example.com"}
      assert decoded == expected
    end

    test "raises error for unknown index" do
      assert_raise ArgumentError, ~r/Unknown index 999 for this PayloadConverter/, fn ->
        TestConverter.decode(999, {})
      end
    end

    test "raises error for schema not found in registry" do
      # Create a mapping with a schema that doesn't exist
      defmodule TestMissingSchemaConverter do
        use ElixirProto.PayloadConverter,
          mapping: [
            {1, "missing.schema"}
          ]
      end

      assert_raise ArgumentError, ~r/Schema 'missing.schema' not found in registry/, fn ->
        TestMissingSchemaConverter.decode(1, {})
      end
    end

    test "handles nil values in payload correctly" do
      payload = {1, nil, "alice@example.com"}
      decoded = TestConverter.decode(1, payload)

      expected = %TestUser{id: 1, name: nil, email: "alice@example.com"}
      assert decoded == expected
    end
  end
end
