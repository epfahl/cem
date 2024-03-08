defmodule CEM.Random do
  @moduledoc """
  Convenience functions for generating random variates.
  """

  @doc """
  Generate a uniform variate from 0 to 1.
  """
  @spec uniform() :: float()
  def uniform(), do: :rand.uniform()

  @doc """
  Generate a uniform variate from `min_value` to `max_value`.
  """
  @spec uniform(number(), number()) :: float()
  def uniform(min_value, max_value) when min_value <= max_value do
    min_value + (max_value - min_value) * :rand.uniform()
  end

  @doc """
  Generate a random integer from `min_value` to `max_value` (inclusive).
  """
  def uniform_int(min_value, max_value)
      when is_integer(min_value) and is_integer(max_value) and min_value <= max_value do
    min_value - 1 + :rand.uniform(max_value - min_value + 1)
  end

  @doc """
  Generate a normal variate with mean `mean` and standard deviation `std`.
  """
  @spec normal(number(), number()) :: float()
  def normal(mean, std), do: mean + std * :rand.normal()

  @doc """
  Generate a bernoulli variate (0 or 1) with probability `p` of being 1.
  """
  @spec bernoulli(number()) :: 0 | 1
  def bernoulli(p), do: if(:rand.uniform() <= p, do: 1, else: 0)

  @doc """
  Generate a random value from a list of `{value, weight}` tuples.

  The probability of selecting a value is proportional to its weight.
  The weights do not need to be normalized.

  An exception is raised if the list is empty.
  """
  @spec choice([{any(), number()}]) :: any()
  def choice([]) do
    raise ArgumentError,
      message: "choice/1 must be called with a non-empty list of value-weight tuples"
  end

  def choice([{_, w} | _] = vws) when is_number(w) do
    u = uniform() * Enum.reduce(vws, 0, fn {_, w}, sum -> sum + w end)
    choice(vws, 0, u)
  end

  @spec choice([{any(), number()}], number(), number()) :: any()
  defp choice([{v, w} | rest], cumsum, u) do
    cumsum_next = cumsum + w
    if u <= cumsum_next, do: v, else: choice(rest, cumsum_next, u)
  end
end
