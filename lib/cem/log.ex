defmodule CEM.Log do
  @moduledoc """

  """

  defmodule Entry do
    defstruct [:step, :params, :score]

    @type t :: %__MODULE__{
            step: pos_integer(),
            params: any(),
            score: float()
          }

    @spec new(pos_integer(), any(), float()) :: t
    def new(step, params, score) do
      %Entry{step: step, params: params, score: score}
    end
  end

  @type t :: [Entry.t()]

  @spec new() :: [Entry.t()]
  def new(), do: []

  @spec update(t, pos_integer(), any, float) :: t
  def update(log, step, params, score) do
    [Entry.new(step, params, score) | log]
  end
end
