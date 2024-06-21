defmodule EtlChallenge.Requests.Dtos.Page do
  @moduledoc false

  defstruct page: 0,
            numbers: []

  @type t :: %__MODULE__{}
end
