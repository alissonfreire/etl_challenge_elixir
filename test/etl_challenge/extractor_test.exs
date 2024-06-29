defmodule EtlChallenge.ExtractorTest do
  use EtlChallenge.DataCase, async: true

  import Mox

  alias EtlChallenge.Extractor
  alias EtlChallenge.Extractor.Context
  alias EtlChallenge.Extractor.HookHandlerMock
  alias EtlChallenge.Factory
  alias EtlChallenge.Models.{Info, Page}
  alias EtlChallenge.Repo
  alias EtlChallenge.Requests.Adapters.MockPageAPIImpl
  alias EtlChallenge.Requests.Dtos.Error, as: ErrorDto
  alias EtlChallenge.Requests.Dtos.Page, as: PageDto
  alias EtlChallenge.Requests.Dtos.PageResponse
  alias EtlChallenge.Services.{InfoService, PageService}

  @default_numbers Enum.to_list(1..10)

  describe "start_fetch/1" do
    test "run until the last page" do
      refute Repo.exists?(Page)

      mock_page_api(:success, num_calls: 3)
      mock_page_api(:fail, num_calls: 2)

      assert {:ok, _info} = Extractor.start_fetch(last_page: 5, until_last_page: true)

      assert [_ | _] = pages = Repo.all(Page)
      assert Enum.count(pages) == 5

      success_pages = Enum.filter(pages, &(not &1.is_failed))
      failed_pages = Enum.filter(pages, & &1.is_failed)

      assert Enum.count(success_pages) == 3
      assert Enum.count(failed_pages) == 2

      Enum.each(success_pages, fn page ->
        assert page.page in [1, 2, 3]
        assert page.numbers == @default_numbers
        assert page.is_failed == false
        assert is_nil(page.fail_reason)
      end)

      Enum.each(failed_pages, fn page ->
        assert page.page in [4, 5]
        assert page.numbers == []
        assert page.is_failed == true
        assert page.fail_reason == "api timeout"
      end)

      assert %{total: 5, total_success: 3, total_failed: 2} = PageService.stats()

      assert %Info{} = info = InfoService.get_info()

      assert info.is_finished == true
      assert info.last_page == 5
      assert info.fetched_pages == 5
      assert info.success_pages == 3
      assert info.failed_pages == 2
      assert info.last_stopped_page == 5
    end

    test "run only failed pages" do
      actual_info =
        Factory.insert(:info,
          attempt: 1,
          is_finished: false,
          fetched_pages: 3,
          success_pages: 3,
          failed_pages: 2,
          last_page: 5,
          last_stopped_page: 3
        )

      Enum.each(
        1..3,
        &Factory.insert(:page, page: &1, is_failed: false, numbers: @default_numbers)
      )

      Enum.each(
        4..5,
        &Factory.insert(:page, page: &1, is_failed: true, fail_reason: "api timeout")
      )

      mock_page_api(:success, num_calls: 2)

      assert {:ok, _info} =
               Extractor.start_fetch(actual_info, last_page: 5, only_failed_pages: true)

      assert [_ | _] = pages = Repo.all(Page)
      assert Enum.count(pages) == 5

      success_pages = Enum.filter(pages, &(not &1.is_failed))
      failed_pages = Enum.filter(pages, & &1.is_failed)

      assert Enum.count(success_pages) == 5
      assert Enum.empty?(failed_pages)

      Enum.each(success_pages, fn page ->
        assert page.page in [1, 2, 3, 4, 5]
        assert page.numbers == @default_numbers
        assert page.is_failed == false
        assert is_nil(page.fail_reason)
      end)

      assert %{total: 5, total_success: 5, total_failed: 0} = PageService.stats()

      assert %Info{} = info = InfoService.get_info()

      assert info.is_finished == true
      assert info.last_page == 5
      assert info.fetched_pages == 5
      assert info.success_pages == 5
      assert info.failed_pages == 0
      assert info.last_stopped_page == 5
    end
  end

  describe "start_fetch/1 with hook callbacks" do
    test "call all callback hooks as anonymous function" do
      ref = make_ref()
      me = self()

      hook_handler = fn hook, args, %Context{} ->
        send(me, {ref, {hook, args}})
      end

      mock_page_api(:success, num_calls: 1)

      assert {:ok, _info} =
               Extractor.start_fetch(
                 last_page: 1,
                 until_last_page: true,
                 hook_handler: hook_handler
               )

      assert_receive {^ref, {:pre_fetch_page, 1}}
      assert_receive {^ref, {:pos_fetch_page, {:ok, _page}}}
      assert_receive {^ref, {:pos_handle_page, _args}}
    end

    test "call all callback hooks as hook_handler module" do
      ref = make_ref()
      me = self()

      expect(HookHandlerMock, :call, 3, fn hook, args, %Context{} ->
        send(me, {ref, {hook, args}})
      end)

      mock_page_api(:success, num_calls: 1)

      assert {:ok, _info} =
               Extractor.start_fetch(
                 last_page: 1,
                 until_last_page: true,
                 hook_handler: HookHandlerMock
               )

      assert_receive {^ref, {:pre_fetch_page, 1}}
      assert_receive {^ref, {:pos_fetch_page, {:ok, _page}}}
      assert_receive {^ref, {:pos_handle_page, _args}}
    end
  end

  defp mock_page_api(type, opts) do
    num_calls = Keyword.get(opts, :num_calls, 1)

    expect(MockPageAPIImpl, :fetch_page, num_calls, fn page_number ->
      build_response(type, page_number, opts)
    end)
  end

  defp build_response(:success, page_number, opts) do
    numbers = Keyword.get(opts, :numbers, @default_numbers)

    page = %PageDto{
      page: page_number,
      numbers: numbers
    }

    {:ok, %PageResponse{status: PageResponse.success(), data: page}}
  end

  defp build_response(:fail, page_number, opts) do
    reason = Keyword.get(opts, :reason, "api timeout")

    error = %ErrorDto{
      page: page_number,
      reason: reason
    }

    {:ok, %PageResponse{status: PageResponse.fail(), error: error}}
  end
end
