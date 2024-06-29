defmodule EtlChallenge.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: EtlChallenge.Repo

  def info_factory do
    %EtlChallenge.Models.Info{}
  end

  def page_factory do
    %EtlChallenge.Models.Page{}
  end
end
