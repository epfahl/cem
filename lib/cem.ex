defmodule CEM do
  @moduledoc """
  The primary interface for defining a CEM optimization problem and executing
  the search.

  ..._summarize the functional flow of CEM optimization_...
  ..._a mermaid diagram may be helpful_...

  ## Define a problem

  A `CEM` problem is a struct that holds seven (7) required functions. In many
  situations, it will make sense to define some or all of these functions in a
  module and then create the problem struct using `CEM.new/1`.

  For example, here's a module that defines a simple one-dimensional
  optimization problem:

      defmodule MyProblem do

        def init(_opts), do: %{mean: 0, std: 100}

        def draw(%{mean: mean, std: std}), do: CEM.Random.normal(mean, std)

        def score(x), do: :math.exp(-x * x)

        def update(sample) do
          n = length(sample)
          mean = sample_mean(sample, n)
          std = sample_std(sample, n, mean)
          %{mean: mean, std: std}
        end

        def smooth(params, params_prev, f_smooth) do
          %{
            mean: smooth(params.mean, params_prev.mean, f_smooth),
            std: smooth(params.std, params_prev.std, f_smooth)
          }
        end

        def terminate?([entry | _], _opts), do: entry.params.std < 0.001

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

  Now build the struct:

      problem =
        CEM.new(
          init: &MyProblem.init/1,
          draw: &MyProblem.draw/1,
          score: &MyProblem.score/1,
          update: &MyProblem.update/1,
          smooth: &MyProblem.smooth/3,
          terminate?: &MyProblem.terminate?/2,
          params_to_instance: &MyProblem.params_to_instance/1
        )

  ## Search

  Once the problem struct is defined, execute the search with `CEM.search/2`:

      CEM.search(problem, opts)

  where `opts` is a keyword list of options. For details, see the documentation
  for `CEM.search/2`.
  """

  alias CEM.Log
  alias CEM.Problem
  alias CEM.Sample
  alias CEM.SearchValidators
  alias CEM.Update

  @search_options_schema [
    n_sample: [
      type: :non_neg_integer,
      default: 100,
      doc: "The size of the sample generated before selecting the elite set."
    ],
    f_elite: [
      type: {:custom, SearchValidators, :validate_range, [0, 1]},
      default: 0.1,
      doc: "The fraction between 0 and 1 of the sample size used to select the elite set."
    ],
    f_smooth: [
      type: {:custom, SearchValidators, :validate_range, [0, 1]},
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
    ],
    other_opts: [
      type: :keyword_list,
      doc: "User-specified options. _Warning: these are not validated._"
    ]
  ]

  @typedoc """
  Map of options used internally.
  """
  @type opts() :: map()

  @typedoc """
  Parameters of the the probability distribution used to generate candidate
  solutions.
  """
  @type params() :: any()

  @typedoc """
  Iteration count for the CEM search.
  """
  @type step() :: non_neg_integer()

  @doc """
  Create a new `CEM.Problem` struct from a keyword list of required functions.

  The required functions are:

  #{NimbleOptions.docs(Problem.schema())}
  """
  @spec new(keyword()) :: Problem.t()
  def new(funcs), do: Problem.new(funcs)

  @doc """
  Replace a required function in the `CEM.Problem` struct.
  """
  @spec replace(Problem.t(), atom(), fun()) :: Problem.t()
  def replace(%Problem{} = problem, fun_name, fun), do: Problem.replace(problem, fun_name, fun)

  @doc """
  Search for the optimal solution instance.

  Given a `CEM` struct and optional parameters, return the optimal solution
  instance and its score, the corresponding parameters of the probabiity
  distribution, and a log of optimization progress.

  ## Options

  #{NimbleOptions.docs(@search_options_schema)}
  """
  @spec search(Problem.t(), opts :: keyword()) :: map()
  def search(%Problem{} = problem, opts \\ []) do
    opts = validate_and_augment(opts, @search_options_schema)
    loop_fns = init_loop_fns(problem, opts)
    loop(problem.init.(opts), 1, Log.new(), loop_fns)
  end

  # The main search loop that refines the parameters of the instance-generating
  # probability distribution.
  @spec loop(params(), step(), Log.t(), map()) :: map()
  defp loop(params, step, log, loop_fns) do
    {sample_elite, score_elite} = loop_fns.generate_fn.(params)
    params_elite = loop_fns.update_fn.(params, sample_elite)
    log = Log.update(log, %{step: step, params: params_elite, score: score_elite})

    if loop_fns.terminate_fn.(log) do
      step = log |> hd() |> Map.get(:step)

      %{
        step: step,
        params: params_elite,
        score: score_elite,
        solution: loop_fns.params_to_instance_fn.(params_elite),
        log: log
      }
    else
      loop(params_elite, step + 1, log, loop_fns)
    end
  end

  # Initialize the functions needed in the search loop
  @spec init_loop_fns(Problem.t(), opts()) :: map()
  defp init_loop_fns(problem, opts) do
    generate_fn =
      fn params ->
        Sample.generate_elite_sample_and_score(
          params,
          problem.draw,
          problem.score,
          opts
        )
      end

    update_fn =
      fn params, sample ->
        Update.update_and_smooth(params, sample, problem.update, problem.smooth, opts)
      end

    terminate_fn = fn
      [] ->
        false

      [%{step: step} | _] = log ->
        step >= opts.n_step_max or problem.terminate?.(log, opts)
    end

    %{
      generate_fn: generate_fn,
      update_fn: update_fn,
      terminate_fn: terminate_fn,
      params_to_instance_fn: problem.params_to_instance
    }
  end

  # Validate `CEM.search/2` options with `NimbleOptions` and augment with new keywords.
  @spec validate_and_augment(keyword(), keyword()) :: map()
  defp validate_and_augment(opts, schema) do
    opts = opts |> NimbleOptions.validate!(schema) |> Map.new()
    Map.put(opts, :n_elite, ceil(opts.f_elite * opts.n_sample))
  end
end
