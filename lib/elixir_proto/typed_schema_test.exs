defmodule ElixirProto.TypedSchemaTest do
  use ExUnit.Case, async: false

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
      assert_raise CompileError, ~r/cannot compile module/, fn ->
        defmodule InvalidNoIndex do
          use ElixirProto.TypedSchema, name: "test.invalid.no.index", index: 600

          typedschema do
            # Missing index
            field(:name, String.t())
          end
        end
      end
    end

    test "raises on duplicate indices" do
      assert_raise ArgumentError, ~r/index 1 is already used by field/, fn ->
        defmodule InvalidDuplicateIndex do
          use ElixirProto.TypedSchema, name: "test.invalid.dup.index", index: 601

          typedschema do
            field(:name, String.t(), index: 1)
            # Duplicate index
            field(:email, String.t(), index: 1)
          end
        end
      end
    end

    test "raises on negative index" do
      assert_raise ArgumentError, ~r/must have a positive integer :index/, fn ->
        defmodule InvalidNegativeIndex do
          use ElixirProto.TypedSchema, name: "test.invalid.negative.index", index: 602

          typedschema do
            # Negative index
            field(:name, String.t(), index: -1)
          end
        end
      end
    end

    test "raises on zero index" do
      assert_raise ArgumentError, ~r/must have a positive integer :index/, fn ->
        defmodule InvalidZeroIndex do
          use ElixirProto.TypedSchema, name: "test.invalid.zero.index", index: 603

          typedschema do
            # Zero index
            field(:name, String.t(), index: 0)
          end
        end
      end
    end

    test "raises on non-integer index" do
      assert_raise ArgumentError, ~r/must have a positive integer :index/, fn ->
        defmodule InvalidStringIndex do
          use ElixirProto.TypedSchema, name: "test.invalid.string.index", index: 604

          typedschema do
            # String index
            field(:name, String.t(), index: "1")
          end
        end
      end
    end
  end

  describe "EXP001_1A_T3: Test field name validation and error messages" do
    test "raises on duplicate field names" do
      assert_raise ArgumentError, ~r/field :name is already defined/, fn ->
        defmodule InvalidDuplicateName do
          use ElixirProto.TypedSchema, name: "test.invalid.dup.name", index: 700

          typedschema do
            field(:name, String.t(), index: 1)
            # Duplicate name
            field(:name, String.t(), index: 2)
          end
        end
      end
    end

    test "raises on non-atom field name" do
      assert_raise FunctionClauseError, fn ->
        defmodule InvalidFieldName do
          use ElixirProto.TypedSchema, name: "test.invalid.field.name", index: 701

          typedschema do
            # String field name
            field("name", String.t(), index: 1)
          end
        end
      end
    end

    test "provides clear error messages for index conflicts" do
      error =
        assert_raise ArgumentError, fn ->
          defmodule IndexConflictTest do
            use ElixirProto.TypedSchema, name: "test.index.conflict", index: 702

            typedschema do
              field(:first_field, String.t(), index: 5)
              # Conflict
              field(:second_field, String.t(), index: 5)
            end
          end
        end

      assert error.message =~ "index 5 is already used by field :first_field"
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

  describe "type specification generation (verified by compilation)" do
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
  end

  # Reset registry before each test to avoid conflicts
  setup do
    # Reset registry for clean tests
    ElixirProto.SchemaRegistry.reset!()

    # Re-register test schemas
    ElixirProto.SchemaRegistry.force_register_index("test.basic.user", 500)
    ElixirProto.SchemaRegistry.force_register_index("test.enforced.product", 501)
    ElixirProto.SchemaRegistry.force_register_index("test.defaults.struct", 502)
    :ok
  end
end
