defmodule EtlChallenge.Extractor.Context do
  @moduledoc false

  alias EtlChallenge.Services.InfoService
  alias EtlChallenge.Models.Info

  defstruct params: %{},
            hook_handler: nil,
            info: nil

  @type t :: %__MODULE__{}

  @last_page 100

  def build_from_params(params) when is_list(params) do
    params
    |> Map.new()
    |> build_from_params()
  end

  def build_from_params(%{} = params) do
    params
    |> setup_info()
    |> final_setup()
  end

  defp final_setup(params) do
    {hook_handler, params} = Map.pop(params, :hook_handler)
    {info, params} = Map.pop(params, :info)

    %__MODULE__{}
    |> Map.put(:params, params)
    |> Map.put(:info, info)
    |> Map.put(:hook_handler, hook_handler)
  end

  defp setup_info(%{info: %Info{}} = params), do: params

  defp setup_info(params) do
    last_page = Access.get(params, :last_page, @last_page)

    info =
      if Access.get(params, :reset_info, false) do
        InfoService.get_info()
      else
        {:ok, info} = InfoService.setup_info(%{last_page: last_page})
        info
      end

    Map.put(params, :info, info)
  end
end
