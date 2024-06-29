defmodule EtlChallenge.Services.PageServiceTest do
  use EtlChallenge.DataCase, async: true

  alias EtlChallenge.Factory
  alias EtlChallenge.Models.Page
  alias EtlChallenge.Repo
  alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
  alias EtlChallenge.Requests.Dtos.Page, as: PageDto
  alias EtlChallenge.Services.PageService

  describe "save_page/2" do
    test "don't insert page without page_number" do
      assert {:error, changeset} = PageService.save_page(%{numbers: [1, 2, 3]})

      assert %Ecto.Changeset{
               valid?: false,
               errors: [page: {"can't be blank", [validation: :required]}]
             } = changeset
    end

    test "don't insert page with empty numbers list without fail reason" do
      refute Repo.exists?(Page)

      assert {:error, changeset} = PageService.save_page(%{page: 1, numbers: []})

      assert %Ecto.Changeset{
               valid?: false,
               errors: [numbers: {"can't be empty without fail reason", []}]
             } = changeset

      assert {:ok, page} =
               PageService.save_page(%{
                 page: 1,
                 fail_reason: "api timeout",
                 numbers: []
               })

      assert page.page == 1
      assert page.is_failed == true
      assert page.fail_reason == "api timeout"
      assert page.numbers == []
    end

    test "successfully insert page" do
      refute Repo.exists?(Page)

      assert {:ok, page} = PageService.save_page(%{page: 1, numbers: [1, 2, 3]})

      assert page.page == 1
      assert page.is_failed == false
      assert is_nil(page.fail_reason)
      assert page.numbers == [1, 2, 3]
    end

    test "successfully insert page from PageDto struct" do
      refute Repo.exists?(Page)

      assert {:ok, page} = PageService.save_page(%PageDto{page: 1, numbers: [1, 2, 3]})

      assert page.page == 1
      assert page.is_failed == false
      assert is_nil(page.fail_reason)
      assert page.numbers == [1, 2, 3]
    end

    test "successfully insert page from ErrorDto struct" do
      refute Repo.exists?(Page)

      assert {:ok, page} = PageService.save_page(%ErrorDto{page: 1, reason: "api timeout"})

      assert page.page == 1
      assert page.is_failed == true
      assert page.numbers == []
      assert page.fail_reason == "api timeout"
    end

    test "successfully update failed page with numbers" do
      _page =
        Factory.insert(:page,
          page: 1,
          is_failed: true,
          fail_reason: "api timeout"
        )

      assert {:ok, page} = PageService.save_page(%PageDto{page: 1, numbers: [1, 2, 3]})

      assert page.page == 1
      assert page.is_failed == false
      assert page.numbers == [1, 2, 3]
      assert is_nil(page.fail_reason)
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

  describe "clear_pages/0" do
    test "it delete all pages" do
      Enum.each(1..3, &Factory.insert(:page, page: &1, is_failed: true))
      Enum.each(4..5, &Factory.insert(:page, page: &1, is_failed: false))

      assert Repo.exists?(Page)

      assert {:ok, 5} = PageService.clear_all_pages()
      refute Repo.exists?(Page)
    end
  end
end
