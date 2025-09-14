defmodule ElixirProto do
  @moduledoc """
  A compact serialization library for Elixir that stores field indices instead of field names.

  ElixirProto combines the robustness of Erlang's term serialization with the space efficiency
  of index-based field storage. Instead of serializing field names repeatedly, it stores only
  field indices and uses schema information during deserialization.
  """

  alias ElixirProto.Schema.Registry
  alias ElixirProto.SchemaRegistry

  @doc """
  Encode a struct to compressed binary format.

  The encoding process:
  1. Extract struct module and fields
  2. Get pre-registered schema index for ultra-compact storage
  3. Convert to fixed tuple format (most efficient)
  4. Skip nil fields for space efficiency
  5. Serialize with Erlang terms
  6. Compress with zlib

  ## Examples

      iex> defmodule TestUser do
      ...>   use ElixirProto.Schema, name: "test.user"
      ...>   defschema TestUser, [:id, :name]
      ...> end
      iex> user = %TestUser{id: 1, name: "Alice"}
      iex> encoded = ElixirProto.encode(user)
      iex> is_binary(encoded)
      true

  """
  def encode(%module{} = struct) do
    schema = Registry.get_schema_by_module(module)

    if schema == nil do
      raise ArgumentError, "Schema not found for module #{inspect(module)}. Make sure the module uses ElixirProto.Schema."
    end

    schema_name = schema.module.__schema__(:name)
    max_fields = length(schema.fields)

    # Get schema index (must be pre-registered)
    schema_index = SchemaRegistry.get_index(schema_name)

    if schema_index == nil do
      raise ArgumentError, "Schema index not found for '#{schema_name}'. Make sure the schema is registered with an explicit index."
    end

    # Convert to fixed tuple format with nested struct support
    values = Enum.map(1..max_fields, fn i ->
      field_name = Map.get(schema.index_fields, i)
      if field_name do
        field_value = Map.get(Map.from_struct(struct), field_name)
        encode_field_value(field_value)
      else
        nil
      end
    end)

    # Create ultra-compact format: {schema_index, tuple_of_values}
    serializable_data = {schema_index, List.to_tuple(values)}

    # Serialize and compress
    serializable_data
    |> :erlang.term_to_binary()
    |> :zlib.compress()
  end

  @doc """
  Decode compressed binary back to struct.

  The decoding process:
  1. Decompress with zlib
  2. Convert to terms
  3. Extract schema index
  4. Look up schema name by index
  5. Reconstruct struct from fixed tuple

  ## Examples

      iex> defmodule TestUser do
      ...>   use ElixirProto.Schema, name: "test.user"
      ...>   defschema TestUser, [:id, :name]
      ...> end
      iex> encoded = ElixirProto.encode(%TestUser{id: 1, name: "Alice"})
      iex> decoded = ElixirProto.decode(encoded)
      iex> decoded.id
      1
      iex> decoded.name
      "Alice"

  """
  def decode(encoded_binary) when is_binary(encoded_binary) do
    # Decompress and deserialize
    {schema_index, values_tuple} =
      encoded_binary
      |> :zlib.uncompress()
      |> :erlang.binary_to_term()

    # Look up schema name by index
    schema_name = SchemaRegistry.get_name(schema_index)

    if schema_name == nil do
      raise ArgumentError, "Schema index #{schema_index} not found in registry. Schema may have been registered after encoding."
    end

    # Look up schema by name
    schema = Registry.get_schema(schema_name)

    if schema == nil do
      raise ArgumentError, "Schema '#{schema_name}' not found in registry. Make sure all required modules are loaded."
    end

    module = schema.module
    fields = schema.fields

    # Convert tuple back to field map
    values_list = Tuple.to_list(values_tuple)

    field_map = fields
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {field_name, index}, acc ->
      value = Enum.at(values_list, index)
      decoded_value = decode_field_value(value)  # Handle nested structs
      Map.put(acc, field_name, decoded_value)
    end)

    struct(module, field_map)
  end

  @doc false
  # Helper function to encode field values, detecting nested ElixirProto structs
  defp encode_field_value(%module{} = nested_struct) do
    case Registry.get_schema_by_module(module) do
      nil ->
        # Not an ElixirProto struct, keep as-is
        nested_struct

      schema ->
        # This is a nested ElixirProto struct - encode it compactly
        schema_name = schema.module.__schema__(:name)
        nested_schema_index = SchemaRegistry.get_index(schema_name)

        if nested_schema_index == nil do
          # Schema not registered, keep as regular struct
          nested_struct
        else
          # Encode nested struct values recursively
          max_fields = length(schema.fields)
          nested_values = Enum.map(1..max_fields, fn i ->
            field_name = Map.get(schema.index_fields, i)
            if field_name do
              field_value = Map.get(Map.from_struct(nested_struct), field_name)
              encode_field_value(field_value)  # Recursive for deeper nesting
            else
              nil
            end
          end)

          # Return nested format: {:ep, schema_index, values_tuple}
          {:ep, nested_schema_index, List.to_tuple(nested_values)}
        end
    end
  end

  defp encode_field_value(other_value), do: other_value

  @doc false
  # Helper function to decode field values, detecting nested ElixirProto markers
  defp decode_field_value({:ep, schema_index, values_tuple}) do
    case SchemaRegistry.get_name(schema_index) do
      nil ->
        # Invalid schema index - treat as literal tuple data
        {:ep, schema_index, values_tuple}

      schema_name ->
        case Registry.get_schema(schema_name) do
          nil ->
            # Schema not found - treat as literal tuple data
            {:ep, schema_index, values_tuple}

          schema ->
            # Valid nested ElixirProto struct - reconstruct it
            module = schema.module
            fields = schema.fields

            # Convert tuple back to field map, recursively decoding nested values
            values_list = Tuple.to_list(values_tuple)
            field_map = fields
            |> Enum.with_index()
            |> Enum.reduce(%{}, fn {field_name, index}, acc ->
              value = Enum.at(values_list, index)
              decoded_value = decode_field_value(value)  # Recursive for deeper nesting
              Map.put(acc, field_name, decoded_value)
            end)

            struct(module, field_map)
        end
    end
  end

  defp decode_field_value(other_value), do: other_value
end
