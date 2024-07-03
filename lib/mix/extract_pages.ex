defmodule Mix.Tasks.ExtractPages do
  @moduledoc """
  The extract pages mix task
  `mix extract_pages`

  ## Params
    --last-page: (integer) indicates the number of the last page
    --until-last-page: (boolean) indicates whether it will run until the last page
    --only-failed-pages: (boolean) extract only failed pages
    --reset-database: (boolean) deletes all extracted pages and resets the info
  """
  use Mix.Task

  alias EtlChallenge.Extractor
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Services.InfoService
  alias EtlChallenge.Services.PageService

  require Logger

  def run(args \\ []) do
    Mix.Task.run("app.config")

    {:ok, _} = Application.ensure_all_started(:etl_challenge)
    Logger.configure(level: :error)

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          last_page: :integer,
          until_last_page: :boolean,
          only_failed_pages: :boolean,
          reset_database: :boolean
        ]
      )

    opts = setup_opts(opts)

    if Keyword.get(opts, :reset_database, false) do
      IO.puts("Reset pages and info!")
      {:ok, _} = PageService.clear_all_pages()
      {:ok, _} = InfoService.reset_info()
    end

    Extractor.start_fetch(opts)

    InfoService.get_info() |> show_info()

    :ok
  end

  defp show_info(%Info{} = info) do
    IO.puts("|--------------------------")
    IO.puts("|           INFO           ")
    IO.puts("| fetched pages: #{info.fetched_pages}")
    IO.puts("| success pages: #{info.success_pages}")
    IO.puts("|  failed pages: #{info.failed_pages}")
    IO.puts("|--------------------------")
  end

  defp setup_opts(opts) do
    until_last_page = Keyword.get(opts, :until_last_page, false)
    only_failed_pages = Keyword.get(opts, :only_failed_pages, false)

    opts =
      if is_nil(until_last_page),
        do: Keyword.put(opts, :until_last_page, false),
        else: opts

    opts =
      if is_nil(only_failed_pages),
        do: Keyword.put(opts, :only_failed_pages, not until_last_page),
        else: opts

    opts
  end
end
