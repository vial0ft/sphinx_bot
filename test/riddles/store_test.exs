defmodule Riddles.StoreTest do
  alias Riddles.Store
  use ExUnit.Case
  doctest Riddles.Store

  test("storing riddle with pid") do
    {:ok, key} = Store.add("riddle", {:riddle, self()})
    assert Store.get(key) == {:ok, {:riddle, self()}}
    assert Store.get("riddle") == {:ok, {:riddle, self()}}
  end

  test("getting not existed riddle") do
    assert Store.get("not_exist") == {:error, "Not found"}
  end

  @tag :slow
  test "getting expired riddle (1 min expiration)" do
    {:ok, key} = Store.add("riddle", {:riddle, self()})
    assert Store.get(key) == {:ok, {:riddle, self()}}
    Process.sleep(65 * 1000)
    assert Store.get(key) == {:error, "Expired"}
  end

  @tag :slow
  @tag timeout: 5 * 70 * 1000
  test "getting cleaned up riddle (5 min before clean up)" do
    {:ok, key} = Store.add("riddle", {:riddle, self()})
    assert Store.get(key) == {:ok, {:riddle, self()}}
    Process.sleep(5 * 65 * 1000)
    assert Store.get(key) == {:error, "Not found"}
  end
end
