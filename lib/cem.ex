defmodule CEM do
  @moduledoc """
  An Elixir framework for applying the cross-entropy method to continuous and
  discrete optimization problems.

  Define a problem module according to the docs in `CEM.Problem`, and then
  execute CEM optimization using `CEM.search/2`. For example, if the problem
  module is `MyProblem`, then the search is executed as

      CEM.search(MyProblem, opts)

  where `opts` is a keyword list of options.
  """

  alias CEM.Log
  alias CEM.Options
  alias CEM.Sample
  alias CEM.Update

  defstruct [:step, :params, :score, :solution, :log]

  @type t :: %__MODULE__{
          step: pos_integer(),
          params: any(),
          score: float(),
          solution: any(),
          log: Log.t()
        }

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

    terminate_fn = fn [%{step: step} | _] = log ->
      step >= opts.n_step_max or problem_module.terminate?(log, opts)
    end

    params_init = problem_module.init_params(opts)

    loop_fns = %{
      generate_fn: generate_fn,
      update_fn: update_fn,
      terminate_fn: terminate_fn,
      params_to_instance_fn: &problem_module.params_to_instance/1
    }

    loop(loop_fns, params_init, 1, Log.new())
  end

  @spec loop(map(), any(), pos_integer(), Log.t()) :: t
  defp loop(loop_fns, params, step, log) do
    {sample_elite, score_elite} = loop_fns.generate_fn.(params)
    params_elite = loop_fns.update_fn.(params, sample_elite)
    log = Log.update(log, step, params_elite, score_elite)

    if loop_fns.terminate_fn.(log) do
      step = log |> hd() |> Map.get(:step)

      %__MODULE__{
        step: step,
        params: params_elite,
        score: score_elite,
        solution: loop_fns.params_to_instance_fn.(params),
        log: log
      }
    else
      loop(loop_fns, params_elite, step + 1, log)
    end
  end
end
