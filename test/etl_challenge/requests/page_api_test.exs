defmodule EtlChallenge.Requests.PageAPITest do
  use ExUnit.Case, async: true

  alias EtlChallenge.Requests.Dtos.{Error, Page, PageResponse}
  alias EtlChallenge.Requests.PageAPI

  alias EtlChallenge.Requests.Adapters.MockPageAPIImpl

  import Mox

  setup :verify_on_exit!

  describe "fetch_page/1" do
    test "successfully returns page" do
      page_number = 1
      numbers = Enum.map(1..10, fn _ -> :rand.uniform(1000) end)

      expect(MockPageAPIImpl, :fetch_page, fn ^page_number ->
        page = %Page{
          page: page_number,
          numbers: numbers
        }

        {:ok, %PageResponse{status: PageResponse.success, data: page}}
      end)

      assert {:ok, %Page{} = page} = PageAPI.fetch_page(page_number)

      assert page.page == page_number
      assert page.numbers == numbers
    end

    test "when api returns error" do
      page_number = 1

      expect(MockPageAPIImpl, :fetch_page, fn ^page_number ->
        error = %Error{
          reason: "invalid api response"
        }

        {:ok, %PageResponse{status: PageResponse.fail, error: error}}
      end)

      assert {:error, %Error{} = error} = PageAPI.fetch_page(page_number)

      assert error.reason == "invalid api response"
    end
  end
end
