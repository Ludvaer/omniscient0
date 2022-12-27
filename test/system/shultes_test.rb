require "application_system_test_case"

class ShultesTest < ApplicationSystemTestCase
  setup do
    @shulte = shultes(:one)
  end

  test "visiting the index" do
    visit shultes_url
    assert_selector "h1", text: "Shultes"
  end

  test "should create shulte" do
    visit shultes_url
    click_on "New shulte"

    fill_in "Mistakes", with: @shulte.mistakes
    fill_in "Shuffle", with: @shulte.shuffle
    fill_in "Size", with: @shulte.size
    fill_in "Time", with: @shulte.time
    fill_in "User", with: @shulte.user_id
    click_on "Create Shulte"

    assert_text "Shulte was successfully created"
    click_on "Back"
  end

  test "should update Shulte" do
    visit shulte_url(@shulte)
    click_on "Edit this shulte", match: :first

    fill_in "Mistakes", with: @shulte.mistakes
    fill_in "Shuffle", with: @shulte.shuffle
    fill_in "Size", with: @shulte.size
    fill_in "Time", with: @shulte.time
    fill_in "User", with: @shulte.user_id
    click_on "Update Shulte"

    assert_text "Shulte was successfully updated"
    click_on "Back"
  end

  test "should destroy Shulte" do
    visit shulte_url(@shulte)
    click_on "Destroy this shulte", match: :first

    assert_text "Shulte was successfully destroyed"
  end
end
