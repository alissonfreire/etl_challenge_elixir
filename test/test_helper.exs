ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EtlChallenge.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
