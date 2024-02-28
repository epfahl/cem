defmodule CEMTest do
  use ExUnit.Case
  doctest CEM

  test "exercise the full pipeline" do
    prob =
      CEM.new(
        init: fn _ -> 1 end,
        draw: fn _ -> 1 end,
        score: fn _ -> 1 end,
        update: fn _ -> 1 end,
        smooth: fn _, _, _ -> 1 end,
        terminate?: fn _, _ -> true end,
        params_to_instance: fn _ -> 1 end
      )

    %{step: step, params: params, solution: solution, score: score, log: log} =
      CEM.search(prob, n_sample: 10, f_elite: 0.3, other_opts: [other: 1])

    assert {step, params, solution, score} == {1, 1, 1, 1}
    assert length(log) == 1
  end
end
