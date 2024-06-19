defmodule EtlChallenge.Models.Info do
  use Ecto.Schema

  schema "info" do
    field :attempt, :string
    field :is_finished, :boolean, default: false
    field :success_pages, :integer, default: 0
    field :fetched_pages, :integer, default: 0
    field :failed_pages, :integer, default: 0
    field :last_page, :integer, default: 0
    field :last_stoped_page, :integer, default: 0
    field :sort_strategy, :string
    field :all_numbers, {:array, :decimal}, default: []
    field :sorted_numbers, {:array, :decimal}, default: []
    field :start_fecthed_at, :utc_datetime
    field :finish_fecthed_at, :utc_datetime
  end
end
