defmodule CEM.Update do
  @moduledoc """
  Update and smooth parameters of the instance-generating probability distribution.
  """

  @type opts :: map
  @type params :: any
  @type instance :: any
  @type update_params_fn :: ([instance()] -> params())
  @type smooth_params_fn :: (params(), params(), float() -> params())

  @doc """
  Update the parameters from a sample and then smooth based on the previous parameter values.
  """
  @spec update_and_smooth_params(
          params(),
          [instance()],
          update_params_fn(),
          smooth_params_fn(),
          opts()
        ) :: params()
  def update_and_smooth_params(params, sample, update_params_fn, smooth_params_fn, opts) do
    sample
    |> update_params_fn.()
    |> smooth_params_fn.(params, opts.f_smooth)
  end
end
