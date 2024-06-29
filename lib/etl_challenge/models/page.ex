defmodule EtlChallenge.Models.Page do
  @moduledoc """
  Page model responsible for mapping the page record from the 'pages' table
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @required_fields ~w(page)a
  @optional_fields ~w(numbers is_failed fail_reason sorted_numbers last_fetched_at)a

  @primary_key {:page, :integer, autogenerate: false}
  schema "pages" do
    field :is_failed, :boolean, default: false
    field :fail_reason, :string
    field :last_fetched_at, :utc_datetime
    field :numbers, {:array, :float}, default: []
    field :sorted_numbers, {:array, :float}, default: []

    timestamps()
  end

  def changeset(%__MODULE__{} = page, attrs) do
    page
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:page, greater_than_or_equal_to: 1)
    |> maybe_override_is_failed_and_reason()
    |> validate_empty_numbers()
    |> validate_fail_reason()
    |> put_last_fetched_at()
  end

  defp maybe_override_is_failed_and_reason(changeset) do
    fail_reason = get_change(changeset, :fail_reason)
    is_failed = not is_nil(fail_reason)

    changeset
    |> put_change(:is_failed, is_failed)
    |> put_change(:fail_reason, fail_reason)
  end

  defp validate_empty_numbers(changeset) do
    numbers = changeset |> get_field(:numbers, []) |> Enum.empty?()

    if numbers and not get_field(changeset, :is_failed) do
      add_error(changeset, :numbers, "can't be empty without fail reason")
    else
      changeset
    end
  end

  defp put_last_fetched_at(changeset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    changeset |> put_change(:last_fetched_at, now)
  end

  defp validate_fail_reason(changeset) do
    reason = get_field(changeset, :fail_reason)

    if get_field(changeset, :is_failed) and reason in [nil, ""] do
      add_error(changeset, :fail_reason, "can't be blank")
    else
      changeset
    end
  end
end
