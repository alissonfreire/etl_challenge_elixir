defmodule EtlChallenge.Sort.SortBehaviour do
  @moduledoc """
  The contract that establishes the callback functions for the ordering modules
  """

  @callback sort([number()]) :: [number()]
end
