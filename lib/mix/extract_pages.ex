defmodule Mix.Tasks.ExtractPages do
  @moduledoc """
  The extract pages mix task
  `mix extract_pages`
  """
  use Mix.Task

  alias EtlChallenge.Extractor
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Services.InfoService

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
      Mix.Task.run("ecto.reset")
    end

    Extractor.start_fetch(opts)

    InfoService.get_info() |> show_info()

    :ok
  end

  defp show_info(%Info{} = info) do
    IO.puts("|--------------------------")
    IO.puts("|           INFO           ")
    IO.puts("| fetched_pages: #{info.fetched_pages}")
    IO.puts("| success_pages: #{info.success_pages}")
    IO.puts("|  failed_pages: #{info.failed_pages}")
    IO.puts("|--------------------------")
  end

  def call(_hook, _args, _ctx), do: :ok

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
