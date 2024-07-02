defmodule EtlChallenge.Services.InfoServiceTest do
  use EtlChallenge.DataCase, async: true

  alias EtlChallenge.Factory
  alias EtlChallenge.Models.Info
  alias EtlChallenge.Repo
  alias EtlChallenge.Services.InfoService

  describe "setup_info/1" do
    test "with invalid params" do
      refute Repo.exists?(Info)

      assert {:error, changeset} = InfoService.setup_info(%{})

      refute Repo.exists?(Info)

      assert %Ecto.Changeset{
               errors: [last_page: {"can't be blank", [validation: :required]}]
             } = changeset
    end

    test "successfully setup info" do
      refute Repo.exists?(Info)

      assert {:ok, info} = InfoService.setup_info(%{last_page: 10_000})

      assert Repo.exists?(Info)

      assert info.attempt == 1
      assert info.last_page == 10_000
    end

    test "don't repeat info register and increment attempt" do
      refute Repo.exists?(Info)

      assert {:ok, info_1} = InfoService.setup_info(%{last_page: 10_000})

      assert Repo.exists?(Info)

      assert {:ok, info_2} = InfoService.setup_info(%{last_page: 20_000})

      assert info_1.id == info_1.id
      assert info_2.attempt == info_1.attempt + 1
      assert info_2.last_page == 20_000
    end

    test "reset values and increment attempt" do
      yesterday =
        DateTime.utc_now()
        |> DateTime.add(-1, :day)
        |> DateTime.truncate(:second)

      actual_info =
        Factory.insert(:info,
          is_finished: true,
          last_page: 10_000,
          fetched_pages: 10,
          success_pages: 4,
          failed_pages: 5,
          last_stopped_page: 9,
          sort_strategy: "merge",
          all_numbers: [2, 3, 1],
          sorted_numbers: [1, 2, 3],
          start_fecthed_at: yesterday,
          finish_fecthed_at: yesterday
        )

      assert {:ok, info_1} = InfoService.setup_info(%{last_page: 20_000})

      assert info_1.id == actual_info.id

      assert info_1.attempt == actual_info.attempt + 1
      assert info_1.last_page == 20_000
      assert info_1.is_finished == false
      assert info_1.fetched_pages == 0
      assert info_1.failed_pages == 0
      assert info_1.last_stopped_page == 0
      assert is_nil(info_1.sort_strategy)
      assert info_1.all_numbers == []
      assert info_1.sorted_numbers == []

      assert DateTime.diff(DateTime.utc_now(), info_1.start_fecthed_at, :second) <= 15
      assert is_nil(info_1.finish_fecthed_at)
    end
  end

  describe "update_info/1" do
    test "successfully update info" do
      Factory.insert(:info)

      params = %{
        attempt: 2,
        is_finished: false,
        fetched_pages: 5,
        success_pages: 3,
        failed_pages: 2,
        last_stopped_page: 2,
        last_page: 10,
        all_numbers: [3, 2, 1],
        sorted_numbers: [1, 2, 3]
      }

      assert {:ok, info} = InfoService.update_info(params)

      assert info.attempt == params.attempt
      assert info.is_finished == params.is_finished
      assert info.fetched_pages == params.fetched_pages
      assert info.success_pages == params.success_pages
      assert info.failed_pages == params.failed_pages
      assert info.last_stopped_page == params.last_stopped_page
      assert info.last_page == params.last_page
      assert info.all_numbers == params.all_numbers
      assert info.sorted_numbers == params.sorted_numbers
    end
  end

  describe "increment_success_pages/2" do
    test "increment success_pages and fetched_pages" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          success_pages: 10
        )

      assert {:ok, info_1} = InfoService.increment_success_pages()

      assert info_1.id == actual_info.id
      assert info_1.fetched_pages == actual_info.fetched_pages + 1
      assert info_1.success_pages == actual_info.success_pages + 1
    end

    test "increment only success_pages" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          success_pages: 10
        )

      assert {:ok, info_1} = InfoService.increment_success_pages(also_inc_fetched_pages: false)

      assert info_1.id == actual_info.id
      assert info_1.fetched_pages == actual_info.fetched_pages
      assert info_1.success_pages == actual_info.success_pages + 1
    end

    test "increment and set last_stopped_page" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          success_pages: 10,
          last_stopped_page: 0,
          is_finished: false
        )

      assert {:ok, info_1} = InfoService.increment_success_pages(set_last_stopped_page: true)

      assert info_1.id == actual_info.id
      assert info_1.last_stopped_page == actual_info.fetched_pages + 1
      assert info_1.success_pages == actual_info.success_pages + 1
      assert info_1.is_finished == true
    end

    test "increment and set specific last_stopped_page" do
      actual_info =
        Factory.insert(:info,
          success_pages: 1,
          last_stopped_page: 1,
          is_finished: false
        )

      assert {:ok, info_1} = InfoService.increment_success_pages(last_stopped_page: 5)

      assert info_1.id == actual_info.id
      assert info_1.last_stopped_page == 5
      assert info_1.success_pages == actual_info.success_pages + 1
      assert info_1.is_finished == false
    end
  end

  describe "increment_failed_pages/2" do
    test "increment failed_pages and fetched_pages" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          failed_pages: 10
        )

      assert {:ok, info_1} = InfoService.increment_failed_pages()

      assert info_1.id == actual_info.id
      assert info_1.fetched_pages == actual_info.fetched_pages + 1
      assert info_1.failed_pages == actual_info.failed_pages + 1
    end

    test "increment only failed_pages" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          failed_pages: 10
        )

      assert {:ok, info_1} = InfoService.increment_failed_pages(also_inc_fetched_pages: false)

      assert info_1.id == actual_info.id
      assert info_1.fetched_pages == actual_info.fetched_pages
      assert info_1.failed_pages == actual_info.failed_pages + 1
    end

    test "increment and set last_stopped_page" do
      actual_info =
        Factory.insert(:info,
          fetched_pages: 10,
          success_pages: 10,
          last_stopped_page: 0,
          is_finished: false
        )

      assert {:ok, info_1} = InfoService.increment_failed_pages(set_last_stopped_page: true)

      assert info_1.id == actual_info.id
      assert info_1.last_stopped_page == actual_info.fetched_pages + 1
      assert info_1.failed_pages == actual_info.failed_pages + 1
      assert info_1.is_finished == true
    end

    test "increment and set specific last_stopped_page" do
      actual_info =
        Factory.insert(:info,
          failed_pages: 1,
          last_stopped_page: 1,
          is_finished: false
        )

      assert {:ok, info_1} = InfoService.increment_failed_pages(last_stopped_page: 5)

      assert info_1.id == actual_info.id
      assert info_1.last_stopped_page == 5
      assert info_1.failed_pages == actual_info.failed_pages + 1
      assert info_1.is_finished == false
    end
  end

  describe "set_all_numbers/1" do
    test "successfully set all_numbers" do
      actual_info = Factory.insert(:info, all_numbers: [])

      assert {:ok, info_1} = InfoService.set_all_numbers([2, 5, 1, 4, 3])

      assert info_1.id == actual_info.id
      refute info_1.all_numbers == actual_info.all_numbers
    end
  end

  describe "set_sorted_numbers/1" do
    test "successfully set sorted_numbers" do
      actual_info = Factory.insert(:info, sorted_numbers: [])

      assert {:ok, info_1} = InfoService.set_sorted_numbers([1, 2, 3, 4, 5, 6])

      assert info_1.id == actual_info.id
      refute info_1.sorted_numbers == actual_info.sorted_numbers
    end
  end
end
