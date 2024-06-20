defmodule EtlChallenge.Services.PageServiceTest do
  use ExUnit.Case, async: true

  alias EtlChallenge.Models.Page
  alias EtlChallenge.Repo
  alias EtlChallenge.Factory
  alias EtlChallenge.Services.PageService

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EtlChallenge.Repo)

    :ok
  end

  describe "save_page/2" do
    test "save page with empty numbers list" do
      refute Repo.exists?(Page)

      assert {:ok, page} = PageService.save_page(%{page: 1, numbers: []})

      assert page.page == 1
      assert page.is_failed == true
      assert page.numbers == []
    end

    test "successfully save page" do
      refute Repo.exists?(Page)

      assert {:ok, page} = PageService.save_page(%{page: 1, numbers: [1, 2, 3]})

      assert page.page == 1
      assert page.is_failed == false
      assert page.numbers == [1, 2, 3]
    end
  end

  describe "stats/2" do
    test "returns all info" do
      Enum.each(1..3, &Factory.insert(:page, page: &1, is_failed: true))
      Enum.each(4..5, &Factory.insert(:page, page: &1, is_failed: false))

      assert %{
               total: 5,
               total_failed: 3,
               total_success: 2
             } = PageService.stats()
    end
  end

  describe "get_page/1" do
    test "returns a page given page_number" do
      Factory.insert(:page, page: 1, is_failed: true)

      assert {:ok, %Page{} = page} = PageService.get_page(1)

      assert page.page == 1
      assert page.is_failed == true
    end

    test "returns error when given page_number doesn't exists" do
      assert {:error, :not_found} = PageService.get_page(1)
    end
  end

  describe "get_all_pages_stream/0" do
    test "returns all pages" do
      Enum.each(1..3, &Factory.insert(:page, page: &1, is_failed: true))
      Enum.each(4..5, &Factory.insert(:page, page: &1, is_failed: false))

      stream = PageService.get_all_pages_stream()

      assert is_function(stream)
      assert 5 == Enum.count(stream)

      Enum.each(stream, fn page ->
        assert %Page{} = page
      end)

      assert [1, 2, 3, 4, 5] = Enum.map(stream, & &1.page)
    end
  end

  describe "get_success_pages_stream/0" do
    test "returns success pages" do
      Enum.each(1..3, &Factory.insert(:page, page: &1, is_failed: true))
      Enum.each(4..5, &Factory.insert(:page, page: &1, is_failed: false))

      stream = PageService.get_success_pages_stream()

      assert is_function(stream)
      assert 2 == Enum.count(stream)

      Enum.each(stream, fn page ->
        assert %Page{is_failed: false} = page
      end)

      assert [4, 5] = Enum.map(stream, & &1.page)
    end
  end

  describe "get_failed_pages_stream/0" do
    test "returns failed pages" do
      Enum.each(1..3, &Factory.insert(:page, page: &1, is_failed: true))
      Enum.each(4..5, &Factory.insert(:page, page: &1, is_failed: false))

      stream = PageService.get_failed_pages_stream()

      assert is_function(stream)
      assert 3 == Enum.count(stream)

      Enum.each(stream, fn page ->
        assert %Page{is_failed: true} = page
      end)

      assert [1, 2, 3] = Enum.map(stream, & &1.page)
    end
  end
end
