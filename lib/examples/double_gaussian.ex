defmodule CEM.Examples.DoubleGaussian do
  @moduledoc """
  ## Notes
  - This could apply to any 1D function, supplied by the user as the score.
    - And it could probably be generalized to any continuous n-D function.
    - Unconstrained n-d optimization.
    - Assume normal distr over n-d vector.
    - In general, would make good use of Nx.
  - How would we automatically determine a prior from the problem description?
    - In general, this is problem-specific.
    - Easy for probability params (bernoulli or transition matrix).
    - Less obvious for continuou, unless a bouning region is defined or can be
      discovered.
    - Same goes for sample size.
  """
  use CEM.Problem

  @impl true
  def init_params(_opts), do: %{mean: 0, std: 100}

  @impl true
  def draw_instance(%{mean: mean, std: std}), do: mean + std * :rand.normal()

  @impl true
  def score_instance(x) do
    :math.exp(-(x - 2) * (x - 2)) + 0.8 * :math.exp(-(x + 2) * (x + 2))
  end

  @impl true
  def update_params(sample) do
    sample_mean_and_std(sample)
  end

  @impl true
  def smooth_params(params_new, params_prev, f_smooth) do
    %{
      mean: scalar_smooth(params_new.mean, params_prev.mean, f_smooth),
      std: scalar_smooth(params_new.std, params_prev.std, f_smooth)
    }
  end

  @impl true
  def terminate?([%{params: %{std: std}} | _], _opts) do
    std < 0.001
  end

  @impl true
  def params_to_instance(%{mean: mean}) do
    mean
  end

  defp sample_mean_and_std(sample) do
    n = length(sample)
    mean = Enum.sum(sample) / n

    std =
      sample
      |> Enum.map(&((&1 - mean) * (&1 - mean)))
      |> Enum.sum()
      |> Kernel./(n)
      |> :math.sqrt()

    %{mean: mean, std: std}
  end

  defp scalar_smooth(x, x_prev, f), do: f * x + (1 - f) * x_prev
end
