defmodule EtlChallenge.Requests.Adapters.PageAPIImpl do
  @moduledoc """
  Page api fecth pages implementation
  """
  @behaviour EtlChallenge.Requests.PageAPI

  alias EtlChallenge.Requests.Dtos.{Error, Page, PageResponse}

  @api_url Application.compile_env!(:etl_challenge, :page_api_url)
  @pages_prefix "/pages"

  @impl true
  @spec fetch_page(any()) :: {:ok, PageResponse.t()}
  def fetch_page(page_number) do
    client()
    |> Tesla.get("#{@pages_prefix}/#{page_number}")
    |> build_response(page_number)
  end

  defp build_response({:ok, %Tesla.Env{status: 200, body: body}}, page_number) do
    page = %Page{page: page_number, numbers: body["numbers"]}

    {:ok, %PageResponse{status: PageResponse.success, data: page}}
  end

  defp build_response({:ok, %Tesla.Env{status: status, body: body}}, page_number) do
    error = %Error{page: page_number, reason: "response error with: #{status} and reason: #{inspect(body)}"}

    {:ok, %PageResponse{status: PageResponse.fail, error: error}}
  end

  defp build_response({:error, error}, page_number) do
    error = %Error{page: page_number, reason: "unexpected api error reason: #{inspect(error)}"}

    {:ok, %PageResponse{status: PageResponse.fail, error: error}}
  end

  defp client do
    default_middlewares() |> Tesla.client()
  end

  defp default_middlewares do
    [
      {Tesla.Middleware.BaseUrl, @api_url},
      {Tesla.Middleware.Query, [chance: 20]},
      Tesla.Middleware.JSON
    ]
  end
end
