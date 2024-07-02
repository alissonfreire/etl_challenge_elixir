defmodule EtlChallenge.Services.InfoService do
  @moduledoc """
  This module is responsible to handle info operations like: retrive info and update info state
  """
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Repo

  @spec get_info() :: Info.t()
  def get_info, do: Info.get_info()

  @doc """
    Setup info table with params

    ## params
    - last_page: (required) max num pages for fecth
  """
  @spec setup_info(params :: map()) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def setup_info(params) do
    params
    |> Info.setup_changeset()
    |> Repo.insert_or_update()
  end

  @spec update_info(map()) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def update_info(params) do
    params
    |> Info.changeset()
    |> Repo.update()
  end

  @spec increment_success_pages(keyword()) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def increment_success_pages(opts \\ []) do
    do_increment_pages(:success_pages, opts)
  end

  @spec increment_failed_pages(keyword()) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def increment_failed_pages(opts \\ []) do
    do_increment_pages(:failed_pages, opts)
  end

  def do_increment_pages(field, opts \\ []) do
    fields =
      if Keyword.get(opts, :also_inc_fetched_pages, true),
        do: [field, :fetched_pages],
        else: [field]

    info = Info.increment_field(fields)
    last_stopped_page = Keyword.get(opts, :last_stopped_page)

    if Keyword.get(opts, :set_last_stopped_page, false) or last_stopped_page do
      Info.set_last_stopped_page(info, last_stopped_page)
    else
      info
    end
    |> Repo.insert_or_update()
  end

  @spec set_all_numbers([integer()]) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def set_all_numbers(all_numbers) do
    all_numbers
    |> Info.set_numbers(:all_numbers)
    |> Repo.insert_or_update()
  end

  @spec set_sorted_numbers([integer()]) :: {:ok, Info.t()} | {:error, Ecto.Changeset.t()}
  def set_sorted_numbers(sorted_numbers) do
    sorted_numbers
    |> Info.set_numbers(:sorted_numbers)
    |> Repo.insert_or_update()
  end
end
