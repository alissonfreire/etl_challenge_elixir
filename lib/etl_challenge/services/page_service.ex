defmodule EtlChallenge.Services.PageService do
  @doc false
  alias EtlChallenge.Models.Page
  alias EtlChallenge.Repo

  import Ecto.Query

  @spec clear_all_pages() :: {:ok, integer()} | {:error, binary()}
  def clear_all_pages do
    case Repo.delete_all(Page) do
      {n, nil} ->
        {:ok, n}

      error ->
        {:error, "unexpected error on delete all pages reason: #{inspect(error)}"}
    end
  end

  @spec save_page(map()) :: {:ok, Page.t()} | {:error, Ecto.Changeset.t()}
  def save_page(params) do
    %Page{}
    |> Page.changeset(params)
    |> Repo.insert_or_update()
  end

  @spec get_page(integer()) :: {:error, :not_found} | {:ok, any()}
  def get_page(page_number) do
    case Repo.get_by(Page, page: page_number) do
      nil -> {:error, :not_found}
      page -> {:ok, page}
    end
  end

  @spec stats() :: map()
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
