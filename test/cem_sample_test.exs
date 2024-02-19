defmodule CEMSampleTest do
  use ExUnit.Case
  doctest CEM.Sample

  alias CEM.Sample

  test "generate a sample and score with mode max" do
    {instances, score} =
      Sample.generate_elite_sample_and_score(
        0,
        fn _ -> 1 end,
        fn _ -> 1 end,
        %{
          mode: :max,
          n_sample: 10,
          n_elite: 3
        }
      )

    assert length(instances) == 3
    assert score == 1
  end

  test "generate a sample and score with mode min" do
    {instances, score} =
      Sample.generate_elite_sample_and_score(
        0,
        fn _ -> 1 end,
        fn _ -> 1 end,
        %{
          mode: :min,
          n_sample: 10,
          n_elite: 3
        }
      )

    assert length(instances) == 3
    assert score == 1
  end
end
