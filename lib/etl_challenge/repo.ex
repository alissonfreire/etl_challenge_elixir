defmodule EtlChallenge.Repo do
  use Ecto.Repo,
    otp_app: :etl_challenge,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
