defmodule ScriptTest do
  use ExUnit.Case
  doctest Script

  test "greets the world" do
    assert Script.hello() == :world
  end
end
