defmodule CEM.Types do
  defmacro __using__(_opts) do
    quote do
      @typedoc "map of options used internally"
      @type opts :: map

      @typedoc "parameters of the the probability distribution used to generate instances"
      @type params :: any

      @typedoc "a canidate solution instance"
      @type instance :: any

      @typedoc "value of the instance objective function used to evaluate instances"
      @type score :: float

      @typedoc "iteration count for a single CEM solver"
      @type step :: non_neg_integer()

      @type log :: [%{step: step, params: params, score: score}]
      @type draw_instance_fn :: (params() -> instance())
      @type score_instance_fn :: (instance() -> float())
      @type update_params_fn :: ([instance()] -> params())
      @type smooth_params_fn :: (params(), params(), float() -> params())
      @type terminate_fn :: (log(), opts() -> boolean())
      @type params_to_instance_fn :: (params() -> instance())
    end
  end
end
