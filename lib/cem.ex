defmodule CEM do
  @moduledoc """

  ## Notes
  - Consider how smoothing might be made configurable.
    - An optional callback for computing the smoothing parameters
      adaptively/dynamically?
  """

  alias CEM.Options
  alias CEM.RankHeap

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
      default_terminate_fn: default_terminate_fn,
      params_to_instance_fn: &problem_module.params_to_instance/1
    }

    loop(loop_fns, params_init, [])
  end

  defp loop(loop_fns, params, trace) do
    {sample_elite, score_elite} = loop_fns.generate_fn.(params)
    params_elite = loop_fns.update_fn.(params, sample_elite)
    trace = update_trace(trace, params_elite, score_elite)

    if loop_fns.terminate_fn.(trace) or loop_fns.default_terminate_fn.(trace) do
      %{
        solution: loop_fns.params_to_instance_fn.(params),
        params: params_elite,
        score: score_elite,
        trace: trace
      }
    else
      loop(loop_fns, params_elite, trace)
    end
  end

  defp generate_elite_sample_and_score(params, draw_instance_fn, score_instance_fn, opts) do
    rank_heap =
      stream_to_rank(
        init_rank_heap(opts.mode, opts.n_elite),
        fn ->
          inst = draw_instance_fn.(params)
          {inst, score_instance_fn.(inst)}
        end,
        opts.n_sample
      )

    sample = RankHeap.values(rank_heap)
    score = RankHeap.root_key(rank_heap)

    {sample, score}
  end

  defp init_rank_heap(mode, size) do
    mode
    |> case do
      :min -> :low
      :max -> :high
    end
    |> RankHeap.new(size)
  end

  # https://elixirforum.com/t/why-is-stream-reduce-while-missing/34422/4
  # Test memory load for an expensive draw/score
  # replace scan, take, to_list with a Enum.reduce and test (memory and time)
  @spec stream_to_rank(RankHeap.t(), (-> {instance, score}), pos_integer) :: RankHeap.t()
  defp stream_to_rank(rank_heap, draw_and_score_fn, n_sample) do
    Stream.repeatedly(fn -> draw_and_score_fn end)
    |> Stream.take(n_sample)
    |> Task.async_stream(& &1.(), ordered: false)
    |> Stream.scan(rank_heap, fn {:ok, {inst, score}}, rh ->
      RankHeap.update(rh, score, inst)
    end)
    |> Stream.take(-1)
    |> Enum.to_list()
    |> hd()
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
end
