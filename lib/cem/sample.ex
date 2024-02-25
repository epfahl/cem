defmodule CEM.Sample do
  @moduledoc """
  Module for generating a sample of instance-score pairs from the
  instance-generating probability distribution.
  """

  alias CEM.RankHeap

  @type opts :: map()
  @type params :: any()
  @type instance :: any()
  @type score :: float()
  @type step :: non_neg_integer()
  @type draw_fn :: (params() -> instance())
  @type score_fn :: (instance() -> score())

  @doc """
  Given parameters of the instance-generating probability distribution,
  generate the elite sample of instances and the smallest (maximization
  problem) or largest (minimization problem) score of that sample.
  """
  @spec generate_elite_sample_and_score(params(), draw_fn(), score_fn(), opts()) ::
          {[instance], score}
  def generate_elite_sample_and_score(params, draw_fn, score_instnace_fn, opts) do
    params
    |> stream_instances_and_scores(draw_fn, score_instnace_fn)
    |> reduce_to_elite_sample_and_score(opts)
  end

  @doc """
  Return a stream of instance-score pairs.
  """
  @spec stream_instances_and_scores(params(), draw_fn(), score_fn()) ::
          Enumerable.t()
  def stream_instances_and_scores(params, draw_fn, score_fn) do
    Stream.repeatedly(fn ->
      fn ->
        inst = draw_fn.(params)
        {inst, score_fn.(inst)}
      end
    end)
  end

  @doc """
  Reduce a stream of instance-score pairs into the elite sample and the score
  associated with that sample.
  """
  @spec reduce_to_elite_sample_and_score(Enumerable.t(), opts()) :: {[instance()], score()}
  def reduce_to_elite_sample_and_score(sample_stream, opts) do
    sample_stream
    |> reduce_to_rank_heap(opts)
    |> get_sample_and_score_from_rank_heap()
  end

  # Use a `RankHeap` to consume a stream of key-value pairs and hold the pairs
  # with largest or smallest keys so far.
  @spec reduce_to_rank_heap(Enumerable.t(), opts()) :: RankHeap.t()
  defp reduce_to_rank_heap(sample_stream, opts) do
    sample_stream
    |> Stream.take(opts.n_sample)
    |> Task.async_stream(& &1.(), ordered: false)
    |> Enum.reduce(
      init_rank_heap(opts.mode, opts.n_elite),
      fn {:ok, {value, key}}, rh ->
        RankHeap.update(rh, key, value)
      end
    )
  end

  @spec get_sample_and_score_from_rank_heap(RankHeap.t()) :: {[instance()], score()}
  defp get_sample_and_score_from_rank_heap(rank_heap) do
    {:ok, score} = RankHeap.root_key(rank_heap)
    {RankHeap.values(rank_heap), score}
  end

  @spec init_rank_heap(atom(), pos_integer()) :: RankHeap.t()
  defp init_rank_heap(cem_mode, size) do
    rank_heap_mode =
      case cem_mode do
        :min -> :low
        :max -> :high
      end

    RankHeap.new(rank_heap_mode, size)
  end
end
