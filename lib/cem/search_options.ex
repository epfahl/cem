defmodule CEM.SearchValidators do
  @moduledoc """
  Validation for `CEM.search/2` options.

  These functions are here so that custom validations can be added as
  public functions.
  """

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
