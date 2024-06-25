defmodule EtlChallenge.Requests.Dtos.Error do
  @moduledoc false

  defstruct page: nil, reason: nil

  @type t :: %__MODULE__{}
end
