ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EtlChallenge.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)

Enum.each(
  [
    {EtlChallenge.Requests.Adapters.MockPageAPIImpl, EtlChallenge.Requests.PageAPI},
    {EtlChallenge.Extractor.HookHandlerMock, EtlChallenge.Extractor.HookHandlerBehaviour}
  ],
  fn {mock, behaviour} ->
    Mox.defmock(mock, for: behaviour)
  end
)
