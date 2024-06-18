defmodule EtlChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EtlChallengeWeb.Telemetry,
      EtlChallenge.Repo,
      {DNSCluster, query: Application.get_env(:etl_challenge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EtlChallenge.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EtlChallenge.Finch},
      # Start a worker by calling: EtlChallenge.Worker.start_link(arg)
      # {EtlChallenge.Worker, arg},
      # Start to serve requests, typically the last entry
      EtlChallengeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EtlChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EtlChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
