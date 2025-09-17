defmodule ElixirProto.PayloadConverter do
  @moduledoc """
  Context-scoped schema registry with centralized index mapping.

  Generates compile-time pattern matching functions for encoding/decoding.
  Eliminates global index collisions while maintaining wire format compatibility.

  ## Example Usage

      defmodule MyApp.Users.PayloadConverter do
        @mapping [
          {1, "myapp.users.user"},
          {2, "myapp.users.profile"},
          {3, "myapp.users.session"}
        ]
        
        use ElixirProto.PayloadConverter, mapping: @mapping
      end
      
      # Usage
      user = %MyApp.Users.User{id: 1, name: "Alice"}
      encoded = MyApp.Users.PayloadConverter.encode(user)
      decoded = MyApp.Users.PayloadConverter.decode(encoded)
  """

  defmacro __using__(opts) when is_list(opts) do
    mapping = Keyword.fetch!(opts, :mapping)

    # Evaluate mapping at compile time if it's an AST
    mapping =
      case mapping do
        {:@, _, [{:mapping, _, nil}]} ->
          # This is a module attribute reference, get it from the caller
          attr_value = Module.get_attribute(__CALLER__.module, :mapping)

          if attr_value == nil do
            raise CompileError,
              description:
                "Module attribute @mapping is nil. Make sure to define @mapping before using PayloadConverter."
          end

          attr_value

        literal when is_list(literal) ->
          literal

        ast ->
          # Try to evaluate the AST
          {result, _} = Code.eval_quoted(ast, [], __CALLER__)
          result
      end

    # Add nil check
    if mapping == nil do
      raise CompileError,
        description:
          "PayloadConverter mapping cannot be nil. Please provide a valid mapping list."
    end

    # Validate mapping at compile time
    validate_mapping!(mapping)

    # No need to generate multiple functions anymore - we use a single function

    # Generate decode functions for each index
    decode_functions = generate_decode_functions(mapping)

    quote do
      @mapping unquote(mapping)

      # Single encode function that handles all mappings
      unquote(generate_single_encode_function(mapping))

      # Binary decode function
      def decode(binary) when is_binary(binary) do
        {index, payload} = binary |> :zlib.uncompress() |> :erlang.binary_to_term()
        decode(index, payload)
      end

      # Index/payload decode functions that pattern match on index  
      unquote_splicing(decode_functions)

      def decode(index, _payload) do
        raise ArgumentError, "Unknown index #{index} for this PayloadConverter"
      end

      # Inspection functions
      def mapping(), do: @mapping
    end
  end

  @doc false
  defp validate_mapping!(mapping) when is_list(mapping) do
    # Check for duplicate indices
    indices = Enum.map(mapping, &elem(&1, 0))

    if length(indices) != length(Enum.uniq(indices)) do
      duplicates = indices -- Enum.uniq(indices)

      raise CompileError,
        description: "Duplicate indices in PayloadConverter mapping: #{inspect(duplicates)}"
    end

    # Check for duplicate schema names
    names = Enum.map(mapping, &elem(&1, 1))

    if length(names) != length(Enum.uniq(names)) do
      duplicates = names -- Enum.uniq(names)

      raise CompileError,
        description: "Duplicate schema names in PayloadConverter mapping: #{inspect(duplicates)}"
    end

    # Validate indices are positive integers
    invalid_indices = Enum.reject(indices, &(is_integer(&1) && &1 > 0))

    if invalid_indices != [] do
      raise CompileError,
        description: "Invalid indices (must be positive integers): #{inspect(invalid_indices)}"
    end

    # Validate schema names are strings
    invalid_names = Enum.reject(names, &is_binary/1)

    if invalid_names != [] do
      raise CompileError,
        description: "Invalid schema names (must be strings): #{inspect(invalid_names)}"
    end
  end

  @doc false
  defp generate_single_encode_function(mapping) do
    quote do
      def encode(struct) when is_struct(struct) do
        module = struct.__struct__
        schema = ElixirProto.SchemaRegistry.get_schema_by_module(module)

        if schema == nil do
          raise ArgumentError,
                "Schema not found for module #{inspect(module)}. Make sure the module uses ElixirProto.Schema or ElixirProto.TypedSchema."
        end

        schema_name = schema.module.__schema__(:name)

        # Find the index for this schema name in our mapping
        mapping_map =
          unquote(Macro.escape(Map.new(mapping, fn {index, name} -> {name, index} end)))

        index =
          case Map.get(mapping_map, schema_name) do
            nil ->
              raise ArgumentError,
                    "Schema '#{schema_name}' not found in this PayloadConverter mapping. Available: #{inspect(unquote(Enum.map(mapping, &elem(&1, 1))))}"

            index ->
              index
          end

        # Encode the struct
        fields = module.__schema__(:fields)
        values = for field <- fields, do: Map.get(struct, field)
        payload = List.to_tuple(values)
        {index, payload} |> :erlang.term_to_binary() |> :zlib.compress()
      end
    end
  end

  @doc false
  defp generate_decode_functions(mapping) do
    for {index, schema_name} <- mapping do
      quote do
        def decode(unquote(index), payload) do
          schema = ElixirProto.SchemaRegistry.get_schema(unquote(schema_name))

          if schema == nil do
            raise ArgumentError,
                  "Schema '#{unquote(schema_name)}' not found in registry. Make sure the module is loaded."
          end

          module = schema.module
          fields = schema.fields
          values = Tuple.to_list(payload)
          field_map = Enum.zip(fields, values) |> Map.new()
          struct(module, field_map)
        end
      end
    end
  end
end
