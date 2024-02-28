defmodule CEM.Stats do
  @moduledoc """
  Helper functions for common statistical aggregates.
  """

  @doc """
  Compute the mean and standard deviation of a sample of numbers.

  If the sample list is empty, `{nil, nil}` is returned.
  """
  @spec sample_mean_and_std([number()]) :: {number() | nil, number() | nil}
  def sample_mean_and_std([x | _] = sample) when is_number(x) do
    n = length(sample)
    mean = sample_mean(sample, n)
    std = sample_std(sample, n, mean)
    {mean, std}
  end

  @doc """
  Compute the mean of a sample of numbers.

  If the sample list is empty, `nil` is returned.
  """
  @spec sample_mean([number()], non_neg_integer()) :: number() | nil
  def sample_mean([], _n), do: nil
  def sample_mean([x | _] = sample, n) when is_number(x) and n > 0, do: Enum.sum(sample) / n

  @doc """
  Compute the standard deviation of a sample of numbers.

  If the sample list is empty, `nil` is returned.
  """
  @spec sample_std([number()], non_neg_integer(), number()) :: number() | nil
  def sample_std([], _n, _mean), do: nil

  def sample_std([x | _] = sample, n, mean) when is_number(x) and n > 0 do
    sample
    |> Enum.map(&((&1 - mean) * (&1 - mean)))
    |> Enum.sum()
    |> Kernel./(n)
    |> :math.sqrt()
  end
end
