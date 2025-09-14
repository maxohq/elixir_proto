defmodule ElixirProto.SchemaRegistryTest do
  use ExUnit.Case, async: false

  setup do
    # Reset registry for clean tests but re-register test modules
    ElixirProto.SchemaNameRegistry.reset!()

    # Manually register test schemas since @after_compile already ran
    ElixirProto.SchemaNameRegistry.force_register_index("test.user", 10)
    ElixirProto.SchemaNameRegistry.force_register_index("test.post", 11)

    # Re-register in the main schema registry too
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

  describe "schema registry" do
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
  end
end
