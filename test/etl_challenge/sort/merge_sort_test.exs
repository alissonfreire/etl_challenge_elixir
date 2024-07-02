defmodule EtlChallenge.Sort.MergeSortTest do
  use ExUnit.Case, async: true

  alias EtlChallenge.Sort.MergeSort

  describe "sort/1" do
    test "with empty list" do
      assert MergeSort.sort([]) == []
      assert MergeSort.sort([]) == Enum.sort([])
    end

    test "with single item list" do
      assert MergeSort.sort([1]) == [1]
      assert MergeSort.sort([1]) == Enum.sort([1])
    end

    test "with decresecent integer list" do
      desc_numbers = [9, 8, 7, 6, 5, 4, 3, 2, 1]

      assert MergeSort.sort(desc_numbers) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
      assert MergeSort.sort(desc_numbers) == Enum.sort(desc_numbers)
    end

    test "with manual filled random and float numbers list" do
      unsorted_numbers = [3.14, 2.67, -1, 5, -6, -2.1]

      assert MergeSort.sort(unsorted_numbers) == [-6, -2.1, -1, 2.67, 3.14, 5]
      assert MergeSort.sort(unsorted_numbers) == Enum.sort(unsorted_numbers)
    end

    test "with random numbers list" do
      unsorted_numbers = for _ <- 0..100, do: :rand.uniform()

      assert MergeSort.sort(unsorted_numbers) == Enum.sort(unsorted_numbers)
    end
  end
end
