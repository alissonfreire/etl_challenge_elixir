defmodule EtlChallenge.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: EtlChallenge.Repo

  def info_factory do
    %EtlChallenge.Models.Info{}
  end
end
