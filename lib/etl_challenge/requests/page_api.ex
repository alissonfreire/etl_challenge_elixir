defmodule EtlChallenge.Requests.PageAPI do
  @moduledoc """
  Module responsible to fecth pages from `page api`
  """

  alias EtlChallenge.Requests.Dtos.{Error, Page, PageResponse}

  @callback fetch_page(page_number :: integer()) :: {:ok, PageResponse.t()}

  @doc """
  Fetch page from remote source using a given implementation or using the default. The custom
  implementation must implement the callbacks of this module's behaviour

  ## Example

    iex> page_number = 1
    iex> PageAPI.fetch_page(page_number)

    iex> PageAPI.fetch_page(EtlChallenge.Requests.CustomImpl, page_number)
  """
  @spec fetch_page(module() | nil, integer()) :: {:ok, Page.t()} | {:error, Error.t()}
  def fetch_page(impl \\ nil, page_number)

  def fetch_page(nil = _impl, page_number) do
    default_impl() |> fetch_page(page_number)
  end

  def fetch_page(impl, page_number) do
    page_number
    |> impl.fetch_page()
    |> unwrap_response()
  end

  defp unwrap_response({:ok, %PageResponse{} = response}) do
    if PageResponse.success?(response) do
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
