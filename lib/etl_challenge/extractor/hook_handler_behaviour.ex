defmodule EtlChallenge.Extractor.HookHandlerBehaviour do
  @moduledoc false

  alias EtlChallenge.Extractor.Context

  @callback call(hook :: atom(), args :: any(), ctx :: Context.t()) :: :ok
end
