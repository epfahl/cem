defmodule CEM.Problem do
  use CEM.Types

  @doc """
  Draw a random instance from the probability distribution with the given
  parameters.
  """
  @callback init_params(opts) :: params

  @doc """
  Draw a random instance from the probability distribution with the given
  parameters.
  """
  @callback draw_instance(params) :: instance

  @doc """
  Score an instance with a floating point number.
  """
  @callback score_instance(instance) :: float

  @doc """
  Update the parameters of the probability distribution using a sample of
  instances.
  """
  @callback update_params([instance]) :: params

  @doc """
  Smooth the parameters of the probability distribution by linearly
  interpolating between the most recent sample-based update and the parameters
  from the previous optimization iteration.
  """
  @callback smooth_params(params_new :: params, params_prev :: params, float) :: params

  @doc """
  Decide if the search should be terminated based on the log so far.
  """
  @callback terminate?(log, opts) :: boolean

  @doc """
  Given final parameters of the instance-generating probability distribution,
  return the corresponding most likely solution instance.
  """
  @callback params_to_instance(params) :: instance

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour CEM.Problem
    end
  end
end
