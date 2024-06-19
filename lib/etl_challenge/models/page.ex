defmodule EtlChallenge.Models.Page do
  use Ecto.Schema

  import Ecto.Changeset

  @required_fields ~w(page)a
  @optional_fields ~w(numbers is_failed sorted_numbers last_fetched_at)a

  schema "pages" do
    field :is_failed, :boolean, default: false
    field :last_fetched_at, :utc_datetime
    field :numbers, {:array, :decimal}, default: []
    field :sorted_numbers, {:array, :decimal}, default: []
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:page, greater_than_or_equal_to: 1)
  end
end
