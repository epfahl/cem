defmodule CEM.Sample do
  @moduledoc """
  Generate a sample of instance-score pairs from the instance-generating
  probability distribution.
  """

  use CEM.Types

  alias CEM.RankHeap

  @doc """
  Given parameters of the instance-generating probability distribution,
  generate the elite sample of instances and the smallest (maximization
  problem) or largest (minimization problem) score of that sample.
  """
  @spec generate_elite_sample_and_score(params(), draw_instance_fn(), score_instance_fn(), opts()) ::
          {[instance], score}
  def generate_elite_sample_and_score(params, draw_instance_fn, score_instnace_fn, opts) do
    params
    |> stream_instances_and_scores(draw_instance_fn, score_instnace_fn)
    |> reduce_to_elite_sample_and_score(opts)
  end

  @doc """
  Return a stream of instance-score pairs.
  """
  @spec stream_instances_and_scores(params(), draw_instance_fn(), score_instance_fn()) ::
          Enumerable.t()
  def stream_instances_and_scores(params, draw_instance_fn, score_instance_fn) do
    Stream.repeatedly(fn ->
      fn ->
        inst = draw_instance_fn.(params)
        {inst, score_instance_fn.(inst)}
      end
    end)
  end

  @doc """
  Reduce a stream of instance-score pairs into the elite sample and the score
  associated with that sample.

  Note: The body of this function
  """
  @spec reduce_to_elite_sample_and_score(Enumerable.t(), opts()) :: {[instance()], score()}
  def reduce_to_elite_sample_and_score(sample_stream, opts) do
    sample_stream
    |> reduce_to_rank_heap(opts)
    |> get_sample_and_score_from_rank_heap()
  end

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
