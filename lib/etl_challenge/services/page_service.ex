defmodule EtlChallenge.Services.PageService do
  @moduledoc """
  This module is responsible to handle page operations like: create/update/delete pages,
  compile and return page statistics and searches pages by given parameters
  """

  alias EtlChallenge.Models.Page
  alias EtlChallenge.Repo
  alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
  alias EtlChallenge.Requests.Dtos.Page, as: PageDto

  import Ecto.Query

  @type stats() :: %{
          total: integer(),
          total_failed: integer(),
          total_success: integer()
        }

  @spec clear_all_pages() :: {:ok, integer()} | {:error, binary()}
  def clear_all_pages do
    case Repo.delete_all(Page) do
      {n, nil} ->
        {:ok, n}

      error ->
        {:error, "unexpected error on delete all pages reason: #{inspect(error)}"}
    end
  end

  @doc """
  Create or update a page based on input params. Input params could be a EtlChallenge.Requests.Dtos.Page.t(),
  EtlChallenge.Requests.Dtos.Error.t() or a simple map with page params

  ## Examples

    iex> alias EtlChallenge.Requests.Dtos.Page, as: PageDto
    iex> alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
    iex> alias EtlChallenge.Services.PageService

    iex> PageService.save_page(%{page: 1, numbers: [1,2,3]})
    {:ok, %EtlChallenge.Models.Page{page: 1, numbers: [1,2,3], is_failed: false}}

    iex> PageService.save_page(%PageDto{page: 1, numbers: [1,2,3]})
    {:ok, %EtlChallenge.Models.Page{page: 1, numbers: [1,2,3], is_failed: false}}

    iex> PageService.save_page(%ErrorDto{page: 1, reason: "api timeout"})
    {:ok, %EtlChallenge.Models.Page{page: 1, fail_reason: "api timeout", is_failed: true}}
  """
  @spec save_page(page :: PageDto.t()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def save_page(%PageDto{} = page) do
    save_page(%{page: page.page, numbers: page.numbers})
  end

  @spec save_page(error :: ErrorDto.t()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def save_page(%ErrorDto{} = error) do
    save_page(%{page: error.page, fail_reason: error.reason})
  end

  @spec save_page(params :: map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def save_page(params) do
    params
    |> Map.get(:page)
    |> maybe_load_page()
    |> Page.changeset(params)
    |> Repo.insert_or_update()
  end

  defp maybe_load_page(nil), do: %Page{page: nil}

  defp maybe_load_page(page) do
    case Repo.get(Page, page) do
      nil -> %Page{page: page}
      page -> page
    end
  end

  @doc """
  Returns a page model or not found error

  ## Examples

    iex> alias EtlChallenge.Services.PageService

    iex> PageService.get_page(1)
    {:ok, %EtlChallenge.Models.Page{page: 1, numbers: [1,2,3]}}

    iex> PageService.get_page(2)
    {:error, :not_found}
  """
  @spec get_page(integer()) :: {:error, :not_found} | {:ok, any()}
  def get_page(page_number) do
    case Repo.get_by(Page, page: page_number) do
      nil -> {:error, :not_found}
      page -> {:ok, page}
    end
  end

  @doc """
  Returns page statistics with total pages searched, total failed and successful pages

  ## Examples

    iex> alias EtlChallenge.Services.PageService

    iex> PageService.stats()
    %{total: 9, total_failed: 4, total_success: 5)}
  """
  @spec stats() :: stats()
  def stats do
    from(p in Page,
      select: %{
        total: count(p.page),
        total_failed: fragment("sum(?::int)", p.is_failed),
        total_success: fragment("sum((not ?)::int)", p.is_failed)
      }
    )
    |> Repo.one()
  end

  @spec get_all_pages_stream() :: function()
  def get_all_pages_stream do
    build_stream(page_order: :asc)
  end

  @spec get_success_pages_stream() :: function()
  def get_success_pages_stream do
    build_stream(page_order: :asc, is_failed: false)
  end

  @spec get_failed_pages_stream() :: function()
  def get_failed_pages_stream do
    build_stream(page_order: :asc, is_failed: true)
  end

  defp build_stream(params) do
    Stream.resource(
      fn -> execute_paginated_query(params, 0) end,
      fn %{
           page_number: page_number,
           total_pages: total_pages,
           entries: entries
         } = page ->
        cond do
          page_number > total_pages ->
            {:halt, :ignore}

          page_number == total_pages ->
            {entries, Map.put(page, :page_number, page_number + 1)}

          true ->
            {entries, execute_paginated_query(params, page_number + 1)}
        end
      end,
      fn _ -> :ok end
    )
  end

  defp execute_paginated_query(params, page) do
    params
    |> build_query()
    |> Repo.paginate(page: page, page_size: 10)
  end

  defp build_query(params) do
    base_query = from(p in Page)

    Enum.reduce(params, base_query, &apply_query_param(&2, &1))
  end

  defp apply_query_param(query, {:is_failed, is_failed}) do
    from(p in query, where: p.is_failed == ^is_failed)
  end

  defp apply_query_param(query, {:page_order, order}) do
    from(p in query, order_by: [{^order, p.page}])
  end
end
