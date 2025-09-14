defmodule ElixirProto do
  @moduledoc """
  A compact serialization library for Elixir that stores field indices instead of field names.

  ElixirProto combines the robustness of Erlang's term serialization with the space efficiency
  of index-based field storage. Instead of serializing field names repeatedly, it stores only
  field indices and uses schema information during deserialization.
  """

  alias ElixirProto.Schema.Registry

  @doc """
  Encode a struct to compressed binary format.

  The encoding process:
  1. Extract struct module and fields
  2. Convert to indexed format using schema registry
  3. Skip nil fields for space efficiency
  4. Serialize with Erlang terms
  5. Compress with zlib

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
    field_indices = schema.field_indices

    # Convert struct to indexed format, skipping nil fields
    indexed_fields =
      struct
      |> Map.from_struct()
      |> Enum.reduce([], fn {field, value}, acc ->
        if value != nil do
          index = Map.fetch!(field_indices, field)
          [{index, value} | acc]
        else
          acc
        end
      end)
      |> Enum.reverse()

    # Create the serializable format
    serializable_data = {schema_name, indexed_fields}

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
  3. Extract schema name
  4. Look up schema in registry
  5. Reconstruct struct using field mappings

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
    {schema_name, indexed_fields} =
      encoded_binary
      |> :zlib.uncompress()
      |> :erlang.binary_to_term()

    # Look up schema
    schema = Registry.get_schema(schema_name)

    if schema == nil do
      raise ArgumentError, "Schema '#{schema_name}' not found in registry. Make sure all required modules are loaded."
    end

    module = schema.module
    index_fields = schema.index_fields

    # Convert indexed fields back to field map
    field_map =
      indexed_fields
      |> Enum.reduce(%{}, fn {index, value}, acc ->
        field = Map.fetch!(index_fields, index)
        Map.put(acc, field, value)
      end)

    # Create struct with all fields (nil for missing ones)
    all_fields = schema.fields
    complete_field_map = Enum.reduce(all_fields, %{}, fn field, acc ->
      Map.put(acc, field, Map.get(field_map, field))
    end)

    struct(module, complete_field_map)
  end
end
