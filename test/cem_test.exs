defmodule CEMTest do
  use ExUnit.Case
  doctest CEM

  test "greets the world" do
    assert CEM.hello() == :world
  end
end
