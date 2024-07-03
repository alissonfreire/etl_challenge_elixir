defmodule Mix.Tasks.Benchmark do
  @moduledoc """
  The benchmark with page numbers
  `mix benchmark`

  ## Params
    --output-type: the possible values ​​are html and console (default)
    --output-path: the benchmark output path, by default it will be in "{project_root_dir}/benchmark/results"
  """
  use Mix.Task

  alias EtlChallenge.Services.PageService
  alias EtlChallenge.Sort.{MergeSort, QuickSort}

  @project_dir File.cwd!()

  require Logger

  def run(args \\ []) do
    Mix.Task.run("app.config")

    {:ok, _} = Application.ensure_all_started(:etl_challenge)
    Logger.configure(level: :error)

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          output_type: :string,
          output_path: :string
        ]
      )

    bechmark_opts = setup_bechmark_opts(opts)

    all_page_numbers = PageService.get_all_page_numbers()

    perform_benchmark(all_page_numbers, bechmark_opts)

    :ok
  end

  defp perform_benchmark(input_list, opts) do
    Benchee.run(
      %{
        "Enum.sort" => fn -> Enum.sort(input_list) end,
        "MergeSort.sort" => fn -> MergeSort.sort(input_list) end,
        "QuickSort.sort" => fn -> QuickSort.sort(input_list) end
      },
      opts
    )
  end

  defp setup_bechmark_opts(opts) do
    formatters = get_formatter_config(opts)

    [formatters: formatters]
  end

  defp get_formatter_config(opts) do
    case Keyword.get(opts, :output_type) do
      "html" -> get_formatter_config(opts, "html")
      _ -> [Benchee.Formatters.Console]
    end
  end

  defp get_formatter_config(opts, "html") do
    file_path =
      opts
      |> Keyword.get(:output_path)
      |> get_output_file_path("html")

    [{Benchee.Formatters.HTML, file: file_path, auto_open: false}]
  end

  defp get_output_file_path(nil, ext) do
    file_name = "output-#{System.os_time()}.#{ext}"

    Path.join([@project_dir, "benchmark", "results", file_name])
  end

  defp get_output_file_path(file_path, _ext) do
    Path.expand(file_path)
  end
end
