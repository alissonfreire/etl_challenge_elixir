defmodule EtlChallenge.Requests.PageAPI do
  @moduledoc """
  Module responsible to fecth pages from `page api`
  """

  alias EtlChallenge.Requests.Dtos.{Error, Page, PageResponse}

  @callback fetch_page(page_number :: integer()) :: {:ok, PageResponse.t()}

  @spec fetch_page(module() | nil, integer()) :: {:ok, Page.t()} | {:error, Error.t()}
  def fetch_page(impl \\ nil, page_number)

  def fetch_page(_impl = nil, page_number) do
    default_impl() |> fetch_page(page_number)
  end

  def fetch_page(impl, page_number) do
    apply(impl, :fetch_page, [page_number]) |> unwrap_response()
  end

  defp unwrap_response({:ok, %PageResponse{} = response}) do
    if PageResponse.is_success?(response) do
      {:ok, response.data}
    else
      {:error, response.error}
    end
  end

  defp default_impl do
    Application.get_env(
      :etl_challenge,
      :page_api_impl,
      EtlChallenge.Requests.Adapters.PageAPIImpl
    )
  end
end
