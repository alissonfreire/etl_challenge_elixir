defmodule EtlChallenge.Models.Info do
  use Ecto.Schema
  alias EtlChallenge.Repo

  import Ecto.Changeset
  import Ecto.Query

  schema "info" do
    field :attempt, :integer, default: 0
    field :is_finished, :boolean, default: false
    field :fetched_pages, :integer, default: 0
    field :success_pages, :integer, default: 0
    field :failed_pages, :integer, default: 0
    field :last_page, :integer
    field :last_stopped_page, :integer, default: 0
    field :sort_strategy, :string
    field :all_numbers, {:array, :decimal}, default: []
    field :sorted_numbers, {:array, :decimal}, default: []
    field :start_fecthed_at, :utc_datetime
    field :finish_fecthed_at, :utc_datetime
  end

  def setup_changeset(params) do
    get_info()
    |> cast(params, [:last_page])
    |> validate_required([:last_page])
    |> validate_number(:last_page, greater_than_or_equal_to: 0)
    |> reset_fields()
    |> maybe_put_attempt()
    |> put_start_fecthed_at()
  end

  defp maybe_put_attempt(changeset) do
    do_increment_field(changeset, :attempt, 0)
  end

  defp put_start_fecthed_at(changeset) do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> then(&put_change(changeset, :start_fecthed_at, &1))
  end

  defp reset_fields(changeset) do
    changeset
    |> put_change(:is_finished, false)
    |> put_change(:fetched_pages, 0)
    |> put_change(:success_pages, 0)
    |> put_change(:failed_pages, 0)
    |> put_change(:last_stopped_page, 0)
    |> put_change(:sort_strategy, nil)
    |> put_change(:all_numbers, [])
    |> put_change(:sorted_numbers, [])
    |> put_change(:finish_fecthed_at, nil)
  end

  def increment_field(field, default \\ 0)
  def increment_field(field, default) do
    get_info() |> increment_field(field, default)
  end

  def increment_field(%__MODULE__{} = info, field, default) do
    info |> change() |> increment_field(field, default)
  end

  def increment_field(%Ecto.Changeset{} = info, field, default) do
    field
    |> List.wrap()
    |> then(&do_increment_field(info, &1, default))
  end

  defp do_increment_field(%Ecto.Changeset{} = changeset, fields, default) when is_list(fields) do
    Enum.reduce(fields, changeset, fn
      {field, default}, acc ->
        do_increment_field(acc, field, default)

      field, acc ->
        do_increment_field(acc, field, default)
    end)
  end

  defp do_increment_field(%Ecto.Changeset{} = changeset, field, default) do
    changeset
    |> get_field(field, default)
    |> then(&put_change(changeset, field, &1 + 1))
  end

  def set_numbers(all_numbers, field \\ :all_numbers)

  def set_numbers(all_numbers, :all_numbers) do
    get_info()
    |> change(%{all_numbers: all_numbers})
    |> put_change(:is_finished, true)
  end

  def set_numbers(sorted_numbers, :sorted_numbers) do
    get_info()
    |> change(%{sorted_numbers: sorted_numbers})
  end

  def get_info do
    from(info in __MODULE__, limit: 1)
    |> Repo.one()
    |> case do
      nil -> %__MODULE__{attempt: 0}
      info -> info
    end
  end
end
