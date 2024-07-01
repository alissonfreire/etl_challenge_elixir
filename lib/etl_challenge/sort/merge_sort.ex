defmodule EtlChallenge.Sort.MergeSort do
  @moduledoc """
  Merge uses the divide and conquer approach. However, it will divide the list into
  two parts recursively until you reach a base case, then come back by merging the two lists
  """

  alias EtlChallenge.Sort.SortBehaviour
  alias EtlChallenge.Sort.Utils

  @behaviour SortBehaviour

  @impl true
  @spec sort(items :: [number()]) :: [number()]
  def sort([]), do: []
  def sort([i]), do: [i]

  def sort(list) do
    {left, rigth} = Utils.split_list_in_2(list)

    merge(sort(left), sort(rigth))
  end

  defp merge(l, r) do
    do_merge(l, r, [])
  end

  defp do_merge(left, [], list) do
    Enum.reverse(list) ++ left
  end

  defp do_merge([], rigth, list) do
    Enum.reverse(list) ++ rigth
  end

  defp do_merge([hl | tl], [hr | _] = rigth, acc) when hl < hr do
    do_merge(tl, rigth, [hl] ++ acc)
  end

  defp do_merge([hl | _] = left, [hr | tr], acc) when hl >= hr do
    do_merge(left, tr, [hr] ++ acc)
  end
end
