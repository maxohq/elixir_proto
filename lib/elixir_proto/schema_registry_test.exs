defmodule ElixirProto.SchemaRegistryTest do
  use ExUnit.Case, async: false

  alias ElixirProto.SchemaRegistry

  setup do
    # Reset registry for each test
    SchemaRegistry.reset!()
    :ok
  end

  describe "schema index registration" do
    test "assigns sequential indices to new schemas" do
      {index1, is_new1} = SchemaRegistry.get_or_create_index("user.schema")
      {index2, is_new2} = SchemaRegistry.get_or_create_index("post.schema")
      {index3, is_new3} = SchemaRegistry.get_or_create_index("comment.schema")

      assert index1 == 1
      assert index2 == 2
      assert index3 == 3
      assert is_new1 == true
      assert is_new2 == true
      assert is_new3 == true
    end

    test "returns existing index for already registered schemas" do
      {index1, _} = SchemaRegistry.get_or_create_index("test.schema")
      {index2, is_new} = SchemaRegistry.get_or_create_index("test.schema")

      assert index1 == index2
      assert is_new == false
    end

    test "get_index returns correct index" do
      {expected_index, _} = SchemaRegistry.get_or_create_index("test.schema")
      actual_index = SchemaRegistry.get_index("test.schema")

      assert actual_index == expected_index
    end

    test "get_index returns nil for unregistered schema" do
      result = SchemaRegistry.get_index("nonexistent.schema")
      assert result == nil
    end

    test "get_name returns correct name" do
      {index, _} = SchemaRegistry.get_or_create_index("test.schema")
      name = SchemaRegistry.get_name(index)

      assert name == "test.schema"
    end

    test "get_name returns nil for invalid index" do
      result = SchemaRegistry.get_name(99999)
      assert result == nil
    end
  end

  describe "registry management" do
    test "list_schemas returns all registered schemas" do
      SchemaRegistry.get_or_create_index("user.schema")
      SchemaRegistry.get_or_create_index("post.schema")

      schemas = SchemaRegistry.list_schemas()

      assert Map.get(schemas, "user.schema") == 1
      assert Map.get(schemas, "post.schema") == 2
      assert map_size(schemas) == 2
    end

    test "stats returns correct information" do
      SchemaRegistry.get_or_create_index("test.schema")

      stats = SchemaRegistry.stats()

      assert stats.total_schemas == 1
      assert stats.next_available_id == 2
      assert Map.get(stats.schemas, "test.schema") == 1
    end

    test "reset! clears all registrations" do
      SchemaRegistry.get_or_create_index("test.schema")
      SchemaRegistry.reset!()

      stats = SchemaRegistry.stats()
      assert stats.total_schemas == 0
      assert stats.next_available_id == 1
    end
  end

  describe "initialization and import/export" do
    test "initialize_with_mappings sets custom mappings" do
      mappings = %{"user.schema" => 5, "post.schema" => 10}

      result = SchemaRegistry.initialize_with_mappings(mappings)
      assert result == :ok

      assert SchemaRegistry.get_index("user.schema") == 5
      assert SchemaRegistry.get_index("post.schema") == 10

      # Next schema should get ID 11 (max + 1)
      {next_index, _} = SchemaRegistry.get_or_create_index("comment.schema")
      assert next_index == 11
    end

    test "initialize_with_mappings rejects invalid mappings" do
      invalid_mappings = %{"test.schema" => "not_a_number"}
      result = SchemaRegistry.initialize_with_mappings(invalid_mappings)
      assert result == {:error, :invalid_mappings}
    end

    test "export_registry returns complete registry state" do
      SchemaRegistry.get_or_create_index("test.schema")

      export = SchemaRegistry.export_registry()

      assert Map.get(export.registry, "test.schema") == 1
      assert export.next_id == 2
      assert %DateTime{} = export.exported_at
    end

    test "import_registry restores registry state" do
      # Create initial state
      SchemaRegistry.get_or_create_index("test1.schema")
      SchemaRegistry.get_or_create_index("test2.schema")

      # Export it
      export = SchemaRegistry.export_registry()

      # Reset and create different state
      SchemaRegistry.reset!()
      SchemaRegistry.get_or_create_index("different.schema")

      # Import original state
      SchemaRegistry.import_registry(export)

      # Verify restoration
      assert SchemaRegistry.get_index("test1.schema") == 1
      assert SchemaRegistry.get_index("test2.schema") == 2
      assert SchemaRegistry.get_index("different.schema") == nil

      stats = SchemaRegistry.stats()
      assert stats.next_available_id == 3
    end
  end

  describe "persistence across processes" do
    test "registry persists after process restart simulation" do
      # Register a schema
      {index, _} = SchemaRegistry.get_or_create_index("persistent.schema")
      assert index == 1

      # Simulate process restart by creating new process that checks registry
      task = Task.async(fn ->
        SchemaRegistry.get_index("persistent.schema")
      end)

      result = Task.await(task)
      assert result == 1
    end
  end
end