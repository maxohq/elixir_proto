defmodule ElixirProto.Schema.Test do
  use ExUnit.Case, async: false

  setup do
    # Reset registry for clean tests
    ElixirProto.SchemaRegistry.reset!()
    :ok
  end

  describe "defschema macro" do
    defmodule TestUser do
      use ElixirProto.Schema, name: "test.user", index: 10
      defschema [:id, :name, :email, :age, :active]
    end

    defmodule TestPost do
      use ElixirProto.Schema, name: "test.post", index: 11
      defschema [:id, :title, :content, :author_id, :created_at]
    end

    test "creates struct with nil defaults" do
      user = %TestUser{}
      assert user.id == nil
      assert user.name == nil
      assert user.email == nil
      assert user.age == nil
      assert user.active == nil
    end

    test "allows creating struct with values" do
      user = %TestUser{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true}
      assert user.id == 1
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
      assert user.age == 30
      assert user.active == true
    end

    test "generates schema metadata" do
      assert TestUser.__schema__(:name) == "test.user"
      assert TestUser.__schema__(:fields) == [:id, :name, :email, :age, :active]

      field_indices = TestUser.__schema__(:field_indices)
      assert field_indices[:id] == 1
      assert field_indices[:name] == 2
      assert field_indices[:email] == 3
      assert field_indices[:age] == 4
      assert field_indices[:active] == 5

      index_fields = TestUser.__schema__(:index_fields)
      assert index_fields[1] == :id
      assert index_fields[2] == :name
      assert index_fields[3] == :email
      assert index_fields[4] == :age
      assert index_fields[5] == :active
    end
  end

  describe "schema registry" do
    alias ElixirProto.Schema.Registry

    test "registers schemas automatically" do
      # Give some time for @after_compile to run
      Process.sleep(10)

      schema = Registry.get_schema("test.user")
      assert schema != nil
      assert schema.module == ElixirProto.Schema.Test.TestUser
      assert schema.fields == [:id, :name, :email, :age, :active]
      assert schema.field_indices[:name] == 2
      assert schema.index_fields[3] == :email
    end

    test "can find schema by module" do
      Process.sleep(10)

      schema = Registry.get_schema_by_module(ElixirProto.Schema.Test.TestUser)
      assert schema != nil
      assert schema.module == ElixirProto.Schema.Test.TestUser
    end

    test "returns nil for unknown schema" do
      schema = Registry.get_schema("unknown.schema")
      assert schema == nil
    end

    test "lists all schemas" do
      Process.sleep(10)

      schemas = Registry.list_schemas()
      assert is_map(schemas)
      assert Map.has_key?(schemas, "test.user")
      assert Map.has_key?(schemas, "test.post")
    end
  end
end