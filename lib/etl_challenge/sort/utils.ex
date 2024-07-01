defmodule EtlChallenge.Sort.Utils do
  @moduledoc """
  Useful functions for sorting, for example, split a list into two
  """

  @spec split_list_in_2(items :: [any()]) :: {[any()], [any()]}
  def split_list_in_2([]), do: {[], []}
  def split_list_in_2([i]), do: {[i], []}

  def split_list_in_2(list) do
    len = length(list)
    middle = div(len, 2)

    split_list_in_2(list, {[], []}, {len, middle, 0})
  end

  defp split_list_in_2(_, {left, right}, {size, _, counter})
       when counter == size do
    {Enum.reverse(left), Enum.reverse(right)}
  end

  defp split_list_in_2([head | tail], {left, right}, {size, middle, counter})
       when counter < middle do
    split_list_in_2(tail, {[head] ++ left, right}, {size, middle, counter + 1})
  end

  defp split_list_in_2([head | tail], {left, right}, {size, middle, counter}) do
    split_list_in_2(tail, {left, [head] ++ right}, {size, middle, counter + 1})
  end
end
