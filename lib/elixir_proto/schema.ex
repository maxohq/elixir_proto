defmodule ElixirProto.Schema do
  @moduledoc """
  Macro module for defining ElixirProto schemas.

  This module provides the `defschema` macro that generates struct definitions
  and registers schemas in a global registry for serialization/deserialization.
  """

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    # Required explicit index
    index = Keyword.fetch!(opts, :index)

    quote do
      import ElixirProto.Schema, only: [defschema: 1]
      @schema_name unquote(name)
      @schema_index unquote(index)
    end
  end

  @doc """
  Define a schema with field mappings.

  ## Example

      defmodule User do
        use ElixirProto.Schema, name: "myapp.ctx.user", index: 1

        defschema [:id, :name, :email, :age, :active]
      end
  """
  defmacro defschema(fields) when is_list(fields) do
    quote do
      defstruct unquote(fields) |> Enum.map(&{&1, nil})

      # Register the schema when the module is compiled
      @after_compile {ElixirProto.SchemaRegistry, :register_schema}

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

      # Add schema index function if explicit index provided
      if @schema_index do
        def __schema_index__(), do: @schema_index
      end
    end
  end
end
