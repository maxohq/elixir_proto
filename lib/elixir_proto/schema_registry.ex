defmodule ElixirProto.SchemaRegistry do
  @moduledoc """
  Global schema name → index registry for ultra-compact serialization.

  Maps schema names to stable numeric IDs to eliminate string overhead.
  Uses persistent_term for fast lookups and persistence across restarts.
  """

  @registry_key {__MODULE__, :schema_index}
  @next_id_key {__MODULE__, :next_id}

  @doc """
  Get schema index by name (returns nil if not found)
  """
  def get_index(schema_name) when is_binary(schema_name) do
    get_registry() |> Map.get(schema_name)
  end

  @doc """
  Get schema name by index (returns nil if not found)
  """
  def get_name(schema_index) when is_integer(schema_index) do
    registry = get_registry()

    Enum.find_value(registry, fn {name, index} ->
      if index == schema_index, do: name
    end)
  end

  @doc """
  List all registered schemas with their indices
  """
  def list_schemas do
    get_registry()
  end

  @doc """
  Reset registry (for testing only)
  """
  def reset! do
    :persistent_term.put(@registry_key, %{})
    :persistent_term.put(@next_id_key, 1)
  end

  @doc """
  Get registry statistics
  """
  def stats do
    registry = get_registry()
    next_id = get_next_id()

    %{
      total_schemas: map_size(registry),
      next_available_id: next_id,
      schemas: registry
    }
  end

  # Private helpers

  defp get_registry do
    case :persistent_term.get(@registry_key, nil) do
      nil -> %{}
      registry -> registry
    end
  end

  defp get_next_id do
    :persistent_term.get(@next_id_key, 1)
  end

  @doc """
  Export current registry for backup/migration
  """
  def export_registry do
    %{
      registry: get_registry(),
      next_id: get_next_id(),
      exported_at: DateTime.utc_now()
    }
  end

  @doc """
  Import registry from backup (replaces current registry)
  """
  def import_registry(%{registry: registry, next_id: next_id}) do
    :persistent_term.put(@registry_key, registry)
    :persistent_term.put(@next_id_key, next_id)
    :ok
  end

  @doc """
  Force register a schema with a specific index (used for explicit index assignment)
  WARNING: This can overwrite existing mappings - use with caution!
  """
  def force_register_index(schema_name, index)
      when is_binary(schema_name) and is_integer(index) and index > 0 do
    registry = get_registry()
    new_registry = Map.put(registry, schema_name, index)
    :persistent_term.put(@registry_key, new_registry)

    # Update next_id if necessary
    current_next = get_next_id()

    if index >= current_next do
      :persistent_term.put(@next_id_key, index + 1)
    end

    :ok
  end
end
