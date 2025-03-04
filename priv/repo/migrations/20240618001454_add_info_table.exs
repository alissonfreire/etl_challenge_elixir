defmodule EtlChallenge.Repo.Migrations.AddInfoTable do
  use Ecto.Migration

  def change do
    create table(:info) do
      add :attempt, :integer, default: 0
      add :is_finished, :boolean, default: false
      add :fetched_pages, :integer, default: 0
      add :success_pages, :integer, default: 0
      add :failed_pages, :integer, default: 0
      add :last_page, :integer, default: 0
      add :last_stopped_page, :integer, default: 0
      add :sort_strategy, :string
      add :all_numbers, {:array, :float}, default: []
      add :sorted_numbers, {:array, :float}, default: []
      add :start_fecthed_at, :utc_datetime, null: true
      add :finish_fecthed_at, :utc_datetime, null: true
    end
  end
end
