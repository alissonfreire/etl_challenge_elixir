defmodule EtlChallenge.Requests.Dtos.PageResponse do
  @moduledoc """
  Page api response dto
  """

  alias EtlChallenge.Requests.Dtos.{Error, Page}

  defstruct status: :success,
            data: %Page{},
            error: %Error{}

  @type t :: %__MODULE__{}

  def success, do: :success
  def fail, do: :fail

  def success?(%__MODULE__{status: status}), do: status == :success
  def fail?(%__MODULE__{status: status}), do: status == :fail
end
