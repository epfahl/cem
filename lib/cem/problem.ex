defmodule CEM.Problem do
  @moduledoc """
  Module defining a `Problem` struct.
  """

  alias __MODULE__

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
  Canidate solution.
  """
  @type instance() :: any()

  @typedoc """
  Iteration count for the CEM search.
  """
  @type step() :: non_neg_integer()

  @typedoc """
  Score value of a candidate solution.
  """
  @type score_value() :: float()

  @function_docs %{
    init: """
    Function to initialize the parameters of the probability distribution used to
    generate candidate solutions.
    """,
    draw: """
    Function to draw a random instance from the probability distribution with the given
    parameters.
    """,
    score: """
    Function to score a candidate solution.
    """,
    update: """
    Function to update the parameters of the probability distribution using a
    sample of candidate solutions.
    """,
    smooth: """
    Function to smooth the parameters of the probability distribution by linearly
    interpolating between the most recent sample-based update and the parameters
    from the previous optimization iteration.
    """,
    terminate?: """
    Function to decide if the search should be terminated based on the log so far.
    If not provided, the search will end when the `n_step_max` is reached (see docs
    for `CEM.search/2`).
    """
  }

  @typedoc @function_docs.init
  @type init() :: (opts() -> params())

  @typedoc @function_docs.draw
  @type draw() :: (params() -> instance())

  @typedoc @function_docs.score
  @type score() :: (instance() -> score_value())

  @typedoc @function_docs.update
  @type update() :: ([instance()] -> params())

  @typedoc @function_docs.smooth
  @type smooth() :: (params_new :: params(), params_prev :: params(), float() -> params())

  @typedoc @function_docs.terminate?
  @type terminate?() :: (Log.t(), opts() -> boolean())

  def schema() do
    [
      init: [
        type: {:fun, 1},
        required: true,
        doc: @function_docs.init
      ],
      draw: [
        type: {:fun, 1},
        required: true,
        doc: @function_docs.draw
      ],
      score: [
        type: {:fun, 1},
        required: true,
        doc: @function_docs.score
      ],
      update: [
        type: {:fun, 1},
        required: true,
        doc: @function_docs.update
      ],
      smooth: [
        type: {:fun, 3},
        required: true,
        doc: @function_docs.smooth
      ],
      terminate?: [
        type: {:fun, 2},
        required: false,
        doc: @function_docs.terminate?
      ]
    ]
  end

  @enforce_keys [:init, :draw, :score, :update, :smooth, :terminate?]
  defstruct [:init, :draw, :score, :update, :smooth, :terminate?]

  @type t :: %Problem{
          init: init(),
          draw: draw(),
          score: score(),
          update: update(),
          smooth: smooth(),
          terminate?: terminate?() | nil
        }

  @spec new(keyword()) :: t()
  def new(funcs) do
    funcs = NimbleOptions.validate!(funcs, schema())

    struct(__MODULE__, funcs)
  end

  @spec replace(t(), atom(), fun()) :: t()
  def replace(%Problem{} = problem, fun_name, fun) when is_atom(fun_name) and is_function(fun) do
    {fun_name, fun} =
      case validate_replace(fun_name, fun) do
        {:ok, {fun_name, fun}} -> {fun_name, fun}
        {:error, validation_error} -> raise validation_error
      end

    Map.replace!(problem, fun_name, fun)
  end

  @spec validate_replace(atom(), fun()) ::
          {:ok, {atom(), fun()}} | {:error, NimbleOptions.ValidationError.t()}
  defp validate_replace(fun_name, fun) do
    opts = [{fun_name, fun}]

    with {:ok, _} <- NimbleOptions.validate(opts, dummy_schema()),
         {:ok, _} <- NimbleOptions.validate(opts, Keyword.take(schema(), [fun_name])) do
      {:ok, {fun_name, fun}}
    end
  end

  @spec dummy_schema() :: [{atom(), []}]
  defp dummy_schema(), do: schema() |> Enum.map(fn {opt, _} -> {opt, []} end)
end
