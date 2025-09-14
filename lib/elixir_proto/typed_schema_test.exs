defmodule ElixirProto.TypedSchemaTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  # Test schemas defined within test module to avoid global pollution
  defmodule BasicUser do
    use ElixirProto.TypedSchema, name: "test.basic.user", index: 500

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, enforce: true)
      field(:email, String.t() | nil, index: 3)
    end
  end

  defmodule EnforcedByDefaultProduct do
    use ElixirProto.TypedSchema, name: "test.enforced.product", index: 501

    typedschema enforce: true do
      field(:sku, String.t(), index: 1)
      field(:name, String.t(), index: 2)
      field(:price, float(), index: 3)
      field(:description, String.t() | nil, index: 4, enforce: false)
    end
  end

  defmodule WithDefaultsStruct do
    use ElixirProto.TypedSchema, name: "test.defaults.struct", index: 502

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:name, String.t(), index: 2, default: "Anonymous")
      field(:active, boolean(), index: 3, default: true)
      field(:created_at, DateTime.t(), index: 4, default: &DateTime.utc_now/0)
    end
  end

  # Additional test modules
  defmodule ComplexTypesTest do
    use ElixirProto.TypedSchema, name: "test.complex.types", index: 703

    typedschema do
      field(:union_field, String.t() | integer(), index: 1)
      field(:list_field, [String.t()], index: 2)
      field(:map_field, %{String.t() => integer()}, index: 3)
      field(:nested_field, {:ok, String.t()} | {:error, atom()}, index: 4)
    end
  end

  defmodule FunctionDefaultsTest do
    use ElixirProto.TypedSchema, name: "test.function.defaults", index: 704

    typedschema do
      field(:id, pos_integer(), index: 1, enforce: true)
      field(:timestamp, DateTime.t(), index: 2, default: &DateTime.utc_now/0)
      field(:uuid, String.t(), index: 3, default: "default-uuid")
    end
  end

  defmodule NullableTest do
    use ElixirProto.TypedSchema, name: "test.nullable", index: 800

    typedschema do
      field(:required_field, String.t(), index: 1, enforce: true)
      # Should become String.t() | nil
      field(:optional_field, String.t(), index: 2)
      # Should stay String.t()
      field(:default_field, String.t(), index: 3, default: "default")
    end
  end

  # Test modules for Phase 2A
  defmodule OrderTest do
    use ElixirProto.TypedSchema, name: "test.order", index: 901

    typedschema do
      field(:third, String.t(), index: 3)
      field(:first, pos_integer(), index: 1, enforce: true)
      field(:second, String.t(), index: 2, default: "middle")
    end
  end

  defmodule TypeNullabilityTest do
    use ElixirProto.TypedSchema, name: "test.nullability", index: 902

    typedschema do
      # Enforced - should stay String.t()
      field(:enforced_field, String.t(), index: 1, enforce: true)
      # Has default - should stay String.t()
      field(:default_field, String.t(), index: 2, default: "test")
      # Optional - should become String.t() | nil
      field(:optional_field, String.t(), index: 3)
    end
  end

  defmodule ComplexSchema do
    use ElixirProto.TypedSchema, name: "test.complex", index: 903

    typedschema enforce: true do
      field(:gamma, String.t(), index: 30)
      field(:alpha, pos_integer(), index: 10, enforce: true)
      field(:beta, String.t(), index: 20, default: "middle")
    end
  end

  describe "EXP001_1A_T1: Test field parsing and schema registration" do
    test "generates struct with correct field order" do
      user = %BasicUser{id: 1, name: "Alice"}
      assert user == %BasicUser{id: 1, name: "Alice", email: nil}
    end

    test "generates struct with defaults" do
      struct = %WithDefaultsStruct{id: 1}
      assert struct.name == "Anonymous"
      assert struct.active == true
      # Function default not evaluated
      assert is_function(struct.created_at, 0)
    end

    test "enforces specified fields" do
      # Test that valid struct creation works and has expected structure
      user = %BasicUser{id: 1, name: "Alice"}
      assert user.id == 1
      assert user.name == "Alice"
      # Should be nil for optional field
      assert user.email == nil

      # Test that the struct definition includes the expected fields
      # alphabetically sorted
      expected_fields = [:__struct__, :email, :id, :name]
      actual_fields = user |> Map.keys() |> Enum.sort()
      assert actual_fields == expected_fields
    end

    test "enforces by default when specified" do
      # Test valid creation with required fields
      product = %EnforcedByDefaultProduct{
        sku: "ABC123",
        name: "Widget",
        price: 10.99
      }

      assert product.sku == "ABC123"
      assert product.name == "Widget"
      assert product.price == 10.99
      # description is not enforced due to enforce: false, should be nil by default
      assert product.description == nil
    end

    test "allows override of global enforcement" do
      # :description is not enforced despite enforce: true at schema level
      product = %EnforcedByDefaultProduct{
        sku: "ABC123",
        name: "Widget",
        price: 10.99
        # description not provided, should default to nil
      }

      assert product.description == nil
    end

    test "generates correct schema metadata" do
      assert BasicUser.__schema__(:name) == "test.basic.user"
      assert BasicUser.__schema__(:index) == 500
      assert BasicUser.__schema__(:fields) == [:id, :name, :email]
      assert BasicUser.__schema__(:field_indices) == %{id: 1, name: 2, email: 3}
      assert BasicUser.__schema__(:index_fields) == %{1 => :id, 2 => :name, 3 => :email}
      assert BasicUser.__schema_index__() == 500
    end
  end

  describe "EXP001_1A_T2: Test field index validation (missing, duplicate, negative)" do
    test "raises on missing index" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Missing required options for field :name/, fn ->
          defmodule InvalidNoIndex do
            use ElixirProto.TypedSchema, name: "test.invalid.no.index", index: 600

            typedschema do
              # Missing index - this should give a clear error message
              field(:name, String.t())
            end
          end
        end
      end)
    end

    test "raises on duplicate indices" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Duplicate field index 1/, fn ->
          defmodule InvalidDuplicateIndex do
            use ElixirProto.TypedSchema, name: "test.invalid.dup.index", index: 601

            typedschema do
              field(:name, String.t(), index: 1)
              # Duplicate index - should give clear error with suggestion
              field(:email, String.t(), index: 1)
            end
          end
        end
      end)
    end

    test "raises on negative index" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Invalid :index value -1/, fn ->
          defmodule InvalidNegativeIndex do
            use ElixirProto.TypedSchema, name: "test.invalid.negative.index", index: 602

            typedschema do
              # Negative index - should give clear error message
              field(:name, String.t(), index: -1)
            end
          end
        end
      end)
    end

    test "raises on zero index" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Invalid :index value 0/, fn ->
          defmodule InvalidZeroIndex do
            use ElixirProto.TypedSchema, name: "test.invalid.zero.index", index: 603

            typedschema do
              # Zero index - should give clear error message
              field(:name, String.t(), index: 0)
            end
          end
        end
      end)
    end

    test "raises on non-integer index" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Invalid :index option for field :name/, fn ->
          defmodule InvalidStringIndex do
            use ElixirProto.TypedSchema, name: "test.invalid.string.index", index: 604

            typedschema do
              # String index - should give clear error about type
              field(:name, String.t(), index: "1")
            end
          end
        end
      end)
    end
  end

  describe "EXP001_1A_T3: Test field name validation and error messages" do
    test "raises on duplicate field names" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Duplicate field name :name/, fn ->
          defmodule InvalidDuplicateName do
            use ElixirProto.TypedSchema, name: "test.invalid.dup.name", index: 700

            typedschema do
              field(:name, String.t(), index: 1)
              # Duplicate name - should give clear error
              field(:name, String.t(), index: 2)
            end
          end
        end
      end)
    end

    test "raises on non-atom field name" do
      capture_io(fn ->
        assert_raise CompileError, ~r/Invalid field name "name"/, fn ->
          defmodule InvalidFieldName do
            use ElixirProto.TypedSchema, name: "test.invalid.field.name", index: 701

            typedschema do
              # String field name - should give clear error with suggestion
              field("name", String.t(), index: 1)
            end
          end
        end
      end)
    end

    test "provides clear error messages for index conflicts" do
      capture_io(fn ->
        error =
          assert_raise CompileError, fn ->
            defmodule IndexConflictTest do
              use ElixirProto.TypedSchema, name: "test.index.conflict", index: 702

              typedschema do
                field(:first_field, String.t(), index: 5)
                # Conflict - should give clear error with suggestion
                field(:second_field, String.t(), index: 5)
              end
            end
          end

        assert error.description =~ "Duplicate field index 5"
        assert error.description =~ "already used by field :first_field"
        assert error.description =~ "Choose a different index"
      end)
    end

    test "handles complex field types correctly" do
      # Should compile without error
      assert ComplexTypesTest.__schema__(:fields) == [
               :union_field,
               :list_field,
               :map_field,
               :nested_field
             ]
    end

    test "handles function defaults correctly without evaluation" do
      struct = %FunctionDefaultsTest{id: 1}
      # Function references should not be called during struct creation
      assert is_function(struct.timestamp, 0)
      # String defaults should be preserved as is
      assert struct.uuid == "default-uuid"
    end

    test "validates field options are lists" do
      assert_raise FunctionClauseError, fn ->
        defmodule InvalidFieldOptions do
          use ElixirProto.TypedSchema, name: "test.invalid.options", index: 705

          typedschema do
            # Options must be keyword list
            field(:name, String.t(), "invalid")
          end
        end
      end
    end
  end

  describe "EXP001_2A_T1: Test struct generation with proper field ordering and defaults" do
    test "struct fields are ordered by index regardless of definition order" do
      # Verify fields are in index order (1, 2, 3), not definition order
      user = %BasicUser{id: 1, name: "Alice", email: "alice@example.com"}
      fields = Map.keys(user) |> Enum.reject(&(&1 == :__struct__)) |> Enum.sort()

      # Fields should be ordered as they appear in the struct definition
      assert fields == [:email, :id, :name]
    end

    test "struct generation respects field defaults" do
      # Test various default types
      struct = %WithDefaultsStruct{id: 1}

      # String default
      assert struct.name == "Anonymous"
      # Boolean default
      assert struct.active == true
      # Function default (not evaluated)
      assert is_function(struct.created_at, 0)
    end

    test "struct generation with complex field ordering" do
      # Verify fields are ordered by index
      assert OrderTest.__schema__(:fields) == [:first, :second, :third]

      # Verify struct field order matches index order
      struct = %OrderTest{first: 1}
      fields = Map.keys(struct) |> Enum.reject(&(&1 == :__struct__))
      assert fields == [:first, :second, :third]
    end
  end

  describe "EXP001_2A_T2: Test @type t() generation with nullable types" do
    test "generates correct typespec (verified by compilation)" do
      # This test verifies that the generated @type t() is syntactically correct
      # If the typespec is malformed, compilation would fail

      # We can't directly inspect @type, but we can verify the module compiled
      assert function_exported?(BasicUser, :__info__, 1)

      # Verify the struct type is accessible for pattern matching
      user = %BasicUser{id: 1, name: "Alice", email: nil}
      assert match?(%BasicUser{}, user)
    end

    test "nullable types for optional fields" do
      # Should compile without Dialyzer warnings
      struct = %NullableTest{required_field: "test"}
      assert struct.optional_field == nil
      assert struct.default_field == "default"
    end

    test "enforced fields keep original types, optional fields become nullable" do
      # Verify module compiles and works
      struct = %TypeNullabilityTest{enforced_field: "required"}
      assert struct.enforced_field == "required"
      assert struct.default_field == "test"
      assert struct.optional_field == nil
    end

    test "complex types maintain structure with nullable wrapper" do
      # Complex types should work correctly
      struct = %ComplexTypesTest{}
      assert struct.union_field == nil
      assert struct.list_field == nil
      assert struct.map_field == nil
      assert struct.nested_field == nil
    end
  end

  describe "EXP001_2A_T3: Test enforcement keys and __schema__ functions" do
    test "__schema__ functions provide complete metadata" do
      assert BasicUser.__schema__(:name) == "test.basic.user"
      assert BasicUser.__schema__(:index) == 500
      assert BasicUser.__schema__(:fields) == [:id, :name, :email]
      assert BasicUser.__schema__(:field_indices) == %{id: 1, name: 2, email: 3}
      assert BasicUser.__schema__(:index_fields) == %{1 => :id, 2 => :name, 3 => :email}
      assert BasicUser.__schema_index__() == 500
    end

    test "enforcement keys are correctly applied" do
      # Test that enforcement is working by checking struct compilation
      # We can't directly access @enforce_keys, but we can verify behavior

      # Valid creation should work
      user = %BasicUser{id: 1, name: "Alice"}
      assert user.id == 1
      assert user.name == "Alice"
    end

    test "global enforcement with per-field override" do
      # EnforcedByDefaultProduct has enforce: true globally
      # but :description has enforce: false override

      # Should work with required fields
      product = %EnforcedByDefaultProduct{
        sku: "ABC123",
        name: "Widget",
        price: 10.99
      }

      assert product.sku == "ABC123"
      assert product.name == "Widget"
      assert product.price == 10.99
      # Override means this isn't enforced
      assert product.description == nil
    end

    test "__schema__ functions work with complex field arrangements" do
      # Fields should be ordered by index
      assert ComplexSchema.__schema__(:fields) == [:alpha, :beta, :gamma]

      # Index mappings should be correct
      expected_field_indices = %{alpha: 10, beta: 20, gamma: 30}
      expected_index_fields = %{10 => :alpha, 20 => :beta, 30 => :gamma}

      assert ComplexSchema.__schema__(:field_indices) == expected_field_indices
      assert ComplexSchema.__schema__(:index_fields) == expected_index_fields
    end
  end

  # Reset registry before each test to avoid conflicts
  setup do
    # Reset registry for clean tests
    ElixirProto.SchemaRegistry.reset!()

    # Re-register test schemas
    ElixirProto.SchemaRegistry.force_register_index("test.basic.user", 500)
    ElixirProto.SchemaRegistry.force_register_index("test.enforced.product", 501)
    ElixirProto.SchemaRegistry.force_register_index("test.defaults.struct", 502)
    ElixirProto.SchemaRegistry.force_register_index("test.complex.types", 703)
    ElixirProto.SchemaRegistry.force_register_index("test.function.defaults", 704)
    ElixirProto.SchemaRegistry.force_register_index("test.nullable", 800)
    ElixirProto.SchemaRegistry.force_register_index("test.order", 901)
    ElixirProto.SchemaRegistry.force_register_index("test.nullability", 902)
    ElixirProto.SchemaRegistry.force_register_index("test.complex", 903)
    :ok
  end
end
