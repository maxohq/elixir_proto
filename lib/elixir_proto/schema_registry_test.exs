defmodule ElixirProto.SchemaRegistryTest do
  use ExUnit.Case, async: false

  # Test schema modules for EXP002_2A_T3
  defmodule TestUser do
    use ElixirProto.Schema, name: "test.user"
    defschema([:id, :name, :email, :age, :active])
  end

  defmodule TestPost do
    use ElixirProto.Schema, name: "test.post"
    defschema([:id, :title, :content, :author_id, :created_at])
  end

  setup do
    # Set up registry with test schemas (no index management)
    registry = %{
      "test.user" => %{
        module: TestUser,
        fields: [:id, :name, :email, :age, :active],
        field_indices: %{id: 1, name: 2, email: 3, age: 4, active: 5},
        index_fields: %{1 => :id, 2 => :name, 3 => :email, 4 => :age, 5 => :active}
      },
      "test.post" => %{
        module: TestPost,
        fields: [:id, :title, :content, :author_id, :created_at],
        field_indices: %{id: 1, title: 2, content: 3, author_id: 4, created_at: 5},
        index_fields: %{1 => :id, 2 => :title, 3 => :content, 4 => :author_id, 5 => :created_at}
      }
    }

    :persistent_term.put({ElixirProto.SchemaRegistry, :schemas}, registry)

    :ok
  end

  describe "EXP002_2A_T3: Test SchemaRegistry no longer manages indices" do
    alias ElixirProto.SchemaRegistry

    test "registers schemas automatically" do
      schema = SchemaRegistry.get_schema("test.user")
      assert schema != nil
      assert schema.module == TestUser
      assert schema.fields == [:id, :name, :email, :age, :active]
      assert schema.field_indices[:name] == 2
      assert schema.index_fields[3] == :email
    end

    test "can find schema by module" do
      schema = SchemaRegistry.get_schema_by_module(TestUser)
      assert schema != nil
      assert schema.module == TestUser
    end

    test "returns nil for unknown schema" do
      schema = SchemaRegistry.get_schema("unknown.schema")
      assert schema == nil
    end

    test "lists all schemas" do
      schemas = SchemaRegistry.list_schemas()
      assert is_map(schemas)
      assert Map.has_key?(schemas, "test.user")
      assert Map.has_key?(schemas, "test.post")
    end

    test "does not manage schema indices anymore" do
      # Verify that SchemaRegistry.register_schema does not require or handle indices
      # The register_schema function should work without index management

      # Mock module info for register_schema callback
      module_info = %{module: TestUser}

      # This should not raise any errors about missing indices
      assert SchemaRegistry.register_schema(module_info, nil) == :ok

      # Verify that no index-related functions exist on SchemaRegistry
      refute function_exported?(ElixirProto.SchemaRegistry, :get_index, 1)
      refute function_exported?(ElixirProto.SchemaRegistry, :get_name, 1)
      refute function_exported?(ElixirProto.SchemaRegistry, :force_register_index, 2)
    end

    test "schema registration only stores name and field mappings" do
      schema = SchemaRegistry.get_schema("test.user")

      # Verify we still have the essential schema information
      assert schema.module == TestUser
      assert schema.fields == [:id, :name, :email, :age, :active]
      assert schema.field_indices == %{id: 1, name: 2, email: 3, age: 4, active: 5}
      assert schema.index_fields == %{1 => :id, 2 => :name, 3 => :email, 4 => :age, 5 => :active}

      # But verify no global index information is stored
      assert !Map.has_key?(schema, :schema_index)
      assert !Map.has_key?(schema, :global_index)
    end
  end
end
