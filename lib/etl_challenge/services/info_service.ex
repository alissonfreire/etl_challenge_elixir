defmodule EtlChallenge.Services.InfoService do
  @doc false
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Repo

  def setup_info(params) do
    params
    |> Info.setup_changeset()
    |> Repo.insert_or_update()
  end

  def increment_success_pages(opts \\ []) do
    do_increment_pages(:success_pages, opts)
  end

  def increment_failed_pages(opts \\ []) do
    do_increment_pages(:failed_pages, opts)
  end

  def do_increment_pages(field, opts \\ []) do
    fields =
      if Keyword.get(opts, :also_inc_fetched_pages, true),
        do: [field, :fetched_pages],
        else: [field]

    fields
    |> Info.increment_field()
    |> Repo.insert_or_update()
  end

  def set_all_numbers(all_numbers) do
    Info.set_numbers(all_numbers, :all_numbers)
    |> Repo.insert_or_update()
  end

  def set_sorted_numbers(sorted_numbers) do
    Info.set_numbers(sorted_numbers, :sorted_numbers)
    |> Repo.insert_or_update()
  end
end
