defmodule ElixirProto.SchemaRegistry do
  @moduledoc """
  Schema registry that stores schema mappings without GenServers.

  Uses persistent_term for fast, global storage that survives application restarts.
  """

  @registry_key {__MODULE__, :schemas}

  @doc """
  Callback called after module compilation to register the schema.
  """
  def register_schema(%{module: module}, _bytecode) do
    if function_exported?(module, :__schema__, 1) do
      schema_name = module.__schema__(:name)
      fields = module.__schema__(:fields)
      field_indices = module.__schema__(:field_indices)
      index_fields = module.__schema__(:index_fields)

      # Check if module has explicit schema index
      explicit_index =
        case function_exported?(module, :__schema_index__, 0) do
          true -> module.__schema_index__()
          false -> nil
        end

      # Register schema in main registry
      registry = get_registry()

      new_registry =
        Map.put(registry, schema_name, %{
          module: module,
          fields: fields,
          field_indices: field_indices,
          index_fields: index_fields
        })

      :persistent_term.put(@registry_key, new_registry)

      # Register schema index - explicit index is required
      if explicit_index do
        register_explicit_index(schema_name, explicit_index)
      else
        raise CompileError,
          description:
            "Schema '#{schema_name}' must have an explicit index parameter. Use: use ElixirProto.Schema, name: \"#{schema_name}\", index: <number>"
      end
    end
  end

  defp register_explicit_index(schema_name, explicit_index) do
    alias ElixirProto.SchemaNameRegistry

    # Check if index is already taken
    existing_name = SchemaNameRegistry.get_name(explicit_index)

    cond do
      existing_name == nil ->
        # Index is available, register it
        # First check if schema already has a different index
        current_index = SchemaNameRegistry.get_index(schema_name)

        if current_index && current_index != explicit_index do
          raise CompileError,
            description:
              "Schema '#{schema_name}' is already registered with index #{current_index}, cannot reassign to #{explicit_index}"
        end

        # Force registration with specific index
        SchemaNameRegistry.force_register_index(schema_name, explicit_index)

      existing_name == schema_name ->
        # Same schema, same index - OK
        :ok

      true ->
        # Index conflict
        raise CompileError,
          description:
            "Schema index #{explicit_index} is already assigned to '#{existing_name}', cannot assign to '#{schema_name}'"
    end
  end

  @doc """
  Get schema information by schema name.
  """
  def get_schema(schema_name) do
    registry = get_registry()
    Map.get(registry, schema_name)
  end

  @doc """
  Get schema information by module.
  """
  def get_schema_by_module(module) do
    registry = get_registry()

    Enum.find_value(registry, fn {_name, schema} ->
      if schema.module == module, do: schema
    end)
  end

  @doc """
  Get all registered schemas.
  """
  def list_schemas do
    get_registry()
  end

  defp get_registry do
    case :persistent_term.get(@registry_key, nil) do
      nil -> %{}
      registry -> registry
    end
  end
end
