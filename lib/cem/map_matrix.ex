defmodule CEM.MapMatrix do
  @moduledoc """
  A matrix data structure based on nested maps with a very limited set of
  operations.

  For certain problems, it's more performant to use `MapMatrix` operations
  than the equivalent opertations on `Nx` tensors.
  """

  alias __MODULE__

  defstruct [:matrix, :shape]

  @type index() :: non_neg_integer()
  @type shape() :: {pos_integer(), pos_integer()}
  @type t :: %MapMatrix{
          matrix: %{index() => %{index() => number()}},
          shape: shape()
        }

  @doc """
  Create a `MapMatrix` with the shape `{n_row, n_col}` and all values set to
  zero.
  """
  @spec zero(shape()) :: t()
  def zero({n_row, n_col})
      when is_integer(n_row) and n_row > 0 and is_integer(n_col) and n_col > 0 do
    matrix =
      Map.new(0..(n_row - 1), fn i ->
        {i, Map.new(0..(n_col - 1), fn j -> {j, 0} end)}
      end)

    %MapMatrix{matrix: matrix, shape: {n_row, n_col}}
  end

  @doc """
  Get the value at the given index pair `{i, j}`.
  """
  @spec get(t(), {index(), index()}) :: number()
  def get(%MapMatrix{matrix: matrix, shape: {n_row, n_col}}, {i, j})
      when 0 <= i and i < n_row and 0 <= j and j < n_col do
    matrix[i][j]
  end

  @doc """
  Set the value at the given index pair `{i, j}`.
  """
  @spec put(t(), {index(), index()}, number) :: t()
  def put(%MapMatrix{matrix: matrix, shape: {n_row, n_col}} = m, {i, j}, value)
      when 0 <= i and i < n_row and 0 <= j and j < n_col and is_number(value) do
    %{m | matrix: put_in(matrix, [i, j], value)}
  end

  @doc """
  Collect values at the given index pairs `[{i, j},...]` into a list.

  This is similar to `Nx.gather/2`.
  """
  @spec gather(t(), [{index(), index()}]) :: [number()]
  def gather(%MapMatrix{} = m, index_pairs) do
    Enum.map(index_pairs, &get(m, &1))
  end

  @doc """
  Return the shape `{n_row, n_col}` of the `MapMatrix`.
  """
  @spec shape(t()) :: shape()
  def shape(%MapMatrix{shape: shape}), do: shape

  @doc """
  Convert the `MapMatrix` to a list of lists of values.

  The result can be passed directly to `Nx.tensor/1` to get the tensor
  representation of the matrix.
  """
  @spec to_list(t()) :: [[number()]]
  def to_list(%MapMatrix{matrix: matrix, shape: {n_row, n_col}}) do
    Enum.map(0..(n_row - 1), fn i ->
      Enum.map(0..(n_col - 1), fn j -> matrix[i][j] end)
    end)
  end

  @doc """
  Given a list of lists of values, return a `MapMatrix`.

  This is useful when converting an `Nx` tensor to a `MapMatrix`.
  """
  @spec from_list([[number()]]) :: t()
  def from_list(list_of_lists) do
    n_row = length(list_of_lists)
    n_col = length(hd(list_of_lists))

    matrix =
      list_of_lists
      |> Enum.with_index(fn row, i ->
        {i,
         row
         |> Enum.with_index(fn v, j -> {j, v} end)
         |> Map.new()}
      end)
      |> Map.new()

    %MapMatrix{matrix: matrix, shape: {n_row, n_col}}
  end
end
