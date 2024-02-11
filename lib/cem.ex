defmodule CEM do
  @moduledoc """
  ## Notes
  - Should CEM provide a function for extracting the final best solution from the
    params?
    - e.g., the float mean for normal params (or list of means)
    - e.g., a list of thresholded binary values for a binary instance?
    - this is where instance type would play a role
  - Introduce a random seed as an optional param so that runs are reproducible.
  - Somehow allow configurable smoothing.
    - Not sure how to do dynamic smoothing in general.
  - When using an ensemble of CEM searchers, what about using a score-weighted
    linear combination?
    - Kind of a generalization of smoothing.
    - Might inhibit premature exploitation in a way that is stronger than
      current-prev smoothing between search steps.
  - The RH means that only the elite sample is stored, but a down side
    is that the scoring can't be parallelized without putting the RH into a
    process.
    - Well, it can be parallelized, but then the whole sample must be in memory, which
      purpose of the RH.
  - Introduce concurrency into CEM
    - Batch size for a single sample (default to n_sample)
    - Number of parallel CEM instances (default to 1)
  """

  alias CEM.Options

  @type opts :: keyword
  @type params :: any
  @type instance :: any
  @type score :: float
  @type step :: non_neg_integer()
  @type trace :: [%{step: step, params: params, score: score}]

  @doc """
  Execute the CEM optimization algorithm for the given problem module and
  optional parameters.
  """
  @spec search(problem_module :: module, opts :: opts) :: map
  def search(problem_module, opts \\ []) do
    opts = NimbleOptions.validate!(opts, Options.schema()) |> Map.new()
    opts = Map.put(opts, :n_elite, ceil(opts.f_elite * opts.n_sample))

    generate_fn =
      fn params ->
        generate_elite_sample_and_score(
          params,
          &problem_module.draw_instance/1,
          &problem_module.score_instance/1,
          opts
        )
      end

    update_fn =
      fn params, sample ->
        update_and_smooth_params(
          params,
          sample,
          &problem_module.update_params/1,
          &problem_module.smooth_params/3,
          opts
        )
      end

    terminate_fn = fn trace ->
      problem_module.terminate?(trace, opts)
    end

    default_terminate_fn = fn [%{step: step} | _] = _trace ->
      step >= opts.n_step_max
    end

    params_init = problem_module.init_params(opts)

    loop_fns = %{
      generate_fn: generate_fn,
      update_fn: update_fn,
      terminate_fn: terminate_fn,
      default_terminate_fn: default_terminate_fn
    }

    loop(loop_fns, params_init, [])
  end

  defp loop(loop_fns, params, trace) do
    {sample_elite, score_elite} = loop_fns.generate_fn.(params)
    params_elite = loop_fns.update_fn.(params, sample_elite)
    trace = update_trace(trace, params_elite, score_elite)

    if loop_fns.terminate_fn.(trace) or loop_fns.default_terminate_fn.(trace) do
      %{params: params_elite, score: score_elite, trace: trace}
    else
      loop(loop_fns, params_elite, trace)
    end
  end

  defp generate_elite_sample_and_score(params, draw_instance_fn, score_instance_fn, opts) do
    order = mode_to_order(opts.mode)

    {sample, scores} =
      1..opts.n_sample
      |> Enum.map(fn _ ->
        inst = draw_instance_fn.(params)
        {inst, score_instance_fn.(inst)}
      end)
      |> Enum.sort_by(fn {_, s} -> s end, order)
      |> take_reverse(opts.n_elite)
      |> Enum.unzip()

    {sample, hd(scores)}
  end

  defp update_and_smooth_params(params, sample, update_params_fn, smooth_params_fn, opts) do
    sample
    |> update_params_fn.()
    |> smooth_params_fn.(params, opts.f_smooth)
  end

  defp update_trace(trace, params, score) do
    step =
      case trace do
        [] -> 1
        [%{step: step} | _] -> step + 1
      end

    [%{step: step, params: params, score: score} | trace]
  end

  defp mode_to_order(:min), do: :asc
  defp mode_to_order(:max), do: :desc

  # Like Enum.take, except the order of the elements is reversed, making it
  # efficient to get what would be the last item of Enum.take
  defp take_reverse(l, n), do: take_reverse(l, n, [])
  defp take_reverse(_l, 0, acc), do: acc
  defp take_reverse([], _n, acc), do: acc
  defp take_reverse([h | t], n, acc), do: take_reverse(t, n - 1, [h | acc])
end
