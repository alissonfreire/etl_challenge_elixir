defmodule EtlChallenge.Repo.Migrations.AddPagesTable do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :page, :integer, primary_key: true
      add :is_failed, :boolean, default: false
      add :numbers, {:array, :decimal}, default: []
      add :sorted_numbers, {:array, :decimal}, default: []
      add :last_fetched_at, :utc_datetime

      timestamps()
    end
  end
end
