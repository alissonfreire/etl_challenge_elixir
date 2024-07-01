defmodule EtlChallenge.Sort.UtilsTest do
  use ExUnit.Case, async: true

  alias EtlChallenge.Sort.Utils

  describe "split_list_in_2/2" do
    test "with empty list" do
      assert Utils.split_list_in_2([]) == {[], []}
    end

    test "with single item list" do
      assert Utils.split_list_in_2([1]) == {[1], []}
    end

    test "with two items list" do
      assert Utils.split_list_in_2([2, 1]) == {[2], [1]}
    end

    test "with an odd number of elements" do
      assert Utils.split_list_in_2([7, 3, 8, 2, 1]) == {[7, 3], [8, 2, 1]}
    end
  end
end
