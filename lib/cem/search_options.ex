defmodule CEM.SearchOptions do
  @moduledoc """
  Validation for `CEM.search/2` options.

  These functions are here so that custom validations can be added as
  public functions.
  """

  @doc """
  Validate `CEM.search/2` options with `NimbleOptions` and augment with new
  keywords.
  """
  @spec validate_and_augment(keyword(), keyword()) :: map()
  def validate_and_augment(opts, schema) do
    opts = opts |> NimbleOptions.validate!(schema) |> Map.new()
    Map.put(opts, :n_elite, ceil(opts.f_elite * opts.n_sample))
  end

  @doc """
  Returns `{:ok, x}` if `low <= x <= high`, and `{:error, message}` otherwise.
  """
  @spec validate_range(any, number, number) :: {:ok, any} | {:error, String.t()}
  def validate_range(x, low, high) do
    if x >= low and x <= high do
      {:ok, x}
    else
      {:error, "expected a value from #{low} to #{high}, but got #{x}"}
    end
  end
end
