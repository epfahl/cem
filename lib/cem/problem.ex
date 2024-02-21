defmodule CEM.Problem do
  @moduledoc """
  A behaviour module that defines callbacks needed to execute CEM optimization.

  ## Example

      defmodule MyProblem do
        use CEM.Problem

        @impl true
        def init_params(_opts), do: %{mean: 0, std: 100}

        @impl true
        def draw_instance(%{mean: mean, std: std}), do: mean + std * :rand.normal()

        @impl true
        def score_instance(x), do: :math.exp(-x * x)

        @impl true
        def update_params(sample) do
          n = length(sample)
          mean = sample_mean(sample, n)
          std = sample_std(sample, n, mean)
          %{mean: mean, std: std}
        end

        @impl true
        def smooth_params(params, params_prev, f_smooth) do
          %{
            mean: smooth(params.mean, params_prev.mean, f_smooth),
            std: smooth(params.std, params_prev.std, f_smooth)
          }
        end

        @impl true
        def terminate?([entry | _], _opts), do: entry.params.std < 0.001

        @impl true
        def params_to_instance(%{mean: mean}), do: mean

        defp sample_mean(sample, n), do: Enum.sum(sample) / n

        defp sample_std(sample, n, mean) do
          sample
          |> Enum.map(&((&1 - mean) * (&1 - mean)))
          |> Enum.sum()
          |> Kernel./(n)
          |> :math.sqrt()
        end

        defp smooth(x, x_prev, f), do: f * x + (1 - f) * x_prev
      end

  This module can be used by passing it to `CEM.search/2`. Execute CEM optimization
  with the default options as follows:

      CEM.search(MyProblem)

  This will return something like

      %CEM{
        step: 8,
        params: %{std: 3.215547569473733e-4, mean: 3.9999115132284735},
        score: 0.9999998819745811,
        solution: 3.99993602848477,
        log: [
          %CEM.Log.Entry{
            step: 8,
            params: %{std: 3.215547569473733e-4, mean: 3.9999115132284735},
            score: 0.9999998819745811
          },
          ...
        ]
      }
  """

  use CEM.Types

  @doc """
  Initialize the parameters of the probability distribution used to generate
  instances.
  """
  @callback init_params(opts) :: params

  @doc """
  Draw a random instance from the probability distribution with the given
  parameters.
  """
  @callback draw_instance(params) :: instance

  @doc """
  Score an instance with a floating point number.
  """
  @callback score_instance(instance) :: float

  @doc """
  Update the parameters of the probability distribution using a sample of
  instances.
  """
  @callback update_params([instance]) :: params

  @doc """
  Smooth the parameters of the probability distribution by linearly
  interpolating between the most recent sample-based update and the parameters
  from the previous optimization iteration.
  """
  @callback smooth_params(params_new :: params, params_prev :: params, float) :: params

  @doc """
  Decide if the search should be terminated based on the log so far.
  """
  @callback terminate?(log, opts) :: boolean

  @doc """
  Given final parameters of the instance-generating probability distribution,
  return the corresponding most likely solution instance.
  """
  @callback params_to_instance(params) :: instance

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour CEM.Problem
    end
  end
end
