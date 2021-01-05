defmodule ActionTest do
  use ExUnit.Case
  doctest Action

  test "greets the world" do
    assert Action.hello() == :world
  end
end
