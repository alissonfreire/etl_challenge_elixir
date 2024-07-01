defmodule EtlChallenge.Sort.QuickSort do
  @moduledoc """
  Quick uses the divide and conquer approach, which basically consists of choosing
  a pivot element, which in this approach will be the head of the list. Then separate
  the entry list into two other lists the one on the left with the items smaller than
  the pivot and on the right containing the numbers greater than the pivot
  """

  alias EtlChallenge.Sort.SortBehaviour

  @behaviour SortBehaviour

  @impl true
  @spec sort(items :: [number()]) :: [number()]

  def sort([]), do: []
  def sort([pivot | []]), do: [pivot]

  def sort([pivot | tail]) do
    left = for i <- tail, i < pivot, do: i
    right = for j <- tail, j > pivot, do: j

    sort(left) ++ [pivot] ++ sort(right)
  end
end
