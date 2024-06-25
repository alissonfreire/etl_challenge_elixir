defmodule EtlChallenge.Repo.Migrations.AddPagesTable do
  use Ecto.Migration

  def change do
    create table(:pages, primary_key: false) do
      add :page, :integer, primary_key: true
      add :is_failed, :boolean, default: false
      add :fail_reason, :string
      add :numbers, {:array, :float}, default: []
      add :sorted_numbers, {:array, :float}, default: []
      add :last_fetched_at, :utc_datetime

      timestamps()
    end
  end
end
