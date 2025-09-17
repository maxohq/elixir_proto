defmodule ElixirProto.TypedSchema do
  @moduledoc """
  TypedStruct-inspired macro for ElixirProto with name-only registration.

  Indices are now managed by PayloadConverter modules, not individual schemas.
  This module provides a `typedschema` macro that combines the compact serialization
  benefits of ElixirProto.Schema with type specifications and explicit field indices
  for better developer experience and deterministic serialization order.
  """

  # Module attributes for accumulating field definitions
  @typedschema_accumulating_attrs [
    # Field definitions for defstruct
    :ts_fields,
    # Field index mappings
    :ts_field_indices,
    # Type specifications
    :ts_types,
    # Enforced field names
    :ts_enforce_keys
  ]

  defmacro __using__(opts) when is_list(opts) do
    schema_name = Keyword.fetch!(opts, :name)
    # No longer require index parameter

    quote do
      # Import typedschema macro
      import ElixirProto.TypedSchema, only: [typedschema: 1, typedschema: 2, field: 2, field: 3]

      # Store schema metadata
      @ts_schema_name unquote(schema_name)

      # Initialize accumulating attributes
      Enum.each(unquote(@typedschema_accumulating_attrs), fn attr ->
        Module.register_attribute(__MODULE__, attr, accumulate: true)
      end)

      @before_compile ElixirProto.TypedSchema
    end
  end

  @doc """
  Define a typed schema block with explicit field indices.

  ## Options
  - `enforce: true` - enforce all fields by default (can be overridden per field)

  ## Example
      typedschema do
        field :id, pos_integer(), index: 1, enforce: true
        field :name, String.t(), index: 2, enforce: true
        field :email, String.t() | nil, index: 3, default: nil
      end
  """
  defmacro typedschema(do: block) do
    quote do
      # Store global options
      @ts_enforce_by_default false

      # Execute the schema definition block
      unquote(block)
    end
  end

  defmacro typedschema(opts, do: block) when is_list(opts) do
    quote do
      # Store global options
      @ts_enforce_by_default unquote(!!opts[:enforce])

      # Execute the schema definition block
      unquote(block)
    end
  end

  @doc """
  Define a field in the typed schema.

  ## Options
  - `index: pos_integer()` - Required field index for serialization order
  - `enforce: boolean()` - Whether this field is required (overrides global setting)
  - `default: any()` - Default value (can be a function reference like &DateTime.utc_now/0)

  ## Examples
      field :id, pos_integer(), index: 1, enforce: true
      field :name, String.t(), index: 2, enforce: true
      field :created_at, DateTime.t(), index: 3, default: &DateTime.utc_now/0
      field :email, String.t() | nil, index: 4  # Optional, defaults to nil
  """
  defmacro field(name, type, opts) when is_atom(name) and is_list(opts) do
    quote bind_quoted: [name: name, type: Macro.escape(type), opts: opts] do
      ElixirProto.TypedSchema.__field__(name, type, opts, __MODULE__)
    end
  end

  # Handle non-atom field names explicitly
  defmacro field(name, type, opts) when is_list(opts) do
    quote bind_quoted: [name: name, type: Macro.escape(type), opts: opts] do
      ElixirProto.TypedSchema.__field__(name, type, opts, __MODULE__)
    end
  end

  @doc """
  This version of field/2 is called when the required options are missing.
  It provides a clear error message for better developer experience.
  """
  defmacro field(name, type) do
    name_str =
      case name do
        name when is_atom(name) -> inspect(name)
        _ -> "#{inspect(name)}"
      end

    raise CompileError,
      description: """
      Missing required options for field #{name_str}.

      TypedSchema fields require explicit field indices and options.

      Expected format:
          field #{name_str}, #{Macro.to_string(type)}, index: <positive_integer>

      Example:
          field #{name_str}, #{Macro.to_string(type)}, index: 1, enforce: true

      Available options:
      - index: pos_integer() - REQUIRED field index for serialization order
      - enforce: boolean() - Whether this field is required (optional)
      - default: any() - Default value (optional)

      For more information, see: ElixirProto.TypedSchema documentation
      """
  end

  @doc false
  def __field__(name, type, opts, module) when is_atom(name) do
    # Get current field definitions to check for duplicates
    existing_fields = Module.get_attribute(module, :ts_fields) || []
    existing_indices = Module.get_attribute(module, :ts_field_indices) || []

    # Validate field index is provided and unique
    index = opts[:index]

    cond do
      is_nil(index) ->
        raise CompileError,
          description: """
          Missing required :index option for field #{inspect(name)}.

          Every TypedSchema field must have an explicit positive integer index.

          Fix:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: <positive_integer>

          Example:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: 1
          """

      not is_integer(index) ->
        raise CompileError,
          description: """
          Invalid :index option for field #{inspect(name)}.

          Expected: positive integer
          Got: #{inspect(index)} (#{if is_map(index) and Map.has_key?(index, :__struct__), do: inspect(index.__struct__), else: typeof(index)})

          Fix:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: <positive_integer>

          Example:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: 1
          """

      index < 1 ->
        raise CompileError,
          description: """
          Invalid :index value #{index} for field #{inspect(name)}.

          Field indices must be positive integers (>= 1) to ensure proper serialization.

          Fix:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: <positive_integer>

          Example:
              field #{inspect(name)}, #{Macro.to_string(type)}, index: 1
          """

      true ->
        :ok
    end

    # Check for duplicate field names
    if Enum.any?(existing_fields, fn {existing_name, _} -> existing_name == name end) do
      raise CompileError,
        description: """
        Duplicate field name #{inspect(name)} in TypedSchema.

        Each field must have a unique name within the schema.

        Current fields: #{existing_fields |> Enum.map(&elem(&1, 0)) |> Enum.map(&inspect/1) |> Enum.join(", ")}

        Solution: Choose a different field name or remove the duplicate definition.
        """
    end

    # Check for duplicate indices
    if Enum.any?(existing_indices, fn {_, existing_index} -> existing_index == index end) do
      existing_field = Enum.find(existing_indices, fn {_, idx} -> idx == index end) |> elem(0)

      raise CompileError,
        description: """
        Duplicate field index #{index} in TypedSchema.

        Index #{index} is already used by field #{inspect(existing_field)}.

        Each field must have a unique positive integer index for proper serialization.

        Current field indices:
        #{existing_indices |> Enum.map(fn {field, idx} -> "  #{inspect(field)}: #{idx}" end) |> Enum.join("\n")}

        Solution: Choose a different index for field #{inspect(name)}.

        Example:
            field #{inspect(name)}, #{Macro.to_string(type)}, index: #{(existing_indices |> Enum.map(&elem(&1, 1)) |> Enum.max()) + 1}
        """
    end

    # Determine if field should be enforced (defaults to false - opt-in only)
    enforce_by_default = Module.get_attribute(module, :ts_enforce_by_default) || false
    has_default = Keyword.has_key?(opts, :default)

    enforce =
      case opts[:enforce] do
        nil ->
          # Only enforce if explicitly requested at schema level AND no default provided
          enforce_by_default && !has_default

        explicit ->
          !!explicit
      end

    # Store field definition
    Module.put_attribute(module, :ts_fields, {name, opts[:default]})
    Module.put_attribute(module, :ts_field_indices, {name, index})

    # Determine type nullability
    nullable_type =
      if enforce || has_default do
        # Type as specified
        type
      else
        # Make nullable for optional fields
        quote(do: unquote(type) | nil)
      end

    Module.put_attribute(module, :ts_types, {name, nullable_type})

    # Add to enforce keys if required
    if enforce do
      Module.put_attribute(module, :ts_enforce_keys, name)
    end
  end

  def __field__(name, type, _opts, _module) do
    raise CompileError,
      description: """
      Invalid field name #{inspect(name)} in TypedSchema.

      Field names must be atoms (not strings, numbers, or other types).

      Got: #{inspect(name)} (#{if is_map(name) and Map.has_key?(name, :__struct__), do: inspect(name.__struct__), else: typeof(name)})
      Expected: atom

      Fix:
          field #{name |> to_string() |> String.trim("\"") |> String.to_atom() |> inspect()}, #{Macro.to_string(type)}, index: <positive_integer>

      Example:
          field :my_field, #{Macro.to_string(type)}, index: 1
      """
  end

  # Helper function to get type name for non-struct types
  defp typeof(val) when is_binary(val), do: :string
  defp typeof(val) when is_integer(val), do: :integer
  defp typeof(val) when is_float(val), do: :float
  defp typeof(val) when is_list(val), do: :list
  defp typeof(val) when is_tuple(val), do: :tuple
  defp typeof(_), do: :unknown

  # Generate final struct and type definitions
  defmacro __before_compile__(env) do
    module = env.module

    # Get accumulated field data
    fields = Module.get_attribute(module, :ts_fields) |> Enum.reverse()
    field_indices = Module.get_attribute(module, :ts_field_indices) |> Enum.reverse() |> Map.new()
    types = Module.get_attribute(module, :ts_types) |> Enum.reverse()
    enforce_keys = Module.get_attribute(module, :ts_enforce_keys) |> Enum.reverse()

    schema_name = Module.get_attribute(module, :ts_schema_name)

    # Sort fields by index for consistent struct definition
    sorted_fields =
      Enum.sort_by(fields, fn {name, _default} ->
        Map.get(field_indices, name, 999)
      end)

    # Create index_fields map (reverse of field_indices)
    index_fields = field_indices |> Enum.map(fn {k, v} -> {v, k} end) |> Map.new()

    quote do
      # Generate struct with enforcement
      @enforce_keys unquote(enforce_keys)
      defstruct unquote(Macro.escape(sorted_fields))

      # Generate type specification
      @type t() :: %__MODULE__{unquote_splicing(types)}

      # Generate schema functions for ElixirProto compatibility
      def __schema__(:name), do: unquote(schema_name)
      def __schema__(:fields), do: unquote(Enum.map(sorted_fields, &elem(&1, 0)))
      def __schema__(:field_indices), do: unquote(Macro.escape(field_indices))
      def __schema__(:index_fields), do: unquote(Macro.escape(index_fields))

      # Register with main schema registry for serialization using after_compile hook
      @after_compile {ElixirProto.SchemaRegistry, :register_schema}
    end
  end
end
