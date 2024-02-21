defmodule CEMTestProblem do
  use CEM
  def init_params(_), do: 1
  def draw_instance(_), do: 1
  def score_instance(_), do: 1
  def update_params(_), do: 1
  def smooth_params(_, _, _), do: 1
  def terminate?(_, _), do: true
  def params_to_instance(_), do: 1
end

defmodule CEMTest do
  use ExUnit.Case
  doctest CEM

  test "exercise the full pipeline" do
    %{step: step, params: params, solution: solution, score: score, log: log} =
      CEM.search(CEMTestProblem, n_sample: 10, f_elite: 0.3)

    assert {step, params, solution, score} == {1, 1, 1, 1}
    assert length(log) == 1
  end
end
