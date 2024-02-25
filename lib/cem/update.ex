defmodule CEM.Update do
  @moduledoc """
  Update and smooth parameters of the instance-generating probability distribution.
  """

  @type opts :: map
  @type params :: any
  @type instance :: any
  @type update_fn :: ([instance()] -> params())
  @type smooth_fn :: (params(), params(), float() -> params())

  @doc """
  Update the parameters from a sample and then smooth based on the previous parameter values.
  """
  @spec update_and_smooth(
          params(),
          [instance()],
          update_fn(),
          smooth_fn(),
          opts()
        ) :: params()
  def update_and_smooth(params, sample, update_fn, smooth_fn, opts) do
    sample
    |> update_fn.()
    |> smooth_fn.(params, opts.f_smooth)
  end
end
