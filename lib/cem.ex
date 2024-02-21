defmodule CEM do
  @moduledoc """
  A behaviour module that defines callbacks needed to execute CEM optimization.

  ## Define a problem

  The `CEM` behaviour defines a number of callbacks that need to be implemented
  in order to fully specify a `CEM` problem.

  Here is a problem module that implements one-dimensional continuous
  optimization for a normal probability distribution:

      defmodule MyProblem do
        use CEM

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

  ## Search

  Once the problem is defined, execute the search with

      CEM.search(MyProblem, opts)

  where `opts` is a keyword list of options.
  """

  alias CEM.Log
  alias CEM.Options
  alias CEM.Sample
  alias CEM.Update

  @typedoc "map of options used internally"
  @type opts :: map()

  @typedoc "parameters of the the probability distribution used to generate instances"
  @type params :: any()

  @typedoc "a canidate solution instance"
  @type instance :: any()

  @typedoc "value of the instance objective function used to evaluate instances"
  @type score :: float()

  @typedoc "iteration count for a single CEM solver"
  @type step :: non_neg_integer()

  @doc """
  Initialize the parameters of the probability distribution used to generate
  instances.
  """
  @callback init_params(opts()) :: params()

  @doc """
  Draw a random instance from the probability distribution with the given
  parameters.
  """
  @callback draw_instance(params()) :: instance()

  @doc """
  Score an instance with a floating point number.
  """
  @callback score_instance(instance()) :: score()

  @doc """
  Update the parameters of the probability distribution using a sample of
  instances.
  """
  @callback update_params([instance()]) :: params()

  @doc """
  Smooth the parameters of the probability distribution by linearly
  interpolating between the most recent sample-based update and the parameters
  from the previous optimization iteration.
  """
  @callback smooth_params(params_new :: params(), params_prev :: params(), float()) :: params()

  @doc """
  Decide if the search should be terminated based on the log so far.
  """
  @callback terminate?(Log.t(), opts()) :: boolean()

  @doc """
  Given final parameters of the instance-generating probability distribution,
  return the corresponding most likely solution instance.
  """
  @callback params_to_instance(params()) :: instance()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour CEM
    end
  end

  @doc """
  Search for the optimal solution instance.

  Given a problem module and optional parameters, execute CEM optimization
  and return the optimal solution instance and its score, corresponding
  parameters of the probabiity distribution, and a log of optimization
  progress.

  ## Options

  #{NimbleOptions.docs(CEM.Options.schema())}
  """
  @spec search(problem_module :: module(), opts :: keyword()) :: map()
  def search(problem_module, opts \\ []) do
    opts = Options.validate_and_augment(opts)
    loop_fns = init_loop_fns(problem_module, opts)
    loop(problem_module.init_params(opts), 1, Log.new(), loop_fns)
  end

  @spec loop(params(), step(), Log.t(), map()) :: map()
  defp loop(params, step, log, loop_fns) do
    {sample_elite, score_elite} = loop_fns.generate_fn.(params)
    params_elite = loop_fns.update_fn.(params, sample_elite)
    log = Log.update(log, step, params_elite, score_elite)

    if loop_fns.terminate_fn.(log) do
      step = log |> hd() |> Map.get(:step)

      %{
        step: step,
        params: params_elite,
        score: score_elite,
        solution: loop_fns.params_to_instance_fn.(params),
        log: log
      }
    else
      loop(params_elite, step + 1, log, loop_fns)
    end
  end

  @spec init_loop_fns(module(), opts()) :: map()
  defp init_loop_fns(problem_module, opts) do
    generate_fn =
      fn params ->
        Sample.generate_elite_sample_and_score(
          params,
          &problem_module.draw_instance/1,
          &problem_module.score_instance/1,
          opts
        )
      end

    update_fn =
      fn params, sample ->
        Update.update_and_smooth_params(
          params,
          sample,
          &problem_module.update_params/1,
          &problem_module.smooth_params/3,
          opts
        )
      end

    terminate_fn = fn
      [] ->
        false

      [%Log.Entry{step: step} | _] = log ->
        step >= opts.n_step_max or problem_module.terminate?(log, opts)
    end

    %{
      generate_fn: generate_fn,
      update_fn: update_fn,
      terminate_fn: terminate_fn,
      params_to_instance_fn: &problem_module.params_to_instance/1
    }
  end
end
