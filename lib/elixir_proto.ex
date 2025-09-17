defmodule ElixirProto do
  @moduledoc """
  A compact serialization library for Elixir that stores field indices instead of field names.

  ElixirProto combines the robustness of Erlang's term serialization with the space efficiency
  of index-based field storage. Instead of serializing field names repeatedly, it stores only
  field indices and uses schema information during deserialization.

  ## DEPRECATED - Use PayloadConverter modules instead

  The global encode/decode functions in this module are deprecated. 
  Use context-scoped PayloadConverter modules for better organization and to prevent index collisions.
  """

  @doc """
  Encode a struct to compressed binary format.

  ## DEPRECATED - Use PayloadConverter modules instead

  This function is deprecated in favor of context-scoped PayloadConverter modules.

  See: ElixirProto.PayloadConverter for the new approach.

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
  @deprecated "Use PayloadConverter modules instead"
  def encode(%_module{} = _struct) do
    raise RuntimeError, """
    Global encode/decode functions are no longer supported.

    Use PayloadConverter modules instead:

    defmodule MyApp.MyContext.PayloadConverter do
      @mapping [
        {1, "schema_name_here"}
      ]
      use ElixirProto.PayloadConverter, mapping: @mapping
    end

    Then use: MyApp.MyContext.PayloadConverter.encode(struct)
    """
  end

  @doc """
  Decode compressed binary back to struct.

  ## DEPRECATED - Use PayloadConverter modules instead

  This function is deprecated in favor of context-scoped PayloadConverter modules.

  See: ElixirProto.PayloadConverter for the new approach.

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
  @deprecated "Use PayloadConverter modules instead"
  def decode(encoded_binary) when is_binary(encoded_binary) do
    raise RuntimeError, """
    Global encode/decode functions are no longer supported.

    Use PayloadConverter modules instead:

    defmodule MyApp.MyContext.PayloadConverter do
      @mapping [
        {1, "schema_name_here"}
      ]
      use ElixirProto.PayloadConverter, mapping: @mapping
    end

    Then use: MyApp.MyContext.PayloadConverter.decode(binary)
    """
  end
end
