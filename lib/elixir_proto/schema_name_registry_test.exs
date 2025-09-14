defmodule ElixirProto.SchemaNameRegistryTest do
  use ExUnit.Case, async: false

  alias ElixirProto.SchemaNameRegistry

  setup do
    # Reset registry for each test
    SchemaNameRegistry.reset!()
    :ok
  end

  describe "schema index registration" do
    test "force registers schemas with explicit indices" do
      SchemaNameRegistry.force_register_index("user.schema", 1)
      SchemaNameRegistry.force_register_index("post.schema", 2)
      SchemaNameRegistry.force_register_index("comment.schema", 3)

      assert SchemaNameRegistry.get_index("user.schema") == 1
      assert SchemaNameRegistry.get_index("post.schema") == 2
      assert SchemaNameRegistry.get_index("comment.schema") == 3
    end

    test "returns existing index for already registered schemas" do
      SchemaNameRegistry.force_register_index("test.schema", 5)
      index = SchemaNameRegistry.get_index("test.schema")

      assert index == 5
    end

    test "get_index returns correct index for schema name" do
      SchemaNameRegistry.force_register_index("test.schema", 42)
      expected_index = SchemaNameRegistry.get_index("test.schema")

      assert expected_index == 42
    end
  end

  describe "get_name/1" do
    test "returns schema name for valid index" do
      SchemaNameRegistry.force_register_index("test.schema", 7)
      index = SchemaNameRegistry.get_index("test.schema")

      assert SchemaNameRegistry.get_name(index) == "test.schema"
    end

    test "returns nil for unknown index" do
      assert SchemaNameRegistry.get_name(999) == nil
    end
  end

  describe "get_index/1" do
    test "returns nil for unknown schema" do
      assert SchemaNameRegistry.get_index("unknown.schema") == nil
    end
  end

  describe "list_schemas/0" do
    test "lists all registered schemas" do
      SchemaNameRegistry.force_register_index("user.schema", 1)
      SchemaNameRegistry.force_register_index("post.schema", 2)

      schemas = SchemaNameRegistry.list_schemas()
      assert Map.get(schemas, "user.schema") == 1
      assert Map.get(schemas, "post.schema") == 2
    end
  end

  describe "reset!/0" do
    test "clears all registered schemas" do
      SchemaNameRegistry.force_register_index("test.schema", 1)
      assert SchemaNameRegistry.get_index("test.schema") == 1

      SchemaNameRegistry.reset!()
      assert SchemaNameRegistry.get_index("test.schema") == nil
    end
  end

  describe "stats/0" do
    test "returns registry statistics" do
      SchemaNameRegistry.force_register_index("test1.schema", 1)
      SchemaNameRegistry.force_register_index("test2.schema", 2)

      stats = SchemaNameRegistry.stats()
      assert stats.total_schemas == 2
      # next_available_id should be higher than max registered index
      assert stats.next_available_id >= 3
      assert Map.get(stats.schemas, "test1.schema") == 1

      SchemaNameRegistry.force_register_index("different.schema", 10)
      stats = SchemaNameRegistry.stats()
      assert stats.next_available_id >= 11
    end
  end

  describe "export_registry/0 and import_registry/1" do
    test "exports and imports registry data" do
      SchemaNameRegistry.force_register_index("persistent.schema", 1)
      index = SchemaNameRegistry.get_index("persistent.schema")

      # Export
      export_data = SchemaNameRegistry.export_registry()
      assert Map.get(export_data.registry, "persistent.schema") == index
      assert export_data.next_id > 1
      assert is_struct(export_data.exported_at, DateTime)

      # Reset and import
      SchemaNameRegistry.reset!()
      assert SchemaNameRegistry.get_index("persistent.schema") == nil

      SchemaNameRegistry.import_registry(export_data)
      assert SchemaNameRegistry.get_index("persistent.schema") == index
    end
  end

  describe "force_register_index/2" do
    test "registers schema with specific index" do
      SchemaNameRegistry.force_register_index("custom.schema", 42)

      assert SchemaNameRegistry.get_index("custom.schema") == 42
      assert SchemaNameRegistry.get_name(42) == "custom.schema"
    end

    test "updates next_id when registering high index" do
      SchemaNameRegistry.force_register_index("high.schema", 100)

      stats = SchemaNameRegistry.stats()
      assert stats.next_available_id >= 101
    end

    test "allows overwriting existing mappings" do
      SchemaNameRegistry.force_register_index("overwrite.schema", 1)
      assert SchemaNameRegistry.get_index("overwrite.schema") == 1

      SchemaNameRegistry.force_register_index("overwrite.schema", 2)
      assert SchemaNameRegistry.get_index("overwrite.schema") == 2
    end
  end
end
