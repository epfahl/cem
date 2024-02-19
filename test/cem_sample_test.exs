defmodule CEMSampleTest do
  use ExUnit.Case
  doctest CEM.Sample

  alias CEM.Sample

  setup_all do
    {:ok,
     generate_fn: fn mode ->
       Sample.generate_elite_sample_and_score(
         0,
         fn _ -> 1 end,
         fn _ -> 1 end,
         %{
           mode: mode,
           n_sample: 10,
           n_elite: 3
         }
       )
     end}
  end

  test "generate a sample and score with mode max", %{generate_fn: generate_fn} do
    {instances, score} = generate_fn.(:max)
    assert length(instances) == 3
    assert score == 1
  end

  test "generate a sample and score with mode min", %{generate_fn: generate_fn} do
    {instances, score} = generate_fn.(:min)
    assert length(instances) == 3
    assert score == 1
  end
end
