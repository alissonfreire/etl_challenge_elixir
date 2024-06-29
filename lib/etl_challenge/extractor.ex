defmodule EtlChallenge.Extractor do
  @moduledoc false

  alias EtlChallenge.Extractor.Context
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Models.Page
  alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
  alias EtlChallenge.Requests.Dtos.Page, as: PageDto
  alias EtlChallenge.Requests.PageAPI
  alias EtlChallenge.Services.InfoService
  alias EtlChallenge.Services.PageService

  @spec start_fetch(info :: Info.t() | nil, keyword() | map()) :: {:ok, Info.t()}
  def start_fetch(info \\ nil, params)

  def start_fetch(info, params) do
    ctx = build_context(info, params)

    ctx
    |> get_page_range()
    |> build_stream(ctx)
    |> Stream.run()

    {:ok, InfoService.get_info()}
  end

  defp build_context(info, params) do
    info
    |> maybe_put_info(params)
    |> Context.build_from_params()
  end

  defp maybe_put_info(nil, params), do: params

  defp maybe_put_info(info, params) when is_list(params) do
    Keyword.put(params, :info, info)
  end

  defp maybe_put_info(info, params) when is_map(params) do
    Map.put(params, :info, info)
  end

  defp build_stream(range, ctx) do
    Stream.transform(
      range,
      fn -> ctx end,
      &perform_page(&2, &1, ctx),
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

  defp perform_page(acc, %Page{page: page_number}, ctx) do
    perform_page(acc, page_number, ctx)
  end

  defp perform_page(_acc, page_number, ctx) do
    page_number
    |> call_hook(:pre_fetch_page, ctx)
    |> fetch_page()
    |> call_hook(:pos_fetch_page, ctx)
    |> handle_fetch()
    |> call_hook(:pos_handle_page, ctx)
    |> case do
      {:ok, info} ->
        {[page_number], Map.put(ctx, :info, info)}
    end
  end

  defp call_hook(args, hook, ctx) do
    maybe_execute_hook_callback(args, hook, ctx)

    args
  end

  defp maybe_execute_hook_callback(args, hook, ctx) do
    case Map.get(ctx, :hook_handler) do
      nil ->
        :ok

      hook_cb when is_atom(hook_cb) ->
        hook_cb.call(hook, args, ctx)

      hook_cb when is_function(hook_cb) ->
        hook_cb.(hook, args, ctx)
    end
  end

  defp get_page_range(%Context{params: params}), do: get_page_range(params)

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
    case PageService.save_page(page) do
      {:ok, %Page{page: page_number}} ->
        InfoService.increment_success_pages(last_stopped_page: page_number)

      error ->
        error
    end
  end

  defp handle_fetch({:error, %ErrorDto{} = page}) do
    case PageService.save_page(page) do
      {:ok, %Page{page: page_number}} ->
        InfoService.increment_failed_pages(last_stopped_page: page_number)

      error ->
        error
    end
  end

  defp fetch_page(page_number) do
    PageAPI.fetch_page(page_number)
  end
end
