defmodule CEM.Helpers do
  @moduledoc """
  Assorted helper functions.
  """
  @doc """
  Linearly interpolate between number `x` and `y` with parameter `f` is the
  interpolation fraction from 0 to 1.

  As `f` varies from 0 to 1, the result varies from `x` to `y`.
  """
  def interpolate(x, y, f) when is_number(x) and is_number(y) and f >= 0 and f <= 1 do
    (1 - f) * x + f * y
  end
end
