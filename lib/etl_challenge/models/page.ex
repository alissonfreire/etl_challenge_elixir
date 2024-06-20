defmodule EtlChallenge.Models.Page do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @required_fields ~w(page)a
  @optional_fields ~w(numbers is_failed sorted_numbers last_fetched_at)a

  @primary_key {:page, :integer, autogenerate: false}
  schema "pages" do
    field :is_failed, :boolean, default: false
    field :last_fetched_at, :utc_datetime
    field :numbers, {:array, :float}, default: []
    field :sorted_numbers, {:array, :float}, default: []

    timestamps()
  end

  def changeset(page = %__MODULE__{}, attrs) do
    page
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:page, greater_than_or_equal_to: 1)
    |> maybe_put_is_failed()
    |> put_last_fetched_at()
  end

  defp maybe_put_is_failed(changeset) do
    changeset
    |> get_field(:numbers, [])
    |> case do
      [] -> true
      [_ | _] -> false
    end
    |> then(&put_change(changeset, :is_failed, &1))
  end

  defp put_last_fetched_at(changeset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    changeset |> put_change(:last_fetched_at, now)
  end
end
