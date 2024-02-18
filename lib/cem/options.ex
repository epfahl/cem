defmodule CEM.Options do
  @moduledoc """
  Manage and validate optional arguments passed to `CEM.search/2`.
  """

  def schema() do
    [
      n_sample: [
        type: :non_neg_integer,
        default: 100,
        doc: "The size of the sample generated before selecting the elite set."
      ],
      f_elite: [
        type: {:custom, CEM.Options, :validate_range, [0, 1]},
        default: 0.1,
        doc: "The fraction between 0 and 1 of the sample size used to select the elite set."
      ],
      f_smooth: [
        type: {:custom, CEM.Options, :validate_range, [0, 1]},
        default: 0.9,
        doc: "A parameter between 0 and 1 used to smooth the distribution parameters."
      ],
      mode: [
        type: {:in, [:min, :max]},
        default: :max,
        doc: "The optimization mode, either `:min` (minimization) or `:max` (maximization)."
      ],
      n_step_max: [
        type: :non_neg_integer,
        default: 100,
        doc:
          "The number of parameter update steps at which the search is terminated. " <>
            "Use this as a fail-safe to prevent infinite recursion."
      ]
    ]
  end

  @spec validate_and_augment(opts :: keyword()) :: map()
  def validate_and_augment(opts) do
    opts = opts |> NimbleOptions.validate!(schema()) |> Map.new()
    Map.put(opts, :n_elite, ceil(opts.f_elite * opts.n_sample))
  end

  @spec validate_range(any, number, number) :: {:ok, any} | {:error, String.t()}
  def validate_range(x, low, high) do
    if x >= low and x <= high do
      {:ok, x}
    else
      {:error, "expected a value from #{low} to #{high}, but got #{x}"}
    end
  end
end
