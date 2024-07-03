defmodule EtlChallengeWeb.Live.Index do
  @moduledoc false
  use EtlChallengeWeb, :live_view

  alias EtlChallenge.Services.{InfoService, PageService}

  alias EtlChallenge.Extractor

  def mount(_params, _session, socket) do
    info = InfoService.get_info()

    {:ok,
     assign(socket,
       extractor_form:
         to_form(%{
           "last_page" => info.last_page,
           "until_last_page" => true,
           "only_failed_pages" => false
         }),
       info: info
     )}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, extractor_form: to_form(params))}
  end

  def handle_event("start-extractor", _params, socket) do
    me = self()

    hook_handler = fn hook, args, ctx ->
      send(me, {:extract_hook, hook, args, ctx})
    end

    extractor_params =
      socket.assigns.extractor_form
      |> build_extractor_params()
      |> Map.put(:hook_handler, hook_handler)

    spawn(fn ->
      Extractor.start_fetch(extractor_params)
    end)

    {:noreply, socket}
  end

  def handle_event("reset-page-info", _params, socket) do
    {:ok, _n} = PageService.clear_all_pages()
    {:ok, info} = InfoService.reset_info()

    {:noreply, assign(socket, :info, info)}
  end

  def handle_info({:extract_hook, :pos_handle_page, {:ok, info}, _ctx}, socket) do
    {:noreply, assign(socket, :info, info)}
  end

  def handle_info({:extract_hook, _hook, _args, _ctx}, socket) do
    {:noreply, socket}
  end

  defp build_extractor_params(%{params: params}) do
    params
    |> Map.take(["last_page", "until_last_page", "only_failed_pages"])
    |> Enum.reduce(%{}, fn
      {"last_page", value}, acc ->
        Map.put(acc, :last_page, String.to_integer(value))

      {key, value}, acc ->
        Map.put(acc, String.to_atom(key), String.to_atom(value))
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-evenly">
      <button
        class="rounded-lg text-white bg-orange-500 px-2 py-1 hover:bg-orange-200/80"
        phx-click="start-extractor"
      >
        <%= gettext("Start extract pages") %>
      </button>
      <button
        class="rounded-lg text-white bg-red-500 px-2 py-1 hover:bg-red-200/80"
        phx-click="reset-page-info"
      >
        <%= gettext("Reset pages & info") %>
      </button>
    </div>

    <.form for={@extractor_form} phx-change="validate" phx-submit="save">
      <div class="flex items-center justify-between	border border-zinc-400 rounded-md p-4 my-3">
        <.label>
          <%= gettext("Last page") %>
          <.input type="number" min="0" field={@extractor_form[:last_page]} class="w-0" />
        </.label>

        <.input
          label={gettext("Until Last Page")}
          type="checkbox"
          class="mt-3"
          field={@extractor_form[:until_last_page]}
        />

        <.input
          label={gettext("Only Failed Pages")}
          type="checkbox"
          class="mt-3"
          field={@extractor_form[:only_failed_pages]}
        />
      </div>
    </.form>

    <div class="border border-zinc-400 rounded-md p-4">
      <h3>Info</h3>
      <p><%= gettext("Last Attempt: %{attempt}", %{attempt: @info.attempt}) %></p>
      <p>
        <%= gettext("Last stopped page: %{last_stopped_page}", %{
          last_stopped_page: @info.last_stopped_page
        }) %>
      </p>
      <p><%= gettext("Fetched pages: %{fetched_pages}", %{fetched_pages: @info.fetched_pages}) %></p>
      <p><%= gettext("Success pages: %{success_pages}", %{success_pages: @info.success_pages}) %></p>
      <p><%= gettext("Failed pages: %{failed_pages}", %{failed_pages: @info.failed_pages}) %></p>
    </div>
    """
  end
end
