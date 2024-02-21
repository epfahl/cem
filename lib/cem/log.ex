defmodule CEM.Log do
  @moduledoc """
  Module that defines the log of optimization progress.
  """

  @type entry :: map()
  @type t :: [entry()]

  @doc """
  Create a new instance of `Log` as an empty list.
  """
  @spec new() :: t
  def new(), do: []

  @doc """
  Update the log by prepending a new entry with the provided step,
  parameters, and score.
  """
  @spec update(t, map()) :: t
  def update(log, entry), do: [entry | log]
end
