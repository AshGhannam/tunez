defmodule Tunez.Music.Changes.UpdateOldList do
  use Ash.Resource.Change

  @impl true
  def change(changeset, opts, _context) do
    field = Keyword.fetch!(opts, :field)
    old_list_field = Keyword.fetch!(opts, :old_list_field)
    allow_duplicates = Keyword.get(opts, :allow_duplicates, false)

    new_value = Ash.Changeset.get_attribute(changeset, field)
    old_value = Ash.Changeset.get_data(changeset, field)
    old_list = Ash.Changeset.get_data(changeset, old_list_field)

    updated_list =
      [old_value | old_list]
      |> if(allow_duplicates, do: & &1, else: &Enum.uniq/1).()
      |> Enum.reject(fn value -> value == new_value end)

    Ash.Changeset.change_attribute(changeset, old_list_field, updated_list)
  end
end
