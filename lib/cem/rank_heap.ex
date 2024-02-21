defmodule CEM.RankHeap do
  @moduledoc """
  Module that defines a `RankHeap` as an adaptation of `PairingHeap`.

  The rank heap maintains a maximum number of key-value pairs that
  represents the pairs with the highest or lowest keys in a stream.
  """

  alias __MODULE__

  defstruct [:heap, :size, :mode, :max_size, :swap?]

  @type mode :: :low | :high
  @type key :: number
  @type value :: any

  @type t :: %RankHeap{
          heap: PairingHeap.t(),
          size: non_neg_integer(),
          mode: mode,
          max_size: pos_integer(),
          swap?: (number, number -> boolean)
        }

  @doc """
  Create a new rank heap.
  """
  @spec new(mode :: mode, max_size :: non_neg_integer()) :: t
  def new(mode, max_size) when max_size > 0 do
    %RankHeap{
      heap: mode |> to_heap_mode() |> PairingHeap.new(),
      size: 0,
      mode: mode,
      max_size: max_size,
      swap?: to_swap_fn(mode)
    }
  end

  @doc """
  Update the rank heap with a new key-value pair.
  """
  @spec update(t, key, value) :: t
  def update(%RankHeap{heap: heap, size: size, max_size: max_size} = rank_heap, key, value)
      when size < max_size do
    %{rank_heap | heap: PairingHeap.put(heap, key, value), size: size + 1}
  end

  def update(%RankHeap{heap: heap, swap?: swap?} = rank_heap, key, value) do
    {:ok, {root_key, _value}} = PairingHeap.peek(heap)

    heap =
      if swap?.(key, root_key) do
        {:ok, _, heap} = PairingHeap.pop(heap)
        PairingHeap.put(heap, key, value)
      else
        heap
      end

    %{rank_heap | heap: heap}
  end

  @doc """
  Return the values in the rank heap.
  """
  @spec values(t) :: [value]
  def values(%RankHeap{heap: heap}) do
    heap
    |> Enum.to_list()
    |> Enum.unzip()
    |> elem(1)
  end

  @doc """
  Return the root key of the rank heap.
  """
  @spec root_key(t) :: {:ok, key} | :error
  def root_key(%RankHeap{heap: heap}) do
    with {:ok, {root_key, _value}} <- PairingHeap.peek(heap) do
      {:ok, root_key}
    end
  end

  @spec to_swap_fn(mode) :: (number, number -> boolean)
  defp to_swap_fn(:low), do: &</2
  defp to_swap_fn(:high), do: &>/2

  @spec to_heap_mode(mode) :: :min | :max
  defp to_heap_mode(:low), do: :max
  defp to_heap_mode(:high), do: :min
end
