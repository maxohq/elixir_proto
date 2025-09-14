defmodule ElixirProto.Schema do
  @moduledoc """
  Macro module for defining ElixirProto schemas.

  This module provides the `defschema` macro that generates struct definitions
  and registers schemas in a global registry for serialization/deserialization.
  """

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)

    quote do
      import ElixirProto.Schema, only: [defschema: 2]
      @schema_name unquote(name)
    end
  end

  @doc """
  Define a schema with field mappings.

  ## Example

      defmodule User do
        use ElixirProto.Schema, name: "myapp.ctx.user"

        defschema User, [:id, :name, :email, :age, :active]
      end
  """
  defmacro defschema(_struct_name, fields) when is_list(fields) do
    quote do
      defstruct unquote(fields) |> Enum.map(&{&1, nil})

      # Register the schema when the module is compiled
      @after_compile {ElixirProto.Schema.Registry, :register_schema}

      def __schema__(:name), do: @schema_name
      def __schema__(:fields), do: unquote(fields)
      def __schema__(:field_indices) do
        unquote(fields)
        |> Enum.with_index(1)
        |> Map.new(fn {field, index} -> {field, index} end)
      end
      def __schema__(:index_fields) do
        unquote(fields)
        |> Enum.with_index(1)
        |> Map.new(fn {field, index} -> {index, field} end)
      end
    end
  end
end

defmodule ElixirProto.Schema.Registry do
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

      registry = get_registry()

      new_registry = Map.put(registry, schema_name, %{
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