defmodule EtlChallenge.Extractor do
  @moduledoc false

  alias EtlChallenge.Models.Info
  alias EtlChallenge.Models.Page
  alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
  alias EtlChallenge.Requests.Dtos.Page, as: PageDto
  alias EtlChallenge.Requests.PageAPI
  alias EtlChallenge.Services.InfoService
  alias EtlChallenge.Services.PageService

  @spec start_fetch(info :: Info.t() | nil, keyword() | map()) :: {:ok, Info.t()}
  def start_fetch(info \\ nil, params)

  def start_fetch(_info = nil, params) do
    last_page = Access.get(params, :last_page, 10_000)

    info =
      if Access.get(params, :reset_info, false) do
        InfoService.get_info()
      else
        {:ok, info} = InfoService.setup_info(%{last_page: last_page})
        info
      end

    start_fetch(info, params)
  end

  def start_fetch(info, params) do
    params = build_params(params)

    params
    |> get_page_range()
    |> build_stream(info)
    |> Stream.run()

    {:ok, InfoService.get_info()}
  end

  defp build_params(%{} = params), do: params

  defp build_params(params) when is_list(params) do
    Map.new(params)
  end

  defp build_stream(range, info) do
    Stream.transform(
      range,
      fn -> info end,
      &perform_page/2,
      &last_function/1
    )
  end

  defp last_function(_acc) do
    stats = PageService.stats()

    InfoService.update_info(%{
      fetched_pages: stats.total,
      success_pages: stats.total_success,
      failed_pages: stats.total_failed
    })
  end

  defp perform_page(%Page{page: page_number}, acc) do
    perform_page(page_number, acc)
  end

  defp perform_page(page_number, _acc) do
    page_number
    |> fetch_page()
    |> handle_fetch()
    |> case do
      {:ok, info} ->
        {[page_number], info}
    end
  end

  defp get_page_range(%{last_page: last_page, until_last_page: true}) do
    1..last_page
  end

  defp get_page_range(%{only_failed_pages: true}) do
    PageService.get_failed_pages_stream()
  end

  defp get_page_range(%{} = params) do
    {down, up} = Map.get(params, :range, {1, 10})

    down..up
  end

  defp handle_fetch({:ok, %PageDto{} = page}) do
    {:ok, %Page{page: page_number}} = PageService.save_page(page)

    {:ok, InfoService.increment_success_pages(last_stopped_page: page_number)}
  end

  defp handle_fetch({:error, %ErrorDto{} = page}) do
    {:ok, %Page{page: page_number}} = PageService.save_page(page)

    {:ok, InfoService.increment_failed_pages(last_stopped_page: page_number)}
  end

  defp fetch_page(page_number) do
    PageAPI.fetch_page(page_number)
  end
end
