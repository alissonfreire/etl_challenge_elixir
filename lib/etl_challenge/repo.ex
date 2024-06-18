defmodule EtlChallenge.Repo do
  use Ecto.Repo,
    otp_app: :etl_challenge,
    adapter: Ecto.Adapters.Postgres
end
