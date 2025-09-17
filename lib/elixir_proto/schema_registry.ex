defmodule ElixirProto.SchemaRegistry do
  @moduledoc """
  Schema registry that stores schema mappings without GenServers.

  Uses persistent_term for fast, global storage that survives application restarts.
  No longer manages schema indices - those are handled by PayloadConverter modules.
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

      # Register schema in main registry (no index management)
      registry = get_registry()

      new_registry =
        Map.put(registry, schema_name, %{
          module: module,
          fields: fields,
          field_indices: field_indices,
          index_fields: index_fields
        })

      :persistent_term.put(@registry_key, new_registry)
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
