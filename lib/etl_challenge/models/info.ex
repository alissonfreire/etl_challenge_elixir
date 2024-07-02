defmodule EtlChallenge.Models.Info do
  @moduledoc """
  Page model responsible for mapping the page record from the 'info' table
  """
  use Ecto.Schema
  alias EtlChallenge.Repo

  import Ecto.Changeset
  import Ecto.Query

  @type t() :: %__MODULE__{}

  @required_fields ~w(last_page)a

  @optional_fields ~w(
    attempt
    is_finished
    fetched_pages
    success_pages
    failed_pages
    last_stopped_page
    sort_strategy
    all_numbers
    sorted_numbers
    start_fecthed_at
    finish_fecthed_at
  )a

  schema "info" do
    field :attempt, :integer, default: 0
    field :is_finished, :boolean, default: false
    field :fetched_pages, :integer, default: 0
    field :success_pages, :integer, default: 0
    field :failed_pages, :integer, default: 0
    field :last_page, :integer
    field :last_stopped_page, :integer, default: 0
    field :sort_strategy, :string
    field :all_numbers, {:array, :float}, default: []
    field :sorted_numbers, {:array, :float}, default: []
    field :start_fecthed_at, :utc_datetime
    field :finish_fecthed_at, :utc_datetime
  end

  def changeset(params) do
    get_info()
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:last_page, greater_than_or_equal_to: 0)
    |> maybe_put_is_finished()
  end

  def setup_changeset(params) do
    get_info()
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:last_page, greater_than_or_equal_to: 0)
    |> reset_fields()
    |> maybe_put_attempt()
    |> put_start_fecthed_at()
  end

  def reset_changeset do
    get_info()
    |> cast(%{}, @required_fields)
    |> reset_fields()
    |> put_change(:last_page, 0)
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
    |> put_change(:start_fecthed_at, nil)
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

  @spec set_numbers([integer()], :all_numbers | :sorted_numbers) :: Ecto.Changeset.t()
  def set_numbers(all_numbers, field \\ :all_numbers)

  def set_numbers(all_numbers, :all_numbers) do
    get_info()
    |> cast(%{all_numbers: all_numbers}, [:all_numbers])
    |> maybe_put_is_finished()
  end

  def set_numbers(sorted_numbers, :sorted_numbers) do
    cast(get_info(), %{sorted_numbers: sorted_numbers}, [:sorted_numbers])
  end

  @spec set_last_stopped_page() :: Ecto.Changeset.t()
  @spec set_last_stopped_page(
          info :: nil | __MODULE__.t() | Ecto.Changeset.t(),
          page :: nil | integer()
        ) :: Ecto.Changeset.t()
  def set_last_stopped_page(info \\ nil, page \\ nil)

  def set_last_stopped_page(nil = _info, page) do
    get_info() |> set_last_stopped_page(page)
  end

  def set_last_stopped_page(%__MODULE__{} = info, page) do
    info
    |> change()
    |> set_last_stopped_page(page)
  end

  def set_last_stopped_page(%Ecto.Changeset{} = changeset, page) do
    page =
      if is_nil(page),
        do: get_field(changeset, :fetched_pages),
        else: page

    changeset
    |> put_change(:last_stopped_page, page)
    |> maybe_put_is_finished()
  end

  defp maybe_put_is_finished(changeset) do
    last_stopped_page = get_field(changeset, :last_stopped_page)
    fetched_pages = get_field(changeset, :fetched_pages)

    is_finished = last_stopped_page != 0 and last_stopped_page == fetched_pages

    put_change(changeset, :is_finished, is_finished)
  end

  @spec get_info() :: __MODULE__.t()
  def get_info do
    from(info in __MODULE__, limit: 1)
    |> Repo.one()
    |> case do
      nil -> %__MODULE__{attempt: 0}
      info -> info
    end
  end
end
